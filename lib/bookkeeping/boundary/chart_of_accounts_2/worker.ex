defmodule Bookkeeping.Boundary.ChartOfAccounts2.Worker do
  use GenServer

  alias Bookkeeping.Core.Account
  alias NimbleCSV.RFC4180, as: CSV

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec create(Account.create_params()) ::
          {:error, :invalid_params}
          | {:error, :invalid_field}
          | {:error, :already_exists}
          | {:ok, Account.t()}
  def create(params) do
    GenServer.call(__MODULE__, {:create, params})
  end

  @spec import_file(String.t()) ::
          {:error, :invalid_file}
          | {:ok,
             %{
               oks: list(Account.t()),
               errors:
                 list(%{
                   reason: :invalid_params | :invalid_field | :already_exists,
                   params: Account.create_params()
                 })
             }}
  def import_file(file_path) do
    file_path |> check_csv() |> read_csv() |> bulk_generate_params() |> bulk_create()
  end

  @spec search_code(Account.account_code()) :: {:error, :not_found} | {:ok, Account.t()}
  def search_code(code) do
    GenServer.call(__MODULE__, {:search_code, code})
  end

  @spec search_name(String.t()) :: {:error, :not_found} | {:ok, Account.t()}
  def search_name(name) do
    GenServer.call(__MODULE__, {:search_name, name})
  end

  @spec init(any()) :: {:ok, nil}
  def init(_) do
    {:ok, nil}
  end

  def handle_info({:"ETS-TRANSFER", table, _pid, _data}, _table) do
    {:noreply, table}
  end

  def handle_call({:create, params}, _from, table) do
    result = create(table, params)
    {:reply, result, table}
  end

  def handle_call({:search_code, code}, _from, table) do
    result = search_code(table, code)
    {:reply, result, table}
  end

  def handle_call({:search_name, name}, _from, table) do
    result = search_name(table, name)
    {:reply, result, table}
  end

  defp create(table, params) do
    with {:ok, params} <- check_similar_account(table, params),
         {:ok, account} <- Account.create(params) do
      :ets.insert(table, {account.code, account.name, account})
      {:ok, account}
    end
  end

  defp check_similar_account(table, params) do
    code = Map.get(params, :code, "")
    name = Map.get(params, :name, "")

    with {:error, :not_found} <- search_code(table, code),
         {:error, :not_found} <- search_name(table, name) do
      {:ok, params}
    else
      {:ok, _account} -> {:error, :already_exists}
    end
  end

  defp search_code(table, code) do
    case :ets.lookup(table, code) do
      [{_, _, account}] -> {:ok, account}
      [] -> {:error, :not_found}
    end
  end

  defp search_name(table, name) do
    result = :ets.match(table, {:_, name, :"$1"}) |> List.flatten() |> List.first()
    if is_nil(result), do: {:error, :not_found}, else: {:ok, result}
  end

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
      code = Map.get(csv_item, "Account Code")
      name = Map.get(csv_item, "Account Name")
      classification = Map.get(csv_item, "Account Type")
      description = Map.get(csv_item, "Account Description", "")

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

  defp bulk_create([]), do: {:error, :invalid_file}

  defp bulk_create(params_list) when is_list(params_list) do
    Enum.reduce(params_list, %{oks: [], errors: []}, fn params, acc ->
      case create(params) do
        {:ok, account} -> %{acc | oks: [account | acc.oks]}
        {:error, reason} -> %{acc | errors: [%{reason: reason, params: params} | acc.errors]}
      end
    end)
  end

  defp bulk_create(error), do: error
end
