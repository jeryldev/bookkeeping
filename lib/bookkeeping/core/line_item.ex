defmodule Bookkeeping.Core.LineItem do
  @moduledoc """
  Bookkeeping.Core.LineItem is a struct that represents a line item in a journal entry.
  A line item is a record of a single account and the amount of money that is either debited or credited.
  """
  alias Bookkeeping.Core.Account
  defstruct account: %Account{}, amount: 0

  @doc """
  Creates a new line item.

  Returns `{:ok, line_item}` if the line item is valid, otherwise `{:error, :invalid_line_item}`.

  ## Examples

      iex> Bookkeeping.Core.LineItem.create(%Bookkeeping.Core.Account{}, 1000)
      {:ok, %Bookkeeping.Core.LineItem{account: %Bookkeeping.Core.Account{}, amount: 1000}}
  """
  def create(account, amount), do: new(account, amount)

  def new(%Account{} = account, %Decimal{} = amount),
    do: {:ok, %__MODULE__{account: account, amount: amount}}

  def new(_account, _amount), do: {:error, :invalid_line_item}
end
