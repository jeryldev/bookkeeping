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

  defstruct ~w[type]a
  @types [:debit, :credit]

  @doc """
  Creates a new debit entry type.
  A debit is an entry made on the left side of an account.
  It increases assets, expenses, contra liability, contra equity, and contra revenue accounts..
  It decreases liabilities, equity, revenue, contra asset and contra expense accounts.

  Returns `{:ok, %Bookkeeping.Core.EntryType{type: debit}}`.

  ## Examples:

      iex> Bookkeeping.Core.EntryType.debit()
      {:ok, %Bookkeeping.Core.EntryType{type: :debit}}
  """
  def debit(), do: __MODULE__.new(:debit)

  @doc """
  Creates a new credit entry type.
  A credit is an entry made on the right side of an account.
  It increases liabilities, equity, revenue, contra asset and contra expense accounts.
  It decreases assets, expenses, contra liability, contra equity, and contra revenue accounts.

  Returns `{:ok, %Bookkeeping.Core.EntryType{type: credit}}`.

  ## Examples:

      iex> Bookkeeping.Core.EntryType.credit()
      {:ok, %Bookkeeping.Core.EntryType{type: :credit}}
  """
  def credit(), do: __MODULE__.new(:credit)

  def new(type) when type in @types, do: {:ok, %__MODULE__{type: type}}
  def new(_type), do: {:error, :invalid_entry_type}
end
