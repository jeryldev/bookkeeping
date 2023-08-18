defmodule Bookkeeping.Core.AccountTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, AccountType, EntryType, PrimaryAccountCategory}

  test "allow integer code, binary name and account type account field" do
    new_account = Account.create("10_000", "cash", "asset")

    assert ^new_account =
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
  end

  test "disallow non-binary code field" do
    new_account = Account.create(10_000, "cash", "asset")

    assert ^new_account = {:error, :invalid_account}
  end

  test "disallow non-binary name field" do
    new_account = Account.create(10_000, 10_000, "asset")

    assert ^new_account = {:error, :invalid_account}
  end

  test "disallow non-%AccountType{} account field" do
    new_account = Account.create(10_000, "cash", "account_type")

    assert ^new_account = {:error, :invalid_account}
  end

  test "disallow empty name" do
    new_account = Account.create(10_000, "", "asset")

    assert ^new_account = {:error, :invalid_account}
  end
end
