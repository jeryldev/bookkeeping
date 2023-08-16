defmodule Bookkeeping.Core.LineItemTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, AccountType, LineItem}

  test "create line item with valid account and amount" do
    {:ok, asset_type} = AccountType.asset()
    {:ok, asset_account} = Account.new(10000, "cash", asset_type)
    line_item = LineItem.new(asset_account, Decimal.new(100))

    assert line_item ==
             {:ok,
              %Bookkeeping.Core.LineItem{
                account: %Bookkeeping.Core.Account{
                  code: 10000,
                  name: "cash",
                  account_type: %Bookkeeping.Core.AccountType{
                    name: "Asset",
                    normal_balance: %Bookkeeping.Core.EntryType{type: :debit, name: "Debit"},
                    primary_reporting_category: %Bookkeeping.Core.ReportingCategory{
                      type: :balance_sheet,
                      primary: true
                    },
                    contra: false
                  }
                },
                amount: Decimal.new("100")
              }}
  end

  test "disallow line item with invalid account" do
    assert LineItem.new("asset", Decimal.new(100)) == {:error, :invalid_line_item}
  end

  test "disallow line item with invalid amount" do
    {:ok, asset_type} = AccountType.asset()
    {:ok, asset_account} = Account.new(10000, "cash", asset_type)
    line_item = LineItem.new(asset_account, 100)

    assert line_item == {:error, :invalid_line_item}
  end
end
