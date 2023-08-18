defmodule Bookkeeping.Core.EntryType do
  @moduledoc """
  Bookkeeping.Core.EntryType is a struct that represents the type of an entry of an account.
  Entry types are used to determine the normal balance of an account.
  There are two types of entries: debit and credit.
  In accounting, debit and credit are terms used to describe the recording of financial transactions.
  They are used in double-entry bookkeeping to reflect the dual effect of a transaction.
  In a double-entry system, every transaction is recorded in at least two accounts:
  one account is debited and another account is credited.
  """

  defstruct type: nil,
            name: nil

  @entry_types [:debit, :credit]

  @doc """
  Creates a new entry type struct.

  Returns `{:ok, %EntryType{}}` if the entry type is valid. Otherwise, returns `{:error, :invalid_entry_type}`.

  ## Examples

      iex> EntryType.create("debit")
      {:ok, %EntryType{type: :debit, name: "Debit"}}
      iex> EntryType.create("credit")
      {:ok, %EntryType{type: :credit, name: "Credit"}}
      iex> EntryType.create("invalid")
      {:error, :invalid_entry_type}
  """
  def create("debit"), do: new(:debit, "Debit")
  def create("credit"), do: new(:credit, "Credit")
  def create(_), do: {:error, :invalid_entry_type}

  defp new(type, name) when type in @entry_types and is_binary(name) and name != "",
    do: {:ok, %__MODULE__{type: type, name: name}}
end
