defmodule Bookkeeping.Core.AccountClassificationTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.AccountClassification

  test "create asset account classification" do
    assert AccountClassification.create("asset") ==
             {:ok,
              %AccountClassification{
                name: "Asset",
                normal_balance: :debit,
                statement_category: :balance_sheet,
                contra: false
              }}
  end

  test "create liability account classification" do
    assert AccountClassification.create("liability") ==
             {:ok,
              %AccountClassification{
                name: "Liability",
                normal_balance: :credit,
                statement_category: :balance_sheet,
                contra: false
              }}
  end

  test "create equity account classification" do
    assert AccountClassification.create("equity") ==
             {:ok,
              %AccountClassification{
                name: "Equity",
                normal_balance: :credit,
                statement_category: :balance_sheet,
                contra: false
              }}
  end

  test "create revenue account classification" do
    assert AccountClassification.create("revenue") ==
             {:ok,
              %AccountClassification{
                name: "Revenue",
                normal_balance: :credit,
                statement_category: :profit_and_loss,
                contra: false
              }}
  end

  test "create expense account classification" do
    assert AccountClassification.create("expense") ==
             {:ok,
              %AccountClassification{
                name: "Expense",
                normal_balance: :debit,
                statement_category: :profit_and_loss,
                contra: false
              }}
  end

  test "create gain account classification" do
    assert AccountClassification.create("gain") ==
             {:ok,
              %AccountClassification{
                name: "Gain",
                normal_balance: :credit,
                statement_category: :profit_and_loss,
                contra: false
              }}
  end

  test "create loss account classification" do
    assert AccountClassification.create("loss") ==
             {:ok,
              %AccountClassification{
                name: "Loss",
                normal_balance: :debit,
                statement_category: :profit_and_loss,
                contra: false
              }}
  end

  test "create contra asset account classification" do
    assert AccountClassification.create("contra_asset") ==
             {:ok,
              %AccountClassification{
                name: "Contra Asset",
                normal_balance: :credit,
                statement_category: :balance_sheet,
                contra: true
              }}
  end

  test "create contra liability account classification" do
    assert AccountClassification.create("contra_liability") ==
             {:ok,
              %AccountClassification{
                name: "Contra Liability",
                normal_balance: :debit,
                statement_category: :balance_sheet,
                contra: true
              }}
  end

  test "create contra equity account classification" do
    assert AccountClassification.create("contra_equity") ==
             {:ok,
              %AccountClassification{
                name: "Contra Equity",
                normal_balance: :debit,
                statement_category: :balance_sheet,
                contra: true
              }}
  end

  test "create contra revenue account classification" do
    assert AccountClassification.create("contra_revenue") ==
             {:ok,
              %AccountClassification{
                name: "Contra Revenue",
                normal_balance: :debit,
                statement_category: :profit_and_loss,
                contra: true
              }}
  end

  test "create contra expense account classification" do
    assert AccountClassification.create("contra_expense") ==
             {:ok,
              %AccountClassification{
                name: "Contra Expense",
                normal_balance: :credit,
                statement_category: :profit_and_loss,
                contra: true
              }}
  end

  test "create contra gain account classification" do
    assert AccountClassification.create("contra_gain") ==
             {:ok,
              %AccountClassification{
                name: "Contra Gain",
                normal_balance: :debit,
                statement_category: :profit_and_loss,
                contra: true
              }}
  end

  test "create contra loss account classification" do
    assert AccountClassification.create("contra_loss") ==
             {:ok,
              %AccountClassification{
                name: "Contra Loss",
                normal_balance: :credit,
                statement_category: :profit_and_loss,
                contra: true
              }}
  end

  test "disallow invalid account classification" do
    assert AccountClassification.create("invalid") == {:error, :invalid_account_classification}
  end
end
