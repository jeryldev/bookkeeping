defmodule Bookkeeping.Core.AccountTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, AccountType, EntryType, ReportingCategory}

  test "allow integer code, binary name and account type account field" do
    {:ok, account_type} = AccountType.asset()
    new_account = Account.new(10_000, "cash", account_type)

    assert ^new_account =
             {:ok,
              %Account{
                code: 10_000,
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
  end

  test "disallow non-integer code field" do
    {:ok, account_type} = AccountType.asset()
    new_account = Account.new("10_000", "cash", account_type)

    assert ^new_account = {:error, :invalid_account}
  end

  test "disallow non-binary name field" do
    {:ok, account_type} = AccountType.asset()
    new_account = Account.new(10_000, 10_000, account_type)

    assert ^new_account = {:error, :invalid_account}
  end

  test "disallow non-%AccountType{} account field" do
    new_account = Account.new(10_000, "cash", "account_type")

    assert ^new_account = {:error, :invalid_account}
  end
end
