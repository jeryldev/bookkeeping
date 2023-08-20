defmodule Bookkeeping.Core.JournalEntryTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, JournalEntry}

  setup do
    details = %{email: "example@example.com"}

    {:ok, asset_account} =
      Account.create("10000", "cash", "asset", "description", details)

    {:ok, expense_account} =
      Account.create("20000", "rent", "expense", "description", details)

    {:ok, details: details, asset_account: asset_account, expense_account: expense_account}
  end

  test "create a journal entry", %{
    details: details,
    asset_account: asset_account,
    expense_account: expense_account
  } do
    assert {:ok, _journal_entry} =
             JournalEntry.create(
               DateTime.utc_now(),
               "reference number",
               "description",
               %{
                 left: [%{account: expense_account, amount: Decimal.new(100)}],
                 right: [%{account: asset_account, amount: Decimal.new(100)}]
               },
               details
             )
  end

  test "disallow journal entry with invalid fields" do
    assert {:error, :invalid_journal_entry} =
             JournalEntry.create(
               nil,
               "reference number",
               "description",
               %{},
               %{}
             )

    assert {:error, :invalid_line_items} =
             JournalEntry.create(
               DateTime.utc_now(),
               "reference number",
               "description",
               %{},
               %{}
             )
  end

  test "update journal entry", %{
    details: details,
    asset_account: asset_account,
    expense_account: expense_account
  } do
    assert {:ok, journal_entry} =
             JournalEntry.create(
               DateTime.utc_now(),
               "reference number 2",
               "description",
               %{
                 left: [%{account: expense_account, amount: Decimal.new(100)}],
                 right: [%{account: asset_account, amount: Decimal.new(100)}]
               },
               details
             )

    assert {:error, :invalid_journal_entry} = JournalEntry.update(journal_entry, %{})

    assert {:ok, updated_journal_entry} =
             JournalEntry.update(journal_entry, %{
               description: "second updated description",
               posted: false,
               t_accounts: %{
                 left: [%{account: expense_account, amount: Decimal.new(200)}],
                 right: [%{account: asset_account, amount: Decimal.new(200)}]
               }
             })

    assert updated_journal_entry.transaction_date == journal_entry.transaction_date
    assert updated_journal_entry.reference_number == journal_entry.reference_number
    refute updated_journal_entry.description == journal_entry.description

    assert {:ok, updated_journal_entry} =
             JournalEntry.update(journal_entry, %{
               description: "updated description",
               posted: true
             })

    assert updated_journal_entry.transaction_date == journal_entry.transaction_date
    assert updated_journal_entry.reference_number == journal_entry.reference_number
    refute updated_journal_entry.description == journal_entry.description
    refute updated_journal_entry.posted == journal_entry.posted

    assert {:error, :already_posted_journal_entry} =
             JournalEntry.update(updated_journal_entry, %{
               description: "third description update",
               posted: true,
               t_accounts: %{
                 left: [%{account: expense_account, amount: Decimal.new(200)}],
                 right: [%{account: asset_account, amount: Decimal.new(200)}]
               }
             })
  end
end
