defmodule Bookkeeping.Boundary.ChartOfAccountsTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Boundary.ChartOfAccounts

  setup do
    description = "description"
    details = %{email: "example@example.com"}
    {:ok, details: details, description: description}
  end

  test "start link" do
    {:error, {:already_started, server}} = ChartOfAccounts.start_link()
    assert server in Process.list()
  end

  test "create account", %{description: description, details: details} do
    assert {:ok, account} =
             ChartOfAccounts.create_account("1000", "Cash1", "asset", description, details)

    assert account.code == "1000"
    assert account.name == "Cash1"

    assert {:ok, %{message: "Account already exists", account: existing_account}} =
             ChartOfAccounts.create_account("1000", "Cash1", "asset", description, details)

    assert existing_account.code == "1000"
    assert existing_account.name == "Cash1"

    assert {:error, :invalid_account} =
             ChartOfAccounts.create_account(
               "1002",
               "Inventory",
               "invalid",
               description,
               true,
               details
             )

    assert {:error, :invalid_account} =
             ChartOfAccounts.create_account("1003", "", "asset", description, details)
  end

  test "update account" do
    assert {:ok, account} =
             ChartOfAccounts.create_account("1000update", "Cash original", "asset", "", %{})

    assert {:ok, updated_account} =
             ChartOfAccounts.update_account(account, %{name: "Cash updated"})

    assert updated_account.code == "1000update"
    assert updated_account.name == "Cash updated"
    assert updated_account.account_type.name == "Asset"
    assert {:error, :invalid_account} = ChartOfAccounts.update_account(account, %{name: ""})
    assert {:error, :invalid_account} = ChartOfAccounts.update_account(account, %{name: 1000})
    assert {:ok, new_updated_account} = ChartOfAccounts.update_account(updated_account, %{})
    assert updated_account.code == new_updated_account.code
    assert updated_account.name == new_updated_account.name
    assert updated_account.account_type == new_updated_account.account_type
  end

  test "all accounts" do
    assert {:ok, accounts} = ChartOfAccounts.all_accounts()
    assert is_list(accounts)
  end

  test "find account by code" do
    assert {:ok, account} =
             ChartOfAccounts.create_account("1001", "Accounts receivable", "asset", "", %{})

    assert {:ok, account} = ChartOfAccounts.find_account_by_code(account.code)
    assert account.code == "1001"
    assert account.name == "Accounts receivable"
    assert {:error, :not_found} = ChartOfAccounts.find_account_by_code("2001")
  end

  test "find account by name" do
    assert {:ok, account} =
             ChartOfAccounts.create_account(
               "10010000",
               "Accounts receivable4",
               "asset",
               "",
               %{}
             )

    assert {:ok, account} = ChartOfAccounts.find_account_by_name(account.name)
    assert account.code == "10010000"
    assert account.name == "Accounts receivable4"
    assert {:error, :not_found} = ChartOfAccounts.find_account_by_name("Accounts payable4")
  end

  test "search accounts by code or name" do
    assert {:ok, account_1} =
             ChartOfAccounts.create_account("100100", "Cash2", "asset", "", %{})

    assert {:ok, account_2} =
             ChartOfAccounts.create_account("100200", "Receivable2", "asset", "", %{})

    assert {:ok, account_3} =
             ChartOfAccounts.create_account("100300", "Inventory2", "asset", "", %{})

    assert {:ok, accounts} = ChartOfAccounts.search_accounts("100")
    assert Enum.member?(accounts, account_1)
    assert Enum.member?(accounts, account_2)
    assert Enum.member?(accounts, account_3)

    assert {:ok, accounts} = ChartOfAccounts.search_accounts("receivable")
    refute Enum.member?(accounts, account_1)
    assert Enum.member?(accounts, account_2)
    refute Enum.member?(accounts, account_3)
  end

  test "get all sorted accounts by code or name" do
    assert {:ok, account_1} =
             ChartOfAccounts.create_account("1001000", "Cash4", "asset", "", %{})

    assert {:ok, account_2} =
             ChartOfAccounts.create_account("1002000", "Receivable4", "asset", "", %{})

    assert {:ok, account_3} =
             ChartOfAccounts.create_account("1003000", "Inventory4", "asset", "", %{})

    assert {:ok, accounts} = ChartOfAccounts.all_accounts()
    assert Enum.member?(accounts, account_1)
    assert Enum.member?(accounts, account_2)
    assert Enum.member?(accounts, account_3)

    assert {:ok, accounts} = ChartOfAccounts.all_sorted_accounts("code")
    account_1_index = find_account_index(accounts, "1001000")
    account_2_index = find_account_index(accounts, "1002000")
    account_3_index = find_account_index(accounts, "1003000")
    assert account_2_index > account_1_index
    assert account_3_index > account_2_index

    assert {:ok, accounts} = ChartOfAccounts.all_sorted_accounts("name")
    account_1_index = find_account_index(accounts, "1001000")
    account_2_index = find_account_index(accounts, "1002000")
    account_3_index = find_account_index(accounts, "1003000")
    assert account_2_index > account_1_index
    assert account_3_index < account_2_index

    assert {:error, :invalid_field} = ChartOfAccounts.all_sorted_accounts("invalid")
  end

  defp find_account_index(accounts, code), do: Enum.find_index(accounts, &(&1.code == code))
end
