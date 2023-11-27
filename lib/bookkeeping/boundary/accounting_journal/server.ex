defmodule Bookkeeping.Boundary.AccountingJournal.Server do
  @moduledoc """
  Bookkeeping.Boundary.AccountingJournal.Server is a GenServer that represents the accounting journal.
  Accounting Journal is a record of all relevant business transactions in terms of money or a record.
  The Accounting Journal GenServer is responsible for creating, updating, and searching journal entries.
  The state of Accounting Journal GenServer is a map in which the keys are maps of transaction date details (year, month, day) and the values are lists of journal entries.
  """
  use GenServer

  alias Bookkeeping.Boundary.AccountingJournal.Backup, as: AccountingJournalBackup
  alias Bookkeeping.Boundary.ChartOfAccounts.Server, as: ChartOfAccountsServer
  alias Bookkeeping.Core.{JournalEntry, LineItem}
  alias NimbleCSV.RFC4180, as: CSV

  @typedoc """
  The state of the Accounting Journal GenServer.
  The state is a map in which the keys are maps of transaction date details (year, month, day) and the values are lists of journal entries.

  ## Examples

      iex> %{
      ...>  %{year: 2021, month: 10, day: 10} => [
      ...>    %JournalEntry{
      ...>      id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>      transaction_date: ~U[2021-10-10 10:10:10.000000Z],
      ...>      journal_entry_number: "reference number",
      ...>      journal_entry_description: "description",
      ...>      journal_entry_details: %{},
      ...>      line_items: [
      ...>        %LineItem{
      ...>          account: %Account{
      ...>            code: "10_000",
      ...>            name: "cash",
      ...>            account_classification: %AccountClassification{
      ...>              name: "asset",
      ...>              normal_balance: :debit,
      ...>              statement_category: :balance_sheet,
      ...>              contra: false
      ...>            }
      ...>          },
      ...>          amount: Decimal.new(100),
      ...>          entry_type: :debit
      ...>        },
      ...>        %LineItem{
      ...>          account: %Account{
      ...>            code: "20_000",
      ...>            name: "sales",
      ...>            account_classification: %AccountClassification{
      ...>              name: "revenue",
      ...>              normal_balance: :credit,
      ...>              statement_category: :profit_and_loss,
      ...>              contra: false
      ...>            }
      ...>          },
      ...>          amount: Decimal.new(100),
      ...>          entry_type: :credit
      ...>        }
      ...>      ],
      ...>      audit_logs: [
      ...>        %AuditLog{
      ...>          id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>          record_type: "journal_entry",
      ...>          action_type: "create",
      ...>          details: %{},
      ...>          created_at: 1633860610,
      ...>          updated_at: 1633860610,
      ...>          deleted_at: nil
      ...>        }
      ...>      ],
      ...>      posted: false
      ...>    }
      ...>  ],
      ...>  ...
      ...> }
  """
  @type accounting_journal_state :: %{
          general_ledger_posting_date_details => list(JournalEntry.t())
        }
  @type accounting_journal_server_pid :: atom | pid | {atom, any} | {:via, atom, any}
  @type create_journal_entry_params :: %{
          transaction_date: DateTime.t(),
          general_ledger_posting_date: DateTime.t(),
          t_accounts: accounting_journal_t_accounts(),
          journal_entry_number: String.t(),
          transaction_reference_number: String.t(),
          journal_entry_description: String.t(),
          journal_entry_details: map(),
          audit_details: map()
        }
  @type general_ledger_posting_date_details :: %{
          year: integer(),
          month: integer(),
          day: integer()
        }
  @type accounting_journal_t_accounts :: %{
          left: list(LineItem.t()),
          right: list(LineItem.t())
        }

  @doc """
  Starts the Accounting Journal GenServer.

  Returns `{:ok, pid}` if the GenServer is started successfully.

  ## Examples

      iex> AccountingJournal.start_link()
      {:ok, #PID<0.123.0>}
  """
  @spec start_link(Keyword.t()) :: {:ok, pid}
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, %{}, options)
  end

  @doc """
  Creates a journal entry.

  Arguments:
    - transaction_date: The date of the transaction. This is usually the date of the source document (i.e. invoice date, check date, etc.)
    - general_ledger_posting_date: The date of the General Ledger posting. This is usually the date when the journal entry is posted to the General Ledger.
    - t_accounts: The map of line items. The map must have the following keys:
      - left: The list of maps with account and amount field and represents the entry type of debit.
      - right: The list of maps with account and amount field and represents the entry type of credit.
    - journal_entry_number: The unique reference number of the journal entry. This is an auto-generated unique sequential identifier that is distinct from the transaction reference number (i.e. JE001000, JE001002, etc).
    - transaction_reference_number (optional): The reference number of the transaction. This is usually the reference number of the source document (i.e. invoice number, check number, etc.)
    - journal_entry_description (optional): The description of the journal entry. This is usually the description of the source document (i.e. invoice description, check description, etc.)
    - journal_entry_details (optional): The details of the journal entry. The details are usually the details of the source document (i.e. invoice details, check details, etc.)
    - audit_details (optional): The details of the audit log.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is created successfully. Otherwise, returns `{:error, :invalid_journal_entry}`.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.create_journal_entry(%{
      ...>   transaction_date: ~U[2021-10-10 10:10:10.000000Z],
      ...>   general_ledger_posting_date: ~U[2021-10-10 10:10:10.000000Z],
      ...>   t_accounts: %{
      ...>     left: [
      ...>       %{
      ...>         account: "Cash",
      ...>         amount: Decimal.new(100)
      ...>       }
      ...>     ],
      ...>     right: [
      ...>       %{
      ...>         account: "Sales Revenue",
      ...>         amount: Decimal.new(100)
      ...>       }
      ...>     ]F
      ...>   },
      ...>   journal_entry_number: "JE001001",
      ...>   transaction_reference_number: "INV001001",
      ...>   journal_entry_description: "description",
      ...>   journal_entry_details: %{},
      ...>   audit_details: %{}
      ...> })
      %{:ok, %Bookkeeping.Core.JournalEntry{...}}
  """
  @spec create_journal_entry(accounting_journal_server_pid(), create_journal_entry_params()) ::
          {:ok, JournalEntry.t()} | {:error, :invalid_journal_entry}
  def create_journal_entry(server \\ __MODULE__, create_journal_entry_params) do
    create_journal_record(server, create_journal_entry_params)
  end

  @doc """
  Imports journal entries from a CSV file.
  The header of the CSV file must be `Journal Entry Number`, `Transaction Date`, `Account Name`, `Debit`, `Credit`, `Line Item Description`, `Posted`, `Journal Entry Description`, `Journal Entry Details`, `Audit Details`, `General Ledger Posting Date`, and `Transaction Reference Number`

  Arguments:
    - path: The path of the CSV file.

  Returns `{:ok, %{ok: list(JournalEntry.t()), error: list(map())}}` if the journal entries are imported successfully. Otherwise, returns `{:error, %{message: :invalid_csv, errors: list(map())}}`.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.import_journal_entries(server, "../../data/sample_journal_entries.csv")
      {:ok,
      %{
        error: [],
        ok: [%Bookkeeping.Core.JournalEntry{...}, %Bookkeeping.Core.JournalEntry{...}, ...]
      }}
  """
  @spec import_journal_entries(accounting_journal_server_pid(), String.t()) ::
          {:ok, %{ok: list(JournalEntry.t()), error: list(map())}}
          | {:error, %{ok: list(JournalEntry.t()), error: list(map())}}
          | {:error, %{message: :invalid_csv, errors: list(map())}}
          | {:error, :invalid_file}
  def import_journal_entries(server \\ __MODULE__, path) do
    with file_path <- Path.expand(path, __DIR__),
         true <- File.exists?(file_path),
         {:ok, csv} <- read_csv(file_path) do
      bulk_create_journal_entries(server, csv)
    else
      _error -> {:error, :invalid_file}
    end
  end

  @doc """
  Returns all journal entries.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.all_journal_entries()
      {:ok, [%JournalEntry{...}, %JournalEntry{...}, ...]}
  """
  @spec all_journal_entries(accounting_journal_server_pid()) :: {:ok, list(JournalEntry.t())}
  def all_journal_entries(server \\ __MODULE__) do
    GenServer.call(server, :all_journal_entries)
  end

  @doc """
  Returns a journal entry by reference number.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is returned successfully. Otherwise, returns `{:error, :not_found}`.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entry_by_journal_entry_number("JE001001")
      {:ok, %JournalEntry{...}}

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entry_by_journal_entry_number("ref_num_2")
      {:error, :not_found}
  """
  @spec find_journal_entry_by_journal_entry_number(accounting_journal_server_pid(), String.t()) ::
          {:ok, JournalEntry.t()} | {:error, :not_found}
  def find_journal_entry_by_journal_entry_number(server \\ __MODULE__, journal_entry_number) do
    GenServer.call(server, {:find_journal_entry_by_journal_entry_number, journal_entry_number})
  end

  @doc """
  Returns a list of journal entries by general ledger posting date.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully. Otherwise, returns `{:error, :invalid_date}`.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entries_by_general_ledger_posting_date(~U[2021-10-10 10:10:10.000000Z])
      {:ok, [%JournalEntry{...}, %JournalEntry{...}, ...]}

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entries_by_general_ledger_posting_date(%{year: 2021, month: 10})
      {:ok, [%JournalEntry{...}, %JournalEntry{...}, ...]}

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entries_by_general_ledger_posting_date(~U[2021-10-10 10:10:10.000000Z])
      {:error, :invalid_date}
  """
  @spec find_journal_entries_by_general_ledger_posting_date(
          accounting_journal_server_pid(),
          DateTime.t() | general_ledger_posting_date_details()
        ) :: {:ok, list(JournalEntry.t())} | {:error, :invalid_date}
  def find_journal_entries_by_general_ledger_posting_date(server \\ __MODULE__, datetime) do
    GenServer.call(server, {:find_journal_entries_by_general_ledger_posting_date, datetime})
  end

  @doc """
  Returns a journal entry by id.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is returned successfully. Otherwise, returns `{:error, :invalid_id}`.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entries_by_id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
      {:ok, %JournalEntry{...}}

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entries_by_id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
      {:error, :invalid_id}
  """
  @spec find_journal_entries_by_id(accounting_journal_server_pid(), String.t()) ::
          {:ok, JournalEntry.t()} | {:error, :invalid_id}
  def find_journal_entries_by_id(server \\ __MODULE__, id) do
    GenServer.call(server, {:find_journal_entries_by_id, id})
  end

  @doc """
  Returns a list of journal entries by general ledger posting date range.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully. Otherwise, returns `{:error, :invalid_date}`.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entries_by_general_ledger_posting_date_range(~U[2021-10-10 10:10:10.000000Z], ~U[2021-10-10 10:10:10.000000Z])
      {:ok, [%JournalEntry{...}]}

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entries_by_general_ledger_posting_date_range(%{year: 2021, month: 10, day: 10}, %{year: 2021, month: 10, day: 10})
      {:ok, [%JournalEntry{...}]}

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entries_by_general_ledger_posting_date_range(~U[2021-10-10 10:10:10.000000Z], ~U[2021-10-10 10:10:10.000000Z])
      {:error, :invalid_date}
  """
  @spec find_journal_entries_by_general_ledger_posting_date_range(
          accounting_journal_server_pid(),
          DateTime.t() | general_ledger_posting_date_details(),
          DateTime.t() | general_ledger_posting_date_details()
        ) :: {:ok, list(JournalEntry.t())} | {:error, :invalid_date}
  def find_journal_entries_by_general_ledger_posting_date_range(
        server \\ __MODULE__,
        from_datetime,
        to_datetime
      ) do
    GenServer.call(
      server,
      {:find_journal_entries_by_general_ledger_posting_date_range, from_datetime, to_datetime}
    )
  end

  @doc """
  Updates a journal entry.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is updated successfully. Otherwise, returns `{:error, :invalid_journal_entry}`.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.find_journal_entry_by_journal_entry_number("ref_num_1")
      {:ok, %JournalEntry{...}}

      iex> Bookkeeping.Boundary.AccountingJournal.Server.update_journal_entry(%JournalEntry{...}, %{journal_entry_description: "updated description",posted: true})
      {:ok, %JournalEntry{journal_entry_description: "updated description", posted: true, ...}}

      iex> Bookkeeping.Boundary.AccountingJournal.Server.update_journal_entry(%JournalEntry{}, %{journal_entry_description: "updated description",posted: true})
      {:error, :invalid_journal_entry}
  """
  @spec update_journal_entry(accounting_journal_server_pid(), JournalEntry.t(), map()) ::
          {:ok, JournalEntry.t()}
          | {:error, :invalid_journal_entry}
          | {:error, :already_posted_journal_entry}
  def update_journal_entry(server \\ __MODULE__, journal_entry, attrs) do
    GenServer.call(server, {:update_journal_entry, journal_entry, attrs})
  end

  @doc """
  Resets the journal entries.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are reset successfully.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.reset_journal_entries()
      {:ok, []}
  """
  @spec reset_journal_entries(accounting_journal_server_pid()) :: {:ok, list(JournalEntry.t())}
  def reset_journal_entries(server \\ __MODULE__) do
    GenServer.call(server, :reset_journal_entries)
  end

  @doc """
  Returns the state of the Accounting Journal GenServer.

  Returns `{:ok, accounting_journal_state()}` if the state is returned successfully.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Server.get_accounting_journal_state()
      {:ok, %{...}}
  """
  @spec get_accounting_journal_state(accounting_journal_server_pid()) ::
          {:ok, accounting_journal_state()}
  def get_accounting_journal_state(server \\ __MODULE__) do
    GenServer.call(server, :get_accounting_journal_state)
  end

  @impl true
  @spec init(accounting_journal_state()) :: {:ok, accounting_journal_state()}
  def init(_journal_entries) do
    AccountingJournalBackup.get()
  end

  @impl true
  def handle_call({:create_journal_entry, params}, _from, journal_entries) do
    with {:error, :not_found} <-
           find_by_journal_entry_number(journal_entries, params.journal_entry_number),
         {:ok, journal_entry} <-
           JournalEntry.create(
             params.transaction_date,
             params.general_ledger_posting_date,
             params.t_accounts,
             params.journal_entry_number,
             params.transaction_reference_number,
             params.journal_entry_description,
             params.journal_entry_details,
             params.audit_details
           ) do
      date_details = Map.take(journal_entry.general_ledger_posting_date, [:year, :month, :day])

      updated_journal_entries =
        if journal_entries[date_details] == nil do
          Map.put(journal_entries, date_details, [journal_entry])
        else
          updated_je_list = [journal_entry | journal_entries[date_details]]
          Map.put(journal_entries, date_details, updated_je_list)
        end

      {:reply, {:ok, journal_entry}, updated_journal_entries, :hibernate}
    else
      {:ok, _journal_entry} ->
        {:reply, {:error, :duplicate_journal_entry_number}, journal_entries, :hibernate}

      {:error, message} ->
        {:reply, {:error, message}, journal_entries, :hibernate}
    end
  end

  @impl true
  def handle_call({:update_journal_entry, journal_entry, attrs}, _from, journal_entries) do
    case JournalEntry.update(journal_entry, attrs) do
      {:ok, updated_journal_entry} ->
        updated_journal_entries =
          process_journal_entry_update(journal_entries, updated_journal_entry)

        {:reply, {:ok, updated_journal_entry}, updated_journal_entries, :hibernate}

      {:error, message} ->
        {:reply, {:error, message}, journal_entries, :hibernate}
    end
  end

  @impl true
  def handle_call(:all_journal_entries, from, journal_entries) do
    Task.async(fn ->
      all_entries =
        Enum.reduce(journal_entries, [], fn {_k, je_list}, acc -> je_list ++ acc end)

      GenServer.reply(from, {:ok, all_entries})
    end)

    {:noreply, journal_entries}
  end

  @impl true
  def handle_call(
        {:find_journal_entry_by_journal_entry_number, journal_entry_number},
        from,
        journal_entries
      ) do
    Task.async(fn ->
      case find_by_journal_entry_number(journal_entries, journal_entry_number) do
        {:ok, journal_entry} -> GenServer.reply(from, {:ok, journal_entry})
        {:error, message} -> GenServer.reply(from, {:error, message})
      end
    end)

    {:noreply, journal_entries}
  end

  @impl true
  def handle_call(
        {:find_journal_entries_by_general_ledger_posting_date, datetime},
        from,
        journal_entries
      ) do
    Task.async(fn ->
      case get_date_details(datetime) do
        {:ok, date_details} ->
          all_journal_entries =
            find_journal_entries_by_posting_date(journal_entries, date_details)

          GenServer.reply(from, {:ok, all_journal_entries})

        {:error, message} ->
          GenServer.reply(from, {:error, message})
      end
    end)

    {:noreply, journal_entries}
  end

  @impl true
  def handle_call({:find_journal_entries_by_id, id}, from, journal_entries) do
    Task.async(fn ->
      case find_by_id(journal_entries, id) do
        {:ok, journal_entry} -> GenServer.reply(from, {:ok, journal_entry})
        {:error, message} -> GenServer.reply(from, {:error, message})
      end
    end)

    {:noreply, journal_entries}
  end

  @impl true
  def handle_call(
        {:find_journal_entries_by_general_ledger_posting_date_range, from_datetime, to_datetime},
        from,
        journal_entries
      ) do
    Task.async(fn ->
      with {:ok, from_date_details} <- get_date_details(from_datetime),
           {:ok, to_date_details} <- get_date_details(to_datetime) do
        je_list =
          find_journal_entries_by_date_range(journal_entries, from_date_details, to_date_details)

        GenServer.reply(from, {:ok, je_list})
      else
        {:error, message} -> GenServer.reply(from, {:error, message})
      end
    end)

    {:noreply, journal_entries}
  end

  @impl true
  def handle_call(:reset_journal_entries, _from, _journal_entries) do
    AccountingJournalBackup.update(%{})
    {:reply, {:ok, []}, %{}}
  end

  @impl true
  def handle_call(:get_accounting_journal_state, from, journal_entries) do
    Task.async(fn -> GenServer.reply(from, {:ok, journal_entries}) end)
    {:noreply, journal_entries}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, journal_entries) do
    AccountingJournalBackup.update(journal_entries)
  end

  defp get_date_details(datetime) when is_struct(datetime, DateTime),
    do: {:ok, Map.take(datetime, [:year, :month, :day])}

  defp get_date_details(%{year: year, month: month, day: day}),
    do: {:ok, %{year: year, month: month, day: day}}

  defp get_date_details(_), do: {:error, :invalid_date}

  defp find_journal_entries_by_posting_date(journal_entries, date_details) do
    tdd_keys = Map.keys(date_details)

    journal_entries
    |> Task.async_stream(fn {k, je} ->
      if Map.take(k, tdd_keys) == date_details, do: je, else: nil
    end)
    |> Enum.reduce([], fn {:ok, je_list}, acc ->
      if is_list(je_list), do: je_list ++ acc, else: acc
    end)
  end

  defp find_journal_entries_by_date_range(journal_entries, from_date_details, to_date_details) do
    from_datetime = convert_date_details_to_datetime(from_date_details, "from")
    to_datetime = convert_date_details_to_datetime(to_date_details, "to")

    journal_entries
    |> Task.async_stream(fn {k, je_list} ->
      k_datetime = convert_date_details_to_datetime(k, "from")

      if DateTime.compare(to_datetime, k_datetime) == :gt and
           DateTime.compare(k_datetime, from_datetime) in [:gt, :eq],
         do: je_list,
         else: nil
    end)
    |> Enum.reduce([], fn {:ok, je_list}, acc ->
      if is_list(je_list), do: je_list ++ acc, else: acc
    end)
  end

  defp find_by_journal_entry_number(journal_entries, journal_entry_number)
       when is_binary(journal_entry_number) do
    journal_entry_found =
      journal_entries
      |> Task.async_stream(fn {_k, je_list} ->
        Enum.find(je_list, &(&1.journal_entry_number == journal_entry_number))
      end)
      |> Enum.reduce(nil, fn {:ok, search_result}, acc ->
        if is_struct(search_result, JournalEntry), do: search_result, else: acc
      end)

    if is_map(journal_entry_found),
      do: {:ok, journal_entry_found},
      else: {:error, :not_found}
  end

  defp find_by_journal_entry_number(_journal_entries, _journal_entry_number),
    do: {:error, :invalid_journal_entry_number}

  defp find_by_id(journal_entries, id) when is_binary(id) do
    journal_entry_found =
      journal_entries
      |> Task.async_stream(fn {_k, je_list} -> Enum.find(je_list, &(&1.id == id)) end)
      |> Enum.reduce(nil, fn {:ok, search_result}, acc ->
        if is_struct(search_result, JournalEntry), do: search_result, else: acc
      end)

    if is_map(journal_entry_found),
      do: {:ok, journal_entry_found},
      else: {:error, :not_found}
  end

  defp find_by_id(_journal_entries, _id), do: {:error, :invalid_id}

  defp process_journal_entry_update(journal_entries, updated_journal_entry) do
    date_details =
      Map.take(updated_journal_entry.general_ledger_posting_date, [:year, :month, :day])

    if journal_entries[date_details] == nil do
      with {:ok, old_journal_entry} <- find_by_id(journal_entries, updated_journal_entry.id),
           {:ok, old_date_details} <-
             get_date_details(old_journal_entry.general_ledger_posting_date) do
        updated_je_list =
          remove_journal_entry_by_id(
            journal_entries,
            old_date_details,
            old_journal_entry.id
          )

        journal_entries
        |> Map.put(date_details, [updated_journal_entry])
        |> Map.put(old_date_details, updated_je_list)
      end
    else
      updated_je_list =
        update_journal_entry_by_id(
          journal_entries,
          date_details,
          updated_journal_entry
        )

      Map.put(journal_entries, date_details, updated_je_list)
    end
  end

  defp remove_journal_entry_by_id(
         journal_entries,
         date_details,
         journal_entry_id
       ) do
    Enum.filter(journal_entries[date_details], fn je ->
      je.id != journal_entry_id
    end)
  end

  defp update_journal_entry_by_id(
         journal_entries,
         date_details,
         updated_journal_entry
       ) do
    Enum.map(journal_entries[date_details], fn je ->
      if je.id == updated_journal_entry.id, do: updated_journal_entry, else: je
    end)
  end

  defp create_journal_record(server, params) do
    t_accounts = params |> Map.get(:t_accounts, %{}) |> update_t_accounts()
    updated_params = Map.put(params, :t_accounts, t_accounts)

    GenServer.call(server, {:create_journal_entry, updated_params})
  end

  defp update_t_accounts(t_accounts) do
    %{
      left: update_account_amount_pair(t_accounts.left),
      right: update_account_amount_pair(t_accounts.right)
    }
  end

  defp update_account_amount_pair(account_amount_pairs) do
    Enum.reduce(account_amount_pairs, [], fn t_account, acc ->
      case ChartOfAccountsServer.find_account_by_name(t_account.account) do
        {:ok, account} -> acc ++ [Map.put(t_account, :account, account)]
        _ -> acc ++ [t_account]
      end
    end)
  end

  defp bulk_create_journal_entries(server, csv) when is_list(csv) and csv != [] do
    with %{ok: ok_create_params, error: []} <- generate_bulk_create_params(csv),
         {:ok, result} <- bulk_create_je_records(server, ok_create_params) do
      {:ok, result}
    else
      %{ok: _ok_create_params, error: errors} ->
        {:error, %{message: :invalid_csv, errors: errors}}

      {:error, result} ->
        {:error, result}
    end
  end

  defp bulk_create_journal_entries(_server, _csv), do: {:error, :invalid_file}

  defp bulk_create_je_records(server, create_params_list) do
    result =
      Enum.reduce(create_params_list, %{ok: [], error: []}, fn params, acc ->
        case create_journal_record(server, params) do
          {:ok, journal_entry} ->
            Map.put(acc, :ok, [journal_entry | acc.ok])

          {:error, message} ->
            errors =
              acc.error ++ [%{journal_entry_number: params.journal_entry_number, error: message}]

            Map.put(acc, :error, errors)
        end
      end)

    if result.ok == [], do: {:error, result}, else: {:ok, result}
  end

  defp generate_bulk_create_params(csv) do
    Enum.reduce(csv, %{ok: [], error: []}, fn csv_item, acc ->
      journal_entry_number = Map.get(csv_item, "Journal Entry Number", "")
      transaction_reference_number = Map.get(csv_item, "Transaction Reference Number", "")
      csv_posted = Map.get(csv_item, "Posted", "no")
      journal_entry_description = Map.get(csv_item, "Journal Entry Description", "")
      journal_entry_details = Map.get(csv_item, "Journal Entry Details", "{}")
      audit_details = Map.get(csv_item, "Audit Details", "{}")
      line_item_description = Map.get(csv_item, "Line Item Description", "")

      posted_field = csv_posted |> String.trim() |> String.downcase()
      posted = if posted_field == "yes", do: true, else: false

      updated_journal_entry_description =
        generate_updated_journal_description(
          acc.ok,
          journal_entry_number,
          journal_entry_description
        )

      with true <-
             validate_csv_items(
               journal_entry_number,
               transaction_reference_number,
               journal_entry_description,
               journal_entry_details,
               audit_details,
               csv_posted,
               line_item_description
             ),
           {:ok, transaction_date} <- parse_date(csv_item, "Transaction Date"),
           {:ok, general_ledger_posting_date} <-
             parse_date(csv_item, "General Ledger Posting Date"),
           {:ok, journal_entry_details} <- Jason.decode(journal_entry_details),
           {:ok, audit_details} <- Jason.decode(audit_details) do
        initial_params = %{
          t_accounts: %{left: [], right: []},
          posted: posted,
          journal_entry_number: journal_entry_number,
          transaction_reference_number: transaction_reference_number,
          journal_entry_description: updated_journal_entry_description,
          line_item_description: line_item_description,
          transaction_date: transaction_date,
          general_ledger_posting_date: general_ledger_posting_date,
          journal_entry_details: journal_entry_details,
          audit_details: audit_details
        }

        oks =
          update_ok_params(
            acc.ok,
            csv_item,
            initial_params,
            journal_entry_number
          )

        Map.put(acc, :ok, oks)
      else
        {:error, error} ->
          errors = acc.error ++ [%{journal_entry_number: journal_entry_number, error: error}]
          Map.put(acc, :error, errors)

        _error ->
          errors =
            acc.error ++ [%{journal_entry_number: journal_entry_number, error: :invalid_csv_item}]

          Map.put(acc, :error, errors)
      end
    end)
  end

  defp validate_csv_items(
         journal_entry_number,
         transaction_reference_number,
         journal_entry_description,
         journal_entry_details,
         audit_details,
         csv_posted,
         line_item_description
       ) do
    is_binary(journal_entry_number) and journal_entry_number != "" and
      is_binary(transaction_reference_number) and is_binary(journal_entry_description) and
      is_binary(journal_entry_details) and is_binary(audit_details) and is_binary(csv_posted) and
      is_binary(line_item_description)
  end

  defp generate_updated_journal_description(
         acc_ok_params,
         journal_entry_number,
         journal_entry_description
       ) do
    existing_journal_entry_description =
      acc_ok_params
      |> Enum.find(%{}, fn param -> param.journal_entry_number == journal_entry_number end)
      |> Map.get(:journal_entry_description, "")

    cond do
      existing_journal_entry_description == "" ->
        journal_entry_description

      existing_journal_entry_description != "" and journal_entry_description == "" ->
        existing_journal_entry_description

      existing_journal_entry_description != "" and journal_entry_description != "" ->
        existing_journal_entry_description <> " " <> journal_entry_description
    end
  end

  defp update_ok_params(
         ok_params,
         csv_item,
         initial_params,
         journal_entry_number
       ) do
    account = Map.get(csv_item, "Account Name", "")
    line_item_description = Map.get(csv_item, "Line Item Description", "")
    debit = Map.get(csv_item, "Debit", "")
    credit = Map.get(csv_item, "Credit", "")

    case Enum.find(ok_params, fn param -> param.journal_entry_number == journal_entry_number end) do
      nil ->
        updated_t_accounts =
          set_t_accounts(debit, credit, account, line_item_description, initial_params)

        params = Map.put(initial_params, :t_accounts, updated_t_accounts)

        ok_params ++ [params]

      found_param ->
        updated_t_accounts =
          set_t_accounts(debit, credit, account, line_item_description, found_param)

        Enum.map(ok_params, fn
          %{journal_entry_number: je_number} when je_number == journal_entry_number ->
            Map.put(initial_params, :t_accounts, updated_t_accounts)

          param ->
            param
        end)
    end
  end

  defp set_t_accounts(debit, "" = _credit, account, line_item_description, params) do
    debit_amount = if debit == "", do: "0", else: Decimal.new(debit)

    t_accounts_debit_item = %{
      account: account,
      amount: Decimal.new(debit_amount),
      line_item_description: line_item_description
    }

    %{
      left: [t_accounts_debit_item] ++ params.t_accounts.left,
      right: params.t_accounts.right
    }
  end

  defp set_t_accounts("" = _debit, credit, account, line_item_description, params) do
    credit_amount = if credit == "", do: "0", else: Decimal.new(credit)

    t_accounts_credit_item = %{
      account: account,
      amount: Decimal.new(credit_amount),
      line_item_description: line_item_description
    }

    %{
      left: params.t_accounts.left,
      right: [t_accounts_credit_item] ++ params.t_accounts.right
    }
  end

  defp parse_date(csv_item, date_column_header) do
    result =
      csv_item
      |> Map.get(date_column_header, "")
      |> String.split("-")

    if length(result) == 3 do
      [month, day, year] = result
      {:ok, datetime, _} = DateTime.from_iso8601("#{year}-#{month}-#{day}T00:00:00Z")
      {:ok, datetime}
    else
      {:error, :invalid_date}
    end
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

  defp convert_date_details_to_datetime(date_details, date_type) do
    year = Map.get(date_details, :year, 1000)
    month = Map.get(date_details, :month, 1)
    day = Map.get(date_details, :day, 1)
    time = if date_type == "from", do: "00:00:00Z", else: "23:59:59Z"

    if is_integer(year) and is_integer(month) and is_integer(day) do
      month = day_or_month_to_string(month)
      day = day_or_month_to_string(day)
      {:ok, datetime, _} = DateTime.from_iso8601("#{year}-#{month}-#{day}T#{time}")
      datetime
    else
      {:error, :invalid_date}
    end
  end

  defp day_or_month_to_string(day_or_month) when day_or_month < 10, do: "0#{day_or_month}"
  defp day_or_month_to_string(day_or_month), do: "#{day_or_month}"
end
