defmodule Bookkeeping.Boundary.ChartOfAccounts.Worker do
  @moduledoc """
  This module is responsible for managing the chart of accounts.
  The Chart of Accounts is a list of all the accounts used by an organization.
  This module wraps the private Chart of Accounts ETS table and provides the interface to other modules.
  The ETS table is a key-value store where the key is the account code, and the values are the account name and the account struct.
  """
  use GenServer

  alias Bookkeeping.Core.Account
  alias NimbleCSV.RFC4180, as: CSV

  @spec start_link(any()) :: {:ok, pid()} | {:error, any()} | {:error, :already_started}
  def start_link(_) do
    case GenServer.start_link(__MODULE__, :ok, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @spec create(Account.create_params()) ::
          {:ok, Account.t()}
          | {:error, :already_exists | :invalid_field | :invalid_params}
  def create(params), do: maybe_handle_call({:create, params})

  @spec import_file(String.t()) ::
          {:ok,
           %{
             accounts: list(Account.t()),
             errors:
               list(%{
                 reason: :invalid_params | :invalid_field | :already_exists,
                 params: Account.create_params()
               })
           }}
          | {:error, :invalid_file}
  def import_file(file_path) do
    file_path
    |> check_csv()
    |> read_csv()
    |> bulk_generate_params()
    |> bulk_create()
  end

  @spec update(Account.t(), Account.update_params()) ::
          {:ok, Account.t()}
          | {:error, :invalid_account | :invalid_field | :invalid_params}
  def update(account, params), do: maybe_handle_call({:update, account, params})

  @spec all_accounts() :: {:ok, list(Account.t())}
  def all_accounts, do: maybe_handle_call(:all_accounts)

  @spec search_code(Account.account_code()) :: {:ok, list(Account.t())} | {:error, :invalid_code}
  def search_code(code), do: maybe_handle_call({:search_code, code})

  @spec search_name(String.t()) :: {:ok, list(Account.t())} | {:error, :invalid_name}
  def search_name(name), do: maybe_handle_call({:search_name, name})

  @spec die() :: :ok
  def die, do: GenServer.cast(__MODULE__, :die)

  @spec init(any()) :: {:ok, nil}
  @impl true
  def init(_), do: {:ok, nil}

  @impl true
  def handle_info({:"ETS-TRANSFER", table, _pid, _data}, _table), do: {:noreply, table}

  @impl true
  def handle_call({:create, params}, _from, table) do
    account = maybe_handle_function(&create/2, table, [params])
    {:reply, account, table}
  end

  @impl true
  def handle_call({:update, account, params}, _from, table) do
    account = maybe_handle_function(&update/3, table, [account, params])
    {:reply, account, table}
  end

  @impl true
  def handle_call(:all_accounts, _from, table) do
    accounts = maybe_handle_function(&all_accounts/1, table)
    {:reply, accounts, table}
  end

  @impl true
  def handle_call({:search_code, prefix}, _from, table) do
    accounts = maybe_handle_function(&prefix_search_code/2, table, [prefix])
    {:reply, accounts, table}
  end

  @impl true
  def handle_call({:search_name, prefix}, _from, table) do
    accounts = maybe_handle_function(&prefix_search_name/2, table, [prefix])
    {:reply, accounts, table}
  end

  @impl true
  def handle_cast(:die, table) do
    table = maybe_handle_function(fn x -> x end, table)
    {:stop, table, :killed}
  end

  defp maybe_handle_function(fun, table, params \\ []) do
    with {:ok, table} <- check_table(table) do
      case params do
        [] -> fun.(table)
        [params] -> fun.(table, params)
        [params1, params2] -> fun.(table, params1, params2)
      end
    end
  end

  defp check_table(table) do
    if Enum.member?(:ets.all(), table), do: {:ok, table}, else: {:error, :invalid_table}
  end

  defp create(table, params) do
    with {:ok, account} <- Account.create(params),
         {:error, :not_found} <- check_similar_account(table, account) do
      :ets.insert(table, {account.code, account.name, account})
      {:ok, account}
    end
  end

  defp update(table, account, params) do
    with {:ok, account} <- Account.update(account, params) do
      :ets.insert(table, {account.code, account.name, account})
      {:ok, account}
    end
  end

  defp all_accounts(table) do
    {:ok, :ets.select(table, [{{:_, :_, :"$1"}, [], [:"$1"]}])}
  end

  defp check_similar_account(table, account) do
    with {:ok, _account} <- match_code(table, account.code),
         {:ok, _account} <- match_name(table, account.name) do
      {:error, :already_exists}
    end
  end

  defp match_code(table, code) do
    case :ets.lookup(table, code) do
      [{_, _, account}] -> {:ok, account}
      _ -> {:error, :not_found}
    end
  end

  defp match_name(table, name) do
    result = :ets.select(table, [{{:_, name, :"$1"}, [], [:"$1"]}]) |> List.first()
    if is_nil(result), do: {:error, :not_found}, else: {:ok, result}
  end

  defp prefix_search_code(table, prefix) when is_binary(prefix) and prefix != "" do
    accounts =
      :ets.foldl(
        fn
          {code, _, account}, acc ->
            if String.starts_with?(code, prefix), do: [account | acc], else: acc

          _, acc ->
            acc
        end,
        [],
        table
      )

    {:ok, accounts}
  end

  defp prefix_search_code(_table, _code), do: {:error, :invalid_code}

  defp prefix_search_name(table, prefix) when is_binary(prefix) and prefix != "" do
    accounts =
      :ets.foldl(
        fn
          {_, name, account}, acc ->
            if String.starts_with?(name, prefix), do: [account | acc], else: acc

          _, acc ->
            acc
        end,
        [],
        table
      )

    {:ok, accounts}
  end

  defp prefix_search_name(_table, _name), do: {:error, :invalid_name}

  defp check_csv(path) when is_binary(path) do
    file_path = Path.expand(path, __DIR__)

    if File.exists?(file_path),
      do: {:ok, file_path},
      else: {:error, :invalid_file}
  end

  defp check_csv(_path), do: {:error, :invalid_file}

  defp read_csv({:ok, path}) do
    csv_inputs =
      path
      |> File.stream!()
      |> CSV.parse_stream(skip_headers: false)
      |> Stream.transform(nil, fn
        headers, nil -> {[], headers}
        row, headers -> {[Enum.zip(headers, row) |> Map.new()], headers}
      end)
      |> Enum.to_list()

    if csv_inputs == [], do: {:error, :invalid_file}, else: {:ok, csv_inputs}
  end

  defp read_csv(error), do: error

  defp bulk_generate_params({:ok, csv}) do
    Enum.reduce(csv, [], fn csv_item, acc ->
      code = Map.get(csv_item, "Code")
      name = Map.get(csv_item, "Name")
      classification = Map.get(csv_item, "Classification")
      description = Map.get(csv_item, "Description", "")

      audit_details =
        case csv_item |> Map.get("Audit Details", "{}") |> Jason.decode() do
          {:ok, audit_details} -> audit_details
          {:error, _} -> %{}
        end

      params = %{
        code: code,
        name: name,
        classification: classification,
        description: description,
        audit_details: audit_details,
        active: true
      }

      [params | acc]
    end)
  end

  defp bulk_generate_params(error), do: error

  defp bulk_create(params_list) when is_list(params_list) do
    Enum.reduce(params_list, %{accounts: [], errors: []}, fn params, acc ->
      case create(params) do
        {:ok, account} -> %{acc | accounts: [account | acc.accounts]}
        {:error, reason} -> %{acc | errors: [%{reason: reason, params: params} | acc.errors]}
      end
    end)
  end

  defp bulk_create(error), do: error

  defp maybe_handle_call(handle_call, backoff \\ 100) do
    result =
      try do
        GenServer.call(__MODULE__, handle_call)
      catch
        _message, _reason -> {:error, :invalid_table}
      end

    case result do
      {:error, :invalid_table} ->
        Process.sleep(backoff)
        backoff = min(3000, round(backoff * 2))
        maybe_handle_call(handle_call, backoff)

      result ->
        result
    end
  end
end
