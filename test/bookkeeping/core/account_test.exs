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

      #   assert {:ok, _liability} =
      #            Account.create(%{
      #              code: "20_000",
      #              name: "liability",
      #              classification: "liability",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _equity} =
      #            Account.create(%{
      #              code: "30_000",
      #              name: "equity",
      #              classification: "equity",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _revenue} =
      #            Account.create(%{
      #              code: "40_000",
      #              name: "revenue",
      #              classification: "revenue",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _expense} =
      #            Account.create(%{
      #              code: "50_000",
      #              name: "expense",
      #              classification: "expense",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _gain} =
      #            Account.create(%{
      #              code: "50_000",
      #              name: "gain",
      #              classification: "gain",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _loss} =
      #            Account.create(%{
      #              code: "50_000",
      #              name: "loss",
      #              classification: "loss",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _contra_asset} =
      #            Account.create(%{
      #              code: "60_000",
      #              name: "contra_asset",
      #              classification: "contra_asset",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _contra_liability} =
      #            Account.create(%{
      #              code: "70_000",
      #              name: "contra_liability",
      #              classification: "contra_liability",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _contra_equity} =
      #            Account.create(%{
      #              code: "80_000",
      #              name: "contra_equity",
      #              classification: "contra_equity",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _contra_revenue} =
      #            Account.create(%{
      #              code: "90_000",
      #              name: "contra_revenue",
      #              classification: "contra_revenue",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _contra_expense} =
      #            Account.create(%{
      #              code: "100_000",
      #              name: "contra_expense",
      #              classification: "contra_expense",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _contra_gain} =
      #            Account.create(%{
      #              code: "100_000",
      #              name: "contra_gain",
      #              classification: "contra_gain",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:ok, _contra_loss} =
      #            Account.create(%{
      #              code: "100_000",
      #              name: "contra_loss",
      #              classification: "contra_loss",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })
      # end

      # test "create/1 with invalid params", %{details: details} do
      #   assert {:error, :invalid_params} = Account.create(%{})
      #   assert {:error, :invalid_params} = Account.create(nil)
      #   assert {:error, :invalid_params} = Account.create("apple")

      #   assert {:error, :invalid_params} =
      #            Account.create(%{
      #              code: "10_000",
      #              name: "cash",
      #              classification: "asset",
      #              description: "description"
      #            })

      #   assert {:error, :invalid_params} =
      #            Account.create(%{
      #              code: "10_000",
      #              name: "cash",
      #              classification: "asset",
      #              description: "description",
      #              audit_details: details
      #            })
      # end

      # test "with invalid field", %{details: details} do
      #   assert {:error, :invalid_field} =
      #            Account.create(%{
      #              code: 10_000,
      #              name: "cash",
      #              classification: "asset",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:error, :invalid_field} =
      #            Account.create(%{
      #              code: "10_000",
      #              name: nil,
      #              classification: "asset",
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:error, :invalid_field} =
      #            Account.create(%{
      #              code: "10_000",
      #              name: "cash",
      #              classification: nil,
      #              description: "description",
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:error, :invalid_field} =
      #            Account.create(%{
      #              code: "10_000",
      #              name: "cash",
      #              classification: "asset",
      #              description: nil,
      #              audit_details: details,
      #              active: true
      #            })

      #   assert {:error, :invalid_field} =
      #            Account.create(%{
      #              code: "10_000",
      #              name: "cash",
      #              classification: "asset",
      #              description: "description",
      #              audit_details: nil,
      #              active: true
      #            })

      #   assert {:error, :invalid_field} =
      #            Account.create(%{
      #              code: "10_000",
      #              name: "cash",
      #              classification: "asset",
      #              description: "description",
      #              audit_details: details,
      #              active: nil
      #            })
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
