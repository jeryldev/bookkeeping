defmodule Bookkeeping.Core.LineItemTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, LineItem}

  setup do
    details = %{email: "example@example.com"}
    {:ok, details: details}
  end

  test "bulk create line items", %{details: details} do
    assert {:ok, asset_account} =
             Account.create("10000", "cash", "asset", "description", details)

    assert {:ok, expense_account} =
             Account.create("20000", "rent", "expense", "description", details)

    assert {:ok, bulk_create_result} =
             LineItem.bulk_create(%{
               left: [
                 %{
                   account: expense_account,
                   amount: Decimal.new(100),
                   line_item_description: "rent expense"
                 }
               ],
               right: [
                 %{
                   account: asset_account,
                   amount: Decimal.new(100),
                   line_item_description: "cash paid for rent"
                 }
               ]
             })

    refute bulk_create_result == []

    assert {:error, %{message: :invalid_line_items, errors: [:invalid_account, :invalid_account]}} =
             LineItem.bulk_create(%{
               left: [%{account: "expense_account", amount: Decimal.new(100)}],
               right: [%{account: "asset_account", amount: Decimal.new(100)}]
             })

    assert {:error, :invalid_line_items} = LineItem.bulk_create(%{})

    assert {:error, [:invalid_account]} =
             LineItem.bulk_create(%{
               left: [%{account: expense_account, amount: Decimal.new(100)}],
               right: [%{account: "asset_account", amount: Decimal.new(100)}]
             })

    assert {:error, :invalid_line_items} =
             LineItem.bulk_create(%{
               left: [%{account: expense_account, amount: Decimal.new(100)}],
               right: []
             })

    assert {:error, :unbalanced_line_items} =
             LineItem.bulk_create(%{
               left: [%{account: expense_account, amount: Decimal.new(100)}],
               right: [%{account: asset_account, amount: Decimal.new(200)}]
             })

    assert {:error, [:invalid_account]} =
             LineItem.bulk_create(%{
               left: [%{account: expense_account, amount: Decimal.new(100)}],
               right: [%{account: asset_account, amount: Decimal.new(100)}, %{}]
             })

    assert {:ok, expense_account_2} =
             Account.create("20020", "depreciation", "expense", "description", details)

    assert {:ok, updated_expense_account_2} =
             Account.update(expense_account_2, %{name: "depreciation expense", active: false})

    assert {:error, [:inactive_account]} =
             LineItem.bulk_create(%{
               left: [%{account: updated_expense_account_2, amount: Decimal.new(100)}],
               right: [%{account: asset_account, amount: Decimal.new(100)}]
             })
  end

  test "create line item with valid account, amount, and binary_entry_type", %{details: details} do
    assert {:ok, asset_account} = Account.create("10000", "cash", "asset", "description", details)

    assert {:ok, line_item} =
             LineItem.create(%{account: asset_account, amount: Decimal.new(100)}, :debit)

    assert line_item.account == asset_account
    assert line_item.amount == Decimal.new(100)
    assert line_item.entry_type == :debit
    assert line_item.line_item_description == ""
  end

  test "disallow line item with invalid fields" do
    assert {:error, :invalid_account} =
             LineItem.create(%{account: "asset", amount: Decimal.new(100)}, "invalid")

    assert {:error, :invalid_account_and_amount_map} = LineItem.create(nil, "invalid")
  end

  test "disallow line item with invalid amount", %{details: details} do
    {:ok, asset_account} = Account.create("10000", "cash", "asset", "description", details)

    assert {:error, :invalid_amount} =
             LineItem.create(%{account: asset_account, amount: 100}, :debit)
  end
end
