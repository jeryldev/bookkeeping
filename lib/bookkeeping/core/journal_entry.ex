defmodule Bookkeeping.Core.JournalEntry do
  @moduledoc """
  Bookkeeping.Core.JournalEntry is a struct that represents a journal entry.
  A journal entry is a record of a financial transaction with two or more accounts.
  The total amount of the debits must equal the total amount of the credits.
  """
  @type t :: %__MODULE__{
          id: UUID.t(),
          transaction_date: DateTime.t(),
          line_items: list(LineItem.t()),
          reference_number: String.t(),
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
            reference_number: "",
            description: "",
            journal_entry_details: %{},
            line_items: [],
            audit_logs: [],
            posted: false

  @doc """
  Creates a new journal entry struct.

  Arguments:
    - transaction_date: The date of the transaction.
    - reference_number: The unique reference number of the journal entry.
    - description: The description of the journal entry.
    - journal_entry_details: The details of the journal entry.
    - t_accounts: The map of line items. The map must have the following keys:
      - left: The list of maps with account and amount field and represents the entry type of debit.
      - right: The list of maps with account and amount field and represents the entry type of credit.
    - audit_details: The details of the audit log.

  Returns `{:ok, %JournalEntry{}}` if the journal entry is valid. Otherwise, returns `{:error, :invalid_journal_entry}`, `{:error, :invalid_line_items}`, `{:error, :unbalanced_line_items}`, or `{:error, list(:invalid_amount | :invalid_account | :inactive_account)}`.

  ## Examples

      iex> JournalEntry.create(DateTime.utc_now(), "reference number", "description", %{}, %{
                 left: [%{account: expense_account, amount: Decimal.new(100)}],
                 right: [%{account: asset_account, amount: Decimal.new(100)}]
               }, %{})
      {:ok,
      %JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "reference number",
        description: "description",
        journal_entry_details: %{},
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: :debit
          },
          %LineItem{
            account: asset_account,
            amount: Decimal.new(100),
            entry_type: :credit
          }
        ],
        audit_logs: [
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "journal_entry",
            action_type: "create",
            details: %{},
            created_at: ~U[2021-10-10 10:10:10.000000Z],
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          }
        ],
        posted: false
      }}

      iex> JournalEntry.create(DateTime.utc_now(), "reference number", "description", %{}, %{})
      {:error, :invalid_journal_entry}

  """
  @spec create(DateTime.t(), t_accounts(), String.t(), String.t(), map(), map()) ::
          {:ok, __MODULE__.t()}
          | {:error, :invalid_journal_entry}
          | {:error, :unbalanced_line_items}
          | {:error, :invalid_line_items}
          | {:error, list(:invalid_amount | :invalid_account | :inactive_account)}
  def create(
        transaction_date,
        t_accounts,
        reference_number,
        description,
        journal_entry_details,
        audit_details
      )
      when is_binary(reference_number) and is_binary(description) and
             is_map(journal_entry_details) and is_map(t_accounts) and
             is_map(audit_details) and not is_nil(transaction_date) do
    new(
      transaction_date,
      t_accounts,
      reference_number,
      description,
      journal_entry_details,
      audit_details
    )
  end

  def create(_, _, _, _, _, _), do: {:error, :invalid_journal_entry}

  @doc """
  Updates a journal entry struct. Update can only be done if the journal entry is not posted.

  Arguments:
    - journal_entry: The journal entry to be updated.
    - attrs: The attributes to be updated. The editable attributes are `transaction_date`, `reference_number`, `description`, `posted`, `t_accounts`, and `audit_details`.

  Returns `{:ok, %JournalEntry{}}` if the journal entry is valid. Otherwise, returns `{:error, :invalid_journal_entry}`.

  ## Examples

      iex> JournalEntry.update(journal_entry, %{})
      {:error, :invalid_journal_entry}

      iex> {:ok, journal_entry} = JournalEntry.create(DateTime.utc_now(), "reference number", "description", %{
                 left: [%{account: expense_account, amount: Decimal.new(100)}],
                 right: [%{account: asset_account, amount: Decimal.new(100)}]
               }, %{})
      {:ok,
      %JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "reference number",
        description: "description",
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: :debit
          },
          %LineItem{
            account: asset_account,
            amount: Decimal.new(100),
            entry_type: :credit
          }
        ],
        audit_logs: [
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "journal_entry",
            action_type: "create",
            details: %{},
            created_at: ~U[2021-10-10 10:10:10.000000Z],
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          }
        ],
        posted: false
      }}

      iex> JournalEntry.update(journal_entry, %{description: "updated description",posted: true})
      {:ok,
      %JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "reference number",
        description: "updated description",
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: :debit
          },
          %LineItem{
            account: asset_account,
            amount: Decimal.new(100),
            entry_type: :credit
          }
        ],
        audit_logs: [
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "journal_entry",
            action_type: "create",
            details: %{},
            created_at: ~U[2021-10-10 10:10:10.000000Z],
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          },
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "journal_entry",
            action_type: "update",
            details: %{},
            created_at: nil,
            updated_at: ~U[2021-10-10 10:10:10.000000Z
            deleted_at: nil
          }
        ],
        posted: true
      }}

      iex> JournalEntry.update(journal_entry, %{transaction_date: DateTime.utc_now()})
      {:error, :already_posted_journal_entry}
  """
  @spec update(__MODULE__.t(), map()) :: {:ok, __MODULE__.t()} | {:error, :invalid_journal_entry}
  def update(journal_entry, attrs)
      when is_map(attrs) and map_size(attrs) > 0 and journal_entry.posted == false do
    transaction_date = Map.get(attrs, :transaction_date, journal_entry.transaction_date)
    reference_number = Map.get(attrs, :reference_number, journal_entry.reference_number)
    description = Map.get(attrs, :description, journal_entry.description)

    journal_entry_details =
      Map.get(attrs, :journal_entry_details, journal_entry.journal_entry_details)

    posted = Map.get(attrs, :posted, journal_entry.posted)
    t_accounts = Map.get(attrs, :t_accounts, %{left: [], right: []})
    audit_details = Map.get(attrs, :audit_details, %{})

    valid_fields? =
      is_binary(reference_number) and reference_number != "" and is_binary(description) and
        not is_nil(transaction_date) and is_boolean(posted) and is_map(t_accounts) and
        is_map(audit_details)

    with true <- valid_fields?,
         {:ok, audit_log} <- AuditLog.create("journal_entry", "update", audit_details) do
      updated_journal_entry =
        process_journal_entry_update(
          journal_entry,
          transaction_date,
          t_accounts,
          reference_number,
          description,
          journal_entry_details,
          audit_log,
          posted
        )

      {:ok, updated_journal_entry}
    else
      _ -> {:error, :invalid_journal_entry}
    end
  end

  def update(journal_entry, _) when journal_entry.posted == true,
    do: {:error, :already_posted_journal_entry}

  def update(_, _), do: {:error, :invalid_journal_entry}

  defp new(
         transaction_date,
         t_accounts,
         reference_number,
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
         line_items: line_items,
         reference_number: reference_number,
         description: description,
         journal_entry_details: journal_entry_details,
         audit_logs: [audit_log]
       }}
    else
      {:error, message} -> {:error, message}
    end
  end

  defp process_journal_entry_update(
         current_journal_entry,
         transaction_date,
         t_accounts,
         reference_number,
         description,
         journal_entry_details,
         audit_log,
         posted
       ) do
    existing_audit_logs = Map.get(current_journal_entry, :audit_logs, [])

    line_items =
      if t_accounts == %{left: [], right: []} do
        current_journal_entry.line_items
      else
        {:ok, line_items} = LineItem.bulk_create(t_accounts)
        line_items
      end

    update_params = %{
      transaction_date: transaction_date,
      reference_number: reference_number,
      description: description,
      journal_entry_details: journal_entry_details,
      line_items: line_items,
      audit_logs: [audit_log | existing_audit_logs],
      posted: posted
    }

    Map.merge(current_journal_entry, update_params)
  end
end
