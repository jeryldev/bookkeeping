defmodule Bookkeeping.Core.AccountType do
  @moduledoc """
  Bookkeeping.Core.AccountType is a struct that represents the type of an account.
  In accounting, we use accounting types to classify and record the different transactions that affect the financial position of a business.
  Account types help to organize the information in a systematic and logical way, and to show the relationship between the assets, liabilities, equity, revenue, expenses, and other elements of the accounting equation.
  Account types also help to prepare the financial statements, such as the balance sheet, income statement, and cash flow statement.
  """
  alias Bookkeeping.Core.EntryType

  defstruct name: :binary,
            normal_balance: %EntryType{},
            contra: false

  @doc """
  Creates a new Asset account type.
  Asset is an account type that represents something that a business owns or controls that has future economic value.
  Examples: cash, accounts receivable, inventory, equipment, land, prepaid expense, prepaid asset, etc.

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
  Liability is an account type that represents something that a business owes or is obligated to pay in the future.
  Examples: accounts payable, wages payable, taxes payable, loans payable, deferred revenue, annual subscription payments received, etc.

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
  Equity is an account type that represents the difference between the assets and liabilities of a business; also known as owner’s or shareholder’s equity.
  Examples: owner's equity, common stock, retained earnings, dividends, etc.

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
  Expense is an account type that represents the cost of using or consuming resources to generate revenue for a business.
  Examples: rent expense, salary expense, interest expense, depreciation expense, etc.

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
  Revenue is an account type that represents the amount of money that a business earns from selling goods or services to customers.
  Examples: sales revenue, service revenue, interest revenue, etc.

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
  Contra Asset is an account type that reduces the value of an asset account, such as accumulated depreciation or allowance for doubtful accounts.
  Examples: accumulated depreciation - equipment, allowance for doubtful accounts - accounts receivable, etc.

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
  Contra Liability is an account type that reduces the value of a liability account, such as discount on bonds payable or premium on bonds payable.
  Examples: discount on bonds payable - bonds payable, premium on bonds payable - bonds payable, etc.

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
  Contra Equity is an account type that reduces the value of an equity account, such as treasury stock or dividends.
  Examples: treasury stock - common stock, dividends - retained earnings, etc.

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
  Contra Expense is an account type that reduces the amount of an expense account, such as purchase returns or sales discounts.
  Examples: purchase returns - purchases expense, sales discounts - sales revenue, etc.

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
  Contra Revenue is an account type that reduces the amount of a revenue account, such as sales returns or sales allowances.
  Examples: sales returns - sales revenue, sales allowances - sales revenue, etc.

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
