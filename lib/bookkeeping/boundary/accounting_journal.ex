defmodule Bookkeeping.Boundary.AccountingJournal do
  @moduledoc """
  Bookkeeping.Boundary.AccountingJournal is a GenServer that represents the accounting journal.
  Accounting Journal is a record of all relevant business transactions in terms of money or a record.
  The Accounting Journal GenServer is responsible for creating, updating, and searching journal entries.
  The state of Accounting Journal GenServer is a map in which the keys are maps of transaction date details (year, month, day) and the values are lists of journal entries.
  """
  use GenServer

  alias Bookkeeping.Core.JournalEntry

  @typedoc """
  The state of the Accounting Journal GenServer.
  The state is a map in which the keys are maps of transaction date details (year, month, day) and the values are lists of journal entries.

  ## Examples

      iex> %{
      ...>  %{year: 2021, month: 10, day: 10} => [
      ...>    %JournalEntry{
      ...>      id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>      transaction_date: ~U[2021-10-10 10:10:10.000000Z],
      ...>      reference_number: "reference number",
      ...>      description: "description",
      ...>      line_items: [
      ...>        %LineItem{
      ...>          account: %Account{
      ...>            code: "10_000",
      ...>            name: "cash",
      ...>            account_type: %AccountType{
      ...>              name: "asset",
      ...>              normal_balance: :debit,
      ...>              primary_account_category: :balance_sheet,
      ...>              contra: false
      ...>            }
      ...>          },
      ...>          amount: Decimal.new(100),
      ...>          entry_type: :debit
      ...>        },
      ...>        %LineItem{
      ...>          account: %Account{
      ...>            code: "20_000",
      ...>            name: "sales",
      ...>            account_type: %AccountType{
      ...>              name: "revenue",
      ...>              normal_balance: :credit,
      ...>              primary_account_category: :profit_and_loss,
      ...>              contra: false
      ...>            }
      ...>          },
      ...>          amount: Decimal.new(100),
      ...>          entry_type: :credit
      ...>        }
      ...>      ],
      ...>      audit_logs: [
      ...>        %AuditLog{
      ...>          id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>          record_type: "journal_entry",
      ...>          action_type: "create",
      ...>          details: %{},
      ...>          created_at: ~U[2021-10-10 10:10:10.000000Z],
      ...>          updated_at: ~U[2021-10-10 10:10:10.000000Z],
      ...>          deleted_at: nil
      ...>        }
      ...>      ],
      ...>      posted: false
      ...>    }
      ...>  ],
      ...>  ...
      ...> }
  """
  @type journal_entries_state :: %{
          transaction_date_details => list(JournalEntry.t())
        }

  @type transaction_date_details :: %{
          year: integer(),
          month: integer(),
          day: integer()
        }

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

  @spec create_journal_entry(
          DateTime.t(),
          String.t(),
          String.t(),
          JournalEntry.t_accounts(),
          map()
        ) :: {:ok, JournalEntry.t()} | {:error, :invalid_journal_entry}
  def create_journal_entry(
        server \\ __MODULE__,
        transaction_date,
        reference_number,
        description,
        t_accounts,
        audit_details
      ) do
    GenServer.call(
      server,
      {:create_journal_entry, transaction_date, reference_number, description, t_accounts,
       audit_details}
    )
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

  @doc """
  Returns a journal entry by reference number.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is returned successfully. Otherwise, returns `{:error, :not_found}`.

  ## Examples

      iex> AccountingJournal.find_journal_entry_by_reference_number("ref_num_1")
      {:ok, %JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "ref_num_1",
        description: "description",
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: %EntryType{type: :debit, name: "Debit"}
          },
          %LineItem{
            account: cash_account,
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
      }}

      iex> AccountingJournal.find_journal_entry_by_reference_number("ref_num_2")
      {:error, :not_found}
  """
  @spec find_journal_entry_by_reference_number(String.t()) ::
          {:ok, JournalEntry.t()} | {:error, :not_found}
  def find_journal_entry_by_reference_number(server \\ __MODULE__, reference_number) do
    GenServer.call(server, {:find_journal_entry_by_reference_number, reference_number})
  end

  @doc """
  Returns a list of journal entries by transaction date.

  Returns `{:ok, list(JournalEntry.t())}` if the journal entries are returned successfully. Otherwise, returns `{:error, :invalid_transaction_date}`.

  ## Examples

      iex> AccountingJournal.find_journal_entries_by_transaction_date(~U[2021-10-10 10:10:10.000000Z])
      {:ok, [%JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "ref_num_1",
        description: "description",
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: %EntryType{type: :debit, name: "Debit"}
          },
          %LineItem{
            account: cash_account,
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
          },
          ...
        ],
        posted: false
      }]}

      iex> AccountingJournal.find_journal_entries_by_transaction_date(%{year: 2021, month: 10})
      {:ok, [%JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "ref_num_1",
        description: "description",
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: %EntryType{type: :debit, name: "Debit"}
          },
          %LineItem{
            account: cash_account,
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
          },
          ...
        ],
        posted: false
      }]}

      iex> AccountingJournal.find_journal_entries_by_transaction_date(~U[2021-10-10 10:10:10.000000Z])
      {:error, :invalid_transaction_date}
  """
  @spec find_journal_entries_by_transaction_date(DateTime.t() | transaction_date_details()) ::
          {:ok, list(JournalEntry.t())} | {:error, :invalid_transaction_date}
  def find_journal_entries_by_transaction_date(server \\ __MODULE__, datetime) do
    GenServer.call(server, {:find_journal_entries_by_transaction_date, datetime})
  end

  @doc """
  Returns a journal entry by id.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is returned successfully. Otherwise, returns `{:error, :invalid_id}`.

  ## Examples

      iex> AccountingJournal.find_journal_entries_by_id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
      {:ok, %JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "ref_num_1",
        description: "description",
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: %EntryType{type: :debit, name: "Debit"}
          },
          %LineItem{
            account: cash_account,
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
      }}

      iex> AccountingJournal.find_journal_entries_by_id("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
      {:error, :invalid_id}
  """
  @spec find_journal_entries_by_id(String.t()) ::
          {:ok, JournalEntry.t()} | {:error, :invalid_id}
  def find_journal_entries_by_id(server \\ __MODULE__, id) do
    GenServer.call(server, {:find_journal_entries_by_id, id})
  end

  def find_journal_entries_by_transaction_date_range(
        server \\ __MODULE__,
        from_datetime,
        to_datetime
      ) do
    GenServer.call(
      server,
      {:find_journal_entries_by_transaction_date_range, from_datetime, to_datetime}
    )
  end

  @doc """
  Updates a journal entry.

  Returns `{:ok, JournalEntry.t()}` if the journal entry is updated successfully. Otherwise, returns `{:error, :invalid_journal_entry}`.

  ## Examples

      iex> AccountingJournal.find_journal_entry_by_reference_number("ref_num_1")
      {:ok, %JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "ref_num_1",
        description: "description",
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: %EntryType{type: :debit, name: "Debit"}
          },
          %LineItem{
            account: cash_account,
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
      }}

      iex> AccountingJournal.update_journal_entry(%JournalEntry{
      ...>   id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>   transaction_date: ~U[2021-10-10 10:10:10.000000Z],
      ...>   reference_number: "ref_num_1",
      ...>   description: "description",
      ...>   line_items: [
      ...>     %LineItem{
      ...>       account: expense_account,
      ...>       amount: Decimal.new(100),
      ...>       entry_type: %EntryType{type: :debit, name: "Debit"}
      ...>     },
      ...>     %LineItem{
      ...>       account: cash_account,
      ...>       amount: Decimal.new(100),
      ...>       entry_type: %EntryType{type: :credit, name: "Credit"}
      ...>     }
      ...>   ],
      ...>   audit_logs: [
      ...>     %AuditLog{
      ...>       id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      ...>       record_type: "journal_entry",
      ...>       action_type: "create",
      ...>       details: %{},
      ...>       created_at: ~U[2021-10-10 10:10:10.000000Z],
      ...>       updated_at: ~U[2021-10-10 10:10:10.000000Z],
      ...>       deleted_at: nil
      ...>     }
      ...>   ],
      ...>   posted: false
      ...> }, %{description: "updated description",posted: true})
      {:ok, %JournalEntry{
        id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        transaction_date: ~U[2021-10-10 10:10:10.000000Z],
        reference_number: "ref_num_1",
        description: "updated description",
        line_items: [
          %LineItem{
            account: expense_account,
            amount: Decimal.new(100),
            entry_type: %EntryType{type: :debit, name: "Debit"}
          },
          %LineItem{
            account: cash_account,
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
          },
          ...
        ],
        posted: true
      }}

      iex> AccountingJournal.update_journal_entry(%JournalEntry{}, %{description: "updated description",posted: true})
      {:error, :invalid_journal_entry}
  """
  @spec update_journal_entry(JournalEntry.t(), map()) ::
          {:ok, JournalEntry.t()} | {:error, :invalid_journal_entry}
  def update_journal_entry(server \\ __MODULE__, journal_entry, attrs) do
    GenServer.call(server, {:update_journal_entry, journal_entry, attrs})
  end

  @impl true
  @spec init(journal_entries_state()) :: {:ok, journal_entries_state()}
  def init(journal_entries), do: {:ok, journal_entries}

  @impl true
  def handle_call(
        {:create_journal_entry, transaction_date, reference_number, description, t_accounts,
         audit_details},
        _from,
        journal_entries
      ) do
    with {:error, :not_found} <- find_by_reference_number(journal_entries, reference_number),
         {:ok, journal_entry} <-
           JournalEntry.create(
             transaction_date,
             reference_number,
             description,
             t_accounts,
             audit_details
           ) do
      transaction_date_details = Map.take(journal_entry.transaction_date, [:year, :month, :day])

      updated_journal_entries =
        if journal_entries[transaction_date_details] == nil do
          Map.put(journal_entries, transaction_date_details, [journal_entry])
        else
          updated_je_list = [journal_entry | journal_entries[transaction_date_details]]
          Map.put(journal_entries, transaction_date_details, updated_je_list)
        end

      {:reply, {:ok, journal_entry}, updated_journal_entries}
    else
      {:ok, _journal_entry} -> {:reply, {:error, :duplicate_reference_number}, journal_entries}
      {:error, message} -> {:reply, {:error, message}, journal_entries}
    end
  end

  @impl true
  def handle_call(:all_journal_entries, _from, journal_entries) do
    all_entries =
      Enum.reduce(journal_entries, [], fn {_k, je_list}, acc -> je_list ++ acc end)

    {:reply, {:ok, all_entries}, journal_entries}
  end

  @impl true
  def handle_call(
        {:find_journal_entry_by_reference_number, reference_number},
        _from,
        journal_entries
      ) do
    case find_by_reference_number(journal_entries, reference_number) do
      {:ok, journal_entry} -> {:reply, {:ok, journal_entry}, journal_entries}
      {:error, message} -> {:reply, {:error, message}, journal_entries}
    end
  end

  @impl true
  def handle_call(
        {:find_journal_entries_by_transaction_date, datetime},
        _from,
        journal_entries
      ) do
    case get_transaction_date_details(datetime) do
      {:ok, transaction_date_details} ->
        all_journal_entries =
          find_by_transaction_date_details(journal_entries, transaction_date_details)

        {:reply, {:ok, all_journal_entries}, journal_entries}

      {:error, message} ->
        {:reply, {:error, message}, journal_entries}
    end
  end

  @impl true
  def handle_call({:find_journal_entries_by_id, id}, _from, journal_entries) do
    case find_by_id(journal_entries, id) do
      {:ok, journal_entry} -> {:reply, {:ok, journal_entry}, journal_entries}
      {:error, message} -> {:reply, {:error, message}, journal_entries}
    end
  end

  @impl true
  def handle_call(
        {:find_journal_entries_by_transaction_date_range, from_datetime, to_datetime},
        _from,
        journal_entries
      ) do
    with {:ok, from_transaction_date_details} <- get_transaction_date_details(from_datetime),
         {:ok, to_transaction_date_details} <- get_transaction_date_details(to_datetime) do
      je_list =
        find_by_range(journal_entries, from_transaction_date_details, to_transaction_date_details)

      {:reply, {:ok, je_list}, journal_entries}
    else
      {:error, message} ->
        {:reply, {:error, message}, journal_entries}
    end
  end

  @impl true
  def handle_call({:update_journal_entry, journal_entry, attrs}, _from, journal_entries) do
    case JournalEntry.update(journal_entry, attrs) do
      {:ok, updated_journal_entry} ->
        updated_journal_entries =
          process_journal_entry_update(journal_entries, updated_journal_entry)

        {:reply, {:ok, updated_journal_entry}, updated_journal_entries}

      {:error, message} ->
        {:reply, {:error, message}, journal_entries}
    end
  end

  defp get_transaction_date_details(datetime)
       when is_struct(datetime, DateTime) or is_map(datetime),
       do: {:ok, Map.take(datetime, [:year, :month, :day])}

  defp get_transaction_date_details(_), do: {:error, :invalid_transaction_date}

  defp find_by_transaction_date_details(journal_entries, transaction_date_details) do
    tdd_keys = Map.keys(transaction_date_details)

    journal_entries
    |> Task.async_stream(fn {k, je} ->
      if Map.take(k, tdd_keys) == transaction_date_details, do: je, else: nil
    end)
    |> Enum.reduce([], fn {:ok, je_list}, acc ->
      if is_list(je_list), do: je_list ++ acc, else: acc
    end)
  end

  defp find_by_range(journal_entries, from_transaction_date_details, to_transaction_date_details) do
    from_tdd_keys = Map.keys(from_transaction_date_details)
    to_tdd_keys = Map.keys(to_transaction_date_details)

    journal_entries
    |> Task.async_stream(fn {k, je_list} ->
      if Map.take(k, from_tdd_keys) >= from_transaction_date_details and
           Map.take(k, to_tdd_keys) <= to_transaction_date_details,
         do: je_list,
         else: nil
    end)
    |> Enum.reduce([], fn {:ok, je_list}, acc ->
      if is_list(je_list), do: je_list ++ acc, else: acc
    end)
  end

  defp find_by_reference_number(journal_entries, reference_number)
       when is_binary(reference_number) do
    journal_entry_found =
      journal_entries
      |> Task.async_stream(fn {_k, je_list} ->
        Enum.find(je_list, &(&1.reference_number == reference_number))
      end)
      |> Enum.reduce(nil, fn {:ok, search_result}, acc ->
        if is_struct(search_result, JournalEntry), do: search_result, else: acc
      end)

    if is_map(journal_entry_found),
      do: {:ok, journal_entry_found},
      else: {:error, :not_found}
  end

  defp find_by_reference_number(_journal_entries, _reference_number),
    do: {:error, :invalid_reference_number}

  defp find_by_id(journal_entries, id) when is_binary(id) do
    journal_entry_found =
      journal_entries
      |> Task.async_stream(fn {_k, je_list} -> Enum.find(je_list, &(&1.id == id)) end)
      |> Enum.reduce(nil, fn {:ok, search_result}, acc ->
        if is_struct(search_result, JournalEntry), do: search_result, else: acc
      end)

    if is_map(journal_entry_found),
      do: {:ok, journal_entry_found},
      else: {:error, :not_found}
  end

  defp find_by_id(_journal_entries, _id), do: {:error, :invalid_id}

  defp process_journal_entry_update(journal_entries, updated_journal_entry) do
    transaction_date_details =
      Map.take(updated_journal_entry.transaction_date, [:year, :month, :day])

    if journal_entries[transaction_date_details] == nil do
      with {:ok, old_journal_entry} <- find_by_id(journal_entries, updated_journal_entry.id),
           {:ok, old_transaction_date_details} <-
             get_transaction_date_details(old_journal_entry.transaction_date) do
        updated_je_list =
          remove_journal_entry_by_id(
            journal_entries,
            old_transaction_date_details,
            old_journal_entry.id
          )

        journal_entries
        |> Map.put(transaction_date_details, [updated_journal_entry])
        |> Map.put(old_transaction_date_details, updated_je_list)
      end
    else
      updated_je_list =
        update_journal_entry_by_id(
          journal_entries,
          transaction_date_details,
          updated_journal_entry
        )

      Map.put(journal_entries, transaction_date_details, updated_je_list)
    end
  end

  defp remove_journal_entry_by_id(journal_entries, transaction_date_details, journal_entry_id) do
    Enum.filter(journal_entries[transaction_date_details], fn je -> je.id != journal_entry_id end)
  end

  defp update_journal_entry_by_id(
         journal_entries,
         transaction_date_details,
         updated_journal_entry
       ) do
    Enum.map(journal_entries[transaction_date_details], fn je ->
      if je.id == updated_journal_entry.id, do: updated_journal_entry, else: je
    end)
  end
end
