defmodule Bookkeeping.Core.JournalEntry do
  @moduledoc """
  Bookkeeping.Core.JournalEntry is a struct that represents a journal entry.
  A journal entry is a record of a financial transaction with two or more accounts.
  The total amount of the debits must equal the total amount of the credits.
  """
  alias Bookkeeping.Core.{AuditLog, LineItem}

  @type t :: %__MODULE__{
          transaction_date: DateTime.t(),
          posting_date: nil | DateTime.t(),
          document_number: String.t(),
          reference_number: nil | String.t(),
          particulars: String.t(),
          details: map(),
          debit_items: list(LineItem.t()),
          credit_items: list(LineItem.t()),
          audit_logs: list(AuditLog.t()),
          posted: boolean(),
          base_currency: String.t(),
          transaction_currency: String.t(),
          base_rate: Decimal.t(),
          transaction_rate: Decimal.t()
        }

  @type create_params :: %{
          transaction_date: DateTime.t(),
          posting_date: nil | DateTime.t(),
          document_number: String.t(),
          reference_number: nil | String.t(),
          particulars: String.t(),
          details: map(),
          debit_items: list(line_item_create_params()),
          credit_items: list(line_item_create_params()),
          audit_logs: list(AuditLog.t()),
          posted: boolean(),
          base_currency: String.t(),
          transaction_currency: String.t(),
          base_rate: Decimal.t(),
          transaction_rate: Decimal.t()
        }

  @type line_item_create_params :: %{
          account: Account.t(),
          amount: integer() | float(),
          particulars: String.t()
        }

  defstruct transaction_date: DateTime.utc_now(),
            posting_date: nil,
            document_number: "",
            reference_number: nil,
            particulars: "",
            details: %{},
            debit_items: [],
            credit_items: [],
            audit_logs: [],
            posted: false,
            base_currency: nil,
            transaction_currency: nil,
            base_rate: Decimal.new(1),
            transaction_rate: Decimal.new(1)

  def create(params) do
    with {:ok, params} <- validate_params(params),
         {:ok, params} <- validate_audit_details(params, "create"),
         {:ok, debit_items} <- validate_line_items(params, :debit_items),
         {:ok, credit_items} <- validate_line_items(params, :credit_items),
         {:ok, nil} <- validate_balance(debit_items, credit_items, params.transaction_currency) do
      params = Map.merge(params, %{debit_items: debit_items, credit_items: credit_items})
      {:ok, Map.merge(%__MODULE__{}, params)}
    end
  end

  defp validate_params(
         %{
           transaction_date: transaction_date,
           posting_date: posting_date,
           document_number: document_number,
           reference_number: reference_number,
           particulars: particulars,
           details: details,
           posted: posted,
           base_currency: base_currency,
           transaction_currency: transaction_currency,
           base_rate: base_rate,
           transaction_rate: transaction_rate
         } = params
       ) do
    with {:ok, _transaction_date} <- validate_transaction_date(transaction_date),
         {:ok, _posting_date} <- validate_posting_date(posting_date),
         {:ok, _document_number} <- validate_binary(document_number, :invalid_document_number),
         {:ok, _reference_number} <- validate_reference_number(reference_number),
         {:ok, _particulars} <- validate_binary(particulars, :invalid_particulars),
         {:ok, _details} <- validate_details(details),
         {:ok, _posted} <- validate_posted_state(posted),
         {:ok, _base_currency} <- validate_binary(base_currency, :invalid_base_currency),
         {:ok, _transaction_currency} <-
           validate_binary(transaction_currency, :invalid_transaction_currency),
         {:ok, _base_rate} <- validate_rate(base_rate, :invalid_base_rate),
         {:ok, _transaction_rate} <- validate_rate(transaction_rate, :invalid_base_rate) do
      {:ok, params}
    end
  end

  defp validate_params(_), do: {:error, :invalid_params}

  defp validate_transaction_date(transaction_date)
       when is_struct(transaction_date, DateTime),
       do: {:ok, transaction_date}

  defp validate_transaction_date(_transaction_date), do: {:error, :invalid_transaction_date}

  defp validate_posting_date(posting_date)
       when is_nil(posting_date) or is_struct(posting_date, DateTime),
       do: {:ok, posting_date}

  defp validate_posting_date(_posting_date), do: {:error, :invalid_posting_date}

  defp validate_reference_number(reference_number)
       when is_nil(reference_number) or (is_binary(reference_number) and reference_number != ""),
       do: {:ok, reference_number}

  defp validate_reference_number(_reference_number), do: {:error, :invalid_reference_number}

  defp validate_binary(binary, _error_message) when is_binary(binary) and binary != "",
    do: {:ok, binary}

  defp validate_binary(_binary, error_message), do: {:error, error_message}

  defp validate_rate(rate, _error_message) when is_struct(rate, Decimal), do: {:ok, rate}
  defp validate_rate(_rate, error_message), do: {:error, error_message}

  defp validate_details(details) when is_map(details), do: {:ok, details}
  defp validate_details(_details), do: {:error, :invalid_details}

  defp validate_posted_state(posted) when is_boolean(posted), do: {:ok, posted}
  defp validate_posted_state(_posted), do: {:error, :invalid_posted_state}

  defp validate_audit_details(params, action) do
    details = Map.get(params, :audit_details, %{})

    case AuditLog.create(%{record: "journal_entry", action: action, details: details}) do
      {:ok, audit_log} ->
        params =
          params
          |> Map.delete(:audit_details)
          |> Map.put(:audit_logs, [audit_log])

        {:ok, params}

      {:error, _reason} ->
        {:error, :invalid_audit_details}
    end
  end

  # defp validate_audit_logs(%{audit_logs: audit_logs})
  #      when is_list(audit_logs) and length(audit_logs) >= 1,
  #      do: {:ok, audit_logs}

  # defp validate_audit_logs(_params), do: {:error, :invalid_audit_logs}

  # defp validate_posting_date(posting_date) when is_nil(posting_date) or is_datetime(posting_date),
  #   do: {:ok, posting_date}

  # defp validate_posting_date(_), do: {:error, :invalid_posting_date}

  # defp validate_document_number(document_number)
  #      when is_binary(document_number) and document_number != "",
  #      do: {:ok, document_number}

  # defp validate_date(datetime, _error_message)
  #      when is_struct(datetime, DateTime),
  #      do: {:ok, datetime}

  # defp validate_date(_datetime, error_message), do: {:error, error_message}

  defp validate_line_items(params, field) do
    line_items = Map.get(params, field, [])

    if line_items == [] or not is_list(line_items) do
      error_reason =
        case field do
          :debit_items -> :invalid_debit_items
          :credit_items -> :invalid_credit_items
        end

      {:error, error_reason}
    else
      transaction_currency = Map.get(params, :transaction_currency)

      Enum.reduce_while(line_items, {:ok, []}, fn item, acc ->
        with {:ok, params} <- transform_amount(item, field, transaction_currency),
             {:ok, line_item} <- LineItem.create(params) do
          {:cont, {:ok, [line_item | elem(acc, 1)]}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp transform_amount(%{amount: amount} = params, field, transaction_currency)
       when is_integer(amount) and field in [:debit_items, :credit_items] do
    entry = if field == :debit_items, do: :debit, else: :credit

    case Money.new(transaction_currency, amount) do
      {:error, _error} -> {:error, :invalid_amount}
      amount -> {:ok, Map.merge(params, %{amount: amount, entry: entry})}
    end
  end

  defp transform_amount(%{amount: amount} = params, field, transaction_currency)
       when is_float(amount) and field in [:debit_items, :credit_items] do
    entry = if field == :debit_items, do: :debit, else: :credit

    case Money.from_float(transaction_currency, amount) do
      {:error, _error} -> {:error, :invalid_amount}
      amount -> {:ok, Map.merge(params, %{amount: amount, entry: entry})}
    end
  end

  defp transform_amount(_params, _field, _transaction_currency), do: {:error, :invalid_amount}

  # defp validate_currency(item, transaction_currency) do
  #   if Atom.to_string(item.amount.currency) == transaction_currency,
  #     do: {:ok, item},
  #     else: {:error, :invalid_currency}
  # end

  defp validate_balance(debit_items, credit_items, transaction_currency) do
    total_debits = sum_amounts(debit_items, transaction_currency)
    total_credits = sum_amounts(credit_items, transaction_currency)

    if Money.compare(total_debits, total_credits) == :eq,
      do: {:ok, nil},
      else: {:error, :unbalanced_line_items}
  end

  defp sum_amounts(line_items, transaction_currency) do
    Enum.reduce(line_items, Money.new(transaction_currency, 0), fn item, acc ->
      Money.add(acc, item.amount) |> elem(1)
    end)
  end

  # defp validate_date(datetime) do
  #   # format should be YYYY-MM-DD
  #   case Date.from_iso8601(datetime) do
  #     {:ok, _} -> true
  #     _ -> false
  #   end
  # end

  # @type t_accounts :: %{
  #         left: list(LineItem.t()),
  #         right: list(LineItem.t())
  #       }
  # @doc """
  # Creates a new journal entry struct.

  # Arguments:
  #   - transaction_date: The date of the transaction. This is usually the date of the source document (i.e. invoice date, check date, etc.)
  #   - posting_date: The date of the General Ledger posting. This is usually the date when the journal entry is posted to the General Ledger.
  #   - t_accounts: The map of line items. The map must have the following keys:
  #     - left: The list of maps with account and amount field and represents the entry type of debit.
  #     - right: The list of maps with account and amount field and represents the entry type of credit.
  #   - document_number: The unique reference number of the journal entry. This is an auto-generated unique sequential identifier that is distinct from the transaction reference number (i.e. JE001000, JE001002, etc).
  #   - reference_number: The reference number of the transaction. This is usually the reference number of the source document (i.e. invoice number, check number, etc.)
  #   - description: The description of the journal entry. This is usually the description of the source document (i.e. invoice description, check description, etc.)
  #   - particulars: The details of the journal entry. The details are usually the details of the source document (i.e. invoice details, check details, etc.)
  #   - audit_details: The details of the audit log.

  # Returns `{:ok, %JournalEntry{}}` if the journal entry is valid. Otherwise, returns `{:error, :invalid_journal_entry}`, `{:error, :invalid_line_items}`, `{:error, :unbalanced_line_items}`, or `{:error, list(:invalid_amount | :invalid_account | :inactive_account)}`.

  # ## Examples

  #     iex> JournalEntry.create(DateTime.utc_now(), DateTime.utc_now(), %{
  #                left: [%{account: asset_account, amount: Decimal.new(100), description: ""}],
  #                right: [%{account: revenue_account, amount: Decimal.new(100), description: ""}]
  #              }, "JE001001", "INV001001", "description", %{}, %{})
  #     {:ok, %JournalEntry{...}}

  #     iex> JournalEntry.create(DateTime.utc_now(), "reference number", "description", %{}, %{})
  #     {:error, :invalid_journal_entry}

  # """
  # @spec create(
  #         DateTime.t(),
  #         DateTime.t(),
  #         t_accounts(),
  #         String.t(),
  #         String.t(),
  #         String.t(),
  #         map(),
  #         map()
  #       ) ::
  #         {:ok, __MODULE__.t()}
  #         | {:error, :invalid_journal_entry}
  #         | {:error, :unbalanced_line_items}
  #         | {:error, :invalid_line_items}
  #         | {:error, list(:invalid_amount | :invalid_account | :inactive_account)}
  # def create(
  #       transaction_date,
  #       posting_date,
  #       t_accounts,
  #       journal_entry_number,
  #       reference_number,
  #       description,
  #       particulars,
  #       audit_details
  #     ) do
  #   valid_fields? =
  #     is_binary(journal_entry_number) and is_binary(reference_number) and
  #       is_binary(description) and is_map(particulars) and
  #       is_map(t_accounts) and is_map(audit_details) and not is_nil(transaction_date) and
  #       not is_nil(posting_date)

  #   if valid_fields? do
  #     new(
  #       transaction_date,
  #       posting_date,
  #       t_accounts,
  #       journal_entry_number,
  #       reference_number,
  #       description,
  #       particulars,
  #       audit_details
  #     )
  #   else
  #     {:error, :invalid_journal_entry}
  #   end
  # end

  # @doc """
  # Updates a journal entry struct. Update can only be done if the journal entry is not posted.

  # Arguments:
  #   - journal_entry: The journal entry to be updated.
  #   - attrs: The attributes to be updated. The editable attributes are `transaction_date`, `journal_entry_number`, `description`, `posted`, `t_accounts`, and `audit_details`.

  # Returns `{:ok, %JournalEntry{}}` if the journal entry is valid. Otherwise, returns `{:error, :invalid_journal_entry}`.

  # ## Examples

  #     iex> JournalEntry.update(journal_entry, %{description: "updated description",posted: true})
  #     {:ok, %JournalEntry{...}}

  #     iex> JournalEntry.update(journal_entry, %{transaction_date: DateTime.utc_now()})
  #     {:error, :already_posted_journal_entry}

  #     iex> JournalEntry.update(not_existing_journal_entry, %{})
  #     {:error, :invalid_journal_entry}
  # """
  # @spec update(__MODULE__.t(), map()) :: {:ok, __MODULE__.t()} | {:error, :invalid_journal_entry}
  # def update(journal_entry, attrs)
  #     when is_map(attrs) and map_size(attrs) > 0 and journal_entry.posted == false do
  #   with {:ok, params} <- validate_update_params(journal_entry, attrs),
  #        {:ok, audit_log} <-
  #          AuditLog.create(%{
  #            record_type: "journal_entry",
  #            action_type: "update",
  #            audit_details: params.audit_details
  #          }),
  #        {:ok, initial_je_update} <-
  #          update_dates_and_line_items(
  #            journal_entry,
  #            params.transaction_date,
  #            params.posting_date,
  #            params.t_accounts
  #          ),
  #        {:ok, final_je_update} <-
  #          update_other_particulars(
  #            initial_je_update,
  #            params.journal_entry_number,
  #            params.reference_number,
  #            params.description,
  #            params.particulars,
  #            audit_log,
  #            params.posted
  #          ) do
  #     {:ok, final_je_update}
  #   else
  #     _ -> {:error, :invalid_journal_entry}
  #   end
  # end

  # def update(journal_entry, _) when journal_entry.posted == true,
  #   do: {:error, :already_posted_journal_entry}

  # def update(_, _), do: {:error, :invalid_journal_entry}

  # defp new(
  #        transaction_date,
  #        posting_date,
  #        t_accounts,
  #        journal_entry_number,
  #        reference_number,
  #        description,
  #        particulars,
  #        audit_details
  #      ) do
  #   with {:ok, line_items} <- LineItem.bulk_create(t_accounts),
  #        {:ok, audit_log} <-
  #          AuditLog.create(%{
  #            record_type: "journal_entry",
  #            action_type: "create",
  #            audit_details: audit_details
  #          }) do
  #     {:ok,
  #      %__MODULE__{
  #        transaction_date: transaction_date,
  #        posting_date: posting_date,
  #        line_items: line_items,
  #        document_number: journal_entry_number,
  #        reference_number: reference_number,
  #        description: description,
  #        particulars: particulars,
  #        audit_logs: [audit_log]
  #      }}
  #   else
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # defp validate_update_fields(params) do
  #   is_binary(params.journal_entry_number) and params.journal_entry_number != "" and
  #     is_binary(params.reference_number) and
  #     is_binary(params.description) and
  #     not is_nil(params.transaction_date) and not is_nil(params.posting_date) and
  #     is_boolean(params.posted) and is_map(params.t_accounts) and is_map(params.audit_details)
  # end

  # defp validate_update_params(journal_entry, attrs) do
  #   params = %{
  #     transaction_date: Map.get(attrs, :transaction_date, journal_entry.transaction_date),
  #     posting_date: Map.get(attrs, :posting_date, journal_entry.posting_date),
  #     t_accounts: Map.get(attrs, :t_accounts, %{left: [], right: []}),
  #     document_number: Map.get(attrs, :journal_entry_number, journal_entry.journal_entry_number),
  #     reference_number: Map.get(attrs, :reference_number, journal_entry.reference_number),
  #     description: Map.get(attrs, :description, journal_entry.description),
  #     particulars: Map.get(attrs, :particulars, journal_entry.particulars),
  #     posted: Map.get(attrs, :posted, journal_entry.posted),
  #     audit_details: Map.get(attrs, :audit_details, %{})
  #   }

  #   if validate_update_fields(params),
  #     do: {:ok, params},
  #     else: {:error, :invalid_journal_entry}
  # end

  # defp update_dates_and_line_items(
  #        journal_entry,
  #        transaction_date,
  #        posting_date,
  #        t_accounts
  #      ) do
  #   line_items =
  #     if t_accounts == %{left: [], right: []} do
  #       journal_entry.line_items
  #     else
  #       {:ok, line_items} = LineItem.bulk_create(t_accounts)
  #       line_items
  #     end

  #   update_params = %{
  #     transaction_date: transaction_date,
  #     posting_date: posting_date,
  #     line_items: line_items
  #   }

  #   {:ok, Map.merge(journal_entry, update_params)}
  # end

  # defp update_other_particulars(
  #        journal_entry,
  #        journal_entry_number,
  #        reference_number,
  #        description,
  #        particulars,
  #        audit_log,
  #        posted
  #      ) do
  #   existing_audit_logs = Map.get(journal_entry, :audit_logs, [])

  #   update_params = %{
  #     document_number: journal_entry_number,
  #     reference_number: reference_number,
  #     description: description,
  #     particulars: particulars,
  #     audit_logs: [audit_log | existing_audit_logs],
  #     posted: posted
  #   }

  #   {:ok, Map.merge(journal_entry, update_params)}
  # end
end
