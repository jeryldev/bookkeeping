defmodule Bookkeeping.Core.AccountTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.Account

  setup do
    details = %{email: "example@example.com"}
    {:ok, details: details}
  end

  test "create/1 with valid params", %{details: details} do
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
    assert account.active

    assert {:ok, _liability} =
             Account.create(%{
               code: "20_000",
               name: "liability",
               classification: "liability",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _equity} =
             Account.create(%{
               code: "30_000",
               name: "equity",
               classification: "equity",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _revenue} =
             Account.create(%{
               code: "40_000",
               name: "revenue",
               classification: "revenue",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _expense} =
             Account.create(%{
               code: "50_000",
               name: "expense",
               classification: "expense",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _gain} =
             Account.create(%{
               code: "50_000",
               name: "gain",
               classification: "gain",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _loss} =
             Account.create(%{
               code: "50_000",
               name: "loss",
               classification: "loss",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _contra_asset} =
             Account.create(%{
               code: "60_000",
               name: "contra_asset",
               classification: "contra_asset",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _contra_liability} =
             Account.create(%{
               code: "70_000",
               name: "contra_liability",
               classification: "contra_liability",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _contra_equity} =
             Account.create(%{
               code: "80_000",
               name: "contra_equity",
               classification: "contra_equity",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _contra_revenue} =
             Account.create(%{
               code: "90_000",
               name: "contra_revenue",
               classification: "contra_revenue",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _contra_expense} =
             Account.create(%{
               code: "100_000",
               name: "contra_expense",
               classification: "contra_expense",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _contra_gain} =
             Account.create(%{
               code: "100_000",
               name: "contra_gain",
               classification: "contra_gain",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, _contra_loss} =
             Account.create(%{
               code: "100_000",
               name: "contra_loss",
               classification: "contra_loss",
               description: "description",
               audit_details: details,
               active: true
             })
  end

  test "create/1 with invalid params", %{details: details} do
    assert {:error, :invalid_params} = Account.create(%{})
    assert {:error, :invalid_params} = Account.create(nil)

    assert {:error, :invalid_params} =
             Account.create(%{
               code: "10_000",
               name: "cash",
               classification: "asset",
               description: "description"
             })

    assert {:error, :invalid_field} =
             Account.create(%{
               code: 10_000,
               name: "cash",
               classification: "asset",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:error, :invalid_field} =
             Account.create(%{
               code: "10_000",
               name: "cash",
               classification: "classification",
               description: "description",
               audit_details: details,
               active: true
             })
  end

  test "update/2 with valid params", %{details: details} do
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

  test "update/2 with invalid params", %{details: details} do
    assert {:error, :invalid_account} = Account.update(%Account{}, %{})
    assert {:error, :invalid_params} = Account.update(%{}, nil)
    assert {:error, :invalid_account} = Account.update(%{}, %{})

    assert {:ok, account} =
             Account.create(%{
               code: "10_000",
               name: "cash",
               classification: "asset",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:error, :invalid_field} = Account.update(account, %{name: nil})

    assert {:error, :invalid_field} =
             Account.update(account, %{name: nil, active: false, test: "test"})

    assert {:error, :invalid_params} = Account.update(account, nil)
  end

  test "validate/1 with valid params", %{details: details} do
    assert {:ok, account} =
             Account.create(%{
               code: "10_000",
               name: "cash",
               classification: "asset",
               description: "description",
               audit_details: details,
               active: true
             })

    assert {:ok, account} = Account.validate(account)
  end

  test "validate/1 with invalid params", %{details: details} do
    assert {:error, :invalid_account} = Account.validate(%{})
    assert {:error, :invalid_account} = Account.validate(nil)
    assert {:error, :invalid_account} = Account.validate(%Account{})

    assert {:error, :invalid_account} =
             Account.validate(%{
               code: "10_000",
               name: "cash",
               classification: "asset",
               description: "description"
             })
  end
end
