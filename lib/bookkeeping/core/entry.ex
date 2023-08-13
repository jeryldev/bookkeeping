defmodule Bookkeeping.Core.Entry do
  defstruct ~w[type]a
  @types [:debit, :credit]

  def new(type) when type in @types, do: {:ok, %__MODULE__{type: type}}
  def new(_type), do: {:error, %__MODULE__{type: :invalid_type}}
end
