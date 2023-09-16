defmodule Bookkeeping.Boundary.AccountingJournal.Supervisor do
  @moduledoc """
  Bookkeeping.Boundary.AccountingJournal.Supervisor is responsible for starting the AccountingJournalServer and AccountingJournalBackup processes.
  It is also responsible for restarting the AccountingJournalServer process if it crashes.
  """
  use Supervisor

  alias Bookkeeping.Boundary.AccountingJournal.Backup, as: AccountingJournalBackup
  alias Bookkeeping.Boundary.AccountingJournal.Server, as: AccountingJournalServer

  @type init_options_t :: list()
  @type sup_flags_t :: map()
  @type children_specs_t :: list(:supervisor.child_spec())

  @spec start_link(init_options_t()) ::
          {:ok, pid} | {:error, {:already_started, pid()} | {:shutdown, term()} | term()}
  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  @impl true
  @spec init(any()) :: {:ok, {sup_flags_t(), children_specs_t}}
  def init(_init_arg) do
    children = [
      {AccountingJournalBackup, %{}},
      {AccountingJournalServer, [name: AccountingJournalServer]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
