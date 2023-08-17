defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.AccountType

  defstruct code: nil,
            name: nil,
            account_type: %AccountType{}

  @doc """
  Creates a new account.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Bookkeeping.Core.Account.create(1000, "Cash", %Bookkeeping.Core.AccountType{})
      {:ok, %Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: 1000, name: "Cash"}}
  """
  def create(code, name, account_type), do: new(code, name, account_type)

  def new(code, name, %AccountType{} = account_type)
      when is_integer(code) and is_binary(name) do
    {:ok,
     %__MODULE__{
       code: code,
       name: name,
       account_type: account_type
     }}
  end

  def new(_code, _name, _account_type), do: {:error, :invalid_account}
end
