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

  alias Bookkeeping.Core.{Account, EntryType}

  defstruct account: %Account{},
            amount: 0,
            entry_type: nil

  @entry_types ["debit", "credit"]

  @doc """
  Creates a list of line item structs.
  Arguments:
    - line_items_map: The map of line items. The map must have the following keys:
      - left: The list of maps with account and amount field and represents the entry type of debit.
      - right: The list of maps with account and amount field and represents the entry type of credit.

  Returns `{:ok, [%LineItem{}, ...]}` if the line item is valid. Otherwise, returns `{:error, :invalid_line_item}`.

  ## Examples

      iex> LineItem.bulk_create(%{left: [%{account: %Account{}, amount: Decimal.new(100)}], right: [%{account: %Account{}, amount: Decimal.new(100)}]})
      {:ok,
       [
         %LineItem{
           account: %Account{
             code: nil,
             name: nil,
             account_type: %AccountType{
               name: nil,
               normal_balance: %EntryType{type: :debit, name: "Debit"},
               primary_account_category: %PrimaryAccountCategory{type: nil, primary: nil},
               contra: nil
             }
           },
           amount: Decimal.new(100),
           entry_type: %EntryType{type: :debit, name: "Debit"}
         },
         %LineItem{
           account: %Account{
             code: nil,
             name: nil,
             account_type: %AccountType{
               name: nil,
               normal_balance: %EntryType{type: :credit, name: "Credit"},
               primary_account_category: %PrimaryAccountCategory{type: nil, primary: nil},
               contra: nil
             }
           },
           amount: Decimal.new(100),
           entry_type: %EntryType{type: :credit, name: "Credit"}
         }
       ]}
  """
  @spec bulk_create(map()) :: {:ok, map()} | {:error, :invalid_line_item}
  def bulk_create(line_items_map) when is_map(line_items_map) and map_size(line_items_map) > 0 do
    bulk_create_result =
      line_items_map
      |> Task.async_stream(fn
        {:left, debit_items} ->
          Task.async_stream(debit_items, fn item -> create(item.account, item.amount, "debit") end)

        {:right, credit_items} ->
          Task.async_stream(credit_items, fn item ->
            create(item.account, item.amount, "credit")
          end)
      end)
      |> Enum.reduce(
        %{
          debit_balance: Decimal.new(0),
          credit_balance: Decimal.new(0),
          balanced: false,
          created_line_items: []
        },
        fn {:ok, line_items}, acc ->
          Enum.reduce(line_items, acc, fn
            {:ok, {:ok, line_item}}, acc ->
              process_line_item(acc, line_item)

            {:ok, {:error, _line_item}}, acc ->
              acc
          end)
        end
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

        iex> LineItem.create(%Account{}, Decimal.new(100), "debit")
        {:ok,
         %LineItem{
           account: %Account{
             code: nil,
             name: nil,
             account_type: %AccountType{
               name: nil,
               normal_balance: %EntryType{type: :debit, name: "Debit"},
               primary_account_category: %PrimaryAccountCategory{type: nil, primary: nil},
               contra: nil
             }
           },
           amount: Decimal.new(100),
           entry_type: %EntryType{type: :debit, name: "Debit"}
         }}
  """
  @spec create(Account.t(), Decimal.t(), binary()) ::
          {:ok, __MODULE__.t()} | {:error, :invalid_line_item}
  def create(%Account{} = account, %Decimal{} = amount, binary_entry_type)
      when binary_entry_type in @entry_types,
      do: new(account, amount, binary_entry_type)

  def create(_, _, _), do: {:error, :invalid_line_item}

  defp new(account, amount, binary_entry_type) do
    {:ok, entry_type} = EntryType.create(binary_entry_type)

    {:ok, %__MODULE__{account: account, amount: amount, entry_type: entry_type}}
  end

  defp process_line_item(acc, line_item) do
    entry_type = line_item.entry_type.type

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
