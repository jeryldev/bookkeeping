defmodule Bookkeeping.Core.AccountType do
  @moduledoc """
  Bookkeeping.Core.AccountType is a struct that represents the type of an account.
  """
  alias Bookkeeping.Core.EntryType

  defstruct name: :binary,
            normal_balance: %EntryType{},
            contra: false

  @doc """
  Creates a new Asset account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Asset",
    normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
    contra: false
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.asset()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Asset",
        normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
        contra: false
      }}
  """
  def asset() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Asset", debit)
  end

  @doc """
  Creates a new Liability account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Liability",
    normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
    contra: false
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.liability()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Liability",
        normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
        contra: false
      }}
  """
  def liability() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Liability", credit)
  end

  @doc """
  Creates a new Equity account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Equity",
    normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
    contra: false
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.equity()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Equity",
        normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
        contra: false
      }}
  """
  def equity() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Equity", credit)
  end

  @doc """
  Creates a new Expense account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Expense",
    normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
    contra: false
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.expense()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Expense",
        normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
        contra: false
      }}
  """
  def expense() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Expense", debit)
  end

  @doc """
  Creates a new Revenue account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Revenue",
    normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
    contra: false
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.revenue()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Revenue",
        normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
        contra: false
      }}
  """
  def revenue() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Revenue", credit)
  end

  @doc """
  Creates a new Contra Asset account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Contra Asset",
    normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
    contra: true
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.contra_asset()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Contra Asset",
        normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
        contra: true
      }}
  """
  def contra_asset() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Contra Asset", credit, true)
  end

  @doc """
  Creates a new Contra Liability account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Contra Liability",
    normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
    contra: true
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.contra_liability()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Contra Liability",
        normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
        contra: true
      }}
  """
  def contra_liability() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Contra Liability", debit, true)
  end

  @doc """
  Creates a new Contra Equity account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Contra Equity",
    normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
    contra: true
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.contra_equity()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Contra Equity",
        normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
        contra: true
      }}
  """
  def contra_equity() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Contra Equity", debit, true)
  end

  @doc """
  Creates a new Contra Expense account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Contra Expense",
    normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
    contra: true
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.contra_expense()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Contra Expense",
        normal_balance: %Bookkeeping.Core.EntryType{type: :credit},
        contra: true
      }}
  """
  def contra_expense() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Contra Expense", credit, true)
  end

  @doc """
  Creates a new Contra Revenue account type.

  Returns `{:ok, %Bookkeeping.Core.AccountType{
    name: "Contra Revenue",
    normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
    contra: true
  }}`.

  ## Examples:

      iex> Bookkeeping.Core.AccountType.contra_revenue()
      {:ok, %Bookkeeping.Core.AccountType{
        name: "Contra Revenue",
        normal_balance: %Bookkeeping.Core.EntryType{type: :debit},
        contra: true
      }}
  """
  def contra_revenue() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Contra Revenue", debit, true)
  end

  def new(name, normal_balance, contra \\ false)

  def new(name, %EntryType{type: entry_type} = normal_balance, contra)
      when is_binary(name) and entry_type in [:debit, :credit] do
    {:ok,
     %__MODULE__{
       name: name,
       normal_balance: normal_balance,
       contra: contra
     }}
  end

  def new(_name, _normal_balance, _contra), do: {:error, :invalid_account_type}
end
