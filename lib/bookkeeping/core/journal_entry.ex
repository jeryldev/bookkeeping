defmodule Bookkeeping.Core.JournalEntry do
  @moduledoc """
  Bookkeeping.Core.JournalEntry is a struct that represents a journal entry.
  A journal entry is a record of a financial transaction with two or more accounts.
  The total amount of the debits must equal the total amount of the credits.
  """
  @type t :: %__MODULE__{
          id: UUID.t(),
          transaction_date: DateTime.t(),
          general_ledger_posting_date: DateTime.t(),
          line_items: list(LineItem.t()),
          journal_entry_number: String.t(),
          transaction_reference_number: String.t(),
          description: String.t(),
          journal_entry_details: map(),
          audit_logs: list(AuditLog.t()),
          posted: boolean()
        }

  @type t_accounts :: %{
          left: list(t_accounts_item),
          right: list(t_accounts_item)
        }

  @type t_accounts_item :: %{
          account: Bookkeeping.Core.Account.t(),
          amount: Decimal.t(),
          entry_type: String.t()
        }

  alias Bookkeeping.Core.{AuditLog, LineItem}

  defstruct id: UUID.uuid4(),
            transaction_date: DateTime.utc_now(),
            general_ledger_posting_date: DateTime.utc_now(),
            journal_entry_number: "",
            transaction_reference_number: "",
            description: "",
            journal_entry_details: %{},
            line_items: [],
            audit_logs: [],
            posted: false

  @doc """
  Creates a new journal entry struct.

  Arguments:
    - transaction_date: The date of the transaction. This is usually the date of the source document (i.e. invoice date, check date, etc.)
    - general_ledger_posting_date: The date of the General Ledger posting. This is usually the date when the journal entry is posted to the General Ledger.
    - t_accounts: The map of line items. The map must have the following keys:
      - left: The list of maps with account and amount field and represents the entry type of debit.
      - right: The list of maps with account and amount field and represents the entry type of credit.
    - journal_entry_number: The unique reference number of the journal entry. This is an auto-generated unique sequential identifier that is distinct from the transaction reference number (i.e. JE001000, JE001002, etc).
    - transaction_reference_number: The reference number of the transaction. This is usually the reference number of the source document (i.e. invoice number, check number, etc.)
    - description: The description of the journal entry. This is usually the description of the source document (i.e. invoice description, check description, etc.)
    - journal_entry_details: The details of the journal entry. The details are usually the details of the source document (i.e. invoice details, check details, etc.)
    - audit_details: The details of the audit log.

  Returns `{:ok, %JournalEntry{}}` if the journal entry is valid. Otherwise, returns `{:error, :invalid_journal_entry}`, `{:error, :invalid_line_items}`, `{:error, :unbalanced_line_items}`, or `{:error, list(:invalid_amount | :invalid_account | :inactive_account)}`.

  ## Examples

      iex> JournalEntry.create(DateTime.utc_now(), DateTime.utc_now(), %{
                 left: [%{account: asset_account, amount: Decimal.new(100)}],
                 right: [%{account: revenue_account, amount: Decimal.new(100)}]
               }, "JE001001", "INV001001", "description", %{}, %{})
      {:ok, %JournalEntry{...}}

      iex> JournalEntry.create(DateTime.utc_now(), "reference number", "description", %{}, %{})
      {:error, :invalid_journal_entry}

  """
  @spec create(
          DateTime.t(),
          DateTime.t(),
          t_accounts(),
          String.t(),
          String.t(),
          String.t(),
          map(),
          map()
        ) ::
          {:ok, __MODULE__.t()}
          | {:error, :invalid_journal_entry}
          | {:error, :unbalanced_line_items}
          | {:error, :invalid_line_items}
          | {:error, list(:invalid_amount | :invalid_account | :inactive_account)}
  def create(
        transaction_date,
        general_ledger_posting_date,
        t_accounts,
        journal_entry_number,
        transaction_reference_number,
        description,
        journal_entry_details,
        audit_details
      ) do
    valid_fields? =
      is_binary(journal_entry_number) and is_binary(transaction_reference_number) and
        is_binary(description) and is_map(journal_entry_details) and is_map(t_accounts) and
        is_map(audit_details) and not is_nil(transaction_date) and
        not is_nil(general_ledger_posting_date)

    if valid_fields? do
      new(
        transaction_date,
        general_ledger_posting_date,
        t_accounts,
        journal_entry_number,
        transaction_reference_number,
        description,
        journal_entry_details,
        audit_details
      )
    else
      {:error, :invalid_journal_entry}
    end
  end

  @doc """
  Updates a journal entry struct. Update can only be done if the journal entry is not posted.

  Arguments:
    - journal_entry: The journal entry to be updated.
    - attrs: The attributes to be updated. The editable attributes are `transaction_date`, `journal_entry_number`, `description`, `posted`, `t_accounts`, and `audit_details`.

  Returns `{:ok, %JournalEntry{}}` if the journal entry is valid. Otherwise, returns `{:error, :invalid_journal_entry}`.

  ## Examples

      iex> JournalEntry.update(journal_entry, %{description: "updated description",posted: true})
      {:ok, %JournalEntry{...}}

      iex> JournalEntry.update(journal_entry, %{transaction_date: DateTime.utc_now()})
      {:error, :already_posted_journal_entry}

      iex> JournalEntry.update(not_existing_journal_entry, %{})
      {:error, :invalid_journal_entry}
  """
  @spec update(__MODULE__.t(), map()) :: {:ok, __MODULE__.t()} | {:error, :invalid_journal_entry}
  def update(journal_entry, attrs)
      when is_map(attrs) and map_size(attrs) > 0 and journal_entry.posted == false do
    with {:ok, params} <- validate_update_params(journal_entry, attrs),
         {:ok, audit_log} <- AuditLog.create("journal_entry", "update", params.audit_details),
         {:ok, initial_je_update} <-
           update_dates_and_line_items(
             journal_entry,
             params.transaction_date,
             params.general_ledger_posting_date,
             params.t_accounts
           ),
         {:ok, final_je_update} <-
           update_other_journal_entry_details(
             initial_je_update,
             params.journal_entry_number,
             params.transaction_reference_number,
             params.description,
             params.journal_entry_details,
             audit_log,
             params.posted
           ) do
      {:ok, final_je_update}
    else
      _ -> {:error, :invalid_journal_entry}
    end
  end

  def update(journal_entry, _) when journal_entry.posted == true,
    do: {:error, :already_posted_journal_entry}

  def update(_, _), do: {:error, :invalid_journal_entry}

  defp new(
         transaction_date,
         general_ledger_posting_date,
         t_accounts,
         journal_entry_number,
         transaction_reference_number,
         description,
         journal_entry_details,
         audit_details
       ) do
    with {:ok, line_items} <- LineItem.bulk_create(t_accounts),
         {:ok, audit_log} <- AuditLog.create("journal_entry", "create", audit_details) do
      {:ok,
       %__MODULE__{
         id: UUID.uuid4(),
         transaction_date: transaction_date,
         general_ledger_posting_date: general_ledger_posting_date,
         line_items: line_items,
         journal_entry_number: journal_entry_number,
         transaction_reference_number: transaction_reference_number,
         description: description,
         journal_entry_details: journal_entry_details,
         audit_logs: [audit_log]
       }}
    else
      {:error, message} -> {:error, message}
    end
  end

  defp validate_update_fields(params) do
    is_binary(params.journal_entry_number) and params.journal_entry_number != "" and
      is_binary(params.transaction_reference_number) and is_binary(params.description) and
      not is_nil(params.transaction_date) and not is_nil(params.general_ledger_posting_date) and
      is_boolean(params.posted) and is_map(params.t_accounts) and is_map(params.audit_details)
  end

  defp validate_update_params(journal_entry, attrs) do
    params = %{
      transaction_date: Map.get(attrs, :transaction_date, journal_entry.transaction_date),
      general_ledger_posting_date:
        Map.get(attrs, :general_ledger_posting_date, journal_entry.general_ledger_posting_date),
      t_accounts: Map.get(attrs, :t_accounts, %{left: [], right: []}),
      journal_entry_number:
        Map.get(attrs, :journal_entry_number, journal_entry.journal_entry_number),
      transaction_reference_number:
        Map.get(attrs, :transaction_reference_number, journal_entry.transaction_reference_number),
      description: Map.get(attrs, :description, journal_entry.description),
      journal_entry_details:
        Map.get(attrs, :journal_entry_details, journal_entry.journal_entry_details),
      posted: Map.get(attrs, :posted, journal_entry.posted),
      audit_details: Map.get(attrs, :audit_details, %{})
    }

    if validate_update_fields(params),
      do: {:ok, params},
      else: {:error, :invalid_journal_entry}
  end

  defp update_dates_and_line_items(
         journal_entry,
         transaction_date,
         general_ledger_posting_date,
         t_accounts
       ) do
    line_items =
      if t_accounts == %{left: [], right: []} do
        journal_entry.line_items
      else
        {:ok, line_items} = LineItem.bulk_create(t_accounts)
        line_items
      end

    update_params = %{
      transaction_date: transaction_date,
      general_ledger_posting_date: general_ledger_posting_date,
      line_items: line_items
    }

    {:ok, Map.merge(journal_entry, update_params)}
  end

  defp update_other_journal_entry_details(
         journal_entry,
         journal_entry_number,
         transaction_reference_number,
         description,
         journal_entry_details,
         audit_log,
         posted
       ) do
    existing_audit_logs = Map.get(journal_entry, :audit_logs, [])

    update_params = %{
      journal_entry_number: journal_entry_number,
      transaction_reference_number: transaction_reference_number,
      description: description,
      journal_entry_details: journal_entry_details,
      audit_logs: [audit_log | existing_audit_logs],
      posted: posted
    }

    {:ok, Map.merge(journal_entry, update_params)}
  end
end
