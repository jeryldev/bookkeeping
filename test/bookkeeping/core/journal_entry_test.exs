defmodule Bookkeeping.Core.JournalEntryTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, JournalEntry}

  setup do
    transaction_date = DateTime.utc_now()
    general_ledger_posting_date = DateTime.utc_now()
    journal_entry_number = "JE100100"
    transaction_reference_number = "INV100100"
    audit_details = %{created_by: "example@example.com"}

    {:ok, asset_account} =
      Account.create("10000", "cash", "asset", "journal_entry_description", audit_details)

    {:ok, revenue_account} =
      Account.create(
        "20000",
        "service revenue",
        "revenue",
        "journal_entry_description",
        audit_details
      )

    t_accounts = %{
      left: [
        %{
          account: asset_account,
          amount: Decimal.new(100),
          description: "cash from service revenue"
        }
      ],
      right: [
        %{
          account: revenue_account,
          amount: Decimal.new(100),
          description: "service revenue"
        }
      ]
    }

    journal_entry_details = %{approved_by: "example@example.com"}

    {:ok,
     transaction_date: transaction_date,
     general_ledger_posting_date: general_ledger_posting_date,
     asset_account: asset_account,
     revenue_account: revenue_account,
     t_accounts: t_accounts,
     journal_entry_number: journal_entry_number,
     transaction_reference_number: transaction_reference_number,
     journal_entry_details: journal_entry_details,
     audit_details: audit_details}
  end

  test "create a journal entry", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    journal_entry_number: journal_entry_number,
    transaction_reference_number: transaction_reference_number,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, _journal_entry} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )
  end

  test "disallow journal entry with invalid t_accounts", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    asset_account: asset_account,
    revenue_account: revenue_account,
    journal_entry_number: journal_entry_number,
    transaction_reference_number: transaction_reference_number,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:error, [:invalid_account]} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: "revenue_account", amount: Decimal.new(100)}],
                 right: [%{account: asset_account, amount: Decimal.new(100)}]
               },
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )

    assert {:error, [:invalid_account]} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: revenue_account, amount: Decimal.new(100)}],
                 right: [%{account: "asset_account", amount: Decimal.new(100)}]
               },
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )

    assert {:error, :unbalanced_line_items} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: revenue_account, amount: Decimal.new(100)}],
                 right: [%{account: asset_account, amount: Decimal.new(200)}]
               },
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )

    assert {:error, [:invalid_amount]} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: revenue_account, amount: 100}],
                 right: [%{account: asset_account, amount: Decimal.new(200)}]
               },
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )

    assert {:error, [:invalid_amount]} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: revenue_account, amount: Decimal.new(200)}],
                 right: [%{account: asset_account, amount: 200}]
               },
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )

    assert {:error, [:invalid_amount]} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               %{
                 left: [%{account: revenue_account, amount: 100}],
                 right: [%{account: asset_account, amount: Decimal.new(200)}]
               },
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )
  end

  test "disallow journal entry with invalid fields", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    journal_entry_number: journal_entry_number,
    transaction_reference_number: transaction_reference_number,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:error, :invalid_journal_entry} =
             JournalEntry.create(
               nil,
               nil,
               %{},
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )

    assert {:error, :invalid_line_items} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               %{},
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )
  end

  test "update journal entry", %{
    transaction_date: transaction_date,
    general_ledger_posting_date: general_ledger_posting_date,
    t_accounts: t_accounts,
    asset_account: asset_account,
    revenue_account: revenue_account,
    journal_entry_number: journal_entry_number,
    transaction_reference_number: transaction_reference_number,
    journal_entry_details: journal_entry_details,
    audit_details: audit_details
  } do
    assert {:ok, journal_entry} =
             JournalEntry.create(
               transaction_date,
               general_ledger_posting_date,
               t_accounts,
               journal_entry_number,
               transaction_reference_number,
               "journal entry description",
               journal_entry_details,
               audit_details
             )

    assert {:error, :invalid_journal_entry} = JournalEntry.update(journal_entry, %{})

    assert {:ok, updated_journal_entry} =
             JournalEntry.update(journal_entry, %{
               journal_entry_description: "second updated description",
               journal_entry_details: %{approved_by: "other_example@example.com"},
               posted: false,
               t_accounts: %{
                 left: [%{account: asset_account, amount: Decimal.new(200)}],
                 right: [%{account: revenue_account, amount: Decimal.new(200)}]
               }
             })

    assert updated_journal_entry.general_ledger_posting_date ==
             journal_entry.general_ledger_posting_date

    assert updated_journal_entry.journal_entry_number == journal_entry.journal_entry_number

    refute updated_journal_entry.journal_entry_description ==
             journal_entry.journal_entry_description

    assert {:ok, updated_journal_entry} =
             JournalEntry.update(journal_entry, %{
               journal_entry_description: "updated description",
               posted: true
             })

    assert updated_journal_entry.general_ledger_posting_date ==
             journal_entry.general_ledger_posting_date

    assert updated_journal_entry.journal_entry_number == journal_entry.journal_entry_number

    refute updated_journal_entry.journal_entry_description ==
             journal_entry.journal_entry_description

    refute updated_journal_entry.posted == journal_entry.posted

    assert {:error, :already_posted_journal_entry} =
             JournalEntry.update(updated_journal_entry, %{
               journal_entry_description: "third description update",
               posted: true,
               t_accounts: %{
                 left: [%{account: asset_account, amount: Decimal.new(200)}],
                 right: [%{account: revenue_account, amount: Decimal.new(200)}]
               }
             })
  end
end
