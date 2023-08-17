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

  defstruct ~w[type name]a
  @entry_types [:debit, :credit]

  @doc """
  Selects an entry type.

  Returns `{:ok, %Bookkeeping.Core.EntryType{type: type, name: name}}` if the entry type is valid. Otherwise, returns `{:error, :invalid_entry_type}`.

  ## Examples:

      iex> Bookkeeping.Core.EntryType.select_entry_type("debit")
      {:ok, %Bookkeeping.Core.EntryType{type: :debit, name: "Debit"}}
  """
  def select_entry_type("debit"), do: debit()
  def select_entry_type("credit"), do: credit()
  def select_entry_type(_), do: {:error, :invalid_entry_type}

  @doc """
  Creates a new debit entry type.
  A debit is an entry made on the left side of an account.
  It increases assets, expenses, contra liability, contra equity, and contra revenue accounts..
  It decreases liabilities, equity, revenue, contra asset and contra expense accounts.

  Returns `{:ok, %Bookkeeping.Core.EntryType{type: debit, name: "Debit"}}`.

  ## Examples:

      iex> Bookkeeping.Core.EntryType.debit()
      {:ok, %Bookkeeping.Core.EntryType{type: :debit, name: "Debit"}}
  """
  def debit, do: new(:debit, "Debit")

  @doc """
  Creates a new credit entry type.
  A credit is an entry made on the right side of an account.
  It increases liabilities, equity, revenue, contra asset and contra expense accounts.
  It decreases assets, expenses, contra liability, contra equity, and contra revenue accounts.

  Returns `{:ok, %Bookkeeping.Core.EntryType{type: credit, name: "Credit"}}`.

  ## Examples:

      iex> Bookkeeping.Core.EntryType.credit()
      {:ok, %Bookkeeping.Core.EntryType{type: :credit, name: "Credit"}}
  """
  def credit, do: new(:credit, "Credit")

  def new(type, name) when type in @entry_types and is_binary(name) and name != "",
    do: {:ok, %__MODULE__{type: type, name: name}}

  def new(_type, _name), do: {:error, :invalid_entry_type}
end
