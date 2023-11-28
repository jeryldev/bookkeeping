defmodule BookkeepingTest do
  use ExUnit.Case
  alias Bookkeeping
  alias Bookkeeping.Core.{Account, JournalEntry}

  test "create account" do
    assert {:ok, _account} =
             Bookkeeping.create_account(
               "1000_bookkeeping_test",
               "Cash_bookkeeping_test",
               "asset",
               "Cash in Bank",
               %{}
             )

    assert {:error, :account_already_exists} =
             Bookkeeping.create_account(
               "1000_bookkeeping_test",
               "Cash_bookkeeping_test",
               "asset",
               "Cash in Bank",
               %{}
             )
  end

  test "import accounts" do
    assert {:ok, []} = Bookkeeping.reset_accounts()
    assert {:ok, []} = Bookkeeping.all_accounts()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_accounts(
               "../../../../test/bookkeeping/data/valid_bookkeeping_accounts.csv"
             )

    assert {:error, :invalid_file} =
             Bookkeeping.import_accounts("test/bookkeeping/data/valid_bookkeeping_accounts.csv")
  end

  test "update account" do
    assert {:ok, account} =
             Bookkeeping.create_account(
               "1000_bookkeeping_test_for_update",
               "Cash_bookkeeping_test_for_update",
               "asset",
               "Cash in Bank",
               %{}
             )

    assert {:ok, _account} =
             Bookkeeping.update_account(
               account,
               %{name: "Cash_bookkeeping_test_updated"}
             )

    assert {:error, :invalid_account} =
             Bookkeeping.update_account(
               %Account{},
               %{name: "Cash_bookkeeping_test_updated"}
             )
  end

  test "all accounts" do
    assert {:ok, _accounts} = Bookkeeping.all_accounts()
  end

  test "find account by code" do
    assert {:ok, _account} =
             Bookkeeping.create_account(
               "1000_bookkeeping_test_for_find_by_code",
               "Cash_bookkeeping_test_for_find_by_code",
               "asset",
               "Cash in Bank",
               %{}
             )

    assert {:ok, _account} =
             Bookkeeping.find_account_by_code("1000_bookkeeping_test_for_find_by_code")

    assert {:error, :not_found} =
             Bookkeeping.find_account_by_code("1000_bookkeeping_test_for_find_by_code_not_found")
  end

  test "find account by name" do
    assert {:ok, _account} =
             Bookkeeping.create_account(
               "1000_bookkeeping_test_for_find_by_name",
               "Cash_bookkeeping_test_for_find_by_name",
               "asset",
               "Cash in Bank",
               %{}
             )

    assert {:ok, _account} =
             Bookkeeping.find_account_by_name("Cash_bookkeeping_test_for_find_by_name")

    assert {:error, :not_found} =
             Bookkeeping.find_account_by_name("Cash_bookkeeping_test_for_find_by_name_not_found")
  end

  test "search accounts" do
    assert {:ok, _accounts} = Bookkeeping.search_accounts("Cash_bookkeeping_test")
  end

  test "all sorted accounts" do
    assert {:ok, _accounts} = Bookkeeping.all_sorted_accounts("code")
    assert {:ok, _accounts} = Bookkeeping.all_sorted_accounts("name")
    assert {:error, :invalid_field} = Bookkeeping.all_sorted_accounts("classification")
    assert {:error, :invalid_field} = Bookkeeping.all_sorted_accounts(nil)
  end

  test "reset accounts" do
    assert {:ok, _accounts} = Bookkeeping.reset_accounts()
  end

  test "get chart of accounts state" do
    assert {:ok, state} = Bookkeeping.get_chart_of_accounts_state()
    assert is_map(state)
  end

  test "create journal entry" do
    transaction_date = DateTime.utc_now()
    general_ledger_posting_date = DateTime.utc_now()
    journal_entry_number = "JE100100_Bookkeeping_Test"
    transaction_reference_number = "INV100100"
    journal_entry_description = "journal entry description"
    audit_details = %{email: "example@example.com"}

    assert {:ok, cash_account} =
             Bookkeeping.create_account(
               "1000_000_bookkeeping_test",
               "1000_000_Cash_bookkeeping_test",
               "asset",
               "Cash in Bank",
               %{}
             )

    {:ok, revenue_account} =
      Bookkeeping.create_account(
        "20_000_000_bookkeeping_test",
        "20_000_000_Sales_revenue_bookkeeping_test",
        "revenue",
        "sales revenue description",
        %{}
      )

    t_accounts = %{
      left: [%{account: cash_account, amount: Decimal.new(100)}],
      right: [%{account: revenue_account, amount: Decimal.new(100)}]
    }

    journal_entry_details = %{approved_by: "John Doe", approved_at: DateTime.utc_now()}

    create_je_params = %{
      transaction_date: transaction_date,
      general_ledger_posting_date: general_ledger_posting_date,
      t_accounts: t_accounts,
      journal_entry_number: journal_entry_number,
      transaction_reference_number: transaction_reference_number,
      journal_entry_description: journal_entry_description,
      journal_entry_details: journal_entry_details,
      audit_details: audit_details
    }

    assert {:ok, _journal_entry_0} = Bookkeeping.create_journal_entry(create_je_params)

    assert {:error, :duplicate_journal_entry_number} =
             Bookkeeping.create_journal_entry(create_je_params)
  end

  test "import journal entries" do
    assert {:ok, _accounts} = Bookkeeping.reset_accounts()
    assert {:ok, []} = Bookkeeping.all_accounts()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_accounts(
               "../../../../test/bookkeeping/data/valid_bookkeeping_accounts.csv"
             )

    assert {:ok, []} = Bookkeeping.reset_journal_entries()
    assert {:ok, []} = Bookkeeping.all_journal_entries()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_journal_entries(
               "../../../../test/bookkeeping/data/valid_bookkeeping_journal_entries.csv"
             )

    assert {:error, :invalid_file} =
             Bookkeeping.import_journal_entries(
               "test/bookkeeping/data/valid_bookkeeping_journal_entries.csv"
             )
  end

  test "all journal entries" do
    assert {:ok, _journal_entries} = Bookkeeping.all_journal_entries()
  end

  test "find journal entry by journal entry number" do
    assert {:ok, _accounts} = Bookkeeping.reset_accounts()
    assert {:ok, []} = Bookkeeping.all_accounts()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_accounts(
               "../../../../test/bookkeeping/data/valid_bookkeeping_accounts.csv"
             )

    assert {:ok, []} = Bookkeeping.reset_journal_entries()
    assert {:ok, []} = Bookkeeping.all_journal_entries()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_journal_entries(
               "../../../../test/bookkeeping/data/valid_bookkeeping_journal_entries.csv"
             )

    assert {:ok, _journal_entry} =
             Bookkeeping.find_journal_entry_by_journal_entry_number("1001_Bookkeeping_Test")

    assert {:error, :not_found} =
             Bookkeeping.find_journal_entry_by_journal_entry_number(
               "JE100100_Bookkeeping_Test_not_found"
             )
  end

  test "find journal entry by journal entry id" do
    assert {:ok, _accounts} = Bookkeeping.reset_accounts()
    assert {:ok, []} = Bookkeeping.all_accounts()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_accounts(
               "../../../../test/bookkeeping/data/valid_bookkeeping_accounts.csv"
             )

    assert {:ok, []} = Bookkeeping.reset_journal_entries()
    assert {:ok, []} = Bookkeeping.all_journal_entries()

    assert {:ok, %{ok: ok, error: _error}} =
             Bookkeeping.import_journal_entries(
               "../../../../test/bookkeeping/data/valid_bookkeeping_journal_entries.csv"
             )

    first_journal_entry_id = ok |> List.first() |> Map.get(:id)

    assert {:ok, journal_entry} = Bookkeeping.find_journal_entries_by_id(first_journal_entry_id)
    assert journal_entry.id == first_journal_entry_id
    assert {:error, :invalid_id} = Bookkeeping.find_journal_entries_by_id(nil)
  end

  test "find journal entries by general ledger posting date" do
    assert {:ok, _accounts} = Bookkeeping.reset_accounts()
    assert {:ok, []} = Bookkeeping.all_accounts()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_accounts(
               "../../../../test/bookkeeping/data/valid_bookkeeping_accounts.csv"
             )

    assert {:ok, []} = Bookkeeping.reset_journal_entries()
    assert {:ok, []} = Bookkeeping.all_journal_entries()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_journal_entries(
               "../../../../test/bookkeeping/data/valid_bookkeeping_journal_entries.csv"
             )

    assert {:ok, []} =
             Bookkeeping.find_journal_entries_by_general_ledger_posting_date(DateTime.utc_now())

    {:ok, datetime, _} = DateTime.from_iso8601("2023-08-12T00:00:00Z")

    assert {:ok, journal_entries} =
             Bookkeeping.find_journal_entries_by_general_ledger_posting_date(datetime)

    refute journal_entries == []
    assert length(journal_entries) == 2

    assert {:error, :invalid_date} =
             Bookkeeping.find_journal_entries_by_general_ledger_posting_date("invalid_date")
  end

  test "find journal entries by general ledger posting date range" do
    assert {:ok, _accounts} = Bookkeeping.reset_accounts()
    assert {:ok, []} = Bookkeeping.all_accounts()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_accounts(
               "../../../../test/bookkeeping/data/valid_bookkeeping_accounts.csv"
             )

    assert {:ok, []} = Bookkeeping.reset_journal_entries()
    assert {:ok, []} = Bookkeeping.all_journal_entries()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_journal_entries(
               "../../../../test/bookkeeping/data/valid_bookkeeping_journal_entries.csv"
             )

    assert {:ok, []} =
             Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(
               DateTime.utc_now(),
               DateTime.utc_now()
             )

    {:ok, datetime, _} = DateTime.from_iso8601("2023-08-11T00:00:00Z")

    assert {:ok, journal_entries} =
             Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(
               datetime,
               DateTime.utc_now()
             )

    assert journal_entries != []
    assert length(journal_entries) == 2

    {:ok, datetime, _} = DateTime.from_iso8601("2023-08-12T00:00:00Z")

    assert {:ok, journal_entries_2} =
             Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(
               datetime,
               %{year: 2023, month: 9, day: 1}
             )

    assert journal_entries_2 != []
    assert length(journal_entries_2) == 2

    assert {:error, :invalid_date} =
             Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(
               "invalid_date",
               DateTime.utc_now()
             )

    assert {:error, :invalid_date} =
             Bookkeeping.find_journal_entries_by_general_ledger_posting_date_range(
               DateTime.utc_now(),
               "invalid_date"
             )
  end

  test "update journal entry" do
    assert {:ok, _accounts} = Bookkeeping.reset_accounts()
    assert {:ok, []} = Bookkeeping.all_accounts()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_accounts(
               "../../../../test/bookkeeping/data/valid_bookkeeping_accounts.csv"
             )

    assert {:ok, []} = Bookkeeping.reset_journal_entries()
    assert {:ok, []} = Bookkeeping.all_journal_entries()

    assert {:ok, %{ok: _ok, error: _error}} =
             Bookkeeping.import_journal_entries(
               "../../../../test/bookkeeping/data/valid_bookkeeping_journal_entries.csv"
             )

    assert {:ok, journal_entry} =
             Bookkeeping.find_journal_entry_by_journal_entry_number("1001_Bookkeeping_Test")

    assert {:ok, journal_entry} =
             Bookkeeping.update_journal_entry(
               journal_entry,
               %{journal_entry_description: "updated journal entry description"}
             )

    assert {:ok, first_journal_entry_update} =
             Bookkeeping.update_journal_entry(
               journal_entry,
               %{
                 journal_entry_description: "first journal entry description update",
                 posted: true
               }
             )

    assert {:error, :already_posted_journal_entry} =
             Bookkeeping.update_journal_entry(
               first_journal_entry_update,
               %{journal_entry_description: "second journal entry description update"}
             )

    assert {:error, :invalid_journal_entry} =
             Bookkeeping.update_journal_entry(
               %JournalEntry{},
               %{journal_entry_description: "updated journal entry description", posted: true}
             )
  end

  test "reset journal entries" do
    assert {:ok, _journal_entries} = Bookkeeping.reset_journal_entries()
  end

  test "get accounting journal state" do
    assert {:ok, state} = Bookkeeping.get_accounting_journal_state()
    assert is_map(state)
  end
end
