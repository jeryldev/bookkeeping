defmodule Bookkeeping.Core.AccountTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.AccountType

  test "create asset account type" do
    assert AccountType.create("asset") ==
             {:ok,
              %AccountType{
                name: "Asset",
                normal_balance: :debit,
                primary_account_category: :balance_sheet,
                contra: false
              }}
  end

  test "create liability account type" do
    assert AccountType.create("liability") ==
             {:ok,
              %AccountType{
                name: "Liability",
                normal_balance: :credit,
                primary_account_category: :balance_sheet,
                contra: false
              }}
  end

  test "create equity account type" do
    assert AccountType.create("equity") ==
             {:ok,
              %AccountType{
                name: "Equity",
                normal_balance: :credit,
                primary_account_category: :balance_sheet,
                contra: false
              }}
  end

  test "create revenue account type" do
    assert AccountType.create("revenue") ==
             {:ok,
              %AccountType{
                name: "Revenue",
                normal_balance: :credit,
                primary_account_category: :profit_and_loss,
                contra: false
              }}
  end

  test "create expense account type" do
    assert AccountType.create("expense") ==
             {:ok,
              %AccountType{
                name: "Expense",
                normal_balance: :debit,
                primary_account_category: :profit_and_loss,
                contra: false
              }}
  end

  test "create gain account type" do
    assert AccountType.create("gain") ==
             {:ok,
              %AccountType{
                name: "Gain",
                normal_balance: :credit,
                primary_account_category: :profit_and_loss,
                contra: false
              }}
  end

  test "create loss account type" do
    assert AccountType.create("loss") ==
             {:ok,
              %AccountType{
                name: "Loss",
                normal_balance: :debit,
                primary_account_category: :profit_and_loss,
                contra: false
              }}
  end

  test "create contra asset account type" do
    assert AccountType.create("contra_asset") ==
             {:ok,
              %AccountType{
                name: "Contra Asset",
                normal_balance: :credit,
                primary_account_category: :balance_sheet,
                contra: true
              }}
  end

  test "create contra liability account type" do
    assert AccountType.create("contra_liability") ==
             {:ok,
              %AccountType{
                name: "Contra Liability",
                normal_balance: :debit,
                primary_account_category: :balance_sheet,
                contra: true
              }}
  end

  test "create contra equity account type" do
    assert AccountType.create("contra_equity") ==
             {:ok,
              %AccountType{
                name: "Contra Equity",
                normal_balance: :debit,
                primary_account_category: :balance_sheet,
                contra: true
              }}
  end

  test "create contra revenue account type" do
    assert AccountType.create("contra_revenue") ==
             {:ok,
              %AccountType{
                name: "Contra Revenue",
                normal_balance: :debit,
                primary_account_category: :profit_and_loss,
                contra: true
              }}
  end

  test "create contra expense account type" do
    assert AccountType.create("contra_expense") ==
             {:ok,
              %AccountType{
                name: "Contra Expense",
                normal_balance: :credit,
                primary_account_category: :profit_and_loss,
                contra: true
              }}
  end

  test "create contra gain account type" do
    assert AccountType.create("contra_gain") ==
             {:ok,
              %AccountType{
                name: "Contra Gain",
                normal_balance: :debit,
                primary_account_category: :profit_and_loss,
                contra: true
              }}
  end

  test "create contra loss account type" do
    assert AccountType.create("contra_loss") ==
             {:ok,
              %AccountType{
                name: "Contra Loss",
                normal_balance: :credit,
                primary_account_category: :profit_and_loss,
                contra: true
              }}
  end

  test "disallow invalid account type" do
    assert AccountType.create("invalid") == {:error, :invalid_account_type}
  end
end
