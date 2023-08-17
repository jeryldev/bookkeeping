defmodule Bookkeeping.Boundary.ChartOfAccountsTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Boundary.ChartOfAccounts
  alias Bookkeeping.Core.AccountType

  setup do
    {:ok, server} = ChartOfAccounts.start_link()
    {:ok, asset_type} = AccountType.asset()
    {:ok, account} = ChartOfAccounts.create_account(server, "10010", "Cash", asset_type)

    {:ok, server: server, account: account, asset_type: asset_type}
  end

  test "create account with valid code, name and account type", %{server: server} do
    {:ok, asset_type} = AccountType.asset()

    assert {:ok, _account} =
             ChartOfAccounts.create_account(server, "10020", "Accounts receivable", asset_type)

    assert {:ok, _account} =
             ChartOfAccounts.create_account("10020", "Accounts receivable", asset_type)
  end

  test "disallow account with invalid code", %{server: server, asset_type: asset_type} do
    assert {:error, :invalid_account} =
             ChartOfAccounts.create_account(server, 10_020, "Accounts receivable", asset_type)

    assert {:error, :invalid_account} =
             ChartOfAccounts.create_account(server, "", "Accounts receivable", asset_type)
  end

  test "disallow account with invalid name", %{server: server} do
    {:ok, asset_type} = AccountType.asset()

    assert {:error, :invalid_account} =
             ChartOfAccounts.create_account(server, "10020", :accounts_receivables, asset_type)

    assert {:error, :invalid_account} =
             ChartOfAccounts.create_account(server, "", :accounts_receivables, asset_type)
  end

  test "disallow account with invalid account type", %{server: server} do
    assert {:error, :invalid_account} =
             ChartOfAccounts.create_account(
               server,
               "10020",
               "Accounts receivable",
               "asset_type"
             )
  end

  test "disallow account with duplicate code", %{server: server, asset_type: asset_type} do
    assert {:error, :duplicate_account} =
             ChartOfAccounts.create_account(server, "10010", "Cash", asset_type)

    assert {:ok, _account} =
             ChartOfAccounts.create_account("10030", "Inventory", asset_type)

    assert {:error, :duplicate_account} =
             ChartOfAccounts.create_account("10030", "Inventory", asset_type)
  end

  test "remove account", %{server: server, account: account} do
    {:ok, other_server} = ChartOfAccounts.start_link()
    {:ok, asset_type} = AccountType.asset()

    {:ok, other_account} =
      ChartOfAccounts.create_account(other_server, "10020", "Accounts receivable", asset_type)

    assert :ok = ChartOfAccounts.remove_account(server, account)
    assert :ok = ChartOfAccounts.remove_account(server, other_account)
    assert {:ok, []} = ChartOfAccounts.all_accounts(server)

    assert {:ok, prepaid_expenses} =
             ChartOfAccounts.create_account("10040", "Prepaid Expenses", asset_type)

    assert {:ok, found_account} = ChartOfAccounts.search_account(prepaid_expenses.code)
    assert :ok = ChartOfAccounts.remove_account(found_account)
    assert {:ok, refreshed_accounts} = ChartOfAccounts.all_accounts()
    refute Enum.member?(refreshed_accounts, found_account)
  end

  test "search account by code", %{server: server, account: account} do
    assert {:ok, [^account]} = ChartOfAccounts.search_account(server, "10010")
    assert {:ok, []} = ChartOfAccounts.search_account(server, "10020 Accounts receivable")
  end

  test "search account by name", %{server: server, account: account} do
    assert {:ok, [^account]} = ChartOfAccounts.search_account(server, "Cash")
    assert {:ok, []} = ChartOfAccounts.search_account(server, "10020 Accounts receivable")
  end

  test "search account by code and name", %{server: server, account: account} do
    assert {:ok, [^account]} = ChartOfAccounts.search_account(server, "10010 Cash")
    assert {:ok, []} = ChartOfAccounts.search_account(server, "10020 Accounts receivable")
  end

  test "search all accounts", %{server: server, account: account} do
    assert {:ok, [^account]} = ChartOfAccounts.all_accounts(server)
  end

  test "sort accounts by code", %{server: server, asset_type: asset_type} do
    ChartOfAccounts.create_account(server, "10030", "Inventory", asset_type)
    ChartOfAccounts.create_account(server, "10020", "Accounts receivable", asset_type)

    {:ok, accounts} = ChartOfAccounts.all_accounts(server)
    codes = Enum.map(accounts, & &1.code)
    assert ["10010", "10030", "10020"] = codes
    assert :ok = ChartOfAccounts.sort_accounts_by_code(server)

    {:ok, sorted_accounts} = ChartOfAccounts.all_accounts(server)
    sorted_codes = Enum.map(sorted_accounts, & &1.code)
    assert ["10010", "10020", "10030"] = sorted_codes

    ChartOfAccounts.create_account("10070", "Land", asset_type)
    ChartOfAccounts.create_account("10010", "Cash and Cash Equivalents", asset_type)
    {:ok, gen_server_accounts_before} = ChartOfAccounts.all_accounts()
    gen_server_account_codes_before = Enum.map(gen_server_accounts_before, & &1.code)
    assert :ok = ChartOfAccounts.sort_accounts_by_code()
    {:ok, gen_server_accounts_after} = ChartOfAccounts.all_accounts()
    gen_server_account_codes_after = Enum.map(gen_server_accounts_after, & &1.code)
    refute gen_server_account_codes_before == gen_server_account_codes_after
  end

  test "sort accounts by name", %{server: server, asset_type: asset_type} do
    ChartOfAccounts.create_account(server, "10030", "Inventory", asset_type)
    ChartOfAccounts.create_account(server, "10020", "Accounts receivable", asset_type)

    {:ok, accounts} = ChartOfAccounts.all_accounts(server)
    names = Enum.map(accounts, & &1.name)
    assert ["Cash", "Inventory", "Accounts receivable"] = names
    assert :ok = ChartOfAccounts.sort_accounts_by_name(server)

    {:ok, sorted_accounts} = ChartOfAccounts.all_accounts(server)
    sorted_names = Enum.map(sorted_accounts, & &1.name)
    assert ["Accounts receivable", "Cash", "Inventory"] = sorted_names

    ChartOfAccounts.create_account("10060", "Trade Inventories", asset_type)
    ChartOfAccounts.create_account("10050", "Accounts Receivables Test", asset_type)
    {:ok, gen_server_accounts_before} = ChartOfAccounts.all_accounts()
    gen_server_account_names_before = Enum.map(gen_server_accounts_before, & &1.name)
    assert :ok = ChartOfAccounts.sort_accounts_by_name()
    {:ok, gen_server_accounts_after} = ChartOfAccounts.all_accounts()
    gen_server_account_names_after = Enum.map(gen_server_accounts_after, & &1.name)
    refute gen_server_account_names_before == gen_server_account_names_after
  end
end
