defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.AccountType

  @type t :: %__MODULE__{
          code: String.t(),
          name: String.t(),
          account_type: %AccountType{}
        }

  defstruct code: "",
            name: "",
            account_type: nil

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
             primary_account_category: %PrimaryAccountCategory{
               type: :balance_sheet
             },
             contra: false
           }
         }}
  """
  @spec create(String.t(), String.t(), String.t()) ::
          {:ok, %__MODULE__{}} | {:error, :invalid_account}
  def create(code, name, binary_account_type)
      when is_binary(code) and is_binary(name) and is_binary(binary_account_type) and
             code != "" and name != "" and binary_account_type in @account_types,
      do: new(code, name, binary_account_type)

  def create(_, _, _), do: {:error, :invalid_account}

  @doc """
  Updates an account.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Account.update(account, %{name: "cash and cash equivalents"})
      {:ok,
       %Account{
         code: "10_000",
         name: "cash and cash equivalents",
         account_type: %AccountType{
           name: "Asset",
           normal_balance: %EntryType{type: :debit, name: "Debit"},
           primary_account_category: %PrimaryAccountCategory{
             type: :balance_sheet
           },
           contra: false
         }
       }}
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, :invalid_account}
  def update(account, attrs) when is_map(attrs) do
    code = Map.get(attrs, :code, account.code)
    name = Map.get(attrs, :name, account.name)
    binary_account_type = Map.get(attrs, :binary_account_type)

    if is_binary(code) and is_binary(name) and code != "" and name != "" do
      if is_binary(binary_account_type) and binary_account_type in @account_types,
        do: create(code, name, binary_account_type),
        else: {:ok, %{account | code: code, name: name}}
    else
      {:error, :invalid_account}
    end
  end

  @spec new(String.t(), String.t(), String.t()) :: {:ok, %__MODULE__{}}
  defp new(code, name, binary_account_type) do
    {:ok, account_type} = AccountType.create(binary_account_type)

    {:ok,
     %__MODULE__{
       code: code,
       name: name,
       account_type: account_type
     }}
  end
end
