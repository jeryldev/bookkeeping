defmodule Bookkeeping.Core.AccountClassification do
  @moduledoc """
  Bookkeeping.Core.AccountClassification is a struct that represents the type of an account.
  In accounting, we use accounting types to classify and record the different transactions that affect the financial position of a business.
  Account types help to organize the information in a systematic and logical way, and to show the relationship between the assets, liabilities, equity, revenue, expenses, and other elements of the accounting equation.
  Account types also help to prepare the financial statements, such as the balance sheet, income statement, and cash flow statement.
  """
  alias Bookkeeping.Core.Types

  @type t :: %__MODULE__{
          name: String.t(),
          normal_balance: Types.entry(),
          category: Types.category(),
          contra: boolean()
        }

  defstruct name: "",
            normal_balance: nil,
            category: nil,
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
    "gain",
    "loss",
    "contra_revenue",
    "contra_expense",
    "contra_gain",
    "contra_loss"
  ]

  @contra_accounts [
    "contra_asset",
    "contra_liability",
    "contra_equity",
    "contra_revenue",
    "contra_expense",
    "contra_gain",
    "contra_loss"
  ]

  @account_classifications [
    "asset",
    "liability",
    "equity",
    "revenue",
    "expense",
    "gain",
    "loss",
    "contra_asset",
    "contra_liability",
    "contra_equity",
    "contra_expense",
    "contra_revenue",
    "contra_gain",
    "contra_loss"
  ]

  @account_classification_names %{
    "asset" => "Asset",
    "liability" => "Liability",
    "equity" => "Equity",
    "revenue" => "Revenue",
    "expense" => "Expense",
    "gain" => "Gain",
    "loss" => "Loss",
    "contra_asset" => "Contra Asset",
    "contra_liability" => "Contra Liability",
    "contra_equity" => "Contra Equity",
    "contra_revenue" => "Contra Revenue",
    "contra_expense" => "Contra Expense",
    "contra_gain" => "Contra Gain",
    "contra_loss" => "Contra Loss"
  }

  @doc """
  Creates a new account classification struct.
  The account classification must be one of the following: `"asset"`, `"liability"`, `"equity"`, `"revenue"`, `"expense"`, `"gain"`, `"loss"`, `"contra_asset"`, `"contra_liability"`, `"contra_equity"`, `"contra_revenue"`, `"contra_expense"`, `"contra_gain"`, `"contra_loss"`.

  Returns `{:ok, %AccountClassification{}}` if the account classification is valid. Otherwise, returns `{:error, :invalid_account_classification}`.

  ## Examples

      iex> AccountClassification.create("asset")
      {:ok, %AccountClassification{...}}

      iex> AccountClassification.create("invalid")
      {:error, :invalid_account_classification}
  """
  @spec create(String.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_account_classification}
  def create(binary_account_classification)
      when binary_account_classification in @account_classifications do
    {:ok, entry_type} = set_entry_type(binary_account_classification)
    {:ok, category} = set_category(binary_account_classification)
    account_classification_name = @account_classification_names[binary_account_classification]
    contra_account? = binary_account_classification in @contra_accounts

    {:ok,
     %__MODULE__{
       name: account_classification_name,
       normal_balance: entry_type,
       category: category,
       contra: contra_account?
     }}
  end

  def create(_), do: {:error, :invalid_account_classification}

  @spec set_entry_type(String.t()) :: {:ok, Types.entry()}
  defp set_entry_type(binary_account_classification)
       when binary_account_classification in @debit_accounts,
       do: {:ok, :debit}

  defp set_entry_type(binary_account_classification)
       when binary_account_classification in @credit_accounts,
       do: {:ok, :credit}

  @spec set_category(String.t()) :: {:ok, Types.category()}
  defp set_category(binary_account_classification)
       when binary_account_classification in @balance_sheet_accounts,
       do: {:ok, :position}

  defp set_category(binary_account_classification)
       when binary_account_classification in @profit_and_loss_accounts,
       do: {:ok, :performance}
end
