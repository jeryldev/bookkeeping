defmodule Bookkeeping.Core.AccountTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{AccountType, EntryType}

  test "create Asset account type" do
    assert AccountType.asset() ==
             {:ok, %AccountType{name: "Asset", normal_balance: %EntryType{type: :debit}}}
  end

  test "create Liability account type" do
    assert AccountType.liability() ==
             {:ok, %AccountType{name: "Liability", normal_balance: %EntryType{type: :credit}}}
  end

  test "create Equity account type" do
    assert AccountType.equity() ==
             {:ok, %AccountType{name: "Equity", normal_balance: %EntryType{type: :credit}}}
  end

  test "create Expense account type" do
    assert AccountType.expense() ==
             {:ok, %AccountType{name: "Expense", normal_balance: %EntryType{type: :debit}}}
  end

  test "create Revenue account type" do
    assert AccountType.revenue() ==
             {:ok, %AccountType{name: "Revenue", normal_balance: %EntryType{type: :credit}}}
  end

  test "create Contra Asset account type" do
    assert AccountType.contra_asset() ==
             {:ok,
              %AccountType{
                name: "Contra Asset",
                normal_balance: %EntryType{type: :credit},
                contra: true
              }}
  end

  test "create Contra Liability account type" do
    assert AccountType.contra_liability() ==
             {:ok,
              %AccountType{
                name: "Contra Liability",
                normal_balance: %EntryType{type: :debit},
                contra: true
              }}
  end

  test "create Contra Equity account type" do
    assert AccountType.contra_equity() ==
             {:ok,
              %AccountType{
                name: "Contra Equity",
                normal_balance: %EntryType{type: :debit},
                contra: true
              }}
  end

  test "create Contra Expense account type" do
    assert AccountType.contra_expense() ==
             {:ok,
              %AccountType{
                name: "Contra Expense",
                normal_balance: %EntryType{type: :credit},
                contra: true
              }}
  end

  test "create Contra Revenue account type" do
    assert AccountType.contra_revenue() ==
             {:ok,
              %AccountType{
                name: "Contra Revenue",
                normal_balance: %EntryType{type: :debit},
                contra: true
              }}
  end

  test "allow account types that has an entry type of debit" do
    assert AccountType.new("Asset", %EntryType{type: :debit}) ==
             {:ok, %AccountType{name: "Asset", normal_balance: %EntryType{type: :debit}}}
  end

  test "allow account types that has an entry type of credit" do
    assert AccountType.new("Liability", %EntryType{type: :credit}) ==
             {:ok, %AccountType{name: "Liability", normal_balance: %EntryType{type: :credit}}}
  end

  test "disallow account types that has no name" do
    assert AccountType.new(nil, %EntryType{type: :debit}) ==
             {:error, :invalid_account_type}
  end

  test "disallow account types that has an entry type other than debit or credit" do
    assert AccountType.new("Invalid", %EntryType{type: :invalid_type}) ==
             {:error, :invalid_account_type}
  end
end
