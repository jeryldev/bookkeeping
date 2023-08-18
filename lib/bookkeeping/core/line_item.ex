defmodule Bookkeeping.Core.LineItem do
  @moduledoc """
  Bookkeeping.Core.LineItem is a struct that represents a line item in a journal entry.
  A line item is a record of a single account and the amount of money that is either debited or credited.
  """
  alias Bookkeeping.Core.{Account, EntryType}

  defstruct account: %Account{},
            amount: 0,
            entry_type: nil

  @entry_types ["debit", "credit"]

  @doc """
    Creates a new line item struct.

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
  def create(%Account{} = account, %Decimal{} = amount, binary_entry_type)
      when binary_entry_type in @entry_types,
      do: new(account, amount, binary_entry_type)

  def create(_, _, _), do: {:error, :invalid_line_item}

  defp new(account, amount, binary_entry_type) do
    {:ok, entry_type} = EntryType.create(binary_entry_type)

    {:ok, %__MODULE__{account: account, amount: amount, entry_type: entry_type}}
  end
end
