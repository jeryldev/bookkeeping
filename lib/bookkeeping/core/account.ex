defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.AccountType

  @account_types [
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
    "contra_revenue",
    "contra_expense",
    "contra_gain",
    "contra_loss"
  ]

  defstruct code: nil,
            name: nil,
            account_type: nil

  @doc """
    Creates a new account struct.

    Returns `{:ok, %Account{}}` if the account is valid. Otherwise, returns `{:error, :invalid_account}`.

    ## Examples

        iex> Account.create("10_000", "cash", "asset")
        {:ok,
         %Account{
           code: "10_000",
           name: "cash",
           account_type: %AccountType{
             name: "Asset",
             normal_balance: %EntryType{type: :debit, name: "Debit"},
             primary_reporting_category: %ReportingCategory{
               type: :balance_sheet,
               primary: true
             },
             contra: false
           }
         }}
  """
  def create(code, name, binary_account_type), do: new(code, name, binary_account_type)

  def new(code, name, binary_account_type)
      when is_binary(code) and is_binary(name) and is_binary(binary_account_type) and
             code != "" and name != "" and binary_account_type in @account_types do
    {:ok, account_type} = AccountType.select_account_type(binary_account_type)

    {:ok,
     %__MODULE__{
       code: code,
       name: name,
       account_type: account_type
     }}
  end

  def new(_code, _name, _account_type), do: {:error, :invalid_account}
end
