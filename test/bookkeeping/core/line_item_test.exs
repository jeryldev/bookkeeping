defmodule Bookkeeping.Core.LineItemTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, LineItem}

  setup do
    account_params = %{
      code: "1000",
      name: "Cash",
      description: "Cash and cash equivalents",
      classification: "asset",
      audit_details: %{email: "example@example.com"},
      active: true
    }

    {:ok, account} = Account.create(account_params)

    params = %{
      account: account,
      amount: Decimal.new(100),
      entry_type: :debit,
      description: "line description"
    }

    {:ok, account: account, params: params}
  end

  describe "create/1" do
    test "with valid params", %{params: params} do
      assert {:ok, line_item} = LineItem.create(params)

      assert line_item.account == params.account
      assert line_item.amount == params.amount
      assert line_item.entry_type == params.entry_type
      assert line_item.description == params.description
    end

    test "with invalid account", %{params: params} do
      params = Map.put(params, :account, %{})
      assert {:error, :invalid_account} = LineItem.create(params)
    end

    test "with invalid amount", %{params: params} do
      params = Map.put(params, :amount, 100)
      assert {:error, :invalid_amount} = LineItem.create(params)
    end

    test "with invalid entry type", %{params: params} do
      params = Map.put(params, :entry_type, "invalid")
      assert {:error, :invalid_entry_type} = LineItem.create(params)
    end

    test "with invalid description", %{params: params} do
      params = Map.put(params, :description, nil)
      assert {:error, :invalid_description} = LineItem.create(params)
    end

    test "with invalid params" do
      assert {:error, :invalid_params} = LineItem.create(%{})
      assert {:error, :invalid_params} = LineItem.create(nil)
      assert {:error, :invalid_params} = LineItem.create("")
    end
  end

  describe "validate/1" do
    test "with valid line_item", %{params: params} do
      assert {:ok, line_item} = LineItem.create(params)
      assert {:ok, line_item} = LineItem.validate(line_item)
    end

    test "with invalid line_item", %{params: params} do
      assert {:error, :invalid_line_item} = LineItem.validate(%{})
      assert {:error, :invalid_line_item} = LineItem.validate(nil)
      assert {:error, :invalid_line_item} = LineItem.validate("")
      assert {:error, :invalid_line_item} = LineItem.validate(params)
      assert {:ok, line_item} = LineItem.create(params)
      modified_line_item = Map.put(line_item, :description, nil)
      assert {:error, :invalid_line_item} = LineItem.validate(modified_line_item)
    end
  end

  defp update_params(params) do
    code = random_string()
    name = random_string()
    Map.merge(params, %{code: code, name: name})
  end

  defp random_string do
    for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>
  end

  # test "bulk create line items", %{details: details} do
  #   assert {:ok, asset_account} =
  #            Account.create("10000", "cash", "asset", "description", details)

  #   assert {:ok, expense_account} =
  #            Account.create("20000", "rent", "expense", "description", details)

  #   assert {:ok, bulk_create_result} =
  #            LineItem.bulk_create(%{
  #              left: [
  #                %{
  #                  account: expense_account,
  #                  amount: Decimal.new(100),
  #                  description: "rent expense"
  #                }
  #              ],
  #              right: [
  #                %{
  #                  account: asset_account,
  #                  amount: Decimal.new(100),
  #                  description: "cash paid for rent"
  #                }
  #              ]
  #            })

  #   refute bulk_create_result == []

  #   assert {:error, %{message: :invalid_line_items, errors: [:invalid_account, :invalid_account]}} =
  #            LineItem.bulk_create(%{
  #              left: [%{account: "expense_account", amount: Decimal.new(100)}],
  #              right: [%{account: "asset_account", amount: Decimal.new(100)}]
  #            })

  #   assert {:error, :invalid_line_items} = LineItem.bulk_create(%{})

  #   assert {:error, [:invalid_account]} =
  #            LineItem.bulk_create(%{
  #              left: [%{account: expense_account, amount: Decimal.new(100)}],
  #              right: [%{account: "asset_account", amount: Decimal.new(100)}]
  #            })

  #   assert {:error, :invalid_line_items} =
  #            LineItem.bulk_create(%{
  #              left: [%{account: expense_account, amount: Decimal.new(100)}],
  #              right: []
  #            })

  #   assert {:error, :unbalanced_line_items} =
  #            LineItem.bulk_create(%{
  #              left: [%{account: expense_account, amount: Decimal.new(100)}],
  #              right: [%{account: asset_account, amount: Decimal.new(200)}]
  #            })

  #   assert {:error, [:invalid_account]} =
  #            LineItem.bulk_create(%{
  #              left: [%{account: expense_account, amount: Decimal.new(100)}],
  #              right: [%{account: asset_account, amount: Decimal.new(100)}, %{}]
  #            })

  #   assert {:ok, expense_account_2} =
  #            Account.create("20020", "depreciation", "expense", "description", details)

  #   assert {:ok, updated_expense_account_2} =
  #            Account.update(expense_account_2, %{name: "depreciation expense", active: false})

  #   assert {:error, [:inactive_account]} =
  #            LineItem.bulk_create(%{
  #              left: [%{account: updated_expense_account_2, amount: Decimal.new(100)}],
  #              right: [%{account: asset_account, amount: Decimal.new(100)}]
  #            })
  # end

  # test "create line item with valid account, amount, and binary_entry_type", %{details: details} do
  #   assert {:ok, asset_account} = Account.create("10000", "cash", "asset", "description", details)

  #   assert {:ok, line_item} =
  #            LineItem.create(%{account: asset_account, amount: Decimal.new(100)}, :debit)

  #   assert line_item.account == asset_account
  #   assert line_item.amount == Decimal.new(100)
  #   assert line_item.entry_type == :debit
  #   assert line_item.description == ""
  # end

  # test "disallow line item with invalid fields" do
  #   assert {:error, :invalid_account} =
  #            LineItem.create(%{account: "asset", amount: Decimal.new(100)}, "invalid")

  #   assert {:error, :invalid_account_and_amount_map} = LineItem.create(nil, "invalid")
  # end

  # test "disallow line item with invalid amount", %{details: details} do
  #   {:ok, asset_account} = Account.create("10000", "cash", "asset", "description", details)

  #   assert {:error, :invalid_amount} =
  #            LineItem.create(%{account: asset_account, amount: 100}, :debit)
  # end
end
