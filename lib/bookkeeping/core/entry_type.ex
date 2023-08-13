defmodule Bookkeeping.Core.EntryType do
  defstruct ~w[type]a
  @types [:debit, :credit]

  def debit(), do: __MODULE__.new(:debit)
  def credit(), do: __MODULE__.new(:credit)

  def new(type) when type in @types, do: {:ok, %__MODULE__{type: type}}
  def new(_type), do: {:error, :invalid_entry_type}
end
