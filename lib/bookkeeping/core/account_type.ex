defmodule Bookkeeping.Core.AccountType do
  @moduledoc """
  Bookkeeping.Core.AccountType is a struct that represents the type of an account.
  In accounting, we use accounting types to classify and record the different transactions that affect the financial position of a business.
  Account types help to organize the information in a systematic and logical way, and to show the relationship between the assets, liabilities, equity, revenue, expenses, and other elements of the accounting equation.
  Account types also help to prepare the financial statements, such as the balance sheet, income statement, and cash flow statement.
  """
  alias Bookkeeping.Core.{EntryType, PrimaryAccountCategory}

  defstruct name: nil,
            normal_balance: %EntryType{},
            primary_account_category: %PrimaryAccountCategory{},
            contra: false

  @debit_accounts [
    "asset",
    "expense",
    "loss",
    "contra_liability",
    "contra_equity",
    "contra_revenue",
    "contra_gain"
  ]

  @credit_accounts [
    "liability",
    "equity",
    "revenue",
    "gain",
    "contra_asset",
    "contra_expense",
    "contra_loss"
  ]

  @balance_sheet_accounts [
    "asset",
    "liability",
    "equity",
    "contra_asset",
    "contra_liability",
    "contra_equity"
  ]

  @profit_and_loss_accounts [
    "expense",
    "revenue",
    "loss",
    "gain",
    "contra_expense",
    "contra_revenue",
    "contra_loss",
    "contra_gain"
  ]

  @contra_accounts [
    "contra_asset",
    "contra_liability",
    "contra_equity",
    "contra_expense",
    "contra_revenue",
    "contra_loss",
    "contra_gain"
  ]

  @account_types [
    "asset",
    "liability",
    "equity",
    "expense",
    "revenue",
    "loss",
    "gain",
    "contra_asset",
    "contra_liability",
    "contra_equity",
    "contra_expense",
    "contra_revenue",
    "contra_loss",
    "contra_gain"
  ]

  @account_type_names %{
    "asset" => "Asset",
    "liability" => "Liability",
    "equity" => "Equity",
    "expense" => "Expense",
    "revenue" => "Revenue",
    "loss" => "Loss",
    "gain" => "Gain",
    "contra_asset" => "Contra Asset",
    "contra_liability" => "Contra Liability",
    "contra_equity" => "Contra Equity",
    "contra_expense" => "Contra Expense",
    "contra_revenue" => "Contra Revenue",
    "contra_loss" => "Contra Loss",
    "contra_gain" => "Contra Gain"
  }

  @doc """
  Creates a new account type struct.

  Returns `{:ok, %AccountType{}}` if the account type is valid. Otherwise, returns `{:error, :invalid_account_type}`.

  ## Examples

      iex> AccountType.create("asset")
      {:ok,
        %AccountType{
          name: "Asset",
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
          contra: false
        }}
      iex> AccountType.create("liability")
      {:ok,
        %AccountType{
          name: "Liability",
          normal_balance: %EntryType{type: :credit, name: "Credit"},
          primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
          contra: false
        }}
      iex> AccountType.create("equity")
      {:ok,
        %AccountType{
          name: "Equity",
          normal_balance: %EntryType{type: :credit, name: "Credit"},
          primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
          contra: false
        }}
      iex> AccountType.create("expense")
      {:ok,
        %AccountType{
          name: "Expense",
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
          contra: false
        }}
      iex> AccountType.create("revenue")
      {:ok,
        %AccountType{
          name: "Revenue",
          normal_balance: %EntryType{type: :credit, name: "Credit"},
          primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
          contra: false
        }}
      iex> AccountType.create("loss")
      {:ok,
        %AccountType{
          name: "Loss",
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
          contra: false
        }}
      iex> AccountType.create("gain")
      {:ok,
        %AccountType{
          name: "Gain",
          normal_balance: %EntryType{type: :credit, name: "Credit"},
          primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
          contra: false
        }}
      iex> AccountType.create("contra_asset")
      {:ok,
        %AccountType{
          name: "Contra Asset",
          normal_balance: %EntryType{type: :credit, name: "Credit"},
          primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
          contra: true
        }}
      iex> AccountType.create("contra_liability")
      {:ok,
        %AccountType{
          name: "Contra Liability",
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
          contra: true
        }}
      iex> AccountType.create("contra_equity")
      {:ok,
        %AccountType{
          name: "Contra Equity",
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
          contra: true
        }}
      iex> AccountType.create("contra_expense")
      {:ok,
        %AccountType{
          name: "Contra Expense",
          normal_balance: %EntryType{type: :credit, name: "Credit"},
          primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
          contra: true
        }}
      iex> AccountType.create("contra_revenue")
      {:ok,
        %AccountType{
          name: "Contra Revenue",
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
          contra: true
        }}
      iex> AccountType.create("contra_loss")
      {:ok,
        %AccountType{
          name: "Contra Loss",
          normal_balance: %EntryType{type: :credit, name: "Credit"},
          primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
          contra: true
        }}
      iex> AccountType.create("contra_gain")
      {:ok,
        %AccountType{
          name: "Contra Gain",
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
          contra: true
        }}
      iex> AccountType.create("invalid")
      {:error, :invalid_account_type}
  """
  def create(binary_account_type) when binary_account_type in @account_types do
    {:ok, entry_type} = set_entry_type(binary_account_type)
    {:ok, primary_account_category} = set_primary_account_category(binary_account_type)
    account_type_name = @account_type_names[binary_account_type]
    contra_account? = binary_account_type in @contra_accounts
    new(account_type_name, entry_type, primary_account_category, contra_account?)
  end

  def create(_), do: {:error, :invalid_account_type}

  defp set_entry_type(binary_account_type)
       when binary_account_type in @credit_accounts,
       do: EntryType.create("credit")

  defp set_primary_account_category(binary_account_type)
       when binary_account_type in @balance_sheet_accounts,
       do: PrimaryAccountCategory.create("balance_sheet")

  defp set_primary_account_category(binary_account_type)
       when binary_account_type in @profit_and_loss_accounts,
       do: PrimaryAccountCategory.create("profit_and_loss")

  defp new(
         name,
         %EntryType{type: entry_type} = normal_balance,
         %PrimaryAccountCategory{} = primary_account_category,
         contra
       )
       when is_binary(name) and name != "" and
              entry_type in [:debit, :credit] and
              is_boolean(contra) do
    {:ok,
     %__MODULE__{
       name: name,
       normal_balance: normal_balance,
       primary_account_category: primary_account_category,
       contra: contra
     }}
  end
end
