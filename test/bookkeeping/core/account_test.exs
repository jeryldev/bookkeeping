defmodule Bookkeeping.Core.AccountTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.Account

  setup do
    details = %{email: "example@example.com"}
    {:ok, details: details}
  end

  describe "Classification classify/1" do
    test "with valid params" do
      asset = Account.Classification.classify("asset")
      assert is_struct(asset)
      assert asset.name == "Asset"
      assert asset.normal_balance == :debit

      liability = Account.Classification.classify("liability")
      assert is_struct(liability)
      assert liability.name == "Liability"
      assert liability.normal_balance == :credit

      equity = Account.Classification.classify("equity")
      assert is_struct(equity)
      assert equity.name == "Equity"
      assert equity.normal_balance == :credit

      revenue = Account.Classification.classify("revenue")
      assert is_struct(revenue)
      assert revenue.name == "Revenue"
      assert revenue.normal_balance == :credit

      expense = Account.Classification.classify("expense")
      assert is_struct(expense)
      assert expense.name == "Expense"
      assert expense.normal_balance == :debit

      gain = Account.Classification.classify("gain")
      assert is_struct(gain)
      assert gain.name == "Gain"
      assert gain.normal_balance == :credit

      loss = Account.Classification.classify("loss")
      assert is_struct(loss)
      assert loss.name == "Loss"
      assert loss.normal_balance == :debit

      contra_asset = Account.Classification.classify("contra_asset")
      assert is_struct(contra_asset)
      assert contra_asset.name == "Contra Asset"
      assert contra_asset.normal_balance == :credit

      contra_liability = Account.Classification.classify("contra_liability")
      assert is_struct(contra_liability)
      assert contra_liability.name == "Contra Liability"
      assert contra_liability.normal_balance == :debit

      contra_equity = Account.Classification.classify("contra_equity")
      assert is_struct(contra_equity)
      assert contra_equity.name == "Contra Equity"
      assert contra_equity.normal_balance == :debit

      contra_revenue = Account.Classification.classify("contra_revenue")
      assert is_struct(contra_revenue)
      assert contra_revenue.name == "Contra Revenue"
      assert contra_revenue.normal_balance == :debit

      contra_expense = Account.Classification.classify("contra_expense")
      assert is_struct(contra_expense)
      assert contra_expense.name == "Contra Expense"
      assert contra_expense.normal_balance == :credit

      contra_gain = Account.Classification.classify("contra_gain")
      assert is_struct(contra_gain)
      assert contra_gain.name == "Contra Gain"
      assert contra_gain.normal_balance == :debit

      contra_loss = Account.Classification.classify("contra_loss")
      assert is_struct(contra_loss)
      assert contra_loss.name == "Contra Loss"
      assert contra_loss.normal_balance == :credit
    end

    test "with invalid params" do
      assert nil == Account.Classification.classify(nil)
      assert nil == Account.Classification.classify("apple")
    end
  end

  describe "create/1" do
    test "with valid params", %{details: details} do
      assert {:ok, account} =
               Account.create(%{
                 code: "10_000",
                 name: "cash",
                 classification: "asset",
                 description: "description",
                 audit_details: details,
                 active: true
               })

      assert account.code == "10_000"
      assert account.name == "cash"
      assert account.classification.name == "Asset"
      assert account.classification.normal_balance == :debit
      assert account.description == "description"
      assert is_boolean(account.active)
      assert is_list(account.audit_logs)
      assert is_struct(account.classification, Bookkeeping.Core.Account.Classification)
    end
  end

  describe "update/2" do
    test "with valid params", %{details: details} do
      assert {:ok, account} =
               Account.create(%{
                 code: "10_000",
                 name: "cash",
                 classification: "asset",
                 description: "description",
                 audit_details: details,
                 active: true
               })

      assert {:ok, account_2} =
               Account.update(account, %{
                 name: "cash and cash equivalents",
                 description: "description 2",
                 audit_details: %{email: "test@test.com"},
                 active: false
               })

      assert account.code == account_2.code
      refute account.name == account_2.name
      assert account.classification == account_2.classification
      refute account.description == account_2.description
      refute account.active == account_2.active
    end

    test "with invalid account" do
      params = %{
        code: "10_000",
        name: "cash",
        classification: "asset",
        description: "description",
        audit_details: %{},
        active: true
      }

      assert {:error, :invalid_account} = Account.update(%Account{}, params)
      assert {:error, :invalid_account} = Account.update(nil, params)
    end

    test "with invalid field" do
      {:ok, account} =
        Account.create(%{
          code: "10_000",
          name: "cash",
          classification: "asset",
          description: "description",
          audit_details: %{},
          active: true
        })

      assert {:error, :invalid_field} = Account.update(account, %{name: nil})
      assert {:error, :invalid_field} = Account.update(account, %{name: "cash", active: nil})
      assert {:error, :invalid_field} = Account.update(account, %{name: "cash", test: "test"})

      assert {:error, :invalid_field} =
               Account.update(account, %{name: "cash", classification: nil})
    end

    test "with invalid params" do
      {:ok, account} =
        Account.create(%{
          code: "10_000",
          name: "cash",
          classification: "asset",
          description: "description",
          audit_details: %{},
          active: true
        })

      assert {:error, :invalid_params} = Account.update(account, nil)
      assert {:error, :invalid_params} = Account.update(account, "apple")
      assert {:error, :invalid_params} = Account.update(account, %{})
    end
  end
end
