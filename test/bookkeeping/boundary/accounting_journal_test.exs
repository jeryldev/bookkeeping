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
    description = "journal entry description"
    audit_details = %{email: "example@example.com"}

    {:ok, cash_account} =
      Account.create("10_000", "cash", "asset", "cash account description", %{})

    {:ok, revenue_account} =
      Account.create(
        "20_000",
        "sales revenue",
        "revenue",
        "sales revenue account description",
        %{}
      )

    {:ok, other_revenue_account} =
      Account.create(
        "20_010",
        "service revenue",
        "revenue",
        "service revenue account description",
        %{}
      )

    {:ok, inactive_revenue_account} = Account.update(other_revenue_account, %{active: false})

    t_accounts = %{
      left: [%{account: cash_account, amount: Decimal.new(100)}],
      right: [%{account: revenue_account, amount: Decimal.new(100)}]
    }

    journal_entry_details = %{approved_by: "John Doe", approved_at: DateTime.utc_now()}

    {:ok,
     transaction_date: transaction_date,
     general_ledger_posting_date: general_ledger_posting_date,
     journal_entry_number: journal_entry_number,
     transaction_reference_number: transaction_reference_number,
     t_accounts: t_accounts,
     cash_account: cash_account,
     revenue_account: revenue_account,
     inactive_revenue_account: inactive_revenue_account,
     description: description,
     journal_entry_details: journal_entry_details,
     audit_details: audit_details}
  end

  test "start link" do
    {:ok, server} = AccountingJournalServer.start_link()
    assert server in Process.list()
  end

  test "create journal entry", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_0} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_0"
             )

    assert journal_entry_0.journal_entry_number == "ref_num_0"

    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_1",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert journal_entry_1.journal_entry_number == "ref_num_1"
    assert journal_entry_1.description == "journal entry description"
    assert journal_entry_1.line_items |> length() == 2
    assert journal_entry_1.audit_logs
    assert journal_entry_1.posted == false
  end

  test "create multiple journal entries on the same day", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_2",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, journal_entry_3} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_3",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    other_transaction_date = DateTime.add(journal_entry_2.transaction_date, 10, :day)

    assert {:ok, journal_entry_4} =
             AccountingJournalServer.create_journal_entry(
               other_transaction_date,
               other_transaction_date,
               t_accounts,
               "ref_num_4",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, found_journal_entries} =
             journal_entry_2.transaction_date
             |> AccountingJournalServer.find_journal_entries_by_transaction_date()

    assert Enum.member?(found_journal_entries, journal_entry_2)
    assert Enum.member?(found_journal_entries, journal_entry_3)
    refute Enum.member?(found_journal_entries, journal_entry_4)
  end

  test "do not create journal entries with duplicate reference numbers", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, _journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_5",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:error, :duplicate_journal_entry_number} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_5",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )
  end

  test "do not create journal entry with invalid inputs", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    cash_account: cash_account,
    revenue_account: revenue_account,
    inactive_revenue_account: inactive_revenue_account,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    empty_t_accounts = %{left: [], right: []}

    invalid_t_accounts = %{
      left: [%{account: cash_account, amount: Decimal.new(100)}],
      right: [%{account: revenue_account, amount: Decimal.new(200)}]
    }

    assert {:error, :invalid_line_items} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               empty_t_accounts,
               "ref_num_6",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:error, :unbalanced_line_items} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               invalid_t_accounts,
               "ref_num_7",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:error, :invalid_journal_entry} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "invalid_je_1",
               transaction_reference_number,
               nil,
               journal_entry_details,
               audit_details
             )

    assert {:error, [:inactive_account]} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: cash_account, amount: Decimal.new(100)}],
                 right: [%{account: inactive_revenue_account, amount: Decimal.new(200)}]
               },
               "invalid_je_2",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:error, :unbalanced_line_items} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: cash_account, amount: Decimal.new(100)}],
                 right: [%{account: revenue_account, amount: Decimal.new(200)}]
               },
               "invalid_je_2",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:error, :invalid_line_items} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: cash_account, amount: Decimal.new(100)}],
                 right: []
               },
               "invalid_je_2",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )
  end

  test "search all journal entries", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_8",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_9",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, all_journal_entries} = AccountingJournalServer.all_journal_entries()

    assert is_list(all_journal_entries)
    assert Enum.member?(all_journal_entries, journal_entry_1)
    assert Enum.member?(all_journal_entries, journal_entry_2)
  end

  test "find journal entries by transaction date", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_10",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, je_result_1} =
             journal_entry_1.transaction_date
             |> AccountingJournalServer.find_journal_entries_by_transaction_date()

    assert is_list(je_result_1)

    assert {:ok, je_result_2} =
             journal_entry_1.transaction_date
             |> Map.take([:year, :month])
             |> AccountingJournalServer.find_journal_entries_by_transaction_date()

    assert is_list(je_result_2)

    assert {:error, :invalid_date} =
             AccountingJournalServer.find_journal_entries_by_transaction_date(nil)
  end

  test "find journal entries by reference number", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_11",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, found_journal_entry} =
             journal_entry_1.journal_entry_number
             |> AccountingJournalServer.find_journal_entry_by_journal_entry_number()

    assert found_journal_entry.journal_entry_number == journal_entry_1.journal_entry_number

    assert {:error, :not_found} =
             AccountingJournalServer.find_journal_entry_by_journal_entry_number("invalid_ref_num")

    assert {:error, :invalid_journal_entry_number} =
             AccountingJournalServer.find_journal_entry_by_journal_entry_number(nil)
  end

  test "find journal entries by id", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_12",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, found_journal_entry} =
             AccountingJournalServer.find_journal_entries_by_id(journal_entry_1.id)

    assert found_journal_entry.id == journal_entry_1.id

    assert {:error, :not_found} =
             AccountingJournalServer.find_journal_entries_by_id("invalid_ref_num")

    assert {:error, :invalid_id} =
             AccountingJournalServer.find_journal_entries_by_id(nil)
  end

  test "find journal entries by transaction date range", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_13",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_14",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    current_from_date_details =
      journal_entry_1.transaction_date
      |> DateTime.add(-10, :day)
      |> Map.take([:year, :month])

    current_to_date_details =
      journal_entry_2.transaction_date
      |> DateTime.add(10, :day)
      |> Map.take([:year, :month])

    assert {:ok, journal_entries} =
             AccountingJournalServer.find_journal_entries_by_transaction_date_range(
               current_from_date_details,
               current_to_date_details
             )

    assert journal_entries |> length() >= 2
    assert Enum.member?(journal_entries, journal_entry_1)
    assert Enum.member?(journal_entries, journal_entry_2)

    assert {:error, :invalid_date} =
             AccountingJournalServer.find_journal_entries_by_transaction_date_range(
               nil,
               journal_entry_1.transaction_date
             )

    assert {:error, :invalid_date} =
             AccountingJournalServer.find_journal_entries_by_transaction_date_range(
               journal_entry_1.transaction_date,
               nil
             )

    from_date_details = Map.take(journal_entry_1.transaction_date, [:year, :month])
    to_date_details = Map.take(journal_entry_2.transaction_date, [:year, :month])

    assert {:ok, journal_entries} =
             AccountingJournalServer.find_journal_entries_by_transaction_date_range(
               from_date_details,
               to_date_details
             )

    assert journal_entries |> length() >= 2
    assert Enum.member?(journal_entries, journal_entry_1)
    assert Enum.member?(journal_entries, journal_entry_2)

    past_from_date_details =
      journal_entry_1.transaction_date
      |> DateTime.add(-100, :day)
      |> Map.take([:year, :month])

    past_to_date_details =
      journal_entry_2.transaction_date
      |> DateTime.add(-50, :day)
      |> Map.take([:year, :month])

    assert {:ok, []} =
             AccountingJournalServer.find_journal_entries_by_transaction_date_range(
               past_from_date_details,
               past_to_date_details
             )

    future_from_date_details =
      journal_entry_1.transaction_date
      |> DateTime.add(100, :day)
      |> Map.take([:year, :month])

    future_to_date_details =
      journal_entry_2.transaction_date
      |> DateTime.add(150, :day)
      |> Map.take([:year, :month])

    assert {:ok, []} =
             AccountingJournalServer.find_journal_entries_by_transaction_date_range(
               future_from_date_details,
               future_to_date_details
             )
  end

  test "import journal entries" do
    assert {:ok, []} = ChartOfAccountsServer.reset_accounts()

    assert {:ok, _charts_of_accounts} =
             ChartOfAccountsServer.import_accounts(
               "../../../../test/bookkeeping/assets/valid_chart_of_accounts.csv"
             )

    # importing a valid file
    assert {:ok, %{ok: created_journals, error: []}} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/assets/valid_journal_entries.csv"
             )

    assert created_journals |> length() == 2

    # importing a journal entry with duplicate reference numbers and invalid accounts
    assert {:error, %{error: errors, ok: []}} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/assets/valid_journal_entries.csv"
             )

    assert errors == [
             %{error: :duplicate_journal_entry_number, journal_entry_number: "1001"},
             %{error: :duplicate_journal_entry_number, journal_entry_number: "1007"}
           ]

    # importing a file with invalid journal entries
    assert {:error, %{errors: errors, message: :invalid_csv}} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/assets/invalid_journal_entries.csv"
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
               "../../../../test/bookkeeping/assets/missing_file.csv"
             )

    # importing a file with empty fields
    assert {:error, :invalid_file} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/assets/empty_journal_entries.csv"
             )

    # importing a partially valid file
    assert {:ok, %{error: errors, ok: oks}} =
             AccountingJournalServer.import_journal_entries(
               "../../../../test/bookkeeping/assets/partially_valid_journal_entries.csv"
             )

    assert errors == [%{error: :unbalanced_line_items, journal_entry_number: "1009"}]
    assert Enum.count(oks) == 1
  end

  test "update accounting journal entry", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    cash_account: cash_account,
    revenue_account: revenue_account,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_15",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:error, :invalid_journal_entry} =
             AccountingJournalServer.update_journal_entry(journal_entry, %{})

    additional_random_days = Enum.random(10..100)

    updated_transaction_date =
      DateTime.add(journal_entry.transaction_date, additional_random_days, :day)

    assert {:ok, updated_journal_entry} =
             AccountingJournalServer.update_journal_entry(journal_entry, %{
               transaction_date: updated_transaction_date,
               description: "second updated description",
               posted: false,
               t_accounts: %{
                 left: [%{account: revenue_account, amount: Decimal.new(200)}],
                 right: [%{account: cash_account, amount: Decimal.new(200)}]
               }
             })

    assert updated_journal_entry.id == journal_entry.id
    refute updated_journal_entry.transaction_date == journal_entry.transaction_date
    assert updated_journal_entry.journal_entry_number == journal_entry.journal_entry_number
    assert updated_journal_entry.description == "second updated description"
    assert updated_journal_entry.posted == false
    assert updated_journal_entry.line_items |> length() == 2
    assert updated_journal_entry.audit_logs

    assert {:ok, third_journal_entry_update} =
             AccountingJournalServer.update_journal_entry(updated_journal_entry, %{
               description: "third updated description",
               posted: true,
               t_accounts: %{
                 left: [%{account: revenue_account, amount: Decimal.new(300)}],
                 right: [%{account: cash_account, amount: Decimal.new(300)}]
               }
             })

    assert third_journal_entry_update.id == journal_entry.id
    refute third_journal_entry_update.transaction_date == journal_entry.transaction_date
    assert third_journal_entry_update.journal_entry_number == journal_entry.journal_entry_number
    assert third_journal_entry_update.description == "third updated description"
    assert third_journal_entry_update.posted == true
    assert third_journal_entry_update.line_items |> length() == 2
    assert third_journal_entry_update.audit_logs

    assert {:error, :already_posted_journal_entry} =
             AccountingJournalServer.update_journal_entry(third_journal_entry_update, %{
               description: "fourth updated description",
               posted: false,
               t_accounts: %{
                 left: [%{account: revenue_account, amount: Decimal.new(400)}],
                 right: [%{account: cash_account, amount: Decimal.new(400)}]
               }
             })

    assert {:ok, journal_entries} =
             journal_entry.transaction_date
             |> AccountingJournalServer.find_journal_entries_by_transaction_date()

    refute Enum.member?(journal_entries, journal_entry)
    refute Enum.member?(journal_entries, updated_journal_entry)
    refute Enum.member?(journal_entries, third_journal_entry_update)

    assert {:ok, journal_entries} =
             updated_journal_entry.transaction_date
             |> AccountingJournalServer.find_journal_entries_by_transaction_date()

    refute Enum.member?(journal_entries, journal_entry)
    refute Enum.member?(journal_entries, updated_journal_entry)
    assert Enum.member?(journal_entries, third_journal_entry_update)
  end

  test "reset journal entries", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_16",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_17",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, journal_entries} = AccountingJournalServer.all_journal_entries()
    assert Enum.member?(journal_entries, journal_entry_1)
    assert Enum.member?(journal_entries, journal_entry_2)

    assert {:ok, []} = AccountingJournalServer.reset_journal_entries()

    assert {:ok, journal_entries} = AccountingJournalServer.all_journal_entries()
    refute Enum.member?(journal_entries, journal_entry_1)
    refute Enum.member?(journal_entries, journal_entry_2)
  end

  test "test accounting journal with working backup", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    transaction_reference_number: transaction_reference_number,
    description: description,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_18",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

    assert {:ok, journal_entry_2} =
             AccountingJournalServer.create_journal_entry(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               "ref_num_19",
               transaction_reference_number,
               description,
               journal_entry_details,
               audit_details
             )

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
