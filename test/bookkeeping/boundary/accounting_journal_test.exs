defmodule Bookkeeping.Boundary.AccountingJournalTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Boundary.AccountingJournal
  alias Bookkeeping.Core.Account

  setup do
    details = %{email: "example@example.com"}

    {:ok, cash_account} =
      Account.create("10_000", "cash", "asset", "cash account description", %{})

    {:ok, expense_account} =
      Account.create("20_000", "expense", "expense", "expense account description", %{})

    t_accounts = %{
      left: [%{account: expense_account, amount: Decimal.new(100)}],
      right: [%{account: cash_account, amount: Decimal.new(100)}]
    }

    {:ok,
     details: details,
     cash_account: cash_account,
     expense_account: expense_account,
     t_accounts: t_accounts}
  end

  test "start link" do
    {:error, {:already_started, server}} = AccountingJournal.start_link()
    assert server in Process.list()
  end

  test "create journal entry", %{
    details: details,
    t_accounts: t_accounts
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_1",
               "journal entry description",
               t_accounts,
               details
             )

    assert journal_entry_1.reference_number == "ref_num_1"
    assert journal_entry_1.description == "journal entry description"
    assert journal_entry_1.line_items |> length() == 2
    assert journal_entry_1.audit_logs
    assert journal_entry_1.posted == false
  end

  test "create multiple journal entries on the same day", %{
    details: details,
    t_accounts: t_accounts
  } do
    assert {:ok, journal_entry_2} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_2",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:ok, journal_entry_3} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_3",
               "journal entry description",
               t_accounts,
               details
             )

    other_transaction_date = DateTime.add(journal_entry_2.transaction_date, 10, :day)

    assert {:ok, journal_entry_4} =
             AccountingJournal.create_journal_entry(
               other_transaction_date,
               "ref_num_4",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:ok, found_journal_entries} =
             AccountingJournal.find_journal_entries_by_transaction_date(
               journal_entry_2.transaction_date
             )

    assert Enum.member?(found_journal_entries, journal_entry_2)
    assert Enum.member?(found_journal_entries, journal_entry_3)
    refute Enum.member?(found_journal_entries, journal_entry_4)
  end

  test "do not create journal entries with duplicate reference numbers", %{
    details: details,
    t_accounts: t_accounts
  } do
    assert {:ok, _journal_entry_1} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_5",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:error, :duplicate_reference_number} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_5",
               "journal entry description",
               t_accounts,
               details
             )
  end

  test "do not create journal entry with invalid inputs", %{
    details: details,
    cash_account: cash_account,
    expense_account: expense_account,
    t_accounts: t_accounts
  } do
    empty_t_accounts = %{left: [], right: []}

    invalid_t_accounts = %{
      left: [%{account: expense_account, amount: Decimal.new(100)}],
      right: [%{account: cash_account, amount: Decimal.new(200)}]
    }

    assert {:error, :invalid_line_items} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_6",
               "journal entry description",
               empty_t_accounts,
               details
             )

    assert {:error, :unbalanced_line_items} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_7",
               "journal entry description",
               invalid_t_accounts,
               details
             )

    assert {:error, :invalid_journal_entry} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "invalid_je_1",
               nil,
               t_accounts,
               details
             )
  end

  test "search all journal entries", %{details: details, t_accounts: t_accounts} do
    assert {:ok, journal_entry_1} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_8",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:ok, journal_entry_2} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_9",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:ok, all_journal_entries} = AccountingJournal.all_journal_entries()

    assert is_list(all_journal_entries)
    assert Enum.member?(all_journal_entries, journal_entry_1)
    assert Enum.member?(all_journal_entries, journal_entry_2)
  end

  test "find journal entries by transaction date", %{
    details: details,
    t_accounts: t_accounts
  } do
    assert {:ok, journal_entry_1} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_10",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:ok, filtered_journal_entries_1} =
             AccountingJournal.find_journal_entries_by_transaction_date(
               journal_entry_1.transaction_date
             )

    assert is_list(filtered_journal_entries_1)

    assert {:error, :invalid_transaction_date} =
             AccountingJournal.find_journal_entries_by_transaction_date(nil)
  end

  test "find journal entries by reference number", %{details: details, t_accounts: t_accounts} do
    assert {:ok, journal_entry_1} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_11",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:ok, found_journal_entry} =
             AccountingJournal.find_journal_entry_by_reference_number(
               journal_entry_1.reference_number
             )

    assert found_journal_entry.reference_number == journal_entry_1.reference_number

    assert {:error, :not_found} =
             AccountingJournal.find_journal_entry_by_reference_number("invalid_ref_num")

    assert {:error, :invalid_reference_number} =
             AccountingJournal.find_journal_entry_by_reference_number(nil)
  end

  test "find journal entries by id", %{details: details, t_accounts: t_accounts} do
    assert {:ok, journal_entry_1} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_12",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:ok, found_journal_entry} =
             AccountingJournal.find_journal_entries_by_id(journal_entry_1.id)

    assert found_journal_entry.id == journal_entry_1.id

    assert {:error, :not_found} =
             AccountingJournal.find_journal_entries_by_id("invalid_ref_num")

    assert {:error, :invalid_id} =
             AccountingJournal.find_journal_entries_by_id(nil)
  end

  test "update accounting journal entry", %{
    details: details,
    cash_account: cash_account,
    expense_account: expense_account,
    t_accounts: t_accounts
  } do
    assert {:ok, journal_entry} =
             AccountingJournal.create_journal_entry(
               DateTime.utc_now(),
               "ref_num_13",
               "journal entry description",
               t_accounts,
               details
             )

    assert {:error, :invalid_journal_entry} =
             AccountingJournal.update_journal_entry(journal_entry, %{})

    additional_random_days = Enum.random(10..100)

    updated_transaction_date =
      DateTime.add(journal_entry.transaction_date, additional_random_days, :day)

    assert {:ok, updated_journal_entry} =
             AccountingJournal.update_journal_entry(journal_entry, %{
               transaction_date: updated_transaction_date,
               description: "second updated description",
               posted: false,
               t_accounts: %{
                 left: [%{account: expense_account, amount: Decimal.new(200)}],
                 right: [%{account: cash_account, amount: Decimal.new(200)}]
               }
             })

    assert updated_journal_entry.id == journal_entry.id
    refute updated_journal_entry.transaction_date == journal_entry.transaction_date
    assert updated_journal_entry.reference_number == journal_entry.reference_number
    assert updated_journal_entry.description == "second updated description"
    assert updated_journal_entry.posted == false
    assert updated_journal_entry.line_items |> length() == 2
    assert updated_journal_entry.audit_logs

    assert {:ok, third_journal_entry_update} =
             AccountingJournal.update_journal_entry(updated_journal_entry, %{
               description: "third updated description",
               posted: true,
               t_accounts: %{
                 left: [%{account: expense_account, amount: Decimal.new(300)}],
                 right: [%{account: cash_account, amount: Decimal.new(300)}]
               }
             })

    assert third_journal_entry_update.id == journal_entry.id
    refute third_journal_entry_update.transaction_date == journal_entry.transaction_date
    assert third_journal_entry_update.reference_number == journal_entry.reference_number
    assert third_journal_entry_update.description == "third updated description"
    assert third_journal_entry_update.posted == true
    assert third_journal_entry_update.line_items |> length() == 2
    assert third_journal_entry_update.audit_logs

    assert {:error, :already_posted_journal_entry} =
             AccountingJournal.update_journal_entry(third_journal_entry_update, %{
               description: "fourth updated description",
               posted: false,
               t_accounts: %{
                 left: [%{account: expense_account, amount: Decimal.new(400)}],
                 right: [%{account: cash_account, amount: Decimal.new(400)}]
               }
             })

    assert {:ok, journal_entries} =
             AccountingJournal.find_journal_entries_by_transaction_date(
               journal_entry.transaction_date
             )

    refute Enum.member?(journal_entries, journal_entry)
    refute Enum.member?(journal_entries, updated_journal_entry)
    refute Enum.member?(journal_entries, third_journal_entry_update)

    assert {:ok, journal_entries} =
             AccountingJournal.find_journal_entries_by_transaction_date(
               updated_journal_entry.transaction_date
             )

    refute Enum.member?(journal_entries, journal_entry)
    refute Enum.member?(journal_entries, updated_journal_entry)
    assert Enum.member?(journal_entries, third_journal_entry_update)
  end
end
