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

  test "update account" do
    assert {:ok, account} = Account.create("10_000", "cash", "asset")
    assert {:ok, account_2} = Account.update(account, %{name: "cash and cash equivalents"})
    assert account.code == account_2.code
    refute account.name == account_2.name
    assert account.account_type == account_2.account_type
    assert {:error, :invalid_account} = Account.update(account, %{name: ""})

    assert {:ok, account_3} =
             Account.update(account, %{
               code: "10_001",
               name: "trade payables",
               binary_account_type: "liability"
             })

    assert account_3 == %Bookkeeping.Core.Account{
             code: "10_001",
             name: "trade payables",
             account_type: %Bookkeeping.Core.AccountType{
               name: "Liability",
               normal_balance: %Bookkeeping.Core.EntryType{type: :credit, name: "Credit"},
               primary_account_category: %Bookkeeping.Core.PrimaryAccountCategory{
                 type: :balance_sheet
               },
               contra: false
             }
           }

    assert {:ok, account_4} =
             Account.update(account, %{
               code: "10_001",
               name: "cash and cash equivalents"
             })
  end
end
