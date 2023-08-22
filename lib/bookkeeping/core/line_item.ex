defmodule Bookkeeping.Core.LineItem do
  @moduledoc """
  Bookkeeping.Core.LineItem is a struct that represents a line item in a journal entry.
  A line item is a record of a single account and the amount of money that is either debited or credited.
  """
  @type t :: %__MODULE__{
          account: Account.t(),
          amount: Decimal.t(),
          entry_type: EntryType.t()
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

  alias Bookkeeping.Core.{Account, EntryType}

  defstruct account: %Account{},
            amount: 0,
            entry_type: nil

  @doc """
  Creates a list of line item structs.

  Arguments:
    - t_accounts: The map of line items. The map must have the following keys:
      - left: The list of maps with account and amount field and represents the entry type of debit.
      - right: The list of maps with account and amount field and represents the entry type of credit.

  Returns `{:ok, [%LineItem{}, ...]}` if the line item is valid. Otherwise, returns `{:error, :invalid_line_item}`.

  ## Examples

      iex> LineItem.bulk_create(%{left: [%{account: expense_account, amount: Decimal.new(100)}], right: [%{account: asset_account, amount: Decimal.new(100)}]})
      {:ok,
       [
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
       ]}
  """
  @spec bulk_create(t_accounts()) ::
          {:ok, list(__MODULE__.t())} | {:error, :invalid_line_item}
  def bulk_create(t_accounts) when is_map(t_accounts) and map_size(t_accounts) > 0 do
    bulk_create_result =
      t_accounts
      |> Task.async_stream(fn
        {:left, debit_items} ->
          Task.async_stream(debit_items, fn item ->
            create(item.account, item.amount, :debit)
          end)

        {:right, credit_items} ->
          Task.async_stream(credit_items, fn item ->
            create(item.account, item.amount, :credit)
          end)
      end)
      |> Enum.reduce(
        %{
          debit_balance: Decimal.new(0),
          credit_balance: Decimal.new(0),
          balanced: false,
          created_line_items: []
        },
        &validate_line_items/2
      )

    case bulk_create_result.created_line_items do
      [] ->
        {:error, :invalid_line_items}

      created_line_items ->
        if bulk_create_result.balanced,
          do: {:ok, created_line_items},
          else: {:error, :unbalanced_line_items}
    end
  end

  def bulk_create(_), do: {:error, :invalid_line_items}

  @doc """
    Creates a new line item struct.

  Arguments:
      - account: The account of the line item.
      - amount: The amount of the line item.
      - binary_entry_type: The entry type of the line item.

    Returns `{:ok, %LineItem{}}` if the line item is valid. Otherwise, returns `{:error, :invalid_line_item}`.

    ## Examples

        iex> LineItem.create(asset_account, Decimal.new(100), "debit")
        {:ok,
         %LineItem{
           account: %Account{
             code: nil,
             name: nil,
             account_type: asset_account,
           amount: Decimal.new(100),
           entry_type: :debit
         }}
  """
  @spec create(Account.t(), Decimal.t(), EntryType.t()) ::
          {:ok, __MODULE__.t()} | {:error, :invalid_line_item}
  def create(account, amount, atom_entry_type) do
    with true <- is_struct(account, Account),
         true <- is_struct(amount, Decimal),
         true <- Decimal.gt?(amount, Decimal.new(0)),
         true <- atom_entry_type in EntryType.all_entry_types(),
         {:ok, entry_type} <- EntryType.create(atom_entry_type) do
      {:ok, %__MODULE__{account: account, amount: amount, entry_type: entry_type}}
    else
      _ -> {:error, :invalid_line_item}
    end
  end

  defp validate_line_items({:ok, line_items}, acc) do
    Enum.reduce(line_items, acc, fn
      {:ok, {:ok, line_item}}, acc -> process_line_item(acc, line_item)
      {:ok, {:error, _line_item}}, acc -> acc
    end)
  end

  defp process_line_item(acc, line_item) do
    entry_type = line_item.entry_type

    updated_debit_balance =
      if entry_type == :debit,
        do: Decimal.add(acc.debit_balance, line_item.amount),
        else: acc.debit_balance

    updated_credit_balance =
      if entry_type == :credit,
        do: Decimal.add(acc.credit_balance, line_item.amount),
        else: acc.credit_balance

    %{
      debit_balance: updated_debit_balance,
      credit_balance: updated_credit_balance,
      balanced: Decimal.equal?(updated_debit_balance, updated_credit_balance),
      created_line_items: [line_item | acc.created_line_items]
    }
  end
end
