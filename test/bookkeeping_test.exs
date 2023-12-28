defmodule BookkeepingTest do
  use ExUnit.Case
  alias Bookkeeping
  alias Bookkeeping.Boundary.ChartOfAccounts
  alias Bookkeeping.Core.{Account, JournalEntry}

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

  ##########################################################
  # Chart of Accounts Tests                                #
  ##########################################################

  describe "Bookkeeping create_account/1 " do
    test "with valid params", %{params: params} do
      params = update_params(params)
      assert {:ok, account} = Bookkeeping.create_account(params)
      assert account.code == params.code
      assert account.name == params.name
      assert account.classification.name == "Asset"
      assert account.description == "description"
      assert is_struct(account.classification, Bookkeeping.Core.Account.Classification)
      assert is_list(account.audit_logs)
    end

    test "that already exists", %{params: params} do
      params = update_params(params)
      assert {:ok, _account} = Bookkeeping.create_account(params)
      assert {:error, :already_exists} = Bookkeeping.create_account(params)
    end

    test "with invalid code", %{params: params} do
      params = update_params(params)
      params = Map.put(params, :code, nil)
      assert {:error, :invalid_code} = Bookkeeping.create_account(params)
    end

    test "with invalid name", %{params: params} do
      params = update_params(params)
      params = Map.put(params, :name, nil)
      assert {:error, :invalid_name} = Bookkeeping.create_account(params)
    end

    test "with invalid classification", %{params: params} do
      params = update_params(params)
      params = Map.put(params, :classification, nil)
      assert {:error, :invalid_classification} = Bookkeeping.create_account(params)
    end

    test "with invalid description", %{params: params} do
      params = update_params(params)
      params = Map.put(params, :description, nil)
      assert {:error, :invalid_description} = Bookkeeping.create_account(params)
    end

    test "with invalid active state", %{params: params} do
      params = update_params(params)
      params = Map.put(params, :active, nil)
      assert {:error, :invalid_active_state} = Bookkeeping.create_account(params)
    end

    test "with invalid audit details", %{params: params} do
      params = update_params(params)
      params = Map.put(params, :audit_details, nil)
      assert {:error, :invalid_audit_details} = Bookkeeping.create_account(params)
    end

    test "with invalid params" do
      assert {:error, :invalid_params} = Bookkeeping.create_account("apple")
      assert {:error, :invalid_params} = Bookkeeping.create_account(%{})
      assert {:error, :invalid_params} = Bookkeeping.create_account(%{code: "1000"})
      assert {:error, :invalid_params} = Bookkeeping.create_account(%{name: "Cash"})
      assert {:error, :invalid_params} = Bookkeeping.create_account(%{classification: "asset"})
      assert {:error, :invalid_params} = Bookkeeping.create_account(%{description: "description"})
      assert {:error, :invalid_params} = Bookkeeping.create_account(%{active: true})

      assert {:error, :invalid_params} =
               Bookkeeping.create_account(%{audit_details: %{email: "example@example.com"}})
    end
  end

  describe "Bookkeeping import_accounts/1" do
    test "with a valid file twice" do
      assert %{accounts: accounts, errors: _errors} =
               Bookkeeping.import_accounts(
                 "../../../../test/bookkeeping/data/valid_chart_of_accounts.csv"
               )

      assert length(accounts) == 9

      Process.sleep(300)

      assert %{accounts: [], errors: errors} =
               Bookkeeping.import_accounts(
                 "../../../../test/bookkeeping/data/valid_chart_of_accounts.csv"
               )

      assert Enum.count(errors) == 9
      assert Enum.all?(errors, fn error -> error.reason == :already_exists end)

      assert %{accounts: [], errors: _errors} =
               Bookkeeping.import_accounts(
                 "../../../../test/bookkeeping/data/empty_chart_of_accounts_2.csv"
               )
    end

    test "with an invalid file" do
      assert {:error, :invalid_file} =
               Bookkeeping.import_accounts("../../../../test/bookkeeping/data/invalid_file.csv")

      assert {:error, :invalid_file} =
               Bookkeeping.import_accounts(
                 "../../../../test/bookkeeping/data/empty_chart_of_accounts.csv"
               )

      assert {:error, :invalid_file} =
               Bookkeeping.import_accounts("../../../../test/bookkeeping/data/text_file.txt")

      assert {:error, :invalid_file} = Bookkeeping.import_accounts(nil)
    end

    test "with a file with invalid values" do
      assert %{accounts: accounts, errors: errors} =
               Bookkeeping.import_accounts(
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

  describe "Bookkeeping update_accounts/2" do
    test "with valid params", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)

      assert {:ok, updated_account} =
               Bookkeeping.update_account(account, %{
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
      assert length(updated_account.audit_logs) == 2
      assert updated_account.active == false
    end

    test "with invalid account" do
      assert {:error, :invalid_account} = Bookkeeping.update_account(nil, %{name: "Cash updated"})

      assert {:error, :invalid_account} =
               Bookkeeping.update_account("apple", %{name: "Cash updated"})
    end

    test "with invalid name", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)
      assert {:error, :invalid_name} = Bookkeeping.update_account(account, %{name: nil})
    end

    test "with invalid description", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)

      assert {:error, :invalid_description} =
               Bookkeeping.update_account(account, %{description: nil})
    end

    test "with invalid audit details", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)

      assert {:error, :invalid_audit_details} =
               Bookkeeping.update_account(account, %{audit_details: nil})
    end

    test "with invalid active state", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)
      assert {:error, :invalid_active_state} = Bookkeeping.update_account(account, %{active: nil})
    end

    test "with invalid params", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)

      assert {:error, :invalid_params} = Bookkeeping.update_account(account, nil)
      assert {:error, :invalid_params} = Bookkeeping.update_account(account, "apple")
      assert {:error, :invalid_params} = Bookkeeping.update_account(account, %{})
    end
  end

  describe "Bookkeeping all_accounts/0" do
    test "returns all accounts", %{params: params} do
      {:ok, account} = Bookkeeping.create_account(params)
      assert {:ok, accounts} = Bookkeeping.all_accounts()
      assert account in accounts
    end
  end

  describe "Bookkeeping search_accounts_by_code/1" do
    test "with complete code", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)
      assert {:ok, accounts} = Bookkeeping.search_accounts_by_code(account.code)
      assert Enum.member?(accounts, account)
      code_prefix = String.slice(account.code, 0, 2)
      assert {:ok, accounts} = Bookkeeping.search_accounts_by_code(code_prefix)
      assert account in accounts
    end

    test "with code prefix", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)

      code_prefix = String.slice(account.code, 0, 2)
      assert {:ok, accounts} = Bookkeeping.search_accounts_by_code(code_prefix)
      assert Enum.member?(accounts, account)
    end

    test "with invalid code" do
      assert {:error, :invalid_code} = Bookkeeping.search_accounts_by_code(nil)
      assert {:error, :invalid_code} = Bookkeeping.search_accounts_by_code(%{})
      assert {:error, :invalid_code} = Bookkeeping.search_accounts_by_code("")
    end
  end

  describe "Bookkeeping search_accounts_by_name/1" do
    test "with complete name", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)
      assert {:ok, accounts} = Bookkeeping.search_accounts_by_name(account.name)
      assert Enum.member?(accounts, account)
      name_prefix = String.slice(account.name, 0, 2)
      assert {:ok, accounts} = Bookkeeping.search_accounts_by_name(name_prefix)
      assert account in accounts
    end

    test "with name prefix", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)
      name_prefix = String.slice(account.name, 0, 2)
      assert {:ok, accounts} = Bookkeeping.search_accounts_by_name(name_prefix)
      assert account in accounts
    end

    test "with invalid name" do
      assert {:error, :invalid_name} = Bookkeeping.search_accounts_by_name(nil)
      assert {:error, :invalid_name} = Bookkeeping.search_accounts_by_name(%{})
      assert {:error, :invalid_name} = Bookkeeping.search_accounts_by_name("")
    end
  end

  describe "Bookkeeping search_accounts/1" do
    test "with complete name", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)
      assert {:ok, accounts} = Bookkeeping.search_accounts(account.name)
      assert Enum.member?(accounts, account)
      name_prefix = String.slice(account.name, 0, 2)
      assert {:ok, accounts} = Bookkeeping.search_accounts(name_prefix)
      assert account in accounts
    end

    test "with name prefix", %{params: params} do
      params = update_params(params)
      {:ok, account} = Bookkeeping.create_account(params)
      name_prefix = String.slice(account.name, 0, 2)
      assert {:ok, accounts} = Bookkeeping.search_accounts(name_prefix)
      assert account in accounts
    end

    test "with invalid name" do
      assert {:error, :invalid_name} = Bookkeeping.search_accounts(nil)
      assert {:error, :invalid_name} = Bookkeeping.search_accounts(%{})
      assert {:error, :invalid_name} = Bookkeeping.search_accounts("")
    end
  end

  ##########################################################
  # Accounting Journal Tests                               #
  ##########################################################

  defp update_params(params) do
    code = random_string()
    name = random_string()
    Map.merge(params, %{code: code, name: name})
  end

  defp random_string do
    for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>
  end
end
