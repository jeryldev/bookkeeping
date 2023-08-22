defmodule Bookkeeping.Core.EntryType do
  @moduledoc """
  Bookkeeping.Core.EntryType is a module that represents the type of an entry of an account.
  Entry types are used to determine the normal balance of an account.
  There are two types of entries: debit and credit.
  In accounting, debit and credit are terms used to describe the recording of financial transactions.
  They are used in double-entry bookkeeping to reflect the dual effect of a transaction.
  In a double-entry system, every transaction is recorded in at least two accounts:
  one account is debited and another account is credited.
  """
  @type t :: :debit | :credit

  @entry_types [:debit, :credit]

  @doc """
  Creates a new entry type atom.

  Returns `{:ok, :debit}` or `{:ok, :credit}` if the entry type is valid. Otherwise, returns `{:error, :invalid_entry_type}`.

  ## Examples

      iex> EntryType.create(:debit)
      {:ok, :debit}

      iex> EntryType.create(:credit)
      {:ok, :credit}

      iex> EntryType.create("invalid")
      {:error, :invalid_entry_type}
  """
  @spec create(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_entry_type}
  def create(atom_entry_type) when atom_entry_type in @entry_types, do: {:ok, atom_entry_type}
  def create(_), do: {:error, :invalid_entry_type}

  @doc """
  Returns a list of all entry types.

  ## Examples

      iex> EntryType.all_entry_types()
      [:debit, :credit]
  """
  def all_entry_types, do: @entry_types
end
