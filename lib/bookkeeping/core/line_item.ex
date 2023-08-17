defmodule Bookkeeping.Core.LineItem do
  @moduledoc """
  Bookkeeping.Core.LineItem is a struct that represents a line item in a journal entry.
  A line item is a record of a single account and the amount of money that is either debited or credited.
  """
  alias Bookkeeping.Core.{Account, EntryType}

  defstruct account: %Account{}, amount: 0, entry_type: %EntryType{}

  @doc """
  Creates a new line item.

  Returns `{:ok, %Bookkeeping.Core.LineItem{account: account, amount: amount, entry_type: entry_type}}`.

  ## Examples:

      iex> Bookkeeping.Core.LineItem.create(%Bookkeeping.Core.Account{name: "Cash"}, Decimal.new(100), Bookkeeping.Core.EntryType.debit())
      {:ok, %Bookkeeping.Core.LineItem{account: %Bookkeeping.Core.Account{name: "Cash"}, amount: #Decimal<100>, entry_type: %Bookkeeping.Core.EntryType{name: "Debit", type: :debit}}}
  """
  def create(account, amount, entry_type), do: new(account, amount, entry_type)

  def new(%Account{} = account, %Decimal{} = amount, %EntryType{type: type} = entry_type)
      when type in [:debit, :credit],
      do: {:ok, %__MODULE__{account: account, amount: amount, entry_type: entry_type}}

  def new(_account, _amount, _entry_type), do: {:error, :invalid_line_item}
end
