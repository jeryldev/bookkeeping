defmodule Bookkeeping.Core.JournalEntryTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{Account, JournalEntry}

  # setup do
  #   transaction_date = DateTime.utc_now()
  #   posting_date = DateTime.utc_now()
  #   journal_entry_number = "JE100100"
  #   reference_number = "INV100100"
  #   audit_details = %{created_by: "example@example.com"}

  #   {:ok, asset_account} =
  #     Account.create("10000", "cash", "asset", "description", audit_details)

  #   {:ok, revenue_account} =
  #     Account.create(
  #       "20000",
  #       "service revenue",
  #       "revenue",
  #       "description",
  #       audit_details
  #     )

  #   t_accounts = %{
  #     left: [
  #       %{
  #         account: asset_account,
  #         amount: Decimal.new(100),
  #         description: "cash from service revenue"
  #       }
  #     ],
  #     right: [
  #       %{
  #         account: revenue_account,
  #         amount: Decimal.new(100),
  #         description: "service revenue"
  #       }
  #     ]
  #   }

  #   particulars = %{approved_by: "example@example.com"}

  #   {:ok,
  #    transaction_date: transaction_date,
  #    posting_date: posting_date,
  #    asset_account: asset_account,
  #    revenue_account: revenue_account,
  #    t_accounts: t_accounts,
  #    document_number: journal_entry_number,
  #    reference_number: reference_number,
  #    particulars: particulars,
  #    audit_details: audit_details}
  # end

  # test "create a journal entry", %{
  #   transaction_date: transaction_date,
  #   posting_date: posting_date,
  #   t_accounts: t_accounts,
  #   document_number: journal_entry_number,
  #   reference_number: reference_number,
  #   particulars: particulars,
  #   audit_details: audit_details
  # } do
  #   assert {:ok, _journal_entry} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              t_accounts,
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )
  # end

  # test "disallow journal entry with invalid t_accounts", %{
  #   transaction_date: transaction_date,
  #   posting_date: posting_date,
  #   asset_account: asset_account,
  #   revenue_account: revenue_account,
  #   document_number: journal_entry_number,
  #   reference_number: reference_number,
  #   particulars: particulars,
  #   audit_details: audit_details
  # } do
  #   assert {:error, [:invalid_account]} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              %{
  #                left: [%{account: "revenue_account", amount: Decimal.new(100)}],
  #                right: [%{account: asset_account, amount: Decimal.new(100)}]
  #              },
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )

  #   assert {:error, [:invalid_account]} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              %{
  #                left: [%{account: revenue_account, amount: Decimal.new(100)}],
  #                right: [%{account: "asset_account", amount: Decimal.new(100)}]
  #              },
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )

  #   assert {:error, :unbalanced_line_items} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              %{
  #                left: [%{account: revenue_account, amount: Decimal.new(100)}],
  #                right: [%{account: asset_account, amount: Decimal.new(200)}]
  #              },
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )

  #   assert {:error, [:invalid_amount]} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              %{
  #                left: [%{account: revenue_account, amount: 100}],
  #                right: [%{account: asset_account, amount: Decimal.new(200)}]
  #              },
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )

  #   assert {:error, [:invalid_amount]} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              %{
  #                left: [%{account: revenue_account, amount: Decimal.new(200)}],
  #                right: [%{account: asset_account, amount: 200}]
  #              },
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )

  #   assert {:error, [:invalid_amount]} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              %{
  #                left: [%{account: revenue_account, amount: 100}],
  #                right: [%{account: asset_account, amount: Decimal.new(200)}]
  #              },
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )
  # end

  # test "disallow journal entry with invalid fields", %{
  #   transaction_date: transaction_date,
  #   posting_date: posting_date,
  #   document_number: journal_entry_number,
  #   reference_number: reference_number,
  #   particulars: particulars,
  #   audit_details: audit_details
  # } do
  #   assert {:error, :invalid_journal_entry} =
  #            JournalEntry.create(
  #              nil,
  #              nil,
  #              %{},
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )

  #   assert {:error, :invalid_line_items} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              %{},
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )
  # end

  # test "update journal entry", %{
  #   transaction_date: transaction_date,
  #   posting_date: posting_date,
  #   t_accounts: t_accounts,
  #   asset_account: asset_account,
  #   revenue_account: revenue_account,
  #   document_number: journal_entry_number,
  #   reference_number: reference_number,
  #   particulars: particulars,
  #   audit_details: audit_details
  # } do
  #   assert {:ok, journal_entry} =
  #            JournalEntry.create(
  #              transaction_date,
  #              posting_date,
  #              t_accounts,
  #              journal_entry_number,
  #              reference_number,
  #              "journal entry description",
  #              particulars,
  #              audit_details
  #            )

  #   assert {:error, :invalid_journal_entry} = JournalEntry.update(journal_entry, %{})

  #   assert {:ok, updated_journal_entry} =
  #            JournalEntry.update(journal_entry, %{
  #              description: "second updated description",
  #              particulars: %{approved_by: "other_example@example.com"},
  #              posted: false,
  #              t_accounts: %{
  #                left: [%{account: asset_account, amount: Decimal.new(200)}],
  #                right: [%{account: revenue_account, amount: Decimal.new(200)}]
  #              }
  #            })

  #   assert updated_journal_entry.posting_date ==
  #            journal_entry.posting_date

  #   assert updated_journal_entry.journal_entry_number == journal_entry.journal_entry_number

  #   refute updated_journal_entry.description ==
  #            journal_entry.description

  #   assert {:ok, updated_journal_entry} =
  #            JournalEntry.update(journal_entry, %{
  #              description: "updated description",
  #              posted: true
  #            })

  #   assert updated_journal_entry.posting_date ==
  #            journal_entry.posting_date

  #   assert updated_journal_entry.journal_entry_number == journal_entry.journal_entry_number

  #   refute updated_journal_entry.description ==
  #            journal_entry.description

  #   refute updated_journal_entry.posted == journal_entry.posted

  #   assert {:error, :already_posted_journal_entry} =
  #            JournalEntry.update(updated_journal_entry, %{
  #              description: "third description update",
  #              posted: true,
  #              t_accounts: %{
  #                left: [%{account: asset_account, amount: Decimal.new(200)}],
  #                right: [%{account: revenue_account, amount: Decimal.new(200)}]
  #              }
  #            })
  # end
end
