defmodule Bookkeeping.Boundary.ChartOfAccounts.Server do
  @moduledoc """
  Bookkeeping.Boundary.ChartOfAccounts.Server is a GenServer that manages the chart of accounts.
  Chart of Accounts is a list of all accounts used by a business.
  The Chart Of Accounts GenServer is responsible for creating, updating, and searching accounts.
  The state of the Chart Of Accounts GenServer is a map in which the keys are the account codes and the values are the account structs.
  """
  use GenServer

  alias Bookkeeping.Boundary.ChartOfAccounts.Backup, as: ChartOfAccountsBackup
  alias Bookkeeping.Core.Account
  alias NimbleCSV.RFC4180, as: CSV

  @typedoc """
  The state of the Chart Of Accounts GenServer.
  The state is a map in which the keys are the account codes and the values are the account structs.

  ## Examples

      iex> %{
      ...>   "1000" => %Account{
      ...>     id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>     code: "1000",
      ...>     name: "Cash",
      ...>     description: "",
      ...>     account_classification: %AccountClassification{
      ...>       name: "Asset",
      ...>       normal_balance: :debit,
      ...>       category: :position,
      ...>       contra: false
      ...>     },
      ...>     active: true,
      ...>     audit_logs: [
      ...>       %AuditLog{
      ...>         id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>         record_type: "account",
      ...>         action_type: "create",
      ...>         details: %{},
      ...>         created_at: 1633860610,
      ...>         updated_at: 1633860610,
      ...>         deleted_at: nil
      ...>       }
      ...>     ]
      ...>   },
      ...>   ...
      ...> }
  """
  @type chart_of_account_state :: %{Account.account_code() => Account.t()}
  @type chart_of_accounts_server_pid :: atom | pid | {atom, any} | {:via, atom, any}

  @account_classifications [
    "asset",
    "liability",
    "equity",
    "revenue",
    "expense",
    "gain",
    "loss",
    "contra_asset",
    "contra_liability",
    "contra_equity",
    "contra_revenue",
    "contra_expense",
    "contra_gain",
    "contra_loss"
  ]

  @doc """
  Starts the Chart of Accounts GenServer.

  Returns `{:ok, pid}` if the GenServer is started successfully.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.start_link()
      {:ok, #PID<0.123.0>}
  """
  @spec start_link(Keyword.t()) :: {:ok, pid}
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, %{}, options)
  end

  @doc """
  Creates a new account.

  Arguments:
    - code: The unique code of the account.
    - name: The unique name of the account.
    - account_classification: The type of the account. The account classification must be one of the following: `"asset"`, `"liability"`, `"equity"`, `"revenue"`, `"expense"`, `"gain"`, `"loss"`, `"contra_asset"`, `"contra_liability"`, `"contra_equity"`, `"contra_revenue"`, `"contra_expense"`, `"contra_gain"`, `"contra_loss"`.
    - description: The description of the account.
    - audit_details: The audit details of the account.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.create_account(server, "1000", "Cash", "asset", "", %{})
      {:ok, %Bookkeeping.Core.Account{...}}

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.create_account(server, "invalid", "invalid", nil, false, %{})
      {:error, :invalid_account}
  """
  @spec create_account(
          chart_of_accounts_server_pid(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          map()
        ) :: {:ok, Account.t()} | {:error, :invalid_account} | {:error, :account_already_exists}
  def create_account(
        server \\ __MODULE__,
        code,
        name,
        account_classification,
        description,
        audit_details
      ) do
    create_account_record(server, code, name, account_classification, description, audit_details)
  end

  @doc """
  Imports default accounts from a CSV file.
  The headers of the CSV file must be `Account Code`, `Account Name`, `Account Type`, `Description`, and `Audit Details`.

  Arguments:
    - path: The path of the CSV file. The path to the default accounts is "../data/sample_chart_of_accounts.csv".

  Returns `{:ok, %{ok: list(map()), error: list(map())}}` if the accounts are imported successfully. If all items are encountered an error, return `{:error, %{ok: list(map()), error: list(map())}}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.import_accounts(server, "../data/sample_chart_of_accounts.csv")
      {:ok,
      %{
        ok: [
          %{account_code: "1000", account_name: "Cash"},
          %{account_code: "1010", account_name: "Petty Cash"},
          %{account_code: "1020", account_name: "Cash on Hand"},
          %{account_code: "1030", account_name: "Cash in Bank"}
        ],
        error: []
      }}

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.import_accounts(server, "../data/invalid_chart_of_accounts.csv")
      {:error,
      %{
        ok: [],
        error: [
          %{
            account_code: "1001",
            account_name: "Cash",
            error: :account_already_exists
          },
          %{
            account_code: "1002",
            account_name: "Cash",
            error: :invalid_account
          },
          ...
        ]
      }}
  """
  @spec import_accounts(chart_of_accounts_server_pid(), String.t()) ::
          {:ok, %{ok: list(Account.t()), error: list(map())}}
          | {:error, %{ok: list(Account.t()), error: list(map())}}
          | {:error, %{message: :invalid_csv, errors: list(map())}}
          | {:error, :invalid_file}
  def import_accounts(server \\ __MODULE__, path) do
    with file_path <- Path.expand(path, __DIR__),
         true <- File.exists?(file_path),
         {:ok, csv} <- read_csv(file_path) do
      bulk_create_accounts(server, csv)
    else
      _error -> {:error, :invalid_file}
    end
  end

  @doc """
  Updates an account.

  Arguments:
    - account: The account to be updated.
    - attrs: The attributes to be updated. The editable attributes are `name`, `description`, `active`, and `audit_details`.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.update_account(server, account, %{name: "Cash and cash equivalents"})
      {:ok, %Bookkeeping.Core.Account{...}}
  """
  @spec update_account(chart_of_accounts_server_pid(), Account.t(), map()) ::
          {:ok, Account.t()} | {:error, :invalid_account}
  def update_account(server \\ __MODULE__, account, attrs) do
    GenServer.call(server, {:update_account, account, attrs})
  end

  @doc """
  Returns all accounts.

  Returns `{:ok, accounts}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.all_accounts(server)
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}
  """
  @spec all_accounts(chart_of_accounts_server_pid()) :: {:ok, list(Account.t())}
  def all_accounts(server \\ __MODULE__) do
    GenServer.call(server, :all_accounts)
  end

  @doc """
  Finds an account by code.

  Arguments:
    - code: The unique code of the account.

  Returns `{:ok, account}` if the account was found, otherwise `{:error, :not_found}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.find_account_by_code(server, "1000")
      {:ok, %Bookkeeping.Core.Account{...}}
  """
  @spec find_account_by_code(chart_of_accounts_server_pid(), String.t()) ::
          {:ok, Account.t()} | {:error, :not_found}
  def find_account_by_code(server \\ __MODULE__, code)

  def find_account_by_code(server, code) when is_binary(code),
    do: GenServer.call(server, {:find_account_by_code, code})

  def find_account_by_code(_server, _code), do: {:error, :invalid_code}

  @doc """
  Finds an account by name.

  Arguments:
    - name: The unique name of the account.

  Returns `{:ok, account}` if the account was found, otherwise `{:error, :not_found}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.find_account_by_name(server, "Cash")
      {:ok, %Bookkeeping.Core.Account{...}}
  """
  @spec find_account_by_name(chart_of_accounts_server_pid(), String.t()) ::
          {:ok, Account.t()} | {:error, :not_found}
  def find_account_by_name(server \\ __MODULE__, name)

  def find_account_by_name(server, name) when is_binary(name),
    do: GenServer.call(server, {:find_account_by_name, name})

  def find_account_by_name(_server, _name), do: {:error, :invalid_name}

  @doc """
  Search accounts by code or name.

  Arguments:
    - query: The query to search for code or name.

  Returns `{:ok, accounts}` if the account was found, otherwise `{:ok, []}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.search_accounts(server, "1000")
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}
  """
  @spec search_accounts(chart_of_accounts_server_pid(), String.t()) ::
          {:ok, list(Account.t())} | {:error, :invalid_query}
  def search_accounts(server \\ __MODULE__, query)

  def search_accounts(server, query) when is_binary(query),
    do: GenServer.call(server, {:search_accounts, query})

  def search_accounts(_server, _query), do: {:error, :invalid_query}

  @doc """
  Get all accounts sorted by code or name.

  Returns `{:ok, accounts}` if the accounts were sorted successfully, otherwise `{:error, :invalid_field}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.all_sorted_accounts(server, :code)
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}
  """
  @spec all_sorted_accounts(chart_of_accounts_server_pid(), String.t()) ::
          {:ok, list(Account.t())} | {:error, :invalid_field}
  def all_sorted_accounts(server \\ __MODULE__, field)
  def all_sorted_accounts(server, "code"), do: GenServer.call(server, {:sort_accounts, :code})
  def all_sorted_accounts(server, "name"), do: GenServer.call(server, {:sort_accounts, :name})
  def all_sorted_accounts(_server, _field), do: {:error, :invalid_field}

  @doc """
  Resets the accounts.

  Returns `{:ok, []}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.reset_accounts(server)
      {:ok, []}
  """
  @spec reset_accounts(chart_of_accounts_server_pid()) :: {:ok, list(Account.t())}
  def reset_accounts(server \\ __MODULE__) do
    GenServer.call(server, :reset_accounts)
  end

  @doc """
  Returns the state of the Chart Of Accounts GenServer.

  Returns `{:ok, state}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.Server.get_chart_of_accounts_state(server)
      {:ok, %{...}}
  """
  @spec get_chart_of_accounts_state(chart_of_accounts_server_pid()) ::
          {:ok, chart_of_account_state()}
  def get_chart_of_accounts_state(server \\ __MODULE__) do
    GenServer.call(server, :get_chart_of_accounts_state)
  end

  @impl true
  @spec init(chart_of_account_state()) :: {:ok, chart_of_account_state()}
  def init(_chart_of_accounts) do
    ChartOfAccountsBackup.get()
  end

  @impl true
  def handle_call(
        {:create_account, code, name, account_classification, description, audit_details},
        _from,
        accounts
      ) do
    case Account.create(code, name, account_classification, description, audit_details) do
      {:ok, account} ->
        updated_accounts = Map.put(accounts, code, account)
        {:reply, {:ok, account}, updated_accounts, :hibernate}

      {:error, message} ->
        {:reply, {:error, message}, accounts, :hibernate}
    end
  end

  @impl true
  def handle_call({:update_account, account, attrs}, _from, accounts) do
    with {:ok, account} <- Account.validate_account(account),
         {:ok, updated_account} <- Account.update(account, attrs) do
      updated_accounts =
        accounts
        |> Map.delete(account.code)
        |> Map.put(updated_account.code, updated_account)

      {:reply, {:ok, updated_account}, updated_accounts, :hibernate}
    else
      _ ->
        {:reply, {:error, :invalid_account}, accounts, :hibernate}
    end
  end

  @impl true
  def handle_call(:all_accounts, from, accounts) do
    Task.async(fn -> GenServer.reply(from, {:ok, Map.values(accounts)}) end)
    {:noreply, accounts}
  end

  @impl true
  def handle_call({:find_account_by_code, code}, from, accounts) do
    Task.async(fn ->
      case Map.get(accounts, code) do
        nil -> GenServer.reply(from, {:error, :not_found})
        account -> GenServer.reply(from, {:ok, account})
      end
    end)

    {:noreply, accounts, :hibernate}
  end

  @impl true
  def handle_call({:find_account_by_name, name}, from, accounts) do
    Task.async(fn ->
      result =
        Enum.find(accounts, fn {_code, account} ->
          String.downcase(account.name) == String.downcase(name)
        end)

      case result do
        nil -> GenServer.reply(from, {:error, :not_found})
        {_code, account} -> GenServer.reply(from, {:ok, account})
      end
    end)

    {:noreply, accounts, :hibernate}
  end

  @impl true
  def handle_call({:search_accounts, binary_query}, from, accounts) do
    Task.async(fn ->
      found_accounts =
        accounts
        |> Task.async_stream(fn {code, account} ->
          query = String.downcase(binary_query)
          name = String.downcase(account.name)
          found? = String.contains?(code, query) or String.contains?(name, query)
          {found?, account}
        end)
        |> Enum.reduce([], fn
          {:ok, {true, account}}, acc -> acc ++ [account]
          _, acc -> acc
        end)

      GenServer.reply(from, {:ok, found_accounts})
    end)

    {:noreply, accounts}
  end

  @impl true
  def handle_call({:sort_accounts, field}, from, accounts) do
    Task.async(fn ->
      sorted_accounts = Enum.sort_by(Map.values(accounts), &Map.get(&1, field))
      GenServer.reply(from, {:ok, sorted_accounts})
    end)

    {:noreply, accounts}
  end

  @impl true
  def handle_call(:reset_accounts, _from, _chart_of_accounts) do
    ChartOfAccountsBackup.update(%{})
    {:reply, {:ok, []}, %{}}
  end

  @impl true
  def handle_call(:get_chart_of_accounts_state, from, accounts) do
    Task.async(fn -> GenServer.reply(from, {:ok, accounts}) end)
    {:noreply, accounts}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, chart_of_accounts) do
    ChartOfAccountsBackup.update(chart_of_accounts)
  end

  defp create_account_record(
         server,
         code,
         name,
         account_classification,
         description,
         audit_details
       ) do
    valid_fields? =
      is_binary(code) and is_binary(name) and account_classification in @account_classifications

    with true <- valid_fields?,
         {:error, :not_found} <- GenServer.call(server, {:find_account_by_code, code}),
         {:error, :not_found} <- GenServer.call(server, {:find_account_by_name, name}) do
      GenServer.call(
        server,
        {:create_account, code, name, account_classification, description, audit_details}
      )
    else
      {:ok, _account} -> {:error, :account_already_exists}
      _ -> {:error, :invalid_account}
    end
  end

  defp bulk_create_accounts(server, csv) when is_list(csv) and csv != [] do
    with %{ok: ok_create_params, error: []} <- generate_bulk_create_params(csv),
         {:ok, result} <- bulk_create_acc_records(server, ok_create_params) do
      {:ok, result}
    else
      %{ok: _ok_create_params, error: errors} ->
        {:error, %{message: :invalid_csv, errors: errors}}

      {:error, result} ->
        {:error, result}
    end
  end

  defp bulk_create_accounts(_server, _csv), do: {:error, :invalid_file}

  defp bulk_create_acc_records(server, create_params_list) do
    result =
      Enum.reduce(
        create_params_list,
        %{ok: [], error: []},
        fn params, acc ->
          case create_account_record(
                 server,
                 params.account_code,
                 params.account_name,
                 params.account_classification,
                 params.description,
                 params.audit_details
               ) do
            {:ok, account} ->
              Map.put(acc, :ok, [account | acc.ok])

            {:error, error} ->
              errors =
                acc.error ++
                  [
                    %{
                      account_code: params.account_code,
                      account_name: params.account_name,
                      error: error
                    }
                  ]

              Map.put(acc, :error, errors)
          end
        end
      )

    if result.ok == [], do: {:error, result}, else: {:ok, result}
  end

  defp generate_bulk_create_params(csv) do
    Enum.reduce(
      csv,
      %{ok: [], error: []},
      fn csv_item, acc ->
        account_code = Map.get(csv_item, "Account Code")
        account_name = Map.get(csv_item, "Account Name")
        account_classification = Map.get(csv_item, "Account Type")
        description = Map.get(csv_item, "Account Description", "")
        audit_details = Map.get(csv_item, "Audit Details", "{}")

        valid_csv_items? =
          is_binary(account_code) and account_code != "" and is_binary(account_name) and
            account_name != "" and is_binary(description) and
            account_classification in @account_classifications

        with true <- valid_csv_items?,
             {:ok, audit_details} <- Jason.decode(audit_details) do
          valid_params = %{
            account_code: account_code,
            account_name: account_name,
            account_classification: account_classification,
            description: description,
            audit_details: audit_details
          }

          Map.put(acc, :ok, acc.ok ++ [valid_params])
        else
          {:error, %Jason.DecodeError{} = _error} ->
            errors =
              acc.error ++
                [
                  %{
                    account_code: account_code,
                    account_name: account_name,
                    error: :invalid_csv_item
                  }
                ]

            Map.put(acc, :error, errors)

          _ ->
            errors =
              acc.error ++
                [
                  %{
                    account_code: account_code,
                    account_name: account_name,
                    error: :invalid_csv_item
                  }
                ]

            Map.put(acc, :error, errors)
        end
      end
    )
  end

  defp read_csv(path) do
    csv_inputs =
      path
      |> File.stream!()
      |> CSV.parse_stream(skip_headers: false)
      |> Stream.transform(nil, fn
        headers, nil -> {[], headers}
        row, headers -> {[Enum.zip(headers, row) |> Map.new()], headers}
      end)
      |> Enum.to_list()

    {:ok, csv_inputs}
  end
end
