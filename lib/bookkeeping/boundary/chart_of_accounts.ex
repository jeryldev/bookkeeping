defmodule Bookkeeping.Boundary.ChartOfAccounts do
  @moduledoc """
  Bookkeeping.Boundary.ChartOfAccounts is a GenServer that manages the chart of accounts.
  Chart of Accounts is a list of all accounts used by a business.
  The Chart Of Accounts GenServer is responsible for creating, updating, and searching accounts.
  The state of the Chart Of Accounts GenServer is a map in which the keys are the account codes and the values are the account structs.
  """
  use GenServer

  alias Bookkeeping.Core.Account
  alias NimbleCSV.RFC4180, as: CSV

  @typedoc """
  The state of the Chart Of Accounts GenServer.
  The state is a map in which the keys are the account codes and the values are the account structs.

  ## Examples

      iex> %{
      ...>   "1000" => %Account{
      ...>     code: "1000",
      ...>     name: "Cash",
      ...>     description: "",
      ...>     account_type: %AccountType{
      ...>       name: "Asset",
      ...>       normal_balance: :debit,
      ...>       primary_account_category: :balance_sheet,
      ...>       contra: false
      ...>     },
      ...>     active: true,
      ...>     audit_logs: [
      ...>       %AuditLog{
      ...>         id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>         record_type: "account",
      ...>         action_type: "create",
      ...>         details: %{},
      ...>         created_at: ~U[2021-10-10 10:10:10.000000Z],
      ...>         updated_at: ~U[2021-10-10 10:10:10.000000Z],
      ...>         deleted_at: nil
      ...>       }
      ...>     ]
      ...>   },
      ...>   ...
      ...> }
  """
  @type chart_of_account_state :: %{Account.account_code() => Account.t()}

  @account_types [
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

      iex> Bookkeeping.Boundary.ChartOfAccounts.start_link()
      {:ok, #PID<0.123.0>}
  """
  @spec start_link(Keyword.t()) :: {:ok, pid}
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  @doc """
  Creates a new account.

  Arguments:
    - code: The unique code of the account.
    - name: The unique name of the account.
    - account_type: The type of the account. The account type must be one of the following: `"asset"`, `"liability"`, `"equity"`, `"revenue"`, `"expense"`, `"gain"`, `"loss"`, `"contra_asset"`, `"contra_liability"`, `"contra_equity"`, `"contra_revenue"`, `"contra_expense"`, `"contra_gain"`, `"contra_loss"`.
    - description (optional): The description of the account.
    - audit_details (optional): The audit details of the account.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.create_account(server, "1000", "Cash", "asset", "", %{})
      {:ok,
      %Bookkeeping.Core.Account{
        code: "1000",
        name: "Cash",
        description: "",
        account_type: %AccountType{
          name: "Asset",
          normal_balance: :debit,
          primary_account_category: :balance_sheet,
          contra: false
        },
        active: true,
        audit_logs: [
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "account",
            action_type: "create",
            details: %{},
            created_at: ~U[2021-10-10 10:10:10.000000Z],
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          }
        ]
      }}
  """
  @spec create_account(String.t(), String.t(), String.t()) ::
          {:ok, Account.t()} | {:error, :invalid_account} | {:error, :account_already_exists}
  def create_account(server \\ __MODULE__, code, name, account_type),
    do: create_account_record(server, code, name, account_type)

  @spec create_account(String.t(), String.t(), String.t(), String.t(), map()) ::
          {:ok, Account.t()} | {:error, :invalid_account} | {:error, :account_already_exists}
  def create_account(server \\ __MODULE__, code, name, account_type, description, audit_details),
    do: create_account_record(server, code, name, account_type, description, audit_details)

  @doc """
  Loads default accounts from a CSV file.

  Arguments:
    - path: The path of the CSV file. The path to the default accounts is "../assets/chart_of_accounts.csv".

  Returns `{:ok, %{ok: list(map()), error: list(map())}}` if the accounts are loaded successfully. If all items are encountered an error, return `{:error, %{ok: list(map()), error: list(map())}}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.load_default_accounts(server, "../assets/chart_of_accounts.csv")
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

      iex> Bookkeeping.Boundary.ChartOfAccounts.load_default_accounts(server, "../priv/data/invalid_chart_of_accounts.csv")
      {:error,
      %{
        ok: [],
        error: [
          %{
            account_code: "1000",
            account_name: "Cash",
            error: :account_already_exists
          },
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
          %{
            account_code: "1003",
            account_name: "Cash",
            error: :invalid_account
          }
        ]
      }}
  """
  def load_default_accounts(server \\ __MODULE__, path) do
    with file_path <- Path.expand(path, __DIR__),
         true <- File.exists?(file_path),
         {:ok, csv} <- read_csv(file_path) do
      bulk_create_account_records(server, csv)
    else
      _ -> {:error, :invalid_file}
    end
  end

  @doc """
  Updates an account.

  Arguments:
    - account: The account to be updated.
    - attrs: The attributes to be updated. The editable attributes are `name`, `description`, `active`, and `audit_details`.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.update_account(server, account, %{name: "Cash and cash equivalents"})
      {:ok,
      %Bookkeeping.Core.Account{
        code: "1000",
        name: "Cash and cash equivalents",
        description: "",
        account_type: %AccountType{
          name: "Asset",
          normal_balance: :debit,
          primary_account_category: :balance_sheet,
          contra: false
        },
        active: true,
        audit_logs: [
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "account",
            action_type: "create",
            details: %{},
            created_at: ~U[2021-10-10 10:10:10.000000Z],
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          }
        ]
      }}
  """
  @spec update_account(Account.t(), map()) :: {:ok, Account.t()} | {:error, :invalid_account}
  def update_account(server \\ __MODULE__, account, attrs) do
    if is_struct(account, Account),
      do: GenServer.call(server, {:update_account, account, attrs}),
      else: {:error, :invalid_account}
  end

  @doc """
  Returns all accounts.

  Returns `{:ok, accounts}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.all_accounts(server)
      {:ok, [%Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: "1000", name: "Cash"}]}
  """
  @spec all_accounts() :: {:ok, list(Account.t())}
  def all_accounts(server \\ __MODULE__) do
    GenServer.call(server, :all_accounts)
  end

  @doc """
  Finds an account by code.

  Arguments:
    - code: The unique code of the account.

  Returns `{:ok, account}` if the account was found, otherwise `{:error, :not_found}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.find_account_by_code(server, "1000")
      {:ok, [%Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: "1000", name: "Cash"}]}
  """
  @spec find_account_by_code(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  def find_account_by_code(server \\ __MODULE__, code) do
    if is_binary(code),
      do: GenServer.call(server, {:find_account_by_code, code}),
      else: {:error, :invalid_code}
  end

  @doc """
  Finds an account by name.

  Arguments:
    - name: The unique name of the account.

  Returns `{:ok, account}` if the account was found, otherwise `{:error, :not_found}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.find_account_by_name(server, "Cash")
      {:ok, [%Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: "1000", name: "Cash"}]}
  """
  @spec find_account_by_name(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  def find_account_by_name(server \\ __MODULE__, name) do
    if is_binary(name),
      do: GenServer.call(server, {:find_account_by_name, name}),
      else: {:error, :invalid_name}
  end

  @doc """
  Search accounts by code or name.

  Arguments:
    - query: The query to search for code or name.

  Returns `{:ok, accounts}` if the account was found, otherwise `{:ok, []}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.search_accounts(server, "1000")
      {:ok, [%Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: "1000", name: "Cash"}]}
  """
  @spec search_accounts(String.t()) :: {:ok, list(Account.t())} | {:error, :invalid_query}
  def search_accounts(server \\ __MODULE__, query) do
    if is_binary(query),
      do: GenServer.call(server, {:search_accounts, query}),
      else: {:error, :invalid_query}
  end

  @doc """
  Get all accounts sorted by code or name.

  Returns `{:ok, accounts}` if the accounts were sorted successfully, otherwise `{:error, :invalid_field}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.all_sorted_accounts(server, :code)
      {:ok, [%Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: "1000", name: "Cash"}]}
  """
  @spec all_sorted_accounts(atom()) :: {:ok, list(Account.t())} | {:error, :invalid_field}
  def all_sorted_accounts(server \\ __MODULE__, field) do
    if field in ["code", "name"],
      do: GenServer.call(server, {:sort_accounts, field}),
      else: {:error, :invalid_field}
  end

  @impl true
  @spec init(chart_of_account_state()) :: {:ok, chart_of_account_state()}
  def init(chart_of_account), do: {:ok, chart_of_account}

  @impl true
  def handle_call(
        {:create_account, code, name, account_type, description, audit_details},
        _from,
        accounts
      ) do
    case Account.create(code, name, account_type, description, audit_details) do
      {:ok, account} ->
        updated_accounts = Map.put(accounts, code, account)
        {:reply, {:ok, account}, updated_accounts}

      {:error, message} ->
        {:reply, {:error, message}, accounts}
    end
  end

  @impl true
  def handle_call({:update_account, account, attrs}, _from, accounts) do
    case Account.update(account, attrs) do
      {:ok, updated_account} ->
        updated_accounts =
          accounts
          |> Map.delete(account.code)
          |> Map.put(updated_account.code, updated_account)

        {:reply, {:ok, updated_account}, updated_accounts}

      {:error, :invalid_account} ->
        {:reply, {:error, :invalid_account}, accounts}
    end
  end

  @impl true
  def handle_call(:all_accounts, _from, accounts) do
    {:reply, {:ok, Map.values(accounts)}, accounts}
  end

  @impl true
  def handle_call({:find_account_by_code, code}, _from, accounts) do
    case Map.get(accounts, code) do
      nil -> {:reply, {:error, :not_found}, accounts}
      account -> {:reply, {:ok, account}, accounts}
    end
  end

  @impl true
  def handle_call({:find_account_by_name, name}, _from, accounts) do
    case Enum.find(accounts, fn {_code, account} ->
           String.downcase(account.name) == String.downcase(name)
         end) do
      nil -> {:reply, {:error, :not_found}, accounts}
      {_code, account} -> {:reply, {:ok, account}, accounts}
    end
  end

  @impl true
  def handle_call({:search_accounts, binary_query}, _from, accounts) do
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

    {:reply, {:ok, found_accounts}, accounts}
  end

  @impl true
  def handle_call({:sort_accounts, field}, _from, accounts) do
    field_map = %{"code" => :code, "name" => :name}
    sorted_accounts = Enum.sort_by(Map.values(accounts), &Map.get(&1, field_map[field]))
    {:reply, {:ok, sorted_accounts}, accounts}
  end

  defp create_account_record(
         server,
         code,
         name,
         account_type,
         description \\ "",
         audit_details \\ %{}
       ) do
    with true <- is_binary(code) and is_binary(name) and account_type in @account_types,
         {:error, :not_found} <- GenServer.call(server, {:find_account_by_code, code}),
         {:error, :not_found} <- GenServer.call(server, {:find_account_by_name, name}) do
      GenServer.call(
        server,
        {:create_account, code, name, account_type, description, audit_details}
      )
    else
      {:ok, _account} -> {:error, :account_already_exists}
      _ -> {:error, :invalid_account}
    end
  end

  defp bulk_create_account_records(server, csv) when is_list(csv) and csv != [] do
    results =
      Enum.reduce(
        csv,
        %{ok: [], error: []},
        fn csv_item, acc ->
          account_code = Map.get(csv_item, "Account Code")
          account_name = Map.get(csv_item, "Account Name")
          account_type = Map.get(csv_item, "Account Type")
          description = Map.get(csv_item, "Description", "")
          audit_details = Map.get(csv_item, "Audit Details", "{}")

          with {:ok, audit_details} <- Jason.decode(audit_details),
               {:ok, _} <-
                 create_account_record(
                   server,
                   account_code,
                   account_name,
                   account_type,
                   description,
                   audit_details
                 ) do
            oks = acc.ok ++ [%{account_code: account_code, account_name: account_name}]
            Map.put(acc, :ok, oks)
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

            {:error, error} ->
              errors =
                acc.error ++
                  [%{account_code: account_code, account_name: account_name, error: error}]

              Map.put(acc, :error, errors)
          end
        end
      )

    if results.ok == [],
      do: {:error, results},
      else: {:ok, results}
  end

  defp bulk_create_account_records(_server, _csv), do: {:error, :invalid_file}

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
