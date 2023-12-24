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
      entry: :debit,
      particulars: "line particulars"
    }

    {:ok, account: account, params: params}
  end

  describe "create/1" do
    test "with valid params", %{params: params} do
      assert {:ok, line_item} = LineItem.create(params)

      assert line_item.account == params.account
      assert line_item.amount == params.amount
      assert line_item.entry == params.entry
      assert line_item.particulars == params.particulars
    end

    test "with invalid account", %{params: params} do
      params = Map.put(params, :account, %{})
      assert {:error, :invalid_account} = LineItem.create(params)
      params = Map.put(params, :account, nil)
      assert {:error, :invalid_account} = LineItem.create(params)
    end

    test "with invalid amount", %{params: params} do
      params = Map.put(params, :amount, 100)
      assert {:error, :invalid_amount} = LineItem.create(params)
      params = Map.put(params, :amount, nil)
      assert {:error, :invalid_amount} = LineItem.create(params)
    end

    test "with invalid entry type", %{params: params} do
      params = Map.put(params, :entry, "invalid")
      assert {:error, :invalid_entry} = LineItem.create(params)
      params = Map.put(params, :entry, nil)
      assert {:error, :invalid_entry} = LineItem.create(params)
    end

    test "with invalid particulars", %{params: params} do
      params = Map.put(params, :particulars, nil)
      assert {:error, :invalid_particulars} = LineItem.create(params)
      params = Map.put(params, :particulars, nil)
      assert {:error, :invalid_particulars} = LineItem.create(params)
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
      assert {:ok, _line_item} = LineItem.validate(line_item)
    end

    test "with invalid line_item", %{params: params} do
      assert {:error, :invalid_line_item} = LineItem.validate(%{})
      assert {:error, :invalid_line_item} = LineItem.validate(nil)
      assert {:error, :invalid_line_item} = LineItem.validate("")
      assert {:error, :invalid_line_item} = LineItem.validate(params)
      assert {:ok, line_item} = LineItem.create(params)
      modified_line_item = Map.put(line_item, :particulars, nil)
      assert {:error, :invalid_line_item} = LineItem.validate(modified_line_item)
    end
  end
end
