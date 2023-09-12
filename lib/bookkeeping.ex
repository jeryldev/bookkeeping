defmodule Bookkeeping do
  @moduledoc """
  Bookkeeping is a library that provides a set of functions for managing the chart of accounts and accounting journal.

  To get started, follow the instructions below:

  1. In the Bookkeeping project directory, run `mix deps.get` to install dependencies.
  2. Run `iex -S mix` to start the Elixir interactive shell.
  3. Run `Bookkeeping.import_accounts("../../assets/sample_chart_of_accounts.csv")` to import sample chart of accounts.
  4. Run `Bookkeeping.import_journal_entries("../../assets/sample_journal_entries.csv")` to import sample journal entries.
  """

  alias Bookkeeping.Boundary.AccountingJournal.Server, as: AccountingJournal
  alias Bookkeeping.Boundary.ChartOfAccounts.Server, as: ChartOfAccounts
  alias Bookkeeping.Core.{Account, JournalEntry}

  ##########################################################
  # Chart of Accounts Functions                            #
  ##########################################################

  @spec create_account(String.t(), String.t(), String.t(), String.t(), map()) ::
          {:ok, Account.t()} | {:error, :invalid_account} | {:error, :account_already_exists}
  defdelegate create_account(code, name, account_type, description, audit_details),
    to: ChartOfAccounts

  @spec import_accounts(String.t()) ::
          {:ok, %{ok: list(Account.t()), error: list(map())}}
          | {:error, %{ok: list(Account.t()), error: list(map())}}
          | {:error, %{message: :invalid_csv, errors: list(map())}}
          | {:error, :invalid_file}
  defdelegate import_accounts(file_path), to: ChartOfAccounts

  @spec update_account(Account.t(), map()) :: {:ok, Account.t()} | {:error, :invalid_account}
  defdelegate update_account(account, attrs), to: ChartOfAccounts

  @spec all_accounts() :: {:ok, list(Account.t())}
  defdelegate all_accounts, to: ChartOfAccounts

  @spec find_account_by_code(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  defdelegate find_account_by_code(code), to: ChartOfAccounts

  @spec find_account_by_name(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  defdelegate find_account_by_name(name), to: ChartOfAccounts

  @spec search_accounts(String.t()) :: {:ok, list(Account.t())} | {:error, :invalid_query}
  defdelegate search_accounts(code_or_name), to: ChartOfAccounts

  @spec all_sorted_accounts(String.t()) :: {:ok, list(Account.t())} | {:error, :invalid_field}
  defdelegate all_sorted_accounts(account_field), to: ChartOfAccounts

  @spec reset_accounts() :: {:ok, list(Account.t())}
  defdelegate reset_accounts, to: ChartOfAccounts

  ##########################################################
  # Accounting Journal Functions                           #
  ##########################################################

  @spec create_journal_entry(AccountingJournal.create_journal_entry_params()) ::
          {:ok, JournalEntry.t()} | {:error, :invalid_journal_entry}
  defdelegate create_journal_entry(create_journal_entry_params), to: AccountingJournal

  @spec import_journal_entries(String.t()) ::
          {:ok, %{ok: list(JournalEntry.t()), error: list(map())}}
          | {:error, %{ok: list(JournalEntry.t()), error: list(map())}}
          | {:error, %{message: :invalid_csv, errors: list(map())}}
          | {:error, :invalid_file}
  defdelegate import_journal_entries(file_path), to: AccountingJournal

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

  @spec find_journal_entries_by_id(String.t()) :: {:ok, JournalEntry.t()} | {:error, :invalid_id}
  defdelegate find_journal_entries_by_id(id), to: AccountingJournal

  @spec find_journal_entries_by_general_ledger_posting_date_range(
          DateTime.t() | AccountingJournal.general_ledger_posting_date_details(),
          DateTime.t() | AccountingJournal.general_ledger_posting_date_details()
        ) :: {:ok, list(JournalEntry.t())} | {:error, :invalid_date}
  defdelegate find_journal_entries_by_general_ledger_posting_date_range(
                from_datetime,
                to_datetime
              ),
              to: AccountingJournal

  @spec update_journal_entry(JournalEntry.t(), map()) ::
          {:ok, JournalEntry.t()}
          | {:error, :invalid_journal_entry}
          | {:error, :already_posted_journal_entry}
  defdelegate update_journal_entry(journal_entry, attrs), to: AccountingJournal

  @spec reset_journal_entries() :: {:ok, list(JournalEntry.t())}
  defdelegate reset_journal_entries, to: AccountingJournal
end
