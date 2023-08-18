defmodule Bookkeeping.Core.AccountTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{AccountType, EntryType, PrimaryAccountCategory}

  test "create asset account type" do
    assert AccountType.create("asset") ==
             {:ok,
              %AccountType{
                name: "Asset",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
                contra: false
              }}
  end

  test "create liability account type" do
    assert AccountType.create("liability") ==
             {:ok,
              %AccountType{
                name: "Liability",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
                contra: false
              }}
  end

  test "create equity account type" do
    assert AccountType.create("equity") ==
             {:ok,
              %AccountType{
                name: "Equity",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
                contra: false
              }}
  end

  test "create expense account type" do
    assert AccountType.create("expense") ==
             {:ok,
              %AccountType{
                name: "Expense",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
                contra: false
              }}
  end

  test "create revenue account type" do
    assert AccountType.create("revenue") ==
             {:ok,
              %AccountType{
                name: "Revenue",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
                contra: false
              }}
  end

  test "create loss account type" do
    assert AccountType.create("loss") ==
             {:ok,
              %AccountType{
                name: "Loss",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
                contra: false
              }}
  end

  test "create gain account type" do
    assert AccountType.create("gain") ==
             {:ok,
              %AccountType{
                name: "Gain",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_account_category: %PrimaryAccountCategory{type: :profit_and_loss},
                contra: false
              }}
  end

  test "create contra asset account type" do
    assert AccountType.create("contra_asset") ==
             {:ok,
              %AccountType{
                name: "Contra Asset",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
                contra: true
              }}
  end

  test "disallow invalid account type" do
    assert AccountType.create("invalid") == {:error, :invalid_account_type}
  end
end
