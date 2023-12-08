defmodule Bookkeeping.Boundary.ChartOfAccountsTest do
  use ExUnit.Case
  alias Bookkeeping.Boundary.ChartOfAccounts2.Worker, as: ChartOfAccounts
  alias Bookkeeping.Boundary.ChartOfAccounts2.Supervisor, as: ChartOfAccountsSupervisor

  setup do
    params = %{
      code: "1000",
      name: "Cash",
      classification: "asset",
      description: "description",
      audit_details: %{email: "example@example.com"},
      active: true
    }

    invalid_params = %{
      code: "1000",
      name: "Cash",
      classification: "invalid",
      description: "description",
      audit_details: %{email: "example@example.com"},
      active: true
    }

    {:ok, server_pid} = ChartOfAccountsSupervisor.start_link([])

    {:ok, params: params, invalid_params: invalid_params, server_pid: server_pid}
  end

  describe "Worker start_link/1 " do
    test "with valid params" do
      {:ok, server} = ChartOfAccounts.start_link([])
      assert server in Process.list()
    end

    test "with invalid params" do
      {:ok, server} = ChartOfAccounts.start_link(test: nil)
    end
  end

  describe "create/1" do
    test "with valid params", %{params: params} do
      assert {:ok, account} = ChartOfAccounts.create(params)
      assert account.code == "1000"
      assert account.name == "Cash"
      assert account.classification.name == "Asset"
      assert account.description == "description"
      assert is_struct(account.classification, Bookkeeping.Core.Account.Classification)
      assert is_list(account.audit_logs)
    end

    test "with invalid params" do
      assert {:error, :invalid_params} = ChartOfAccounts.create("apple")
      assert {:error, :invalid_params} = ChartOfAccounts.create(%{})
      assert {:error, :invalid_params} = ChartOfAccounts.create(%{code: "1000"})
      assert {:error, :invalid_params} = ChartOfAccounts.create(%{name: "Cash"})
      assert {:error, :invalid_params} = ChartOfAccounts.create(%{classification: "asset"})
      assert {:error, :invalid_params} = ChartOfAccounts.create(%{description: "description"})

      assert {:error, :invalid_params} =
               ChartOfAccounts.create(%{audit_details: %{email: "example@example.com"}})

      assert {:error, :invalid_params} = ChartOfAccounts.create(%{active: true})
    end

    test "with invalid field", %{params: params, invalid_params: invalid_params} do
      assert {:error, :invalid_field} = ChartOfAccounts.create(invalid_params)
    end

    test "that already exists", %{params: params} do
      assert {:ok, account} = ChartOfAccounts.create(params)
      assert {:error, :already_exists} = ChartOfAccounts.create(params)
    end
  end

  describe "import/1" do
    test "with a valid file" do
      assert %{accounts: accounts, errors: _errors} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/valid_chart_of_accounts.csv"
               )

      assert Enum.count(accounts) == 9
    end

    test "with a valid file twice" do
      assert %{accounts: accounts, errors: errors} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/valid_chart_of_accounts.csv"
               )

      assert %{accounts: [], errors: errors} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/valid_chart_of_accounts.csv"
               )

      assert Enum.count(accounts) == 9
      assert Enum.count(errors) == 9
      assert Enum.all?(errors, fn error -> error.reason == :already_exists end)

      assert %{accounts: [], errors: errors} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/empty_chart_of_accounts_2.csv"
               )
    end

    test "with an invalid file" do
      assert {:error, :invalid_file} =
               ChartOfAccounts.import_file("../../../../test/bookkeeping/data/invalid_file.csv")

      assert {:error, :invalid_file} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/empty_chart_of_accounts.csv"
               )

      assert {:error, :invalid_file} =
               ChartOfAccounts.import_file("../../../../test/bookkeeping/data/text_file.txt")

      assert {:error, :invalid_file} = ChartOfAccounts.import_file(nil)
    end

    test "with a file with invalid values" do
      assert %{accounts: accounts, errors: errors} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/partially_valid_chart_of_accounts.csv"
               )

      assert Enum.count(accounts) == 7
      assert Enum.count(errors) == 3

      assert Enum.all?(errors, fn error ->
               error.reason in [:already_exists, :invalid_field]
             end)
    end
  end

  describe "update/2" do
    test "with valid params", %{params: params} do
      {:ok, account} = ChartOfAccounts.create(params)

      assert {:ok, updated_account} =
               ChartOfAccounts.update(account, %{
                 name: "Cash updated",
                 description: "description updated",
                 audit_details: %{updated_by: "example@example.com"},
                 active: false
               })

      assert updated_account.code == "1000"
      assert updated_account.name == "Cash updated"
      assert updated_account.classification.name == "Asset"
      assert updated_account.description == "description updated"
      assert is_struct(updated_account.classification, Bookkeeping.Core.Account.Classification)
      assert is_list(updated_account.audit_logs)
      assert length(updated_account.audit_logs) == 2
      assert updated_account.active == false
    end

    test "with invalid account" do
      assert {:error, :invalid_account} = ChartOfAccounts.update(nil, %{name: "Cash updated"})
      assert {:error, :invalid_account} = ChartOfAccounts.update("apple", %{name: "Cash updated"})
    end

    test "with invalid field", %{params: params} do
      {:ok, account} = ChartOfAccounts.create(params)

      assert {:error, :invalid_field} = ChartOfAccounts.update(account, %{code: "1001"})

      assert {:error, :invalid_field} =
               ChartOfAccounts.update(account, %{classification: "liability"})

      assert {:error, :invalid_field} = ChartOfAccounts.update(account, %{test: "test"})
    end

    test "with invalid params", %{params: params} do
      {:ok, account} = ChartOfAccounts.create(params)

      assert {:error, :invalid_params} = ChartOfAccounts.update(account, nil)
      assert {:error, :invalid_params} = ChartOfAccounts.update(account, "apple")
      assert {:error, :invalid_params} = ChartOfAccounts.update(account, %{})
    end
  end

  describe "search_code/1" do
    test "with complete code", %{params: params} do
      {:ok, account} = ChartOfAccounts.create(params)
      assert {:ok, accounts} = ChartOfAccounts.search_code(account.code)
      assert Enum.member?(accounts, account)

      assert {:ok, accounts} = ChartOfAccounts.search_code("10")
      assert accounts == [account]
    end

    test "with code prefix", %{params: params} do
      {:ok, account} = ChartOfAccounts.create(params)
      assert {:ok, accounts} = ChartOfAccounts.search_code("10")
      assert Enum.member?(accounts, account)
    end

    test "with invalid code" do
      assert {:error, :invalid_code} = ChartOfAccounts.search_code(nil)
      assert {:error, :invalid_code} = ChartOfAccounts.search_code(%{})
      assert {:error, :invalid_code} = ChartOfAccounts.search_code("")
    end
  end

  describe "search_name/1" do
    test "with complete name", %{params: params} do
      {:ok, account} = ChartOfAccounts.create(params)
      assert {:ok, accounts} = ChartOfAccounts.search_name(account.name)
      assert Enum.member?(accounts, account)

      assert {:ok, accounts} = ChartOfAccounts.search_name("Cash")
      assert accounts == [account]
    end

    test "with name prefix", %{params: params} do
      {:ok, account} = ChartOfAccounts.create(params)
      assert {:ok, accounts} = ChartOfAccounts.search_name("Ca")
      assert Enum.member?(accounts, account)
    end

    test "with invalid name" do
      assert {:error, :invalid_name} = ChartOfAccounts.search_name(nil)
      assert {:error, :invalid_name} = ChartOfAccounts.search_name(%{})
      assert {:error, :invalid_name} = ChartOfAccounts.search_name("")
    end
  end
end
