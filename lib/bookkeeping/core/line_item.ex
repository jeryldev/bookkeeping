defmodule Bookkeeping.Core.LineItem do
  alias Bookkeeping.Core.Account
  defstruct account: %Account{}, amount: 0

  def new(%Account{} = account, %Decimal{} = amount),
    do: {:ok, %__MODULE__{account: account, amount: amount}}

  def new(_account, _amount), do: {:error, :invalid_line_item}
end
