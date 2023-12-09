defmodule Bookkeeping do
  @moduledoc """
  Bookkeeping is a library that provides a set of functions for managing the chart of accounts and accounting journal.

  To get started, follow the instructions below:

  1. In the Bookkeeping project directory, run `mix deps.get` to install dependencies.
  2. Run `iex -S mix` to start the Elixir interactive shell.
  3. Run `Bookkeeping.import_accounts("../../data/sample_chart_of_accounts.csv")` to import sample chart of accounts.
  4. Run `Bookkeeping.import_journal_entries("../../data/sample_journal_entries.csv")` to import sample journal entries.
  """

  alias Bookkeeping.Boundary.AccountingJournal.Server, as: AccountingJournal
  alias Bookkeeping.Boundary.ChartOfAccounts.Worker, as: ChartOfAccounts
  alias Bookkeeping.Core.{Account, JournalEntry}

  ##########################################################
  # Chart of Accounts Functions                            #
  ##########################################################

  @doc """
  Creates a new account.

  Arguments:
    - code: The unique code of the account.
    - name: The unique name of the account.
    - classification: The classification of the account. The account classification must be one of the following: `"asset"`, `"liability"`, `"equity"`, `"revenue"`, `"expense"`, `"gain"`, `"loss"`, `"contra_asset"`, `"contra_liability"`, `"contra_equity"`, `"contra_revenue"`, `"contra_expense"`, `"contra_gain"`, `"contra_loss"`.
    - description: The description of the account.
    - audit_details: The audit details of the account.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Bookkeeping.create_account(server, "1000", "Cash", "asset", "", %{})
      {:ok, %Bookkeeping.Core.Account{...}}

      iex> Bookkeeping.create_account(server, "invalid", "invalid", nil, false, %{})
      {:error, :invalid_account}
  """
  @spec create_account(String.t(), String.t(), String.t(), String.t(), map()) ::
          {:ok, Account.t()} | {:error, :invalid_account} | {:error, :account_already_exists}
  defdelegate create_account(code, name, classification, description, audit_details),
    to: ChartOfAccounts

  @doc """
  Imports default accounts from a CSV file.
  The headers of the CSV file must be `Account Code`, `Account Name`, `Account Type`, `Description`, and `Audit Details`.

  Arguments:
    - path: The path of the CSV file. The path to the default accounts is "../data/sample_chart_of_accounts.csv".

  Returns `{:ok, %{ok: list(map()), error: list(map())}}` if the accounts are imported successfully. If all items are encountered an error, return `{:error, %{ok: list(map()), error: list(map())}}`.

  ## Examples

      iex> Bookkeeping.import_accounts(server, "../data/sample_chart_of_accounts.csv")
      {:ok,
      %{
        ok: [%{account_code: "1000", account_name: "Cash"}, ...],
        error: []
      }}

      iex> Bookkeeping.import_accounts(server, "../data/invalid_chart_of_accounts.csv")
      {:error,
      %{
        ok: [],
        error: [
          %{account_code: "1001", account_name: "Cash", error: :account_already_exists},
          %{account_code: "1002", account_name: "Cash", error: :invalid_account},
          ...
        ]
      }}
  """
  @spec import_accounts(String.t()) ::
          {:ok, %{ok: list(Account.t()), error: list(map())}}
          | {:error, %{ok: list(Account.t()), error: list(map())}}
          | {:error, %{message: :invalid_csv, errors: list(map())}}
          | {:error, :invalid_file}
  defdelegate import_accounts(file_path), to: ChartOfAccounts

  @doc """
  Updates an account.

  Arguments:
    - account: The account to be updated.
    - attrs: The attributes to be updated. The editable attributes are `name`, `description`, `active`, and `audit_details`.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Bookkeeping.update_account(server, account, %{name: "Cash and cash equivalents"})
      {:ok, %Bookkeeping.Core.Account{...}}
  """
  @spec update_account(Account.t(), map()) :: {:ok, Account.t()} | {:error, :invalid_account}
  defdelegate update_account(account, attrs), to: ChartOfAccounts

  @doc """
  Returns all accounts.

  Returns `{:ok, accounts}`.

  ## Examples

      iex> Bookkeeping.all_accounts(server)
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}
  """
  @spec all_accounts() :: {:ok, list(Account.t())}
  defdelegate all_accounts, to: ChartOfAccounts

  @doc """
  Finds an account by code.

  Arguments:
    - code: The unique code of the account.

  Returns `{:ok, account}` if the account was found, otherwise `{:error, :not_found}`.

  ## Examples

      iex> Bookkeeping.find_account_by_code(server, "1000")
      {:ok, %Bookkeeping.Core.Account{...}}
  """
  @spec find_account_by_code(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  defdelegate find_account_by_code(code), to: ChartOfAccounts

  @doc """
  Finds an account by name.

  Arguments:
    - name: The unique name of the account.

  Returns `{:ok, account}` if the account was found, otherwise `{:error, :not_found}`.

  ## Examples

      iex> Bookkeeping.find_account_by_name(server, "Cash")
      {:ok, %Bookkeeping.Core.Account{...}}
  """
  @spec find_account_by_name(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  defdelegate find_account_by_name(name), to: ChartOfAccounts

  @doc """
  Search accounts by code or name.

  Arguments:
    - query: The query to search for code or name.

  Returns `{:ok, accounts}` if the account was found, otherwise `{:ok, []}`.

  ## Examples

      iex> Bookkeeping.search_accounts(server, "1000")
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}
  """
  @spec search_accounts(String.t()) :: {:ok, list(Account.t())} | {:error, :invalid_query}
  defdelegate search_accounts(code_or_name), to: ChartOfAccounts

  @doc """
  Get all accounts sorted by code or name.

  Returns `{:ok, accounts}` if the accounts were sorted successfully, otherwise `{:error, :invalid_field}`.

  ## Examples

      iex> Bookkeeping.all_sorted_accounts(server, :code)
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}
  """
  @spec all_sorted_accounts(String.t()) :: {:ok, list(Account.t())} | {:error, :invalid_field}
  defdelegate all_sorted_accounts(account_field), to: ChartOfAccounts

  @doc """
  Resets the accounts.

  Returns `{:ok, []}`.

  ## Examples

      iex> Bookkeeping.reset_accounts(server)
      {:ok, []}
  """
  @spec reset_accounts() :: {:ok, list(Account.t())}
  defdelegate reset_accounts, to: ChartOfAccounts

  @doc """
  Returns the state of the chart of accounts.

  Returns `{:ok, state}`.

  ## Examples

      iex> Bookkeeping.get_chart_of_accounts_state()
      {:ok, %{...}}
  """
  @spec get_chart_of_accounts_state() :: {:ok, ChartOfAccounts.chart_of_account_state()}
  defdelegate get_chart_of_accounts_state, to: ChartOfAccounts

  ##########################################################
  # Accounting Journal Functions                           #
  ##########################################################

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

      iex> Bookkeeping.create_journal_entry(%{
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
  @spec create_journal_entry(AccountingJournal.create_journal_entry_params()) ::
          {:ok, JournalEntry.t()} | {:error, :invalid_journal_entry}
  defdelegate create_journal_entry(create_journal_entry_params), to: AccountingJournal

  @doc """
  Imports journal entries from a CSV file.
  The header of the CSV file must be `Journal Entry Number`, `Transaction Date`, `Account Name`, `Debit`, `Credit`, `Line Item Description`, `Posted`, `Journal Entry Description`, `Journal Entry Details`, `Audit Details`, `General Ledger Posting Date`, and `Transaction Reference Number`

  Arguments:
    - path: The path of the CSV file.

  Returns `{:ok, %{ok: list(JournalEntry.t()), error: list(map())}}` if the journal entries are imported successfully. Otherwise, returns `{:error, %{message: :invalid_csv, errors: list(map())}}`.

  ## Examples

      iex> Bookkeeping.import_journal_entries(server, "../../data/sample_journal_entries.csv")
      {:ok,
      %{
        error: [],
        ok: [%Bookkeeping.Core.JournalEntry{...}, %Bookkeeping.Core.JournalEntry{...}, ...]
      }}
  """
  @spec import_journal_entries(String.t()) ::
          {:ok, %{ok: list(JournalEntry.t()), error: list(map())}}
          | {:error, %{ok: list(JournalEntry.t()), error: list(map())}}
          | {:error, %{message: :invalid_csv, errors: list(map())}}
          | {:error, :invalid_file}
  defdelegate import_journal_entries(file_path), to: AccountingJournal

  @doc """
  Returns all journal entries.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully.

  ## Examples

      iex> Bookkeeping.all_journal_entries()
      {:ok, [%JournalEntry{...}, %JournalEntry{...}, ...]}
  """
  @spec all_journal_entries() :: {:ok, list(JournalEntry.t())}
  defdelegate all_journal_entries, to: AccountingJournal

  @spec find_journal_entry_by_journal_entry_number(String.t()) ::
          {:ok, JournalEntry.t()} | {:error, :not_found}
  defdelegate find_journal_entry_by_journal_entry_number(journal_entry_number),
    to: AccountingJournal

  @spec find_journal_entries_by_general_ledger_posting_date(
          DateTime.t()
          | AccountingJournal.general_ledger_posting_date_details()
        ) :: {:ok, list(JournalEntry.t())} | {:error, :invalid_date}
  defdelegate find_journal_entries_by_general_ledger_posting_date(datetime), to: AccountingJournal

  @doc """
  Returns a journal entry by id.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is returned successfully. Otherwise, returns `{:error, :invalid_id}`.

  ## Examples

      iex> Bookkeeping.find_journal_entries_by_id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
      {:ok, %JournalEntry{...}}

      iex> Bookkeeping.find_journal_entries_by_id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
      {:error, :invalid_id}
  """
  @spec find_journal_entries_by_id(String.t()) :: {:ok, JournalEntry.t()} | {:error, :invalid_id}
  defdelegate find_journal_entries_by_id(id), to: AccountingJournal

  @doc """
  Returns a list of journal entries by general ledger posting date range.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully. Otherwise, returns `{:error, :invalid_date}`.

  ## Examples

      iex> Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(~U[2021-10-10 10:10:10.000000Z], ~U[2021-10-10 10:10:10.000000Z])
      {:ok, [%JournalEntry{...}]}

      iex> Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(%{year: 2021, month: 10, day: 10}, %{year: 2021, month: 10, day: 10})
      {:ok, [%JournalEntry{...}]}

      iex> Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(~U[2021-10-10 10:10:10.000000Z], ~U[2021-10-10 10:10:10.000000Z])
      {:error, :invalid_date}
  """
  @spec find_journal_entries_by_general_ledger_posting_date_range(
          DateTime.t() | AccountingJournal.general_ledger_posting_date_details(),
          DateTime.t() | AccountingJournal.general_ledger_posting_date_details()
        ) :: {:ok, list(JournalEntry.t())} | {:error, :invalid_date}
  defdelegate find_journal_entries_by_general_ledger_posting_date_range(
                from_datetime,
                to_datetime
              ),
              to: AccountingJournal

  @doc """
  Updates a journal entry.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is updated successfully. Otherwise, returns `{:error, :invalid_journal_entry}`.

  ## Examples

      iex> Bookkeeping.find_journal_entry_by_journal_entry_number("ref_num_1")
      {:ok, %JournalEntry{...}}

      iex> Bookkeeping.update_journal_entry(%JournalEntry{...}, %{journal_entry_description: "updated description",posted: true})
      {:ok, %JournalEntry{journal_entry_description: "updated description", posted: true, ...}}

      iex> Bookkeeping.update_journal_entry(%JournalEntry{}, %{journal_entry_description: "updated description",posted: true})
      {:error, :invalid_journal_entry}
  """
  @spec update_journal_entry(JournalEntry.t(), map()) ::
          {:ok, JournalEntry.t()}
          | {:error, :invalid_journal_entry}
          | {:error, :already_posted_journal_entry}
  defdelegate update_journal_entry(journal_entry, attrs), to: AccountingJournal

  @doc """
  Resets the journal entries.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are reset successfully.

  ## Examples

      iex> Bookkeeping.reset_journal_entries()
      {:ok, []}
  """
  @spec reset_journal_entries() :: {:ok, list(JournalEntry.t())}
  defdelegate reset_journal_entries, to: AccountingJournal

  @doc """
  Returns the state of the accounting journal.

  Returns `{:ok, state}`.

  ## Examples

      iex> Bookkeeping.get_accounting_journal_state()
      {:ok, %{...}}
  """
  @spec get_accounting_journal_state() :: {:ok, AccountingJournal.accounting_journal_state()}
  defdelegate get_accounting_journal_state, to: AccountingJournal
end
