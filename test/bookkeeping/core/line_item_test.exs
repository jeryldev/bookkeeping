defmodule Bookkeeping.Core.LineItemTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, EntryType, LineItem}

  setup do
    details = %{email: "example@example.com"}
    {:ok, details: details}
  end

  test "create line item with valid account, amount, and binary_entry_type", %{details: details} do
    assert {:ok, asset_account} =
             Account.create("10000", "cash", "asset", "description",  details)

    assert {:ok, line_item} = LineItem.create(asset_account, Decimal.new(100), "debit")
    assert line_item.account == asset_account
    assert line_item.amount == Decimal.new(100)
    assert line_item.entry_type == %EntryType{type: :debit, name: "Debit"}
  end

  test "disallow line item with invalid fields" do
    assert {:error, :invalid_line_item} = LineItem.create("asset", Decimal.new(100), "invalid")
  end

  test "disallow line item with invalid amount", %{details: details} do
    {:ok, asset_account} = Account.create("10000", "cash", "asset", "description",  details)
    line_item = LineItem.create(asset_account, 100, "debit")

    assert line_item == {:error, :invalid_line_item}
  end
end
