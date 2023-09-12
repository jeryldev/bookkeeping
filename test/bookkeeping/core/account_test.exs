defmodule Bookkeeping.Core.AccountTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.Account

  setup do
    details = %{email: "example@example.com"}
    {:ok, details: details}
  end

  test "allow integer code, binary name and account type account field", %{details: details} do
    assert {:ok, new_account} =
             Account.create("10_000", "cash", "asset", "description", details)

    assert new_account.code == "10_000"
    assert new_account.name == "cash"
    assert new_account.account_type.name == "Asset"
    assert new_account.account_type.normal_balance == :debit

    assert {:ok, _valid_account} = Account.validate_account(new_account)
  end

  test "create account with description and active fields", %{details: details} do
    assert {:ok, new_account} =
             Account.create("10_010", "cash", "asset", "cash and cash equivalents", details)

    assert new_account.code == "10_010"
    assert new_account.name == "cash"
    assert new_account.account_type.name == "Asset"
    assert new_account.account_type.normal_balance == :debit
    assert new_account.account_description == "cash and cash equivalents"
    assert new_account.active
  end

  test "disallow non-binary code field", %{details: details} do
    new_account = Account.create(10_000, "cash", "asset", "description", details)

    assert ^new_account = {:error, :invalid_account}
  end

  test "disallow non-binary name field", %{details: details} do
    new_account = Account.create(10_000, 10_000, "asset", "description", details)

    assert ^new_account = {:error, :invalid_account}
  end

  test "disallow non-%AccountType{} account field", %{details: details} do
    new_account = Account.create(10_000, "cash", "account_type", "description", details)

    assert ^new_account = {:error, :invalid_account}
  end

  test "disallow empty name", %{details: details} do
    new_account = Account.create(10_000, "", "asset", "description", details)

    assert ^new_account = {:error, :invalid_account}
  end

  test "update account", %{details: details} do
    assert {:ok, account} =
             Account.create("10_000", "cash", "asset", "description", details)

    assert {:ok, account_2} = Account.update(account, %{name: "cash and cash equivalents"})
    assert account.code == account_2.code
    refute account.name == account_2.name
    assert account.account_type == account_2.account_type
    assert {:error, :invalid_account} = Account.update(account, %{name: ""})

    assert {:ok, account_3} =
             Account.update(account, %{
               code: "10_001",
               name: "trade payables",
               binary_account_type: "liability"
             })

    assert account.code == account_3.code
    refute account.name == account_3.name
    assert account.account_type == account_3.account_type

    assert {:ok, _account_4} =
             Account.update(account, %{
               code: "10_001",
               name: "cash and cash equivalents"
             })
  end

  test "validate account" do
    assert {:error, :invalid_account} = Account.validate_account(%Account{})
  end
end
