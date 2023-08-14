defmodule Bookkeeping.Core.EntryType do
  @moduledoc """
  Bookkeeping.Core.EntryType is a struct that represents the type of an entry of an account.
  """

  defstruct ~w[type]a
  @types [:debit, :credit]

  @doc """
  Creates a new debit entry type.

  Returns `{:ok, %Bookkeeping.Core.EntryType{type: debit}}`.

  ## Examples:

      iex> Bookkeeping.Core.EntryType.debit()
      {:ok, %Bookkeeping.Core.EntryType{type: :debit}}
  """
  def debit(), do: __MODULE__.new(:debit)

  @doc """
  Creates a new credit entry type.

  Returns `{:ok, %Bookkeeping.Core.EntryType{type: credit}}`.

  ## Examples:

      iex> Bookkeeping.Core.EntryType.credit()
      {:ok, %Bookkeeping.Core.EntryType{type: :credit}}
  """
  def credit(), do: __MODULE__.new(:credit)

  def new(type) when type in @types, do: {:ok, %__MODULE__{type: type}}
  def new(_type), do: {:error, :invalid_entry_type}
end
