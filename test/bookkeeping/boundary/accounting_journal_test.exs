defmodule Bookkeeping.Boundary.AccountingJournalTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Boundary.AccountingJournal.Backup, as: AccountingJournalBackup
  alias Bookkeeping.Boundary.AccountingJournal.Server, as: AccountingJournalServer
  alias Bookkeeping.Boundary.ChartOfAccounts.Server, as: ChartOfAccountsServer
  alias Bookkeeping.Core.Account

  setup do
    transaction_date = DateTime.utc_now()
    general_ledger_posting_date = DateTime.utc_now()
    journal_entry_number = "JE100100"
    transaction_reference_number = "INV100100"
    journal_entry_description = "journal entry description"
    audit_details = %{email: "example@example.com"}

    {:ok, cash_account} =
      Account.create("10_000", "cash", "asset", "cash description", %{})

    {:ok, revenue_account} =
      Account.create(
        "20_000",
        "sales revenue",
        "revenue",
        "sales revenue description",
        %{}
      )

    {:ok, other_revenue_account} =
      Account.create(
        "20_010",
        "service revenue",
        "revenue",
        "service revenue description",
        %{}
      )

    {:ok, inactive_revenue_account} = Account.update(other_revenue_account, %{active: false})

    t_accounts = %{
      left: [
        %{
          account: cash_account,
          amount: Decimal.new(100),
          line_item_description: "cash from service revenue"
        }
      ],
      right: [
        %{
          account: revenue_account,
          amount: Decimal.new(100),
          line_item_description: "service revenue"
        }
      ]
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

    {:ok,
     transaction_date: transaction_date,
     general_ledger_posting_date: general_ledger_posting_date,
     journal_entry_number: journal_entry_number,
     transaction_reference_number: transaction_reference_number,
     t_accounts: t_accounts,
     cash_account: cash_account,
     revenue_account: revenue_account,
     inactive_revenue_account: inactive_revenue_account,
     journal_entry_description: journal_entry_description,
     journal_entry_details: journal_entry_details,
     audit_details: audit_details,
     create_je_params: create_je_params}
  end

  test "start link" do
    {:ok, server} = AccountingJournalServer.start_link()
    assert server in Process.list()
  end

  test "create journal entry", %{create_je_params: create_je_params} do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_0")

    assert {:ok, journal_entry_0} =
             AccountingJournalServer.create_journal_entry(params)

    assert journal_entry_0.journal_entry_number == "ref_num_0"

    params = Map.put(create_je_params, :journal_entry_number, "ref_num_1")

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(params)

    assert journal_entry_1.journal_entry_number == "ref_num_1"
    assert journal_entry_1.journal_entry_description == "journal entry description"
    assert journal_entry_1.line_items |> length() == 2
    assert journal_entry_1.audit_logs
    assert journal_entry_1.posted == false
  end

  test "create multiple journal entries on the same day", %{create_je_params: create_je_params} do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_2")
    assert {:ok, journal_entry_2} = AccountingJournalServer.create_journal_entry(params)
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_3")

    assert {:ok, journal_entry_3} =
             AccountingJournalServer.create_journal_entry(params)

    other_transaction_date = DateTime.add(journal_entry_2.general_ledger_posting_date, 10, :day)

    params =
      create_je_params
      |> Map.put(:transaction_date, other_transaction_date)
      |> Map.put(:general_ledger_posting_date, other_transaction_date)
      |> Map.put(:journal_entry_number, "ref_num_4")

    assert {:ok, journal_entry_4} =
             AccountingJournalServer.create_journal_entry(params)

    assert {:ok, found_journal_entries} =
             journal_entry_2.general_ledger_posting_date
             |> AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date()

    assert Enum.member?(found_journal_entries, journal_entry_2)
    assert Enum.member?(found_journal_entries, journal_entry_3)
    refute Enum.member?(found_journal_entries, journal_entry_4)
  end

  test "do not create journal entries with duplicate reference numbers", %{
    create_je_params: create_je_params
  } do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_5")
    assert {:ok, _journal_entry_1} = AccountingJournalServer.create_journal_entry(params)
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_5")

    assert {:error, :duplicate_journal_entry_number} =
             AccountingJournalServer.create_journal_entry(params)
  end

  test "do not create journal entry with invalid inputs", %{
    cash_account: cash_account,
    revenue_account: revenue_account,
    inactive_revenue_account: inactive_revenue_account,
    create_je_params: create_je_params
  } do
    empty_t_accounts = %{left: [], right: []}

    invalid_t_accounts = %{
      left: [%{account: cash_account, amount: Decimal.new(100)}],
      right: [%{account: revenue_account, amount: Decimal.new(200)}]
    }

    params =
      create_je_params
      |> Map.put(:t_accounts, empty_t_accounts)
      |> Map.put(:journal_entry_number, "ref_num_6")

    assert {:error, :invalid_line_items} =
             AccountingJournalServer.create_journal_entry(params)

    params =
      create_je_params
      |> Map.put(:t_accounts, invalid_t_accounts)
      |> Map.put(:journal_entry_number, "ref_num_7")

    assert {:error, :unbalanced_line_items} =
             AccountingJournalServer.create_journal_entry(params)

    params =
      create_je_params
      |> Map.put(:journal_entry_description, nil)
      |> Map.put(:journal_entry_number, "invalid_je_1")

    assert {:error, :invalid_journal_entry} =
             AccountingJournalServer.create_journal_entry(params)

    params =
      create_je_params
      |> Map.put(:t_accounts, %{
        left: [%{account: cash_account, amount: Decimal.new(100)}],
        right: [%{account: inactive_revenue_account, amount: Decimal.new(200)}]
      })
      |> Map.put(:journal_entry_number, "invalid_je_2")

    assert {:error, [:inactive_account]} =
             AccountingJournalServer.create_journal_entry(params)

    params =
      create_je_params
      |> Map.put(:t_accounts, %{
        left: [%{account: cash_account, amount: Decimal.new(100)}],
        right: [%{account: revenue_account, amount: Decimal.new(200)}]
      })
      |> Map.put(:journal_entry_number, "invalid_je_2")

    assert {:error, :unbalanced_line_items} =
             AccountingJournalServer.create_journal_entry(params)

    params =
      create_je_params
      |> Map.put(:t_accounts, %{
        left: [%{account: cash_account, amount: Decimal.new(100)}],
        right: []
      })
      |> Map.put(:journal_entry_number, "invalid_je_2")

    assert {:error, :invalid_line_items} =
             AccountingJournalServer.create_journal_entry(params)
  end

  test "search all journal entries", %{create_je_params: create_je_params} do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_8")

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(params)

    params = Map.put(create_je_params, :journal_entry_number, "ref_num_9")

    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(params)

    assert {:ok, all_journal_entries} = AccountingJournalServer.all_journal_entries()

    assert is_list(all_journal_entries)
    assert Enum.member?(all_journal_entries, journal_entry_1)
    assert Enum.member?(all_journal_entries, journal_entry_2)
  end

  test "find journal entries by general ledger posting date", %{
    create_je_params: create_je_params
  } do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_10")

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(params)

    assert {:ok, je_result_1} =
             journal_entry_1.general_ledger_posting_date
             |> AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date()

    assert is_list(je_result_1)

    assert {:ok, je_result_2} =
             journal_entry_1.general_ledger_posting_date
             |> Map.take([:year, :month, :day])
             |> AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date()

    assert is_list(je_result_2)

    assert {:error, :invalid_date} =
             AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date(nil)
  end

  test "find journal entries by reference number", %{create_je_params: create_je_params} do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_11")

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(params)

    assert {:ok, found_journal_entry} =
             journal_entry_1.journal_entry_number
             |> AccountingJournalServer.find_journal_entry_by_journal_entry_number()

    assert found_journal_entry.journal_entry_number == journal_entry_1.journal_entry_number

    assert {:error, :not_found} =
             AccountingJournalServer.find_journal_entry_by_journal_entry_number("invalid_ref_num")

    assert {:error, :invalid_journal_entry_number} =
             AccountingJournalServer.find_journal_entry_by_journal_entry_number(nil)
  end

  test "find journal entries by id", %{create_je_params: create_je_params} do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_12")

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(params)

    assert {:ok, found_journal_entry} =
             AccountingJournalServer.find_journal_entries_by_id(journal_entry_1.id)

    assert found_journal_entry.id == journal_entry_1.id

    assert {:error, :not_found} =
             AccountingJournalServer.find_journal_entries_by_id("invalid_ref_num")

    assert {:error, :invalid_id} =
             AccountingJournalServer.find_journal_entries_by_id(nil)
  end

  test "find journal entries by general ledger posting date range", %{
    create_je_params: create_je_params
  } do
    assert {:ok, []} = AccountingJournalServer.reset_journal_entries()
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_13")

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(params)

    params = Map.put(create_je_params, :journal_entry_number, "ref_num_14")

    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(params)

    current_from_date_details =
      journal_entry_1.general_ledger_posting_date
      |> DateTime.add(-10, :day)
      |> Map.take([:year, :month, :day])

    current_to_date_details =
      journal_entry_2.general_ledger_posting_date
      |> DateTime.add(10, :day)
      |> Map.take([:year, :month, :day])

    assert {:ok, journal_entries} =
             AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date_range(
               current_from_date_details,
               current_to_date_details
             )

    assert journal_entries |> length() >= 2
    assert Enum.member?(journal_entries, journal_entry_1)
    assert Enum.member?(journal_entries, journal_entry_2)

    assert {:error, :invalid_date} =
             AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date_range(
               nil,
               journal_entry_1.general_ledger_posting_date
             )

    assert {:error, :invalid_date} =
             AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date_range(
               journal_entry_1.general_ledger_posting_date,
               nil
             )

    from_date_details =
      Map.take(journal_entry_1.general_ledger_posting_date, [:year, :month, :day])

    to_date_details = Map.take(journal_entry_2.general_ledger_posting_date, [:year, :month, :day])

    assert {:ok, journal_entries} =
             AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date_range(
               from_date_details,
               to_date_details
             )

    assert journal_entries |> length() >= 2
    assert Enum.member?(journal_entries, journal_entry_1)
    assert Enum.member?(journal_entries, journal_entry_2)

    past_from_date_details =
      journal_entry_1.general_ledger_posting_date
      |> DateTime.add(-100, :day)
      |> Map.take([:year, :month, :day])

    past_to_date_details =
      journal_entry_2.general_ledger_posting_date
      |> DateTime.add(-50, :day)
      |> Map.take([:year, :month, :day])

    assert {:ok, []} =
             AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date_range(
               past_from_date_details,
               past_to_date_details
             )

    future_from_date_details =
      journal_entry_1.general_ledger_posting_date
      |> DateTime.add(100, :day)
      |> Map.take([:year, :month, :day])

    future_to_date_details =
      journal_entry_2.general_ledger_posting_date
      |> DateTime.add(150, :day)
      |> Map.take([:year, :month, :day])

    assert {:ok, []} =
             AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date_range(
               future_from_date_details,
               future_to_date_details
             )
  end

  test "import journal entries" do
    assert {:ok, []} = ChartOfAccountsServer.reset_accounts()

    assert {:ok, _charts_of_accounts} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/data/valid_chart_of_accounts.csv"
             )

    # importing a valid file
    assert {:ok, %{ok: created_journals, error: []}} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/data/valid_journal_entries.csv"
             )

    journal_entry_descriptions =
      Enum.map(created_journals, fn journal_entry -> journal_entry.journal_entry_description end)

    assert Enum.member?(
             journal_entry_descriptions,
             "JE_1001_INV JE_1001_AP JE_1001_LTD JE_1001_STD JE_1001_C"
           )

    assert Enum.member?(journal_entry_descriptions, "JE_1007_INV")

    line_item_descriptions =
      created_journals
      |> Enum.map(fn journal_entry -> journal_entry.line_items end)
      |> List.flatten()
      |> Enum.map(fn line_item -> line_item.line_item_description end)

    assert Enum.member?(line_item_descriptions, "Bought a new property")
    assert Enum.member?(line_item_descriptions, "Bought additional inventory from AAA Company")
    assert Enum.member?(line_item_descriptions, "Remaining Payable amount")

    assert created_journals |> length() == 2

    # importing a journal entry with duplicate reference numbers and invalid accounts
    assert {:error, %{error: errors, ok: []}} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/data/valid_journal_entries.csv"
             )

    assert errors == [
             %{error: :duplicate_journal_entry_number, journal_entry_number: "1001"},
             %{error: :duplicate_journal_entry_number, journal_entry_number: "1007"}
           ]

    # importing a file with invalid journal entries
    assert {:error, %{errors: errors, message: :invalid_csv}} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/data/invalid_journal_entries.csv"
             )

    assert errors == [
             %{error: :invalid_date, journal_entry_number: "1003"},
             %{error: :invalid_csv_item, journal_entry_number: ""},
             %{error: :invalid_date, journal_entry_number: "1003"},
             %{error: :invalid_date, journal_entry_number: "1005"}
           ]

    # importing a missing file
    assert {:error, :invalid_file} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/data/missing_file.csv"
             )

    # importing a file with empty fields
    assert {:error, :invalid_file} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/data/empty_journal_entries.csv"
             )

    # importing a partially valid file
    assert {:ok, %{error: errors, ok: oks}} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/data/partially_valid_journal_entries.csv"
             )

    assert errors == [%{error: :unbalanced_line_items, journal_entry_number: "1009"}]
    assert Enum.count(oks) == 1
  end

  test "update accounting journal entry", %{
    cash_account: cash_account,
    revenue_account: revenue_account,
    create_je_params: create_je_params
  } do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_15")

    assert {:ok, journal_entry} =
             AccountingJournalServer.create_journal_entry(params)

    assert {:error, :invalid_journal_entry} =
             AccountingJournalServer.update_journal_entry(journal_entry, %{})

    additional_random_days = Enum.random(10..100)

    updated_general_ledger_posting_date =
      DateTime.add(journal_entry.general_ledger_posting_date, additional_random_days, :day)

    assert {:ok, updated_journal_entry} =
             AccountingJournalServer.update_journal_entry(journal_entry, %{
               general_ledger_posting_date: updated_general_ledger_posting_date,
               journal_entry_description: "second updated description",
               posted: false,
               t_accounts: %{
                 left: [%{account: revenue_account, amount: Decimal.new(200)}],
                 right: [%{account: cash_account, amount: Decimal.new(200)}]
               }
             })

    assert updated_journal_entry.id == journal_entry.id

    refute updated_journal_entry.general_ledger_posting_date ==
             journal_entry.general_ledger_posting_date

    assert updated_journal_entry.journal_entry_number == journal_entry.journal_entry_number
    assert updated_journal_entry.journal_entry_description == "second updated description"
    assert updated_journal_entry.posted == false
    assert updated_journal_entry.line_items |> length() == 2
    assert updated_journal_entry.audit_logs

    assert {:ok, third_journal_entry_update} =
             AccountingJournalServer.update_journal_entry(updated_journal_entry, %{
               journal_entry_description: "third updated description",
               posted: true,
               t_accounts: %{
                 left: [%{account: revenue_account, amount: Decimal.new(300)}],
                 right: [%{account: cash_account, amount: Decimal.new(300)}]
               }
             })

    assert third_journal_entry_update.id == journal_entry.id

    refute third_journal_entry_update.general_ledger_posting_date ==
             journal_entry.general_ledger_posting_date

    assert third_journal_entry_update.journal_entry_number == journal_entry.journal_entry_number
    assert third_journal_entry_update.journal_entry_description == "third updated description"
    assert third_journal_entry_update.posted == true
    assert third_journal_entry_update.line_items |> length() == 2
    assert third_journal_entry_update.audit_logs

    assert {:error, :already_posted_journal_entry} =
             AccountingJournalServer.update_journal_entry(third_journal_entry_update, %{
               journal_entry_description: "fourth updated description",
               posted: false,
               t_accounts: %{
                 left: [%{account: revenue_account, amount: Decimal.new(400)}],
                 right: [%{account: cash_account, amount: Decimal.new(400)}]
               }
             })

    assert {:ok, journal_entries} =
             journal_entry.general_ledger_posting_date
             |> AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date()

    refute Enum.member?(journal_entries, journal_entry)
    refute Enum.member?(journal_entries, updated_journal_entry)
    refute Enum.member?(journal_entries, third_journal_entry_update)

    assert {:ok, journal_entries} =
             updated_journal_entry.general_ledger_posting_date
             |> AccountingJournalServer.find_journal_entries_by_general_ledger_posting_date()

    refute Enum.member?(journal_entries, journal_entry)
    refute Enum.member?(journal_entries, updated_journal_entry)
    assert Enum.member?(journal_entries, third_journal_entry_update)
  end

  test "reset journal entries", %{create_je_params: create_je_params} do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_16")

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(params)

    params = Map.put(create_je_params, :journal_entry_number, "ref_num_17")

    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(params)

    assert {:ok, journal_entries} = AccountingJournalServer.all_journal_entries()
    assert Enum.member?(journal_entries, journal_entry_1)
    assert Enum.member?(journal_entries, journal_entry_2)

    assert {:ok, []} = AccountingJournalServer.reset_journal_entries()

    assert {:ok, journal_entries} = AccountingJournalServer.all_journal_entries()
    refute Enum.member?(journal_entries, journal_entry_1)
    refute Enum.member?(journal_entries, journal_entry_2)
  end

  test "get accounting journal state" do
    assert {:ok, state} = AccountingJournalServer.get_accounting_journal_state()
    assert is_map(state) == true
  end

  test "test accounting journal with working backup", %{create_je_params: create_je_params} do
    params = Map.put(create_je_params, :journal_entry_number, "ref_num_18")

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(params)

    params = Map.put(create_je_params, :journal_entry_number, "ref_num_19")

    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(params)

    assert {:ok, journal_entries} = AccountingJournalServer.all_journal_entries()
    assert Enum.member?(journal_entries, journal_entry_1)
    assert Enum.member?(journal_entries, journal_entry_2)
    assert {:ok, backup} = AccountingJournalBackup.get()
    assert backup == %{}
    assert {:ok, :backup_updated} = AccountingJournalBackup.update(journal_entries)
    assert {:ok, backup} = AccountingJournalBackup.get()
    assert backup == journal_entries

    assert {:ok, :backup_updated} = AccountingJournalServer.terminate(:normal, %{})
  end
end
