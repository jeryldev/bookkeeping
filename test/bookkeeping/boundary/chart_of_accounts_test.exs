defmodule Bookkeeping.Boundary.ChartOfAccountsTest do
  use ExUnit.Case
  alias Bookkeeping.Boundary.ChartOfAccounts.Worker, as: ChartOfAccounts

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

    {:ok, params: params, invalid_params: invalid_params}
  end

  describe "Worker start_link/1 " do
    test "with valid params" do
      {:ok, server} = ChartOfAccounts.start_link([])
      assert server in Process.list()
    end

    test "with invalid params" do
      {:ok, _server} = ChartOfAccounts.start_link(test: nil)
    end
  end

  describe "create/1" do
    test "with valid params", %{params: params} do
      params = update_params(params)
      assert {:ok, account} = ChartOfAccounts.create(params)
      assert account.code == params.code
      assert account.name == params.name
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

    test "with invalid code", %{params: params} do
      params = params |> update_params() |> Map.put(:code, nil)
      assert {:error, :invalid_code} = ChartOfAccounts.create(params)
    end

    test "with invalid name", %{params: params} do
      params = params |> update_params() |> Map.put(:name, nil)
      assert {:error, :invalid_name} = ChartOfAccounts.create(params)
    end

    test "with invalid classification", %{params: params} do
      params = params |> update_params() |> Map.put(:classification, nil)
      assert {:error, :invalid_classification} = ChartOfAccounts.create(params)
    end

    test "with invalid description", %{params: params} do
      params = params |> update_params() |> Map.put(:description, nil)
      assert {:error, :invalid_description} = ChartOfAccounts.create(params)
    end

    test "with invalid audit_details", %{params: params} do
      params = params |> update_params() |> Map.put(:audit_details, nil)
      assert {:error, :invalid_audit_details} = ChartOfAccounts.create(params)
    end

    test "with invalid active state", %{params: params} do
      params = params |> update_params() |> Map.put(:active, nil)
      assert {:error, :invalid_active_state} = ChartOfAccounts.create(params)
    end

    test "that already exists", %{params: params} do
      params = update_params(params)
      assert {:ok, _account} = ChartOfAccounts.create(params)
      assert {:error, :already_exists} = ChartOfAccounts.create(params)
    end
  end

  describe "import/1" do
    test "with a valid file twice" do
      assert %{accounts: accounts, errors: _errors} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/valid_chart_of_accounts.csv"
               )

      assert length(accounts) == 9

      Process.sleep(300)

      assert %{accounts: [], errors: errors} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/valid_chart_of_accounts.csv"
               )

      assert Enum.count(errors) == 9
      assert Enum.all?(errors, fn error -> error.reason == :already_exists end)

      assert %{accounts: [], errors: _errors} =
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

      assert Enum.all?(
               errors,
               &(&1.reason in [:already_exists, :invalid_name, :invalid_classification])
             )
    end
  end

  describe "update/2" do
    test "with valid params", %{params: params} do
      params = update_params(params)
      {:ok, account} = ChartOfAccounts.create(params)

      assert {:ok, updated_account} =
               ChartOfAccounts.update(account, %{
                 name: "Cash updated",
                 description: "description updated",
                 audit_details: %{updated_by: "example@example.com"},
                 active: false
               })

      assert updated_account.code == account.code
      assert updated_account.name == "Cash updated"
      assert updated_account.classification.name == "Asset"
      assert updated_account.description == "description updated"
      assert is_struct(updated_account.classification, Bookkeeping.Core.Account.Classification)
      assert is_list(updated_account.audit_logs)
      assert length(updated_account.audit_logs) > 1
      assert updated_account.active == false
    end

    test "with invalid account" do
      assert {:error, :invalid_account} = ChartOfAccounts.update(nil, %{name: "Cash updated"})
      assert {:error, :invalid_account} = ChartOfAccounts.update("apple", %{name: "Cash updated"})
    end

    test "with invalid params", %{params: params} do
      params = update_params(params)
      {:ok, account} = ChartOfAccounts.create(params)

      assert {:error, :invalid_params} = ChartOfAccounts.update(account, nil)
      assert {:error, :invalid_params} = ChartOfAccounts.update(account, "apple")
      assert {:error, :invalid_params} = ChartOfAccounts.update(account, %{})
      assert {:error, :invalid_params} = ChartOfAccounts.update(account, %{code: "1001"})
      assert {:error, :invalid_params} = ChartOfAccounts.update(account, %{test: "test"})

      assert {:error, :invalid_params} =
               ChartOfAccounts.update(account, %{classification: "liability"})
    end
  end

  describe "all_accounts/0" do
    test "returns all accounts", %{params: params} do
      {:ok, account} = ChartOfAccounts.create(params)
      assert {:ok, accounts} = ChartOfAccounts.all_accounts()
      assert account in accounts
    end
  end

  describe "search_code/1" do
    test "with complete code", %{params: params} do
      params = update_params(params)
      {:ok, account} = ChartOfAccounts.create(params)
      assert {:ok, accounts} = ChartOfAccounts.search_code(account.code)
      assert Enum.member?(accounts, account)
      code_prefix = String.slice(account.code, 0, 2)
      assert {:ok, accounts} = ChartOfAccounts.search_code(code_prefix)
      assert account in accounts
    end

    test "with code prefix", %{params: params} do
      params = update_params(params)
      {:ok, account} = ChartOfAccounts.create(params)

      code_prefix = String.slice(account.code, 0, 2)
      assert {:ok, accounts} = ChartOfAccounts.search_code(code_prefix)
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
      params = update_params(params)
      {:ok, account} = ChartOfAccounts.create(params)
      assert {:ok, accounts} = ChartOfAccounts.search_name(account.name)
      assert Enum.member?(accounts, account)
      name_prefix = String.slice(account.name, 0, 2)
      assert {:ok, accounts} = ChartOfAccounts.search_name(name_prefix)
      assert account in accounts
    end

    test "with name prefix", %{params: params} do
      params = update_params(params)
      {:ok, account} = ChartOfAccounts.create(params)
      name_prefix = String.slice(account.name, 0, 2)
      assert {:ok, accounts} = ChartOfAccounts.search_name(name_prefix)
      assert account in accounts
    end

    test "with invalid name" do
      assert {:error, :invalid_name} = ChartOfAccounts.search_name(nil)
      assert {:error, :invalid_name} = ChartOfAccounts.search_name(%{})
      assert {:error, :invalid_name} = ChartOfAccounts.search_name("")
    end
  end

  describe "Worker die/0" do
    test "still restores the state of the table", %{params: params} do
      params = update_params(params)
      assert {:ok, account} = ChartOfAccounts.create(params)
      assert is_struct(account)

      ChartOfAccounts.die()

      assert {:ok, accounts} = ChartOfAccounts.search_code(account.code)
      assert account in accounts
    end

    test "repeats the call until the proper response is returned if the table is not yet available and then function was immediately called",
         %{params: params} do
      ChartOfAccounts.die()
      params = update_params(params)
      assert {:ok, account} = ChartOfAccounts.create(params)
      assert is_struct(account)

      ChartOfAccounts.die()
      assert {:ok, accounts} = ChartOfAccounts.search_code(account.code)
      assert account in accounts
      assert {:ok, accounts} = ChartOfAccounts.search_name(account.name)
      assert account in accounts

      ChartOfAccounts.die()
      assert {:ok, updated_account} = ChartOfAccounts.update(account, %{name: "Cash updated"})
      assert updated_account.code == account.code
      assert updated_account.name == "Cash updated"

      ChartOfAccounts.die()

      assert %{accounts: accounts, errors: []} =
               ChartOfAccounts.import_file(
                 "../../../../test/bookkeeping/data/valid_chart_of_accounts_2.csv"
               )

      assert length(accounts) == 9

      ChartOfAccounts.die()
      assert {:ok, _accounts} = ChartOfAccounts.all_accounts()
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
end
