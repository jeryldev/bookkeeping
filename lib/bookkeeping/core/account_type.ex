defmodule Bookkeeping.Core.AccountType do
  alias Bookkeeping.Core.EntryType

  defstruct name: :binary,
            normal_balance: %EntryType{},
            contra: false

  def asset() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Asset", debit)
  end

  def liability() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Liability", credit)
  end

  def equity() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Equity", credit)
  end

  def expense() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Expense", debit)
  end

  def revenue() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Revenue", credit)
  end

  def contra_asset() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Contra Asset", credit, true)
  end

  def contra_liability() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Contra Liability", debit, true)
  end

  def contra_equity() do
    {:ok, debit} = EntryType.debit()
    __MODULE__.new("Contra Equity", debit, true)
  end

  def contra_expense() do
    {:ok, credit} = EntryType.credit()
    __MODULE__.new("Contra Expense", credit, true)
  end

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
