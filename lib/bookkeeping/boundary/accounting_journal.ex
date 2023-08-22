defmodule Bookkeeping.Boundary.AccountingJournal do
  @moduledoc """
  Bookkeeping.Boundary.AccountingJournal is a GenServer that represents the accounting journal.
  Accounting Journal is a record of all relevant business transactions in terms of money or a record.
  The Accounting Journal GenServer is responsible for creating, updating, and searching journal entries.
  The Accounting Journal GenServer is a map in which the keys are maps of transaction date details (year, month, day) and the values are lists of journal entries.
  """
  use GenServer

  alias Bookkeeping.Core.JournalEntry

  @doc """
  Starts the Accounting Journal GenServer.

  Returns `{:ok, pid}` if the GenServer is started successfully.

  ## Examples

      iex> AccountingJournal.start_link()
      {:ok, #PID<0.123.0>}
  """
  @spec start_link(Keyword.t()) :: {:ok, pid}
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  @doc """
  Returns all journal entries.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully.

  ## Examples

      iex> AccountingJournal.all_journal_entries()
      {:ok, [%JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "reference number",
        description: "description",
        line_items: [
          %LineItem{
            account: %Account{
              code: nil,
              name: nil,
              account_type: %AccountType{
                name: nil,
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_account_category: %PrimaryAccountCategory{type: nil, primary: nil},
                contra: nil
              }
            },
            amount: Decimal.new(100),
            entry_type: %EntryType{type: :debit, name: "Debit"}
          },
          %LineItem{
            account: %Account{
              code: nil,
              name: nil,
              account_type: %AccountType{
                name: nil,
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_account_category: %PrimaryAccountCategory{type: nil, primary: nil},
                contra: nil
              }
            },
            amount: Decimal.new(100),
            entry_type: %EntryType{type: :credit, name: "Credit"}
          }
        ],
        audit_logs: [
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "journal_entry",
            action_type: "create",
            details: %{},
            created_at: ~U[2021-10-10 10:10:10.000000Z],
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          }
        ],
        posted: false
      }]}
  """
  @spec all_journal_entries() :: {:ok, list(JournalEntry.t())}
  def all_journal_entries(server \\ __MODULE__) do
    GenServer.call(server, :all_journal_entries)
  end

  @impl true
  def init(journal_entries), do: {:ok, journal_entries}

  @impl true
  def handle_call(:all_journal_entries, _from, journal_entries) do
    all_entries = Enum.reduce(journal_entries, [], fn {_k, v}, acc -> [v | acc] end)

    {:reply, {:ok, all_entries}, journal_entries}
  end

  @impl true
  def handle_call(
        {:find_journal_entry_by_reference_number, reference_number},
        _from,
        journal_entries
      ) do
    journal_entry =
      Task.async_stream(journal_entries, fn {_k, v} ->
        Task.async_stream(v, fn je ->
          if je.reference_number == reference_number, do: je, else: nil
        end)
      end)
      |> Enum.reduce(nil, fn {:ok, {:ok, je}}, acc ->
        if is_map(je), do: je, else: acc
      end)

    if is_map(journal_entry),
      do: {:reply, {:ok, journal_entry}, journal_entries},
      else: {:reply, {:error, :not_found}, journal_entries}
  end

  def handle_call(
        {:create_journal_entry, transaction_date, reference_number, description, t_accounts,
         audit_details},
        _from,
        journal_entries
      ) do
    with {:ok, journal_entry} <-
           JournalEntry.create(
             transaction_date,
             reference_number,
             description,
             t_accounts,
             audit_details
           ) do
      # %{
      #   %{
      #     # datetime.year
      #     year: "2019",
      #     # datetime.month
      #     month: "01",
      #     # datetime.day
      #     day: "01"
      #   } => []
      # }
      {:reply, {:ok, journal_entry}, journal_entries}
    else
      {:error, message} -> {:reply, {:error, message}, journal_entries}
      _ -> {:reply, {:error, :invalid_journal_entry}, journal_entries}
    end
  end
end
