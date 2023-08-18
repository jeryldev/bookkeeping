defmodule Bookkeeping.Core.LineItemTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, LineItem}

  test "create line item with valid account, amount, and binary_entry_type" do
    {:ok, asset_account} = Account.create("10000", "cash", "asset")
    line_item = LineItem.create(asset_account, Decimal.new(100), "debit")

    assert line_item ==
             {:ok,
              %Bookkeeping.Core.LineItem{
                account: %Bookkeeping.Core.Account{
                  code: "10000",
                  name: "cash",
                  account_type: %Bookkeeping.Core.AccountType{
                    name: "Asset",
                    normal_balance: %Bookkeeping.Core.EntryType{type: :debit, name: "Debit"},
                    primary_account_category: %Bookkeeping.Core.PrimaryAccountCategory{
                      type: :balance_sheet
                    },
                    contra: false
                  }
                },
                amount: Decimal.new("100"),
                entry_type: %Bookkeeping.Core.EntryType{name: "Debit", type: :debit}
              }}
  end

  test "disallow line item with invalid fields" do
    assert LineItem.create("asset", Decimal.new(100), "invalid") == {:error, :invalid_line_item}
  end

  test "disallow line item with invalid amount" do
    {:ok, asset_account} = Account.create("10000", "cash", "asset")
    line_item = LineItem.create(asset_account, 100, "debit")

    assert line_item == {:error, :invalid_line_item}
  end
end
