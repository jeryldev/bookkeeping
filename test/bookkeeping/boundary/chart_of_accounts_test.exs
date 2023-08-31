defmodule Bookkeeping.Boundary.ChartOfAccountsTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Boundary.ChartOfAccounts.Backup, as: ChartOfAccountsBackup
  alias Bookkeeping.Boundary.ChartOfAccounts.Server, as: ChartOfAccountsServer

  setup do
    description = "description"
    details = %{email: "example@example.com"}

    {:ok, details: details, description: description}
  end

  test "start link" do
    {:ok, server} = ChartOfAccountsServer.start_link()
    assert server in Process.list()
  end

  test "create account", %{description: description, details: details} do
    assert {:ok, _account} =
             ChartOfAccountsServer.create_account("1000101", "Cash Test", "asset")

    assert {:ok, account} =
             ChartOfAccountsServer.create_account("1000", "Cash1", "asset", description, details)

    assert account.code == "1000"
    assert account.name == "Cash1"

    assert {:error, :account_already_exists} =
             ChartOfAccountsServer.create_account("1000", "Cash1", "asset", description, details)

    assert {:error, :invalid_account} =
             ChartOfAccountsServer.create_account(
               "1002",
               "Inventory",
               "invalid",
               description,
               true,
               details
             )

    assert {:error, :invalid_account} =
             ChartOfAccountsServer.create_account("1003", "", "asset", description, details)
  end

  test "import default accounts" do
    assert {:ok, []} = ChartOfAccountsServer.reset_accounts()

    # importing a valid file
    assert {:ok, %{ok: _oks, error: _errors}} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/assets/valid_chart_of_accounts.csv"
             )

    # importing an invalid or missing file
    assert {:error, :invalid_file} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/assets/invalid_file.csv"
             )

    # importing accounts with empty fields
    assert {:error, %{message: :invalid_csv, errors: _errors}} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/assets/invalid_chart_of_accounts.csv"
             )

    # importing an empty file
    assert {:error, :invalid_file} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/assets/empty_chart_of_accounts.csv"
             )

    # importing accounts with invalid account type
    assert {:error, %{message: :invalid_csv, errors: _errors}} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/assets/decode_error_chart_of_accounts.csv"
             )

    # importing duplicate accounts in a single file
    assert {:ok, %{ok: _oks, error: _errors}} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/assets/duplicate_chart_of_accounts.csv"
             )

    # importing the file twice
    assert {:error, %{ok: _oks, error: _errors}} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/assets/duplicate_chart_of_accounts.csv"
             )
  end

  test "update account" do
    assert {:ok, account} =
             ChartOfAccountsServer.create_account("1000update", "Cash original", "asset", "", %{})

    assert {:ok, updated_account} =
             ChartOfAccountsServer.update_account(account, %{name: "Cash updated"})

    assert updated_account.code == "1000update"
    assert updated_account.name == "Cash updated"
    assert updated_account.account_type.name == "Asset"
    assert {:error, :invalid_account} = ChartOfAccountsServer.update_account(account, %{name: ""})

    assert {:error, :invalid_account} =
             ChartOfAccountsServer.update_account(account, %{name: 1000})

    assert {:ok, new_updated_account} = ChartOfAccountsServer.update_account(updated_account, %{})
    assert updated_account.code == new_updated_account.code
    assert updated_account.name == new_updated_account.name
    assert updated_account.account_type == new_updated_account.account_type
  end

  test "all accounts" do
    assert {:ok, accounts} = ChartOfAccountsServer.all_accounts()
    assert is_list(accounts)
  end

  test "find account by code" do
    assert {:ok, account} =
             ChartOfAccountsServer.create_account("1001", "Accounts receivable", "asset", "", %{})

    assert {:ok, account} = ChartOfAccountsServer.find_account_by_code(account.code)
    assert account.code == "1001"
    assert account.name == "Accounts receivable"
    assert {:error, :not_found} = ChartOfAccountsServer.find_account_by_code("2001")
  end

  test "find account by name" do
    assert {:ok, account} =
             ChartOfAccountsServer.create_account(
               "10010000",
               "Accounts receivable4",
               "asset",
               "",
               %{}
             )

    assert {:ok, account} = ChartOfAccountsServer.find_account_by_name(account.name)
    assert account.code == "10010000"
    assert account.name == "Accounts receivable4"
    assert {:error, :not_found} = ChartOfAccountsServer.find_account_by_name("Accounts payable4")
  end

  test "search accounts by code or name" do
    assert {:ok, account_1} =
             ChartOfAccountsServer.create_account("100100", "Cash2", "asset", "", %{})

    assert {:ok, account_2} =
             ChartOfAccountsServer.create_account("100200", "Receivable2", "asset", "", %{})

    assert {:ok, account_3} =
             ChartOfAccountsServer.create_account("100300", "Inventory2", "asset", "", %{})

    assert {:ok, accounts} = ChartOfAccountsServer.search_accounts("100")
    assert Enum.member?(accounts, account_1)
    assert Enum.member?(accounts, account_2)
    assert Enum.member?(accounts, account_3)

    assert {:ok, accounts} = ChartOfAccountsServer.search_accounts("receivable")
    refute Enum.member?(accounts, account_1)
    assert Enum.member?(accounts, account_2)
    refute Enum.member?(accounts, account_3)
  end

  test "get all sorted accounts by code or name" do
    assert {:ok, account_1} =
             ChartOfAccountsServer.create_account("1001000", "Cash4", "asset", "", %{})

    assert {:ok, account_2} =
             ChartOfAccountsServer.create_account("1002000", "Receivable4", "asset", "", %{})

    assert {:ok, account_3} =
             ChartOfAccountsServer.create_account("1003000", "Inventory4", "asset", "", %{})

    assert {:ok, accounts} = ChartOfAccountsServer.all_accounts()
    assert Enum.member?(accounts, account_1)
    assert Enum.member?(accounts, account_2)
    assert Enum.member?(accounts, account_3)

    assert {:ok, accounts} = ChartOfAccountsServer.all_sorted_accounts("code")
    account_1_index = find_account_index(accounts, "1001000")
    account_2_index = find_account_index(accounts, "1002000")
    account_3_index = find_account_index(accounts, "1003000")
    assert account_2_index > account_1_index
    assert account_3_index > account_2_index

    assert {:ok, accounts} = ChartOfAccountsServer.all_sorted_accounts("name")
    account_1_index = find_account_index(accounts, "1001000")
    account_2_index = find_account_index(accounts, "1002000")
    account_3_index = find_account_index(accounts, "1003000")
    assert account_2_index > account_1_index
    assert account_3_index < account_2_index

    assert {:error, :invalid_field} = ChartOfAccountsServer.all_sorted_accounts("invalid")
  end

  test "reset accounts" do
    assert {:ok, account_1} =
             ChartOfAccountsServer.create_account("10010000101", "Cash5", "asset", "", %{})

    assert {:ok, account_2} =
             ChartOfAccountsServer.create_account("10020000101", "Receivable5", "asset", "", %{})

    assert {:ok, account_3} =
             ChartOfAccountsServer.create_account("10030000101", "Inventory5", "asset", "", %{})

    assert {:ok, accounts} = ChartOfAccountsServer.all_accounts()
    assert Enum.member?(accounts, account_1)
    assert Enum.member?(accounts, account_2)
    assert Enum.member?(accounts, account_3)

    assert {:ok, []} = ChartOfAccountsServer.reset_accounts()

    assert {:ok, accounts} = ChartOfAccountsServer.all_accounts()
    refute Enum.member?(accounts, account_1)
    refute Enum.member?(accounts, account_2)
    refute Enum.member?(accounts, account_3)
  end

  test "test chart of accounts with working backup" do
    assert {:ok, account_1} =
             ChartOfAccountsServer.create_account("1001000010101", "Cash6", "asset", "", %{})

    assert {:ok, account_2} =
             ChartOfAccountsServer.create_account(
               "1002000010101",
               "Receivable6",
               "asset",
               "",
               %{}
             )

    assert {:ok, account_3} =
             ChartOfAccountsServer.create_account("1003000010101", "Inventory6", "asset", "", %{})

    assert {:ok, accounts} = ChartOfAccountsServer.all_accounts()
    assert Enum.member?(accounts, account_1)
    assert Enum.member?(accounts, account_2)
    assert Enum.member?(accounts, account_3)
    assert {:ok, backup} = ChartOfAccountsBackup.get()
    assert backup == %{}
    assert {:ok, :backup_updated} = ChartOfAccountsBackup.update(accounts)
    assert {:ok, backup} = ChartOfAccountsBackup.get()
    assert backup == accounts
    assert {:ok, []} = ChartOfAccountsServer.reset_accounts()
    assert {:ok, accounts} = ChartOfAccountsServer.all_accounts()
    refute Enum.member?(accounts, account_1)
    refute Enum.member?(accounts, account_2)
    refute Enum.member?(accounts, account_3)
    assert {:ok, %{}} = ChartOfAccountsBackup.get()

    assert {:ok, :backup_updated} = ChartOfAccountsServer.terminate(:normal, %{})
  end

  defp find_account_index(accounts, code), do: Enum.find_index(accounts, &(&1.code == code))
end
