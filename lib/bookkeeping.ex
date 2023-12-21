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
  Creates an account.

  Arguments:
    - params: The map of account attributes. The map must have the following keys:
      - code: The unique code of the account.
      - name: The unique name of the account.
      - classification: The classification of the account. The account classification must be one of the following: `asset`, `liability`, `equity`, `revenue`, `expense`, `gain`, `loss`, `contra_asset`, `contra_liability`, `contra_equity`, `contra_revenue`, `contra_expense`, `contra_gain`, `contra_loss`.
      - description: The description of the account.
      - audit_details: The details of the audit log.
      - active: The status of the account. The account status must be one of the following: `true` or `false`.

  Returns `{:ok, %Account{}}` if the account is valid. Otherwise, returns `{:error, :invalid_params}` or `{:error, :invalid_field}`.

  ## Examples

     iex> Bookkeeping.create_account(%{code: "10_000", name: "cash", classification: "asset", description: "", audit_details: %{}, active: true})
      {:ok, %Account{...}}

      iex> Bookkeeping.create_account([])"
      {:error, :invalid_params}

      iex> Bookkeeping.create_account(%{code: "invalid", name: "invalid", classification: "invalid", description: nil, audit_details: false, active: %{}})
      {:error, :invalid_field}
  """
  @spec create_account(map()) :: {:ok, Account.t()} | {:error, :invalid_params | :invalid_field}
  def create_account(params), do: ChartOfAccounts.create(params)

  @doc """
  Imports accounts from a CSV file.

  The header of the CSV file must be `Account Code`, `Account Name`, `Classification`, `Account Description`, and `Audit Details`.

  Arguments:
    - path: The path of the CSV file.

  Returns `{:ok, %{accounts: [...], errors: [...]}}` if the accounts are imported successfully and if it has errors. Otherwise, returns `{:error, :invalid_file}`.

  ## Examples

      iex> Bookkeeping.import_accounts("../../data/sample_chart_of_accounts.csv")
      {:ok,
      %{
        accounts: [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...],
        errors: []
      }}

      iex> Bookkeeping.import_accounts("../../data/invalid_file.csv")
      {:error, :invalid_file}
  """
  @spec import_accounts(String.t()) ::
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
  def import_accounts(file_path), do: ChartOfAccounts.import_file(file_path)

  @doc """
  Updates an account.

  Arguments:
    - account: The account to be updated.
    - params: The map of account attributes. The map must have the following keys:
      - name: The unique name of the account.
      - description: The description of the account.
      - audit_details: The details of the audit log.
      - active: The status of the account. The account status must be one of the following: `true` or `false`.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`, `{:error, :invalid_field}`, or `{:error, :invalid_params}`.

  ## Examples

      iex> Bookkeeping.update_account(account, %{name: "Cash and cash equivalents"})
      {:ok, %Bookkeeping.Core.Account{...}}

      iex> Bookkeeping.update_account(account, %{name: "Cash and cash equivalents"})
      {:error, :invalid_account}

      iex> Bookkeeping.update_account(account, %{code: "1002"})
      {:error, :invalid_field}

      iex> Bookkeeping.update_account(account, nil)
      {:error, :invalid_params}
  """
  @spec update_account(Account.t(), map()) ::
          {:ok, Account.t()} | {:error, :invalid_account | :invalid_field | :invalid_params}
  def update_account(account, params), do: ChartOfAccounts.update(account, params)

  @doc """
  Returns all accounts.

  Returns `{:ok, accounts}`.

  ## Examples

      iex> Bookkeeping.all_accounts(server)
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}
  """
  @spec all_accounts() :: {:ok, list(Account.t())}
  def all_accounts(), do: ChartOfAccounts.all_accounts()

  @doc """
  Search accounts by code.

  Arguments:
    - code: The unique code of the account.

  Returns `{:ok, accounts}` whether the account is found or not. If the input is invalid, returns `{:error, :invalid_code}`.

  ## Examples

      iex> Bookkeeping.search_accounts_by_code(server, "1000")
      {:ok, [%Bookkeeping.Core.Account{...}, ...]}

      iex> Bookkeeping.search_accounts_by_code(server, nil)
      {:error, :invalid_code}
  """
  @spec search_accounts_by_code(Account.account_code()) ::
          {:ok, list(Account.t())} | {:error, :not_found | :invalid_code}
  def search_accounts_by_code(code), do: ChartOfAccounts.search_code(code)

  @doc """
  Search accounts by name.

  Arguments:
    - name: The unique name of the account.

  Returns `{:ok, accounts}` whether the account is found or not. If the input is invalid, returns `{:error, :invalid_name}`.

  ## Examples

      iex> Bookkeeping.search_accounts_by_name(server, "Cash")
      {:ok, [%Bookkeeping.Core.Account{...}, ...]}

      iex> Bookkeeping.search_accounts_by_name(server, nil)
      {:error, :invalid_name}
  """
  @spec search_accounts_by_name(String.t()) ::
          {:ok, list(Account.t())} | {:error, :not_found | :invalid_name}
  def search_accounts_by_name(name), do: ChartOfAccounts.search_name(name)

  @doc """
  Search accounts by code or name.

  Arguments:
    - query: The query to search for code or name.

  Returns `{:ok, accounts}` whether the account is found or not. If the input is invalid, returns `{:error, :invalid_name}`.

  ## Examples

      iex> Bookkeeping.search_accounts("1000")
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}

      iex> Bookkeeping.search_accounts("Cash")
      {:ok, [%Bookkeeping.Core.Account{...}, %Bookkeeping.Core.Account{...}, ...]}

      iex> Bookkeeping.search_accounts("invalid")
      {:ok, []}

      iex> Bookkeeping.search_accounts(nil)
      {:error, :invalid_name}
  """
  @spec search_accounts(String.t()) ::
          {:ok, list(Account.t())} | {:error, :invalid_code | :invalid_name}
  def search_accounts(code_or_name) do
    with {:ok, accounts_based_on_name} <- ChartOfAccounts.search_name(code_or_name),
         {:ok, accounts_based_on_code} <- ChartOfAccounts.search_code(code_or_name) do
      {:ok, accounts_based_on_code ++ accounts_based_on_name}
    end
  end

  ##########################################################
  # Accounting Journal Functions                           #
  ##########################################################

  # @doc """
  # Creates a journal entry.

  # Arguments:
  #   - transaction_date: The date of the transaction. This is usually the date of the source document (i.e. invoice date, check date, etc.)
  #   - general_ledger_posting_date: The date of the General Ledger posting. This is usually the date when the journal entry is posted to the General Ledger.
  #   - t_accounts: The map of line items. The map must have the following keys:
  #     - left: The list of maps with account and amount field and represents the entry type of debit.
  #     - right: The list of maps with account and amount field and represents the entry type of credit.
  #   - journal_entry_number: The unique reference number of the journal entry. This is an auto-generated unique sequential identifier that is distinct from the transaction reference number (i.e. JE001000, JE001002, etc).
  #   - transaction_reference_number (optional): The reference number of the transaction. This is usually the reference number of the source document (i.e. invoice number, check number, etc.)
  #   - journal_entry_description (optional): The description of the journal entry. This is usually the description of the source document (i.e. invoice description, check description, etc.)
  #   - journal_entry_details (optional): The details of the journal entry. The details are usually the details of the source document (i.e. invoice details, check details, etc.)
  #   - audit_details (optional): The details of the audit log.

  # Returns `{:ok, JournalEntry.t()}` if the journal entry is created successfully. Otherwise, returns `{:error, :invalid_journal_entry}`.

  # ## Examples

  #     iex> Bookkeeping.create_journal_entry(%{
  #     ...>   transaction_date: ~U[2021-10-10 10:10:10.000000Z],
  #     ...>   general_ledger_posting_date: ~U[2021-10-10 10:10:10.000000Z],
  #     ...>   t_accounts: %{
  #     ...>     left: [
  #     ...>       %{
  #     ...>         account: "Cash",
  #     ...>         amount: Decimal.new(100)
  #     ...>       }
  #     ...>     ],
  #     ...>     right: [
  #     ...>       %{
  #     ...>         account: "Sales Revenue",
  #     ...>         amount: Decimal.new(100)
  #     ...>       }
  #     ...>     ]F
  #     ...>   },
  #     ...>   journal_entry_number: "JE001001",
  #     ...>   transaction_reference_number: "INV001001",
  #     ...>   journal_entry_description: "description",
  #     ...>   journal_entry_details: %{},
  #     ...>   audit_details: %{}
  #     ...> })
  #     %{:ok, %Bookkeeping.Core.JournalEntry{...}}
  # """
  # @spec create_journal_entry(AccountingJournal.create_journal_entry_params()) ::
  #         {:ok, JournalEntry.t()} | {:error, :invalid_journal_entry}
  # defdelegate create_journal_entry(create_journal_entry_params), to: AccountingJournal

  # @doc """
  # Imports journal entries from a CSV file.
  # The header of the CSV file must be `Journal Entry Number`, `Transaction Date`, `Account Name`, `Debit`, `Credit`, `Line Item Description`, `Posted`, `Journal Entry Description`, `Journal Entry Details`, `Audit Details`, `General Ledger Posting Date`, and `Transaction Reference Number`

  # Arguments:
  #   - path: The path of the CSV file.

  # Returns `{:ok, %{ok: list(JournalEntry.t()), error: list(map())}}` if the journal entries are imported successfully. Otherwise, returns `{:error, %{message: :invalid_csv, errors: list(map())}}`.

  # ## Examples

  #     iex> Bookkeeping.import_journal_entries(server, "../../data/sample_journal_entries.csv")
  #     {:ok,
  #     %{
  #       error: [],
  #       ok: [%Bookkeeping.Core.JournalEntry{...}, %Bookkeeping.Core.JournalEntry{...}, ...]
  #     }}
  # """
  # @spec import_journal_entries(String.t()) ::
  #         {:ok, %{ok: list(JournalEntry.t()), error: list(map())}}
  #         | {:error, %{ok: list(JournalEntry.t()), error: list(map())}}
  #         | {:error, %{message: :invalid_csv, errors: list(map())}}
  #         | {:error, :invalid_file}
  # defdelegate import_journal_entries(file_path), to: AccountingJournal

  # @doc """
  # Returns all journal entries.

  # Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully.

  # ## Examples

  #     iex> Bookkeeping.all_journal_entries()
  #     {:ok, [%JournalEntry{...}, %JournalEntry{...}, ...]}
  # """
  # @spec all_journal_entries() :: {:ok, list(JournalEntry.t())}
  # defdelegate all_journal_entries, to: AccountingJournal

  # @spec find_journal_entry_by_journal_entry_number(String.t()) ::
  #         {:ok, JournalEntry.t()} | {:error, :not_found}
  # defdelegate find_journal_entry_by_journal_entry_number(journal_entry_number),
  #   to: AccountingJournal

  # @spec find_journal_entries_by_general_ledger_posting_date(
  #         DateTime.t()
  #         | AccountingJournal.general_ledger_posting_date_details()
  #       ) :: {:ok, list(JournalEntry.t())} | {:error, :invalid_date}
  # defdelegate find_journal_entries_by_general_ledger_posting_date(datetime), to: AccountingJournal

  # @doc """
  # Returns a journal entry by id.

  # Returns `{:ok, JournalEntry.t()}` if the journal entry is returned successfully. Otherwise, returns `{:error, :invalid_id}`.

  # ## Examples

  #     iex> Bookkeeping.find_journal_entries_by_id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
  #     {:ok, %JournalEntry{...}}

  #     iex> Bookkeeping.find_journal_entries_by_id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
  #     {:error, :invalid_id}
  # """
  # @spec find_journal_entries_by_id(String.t()) :: {:ok, JournalEntry.t()} | {:error, :invalid_id}
  # defdelegate find_journal_entries_by_id(id), to: AccountingJournal

  # @doc """
  # Returns a list of journal entries by general ledger posting date range.

  # Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully. Otherwise, returns `{:error, :invalid_date}`.

  # ## Examples

  #     iex> Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(~U[2021-10-10 10:10:10.000000Z], ~U[2021-10-10 10:10:10.000000Z])
  #     {:ok, [%JournalEntry{...}]}

  #     iex> Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(%{year: 2021, month: 10, day: 10}, %{year: 2021, month: 10, day: 10})
  #     {:ok, [%JournalEntry{...}]}

  #     iex> Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(~U[2021-10-10 10:10:10.000000Z], ~U[2021-10-10 10:10:10.000000Z])
  #     {:error, :invalid_date}
  # """
  # @spec find_journal_entries_by_general_ledger_posting_date_range(
  #         DateTime.t() | AccountingJournal.general_ledger_posting_date_details(),
  #         DateTime.t() | AccountingJournal.general_ledger_posting_date_details()
  #       ) :: {:ok, list(JournalEntry.t())} | {:error, :invalid_date}
  # defdelegate find_journal_entries_by_general_ledger_posting_date_range(
  #               from_datetime,
  #               to_datetime
  #             ),
  #             to: AccountingJournal

  # @doc """
  # Updates a journal entry.

  # Returns `{:ok, JournalEntry.t()}` if the journal entry is updated successfully. Otherwise, returns `{:error, :invalid_journal_entry}`.

  # ## Examples

  #     iex> Bookkeeping.find_journal_entry_by_journal_entry_number("ref_num_1")
  #     {:ok, %JournalEntry{...}}

  #     iex> Bookkeeping.update_journal_entry(%JournalEntry{...}, %{journal_entry_description: "updated description",posted: true})
  #     {:ok, %JournalEntry{journal_entry_description: "updated description", posted: true, ...}}

  #     iex> Bookkeeping.update_journal_entry(%JournalEntry{}, %{journal_entry_description: "updated description",posted: true})
  #     {:error, :invalid_journal_entry}
  # """
  # @spec update_journal_entry(JournalEntry.t(), map()) ::
  #         {:ok, JournalEntry.t()}
  #         | {:error, :invalid_journal_entry}
  #         | {:error, :already_posted_journal_entry}
  # defdelegate update_journal_entry(journal_entry, attrs), to: AccountingJournal

  # @doc """
  # Resets the journal entries.

  # Returns `{:ok, list(JournalEntry.t())}` if the journal entries are reset successfully.

  # ## Examples

  #     iex> Bookkeeping.reset_journal_entries()
  #     {:ok, []}
  # """
  # @spec reset_journal_entries() :: {:ok, list(JournalEntry.t())}
  # defdelegate reset_journal_entries, to: AccountingJournal

  # @doc """
  # Returns the state of the accounting journal.

  # Returns `{:ok, state}`.

  # ## Examples

  #     iex> Bookkeeping.get_accounting_journal_state()
  #     {:ok, %{...}}
  # """
  # @spec get_accounting_journal_state() :: {:ok, AccountingJournal.accounting_journal_state()}
  # defdelegate get_accounting_journal_state, to: AccountingJournal
end
