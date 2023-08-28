defmodule Bookkeeping.Boundary.AccountingJournal.Supervisor do
  @moduledoc """
  Bookkeeping.Boundary.AccountingJournal.Supervisor is responsible for starting the AccountingJournalServer and AccountingJournalBackup processes.
  It is also responsible for restarting the AccountingJournalServer process if it crashes.
  """
  use Supervisor

  @spec start_link([{:name, atom | {:global, any} | {:via, atom, any}}]) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Bookkeeping.Boundary.AccountingJournal.Backup, %{}},
      {Bookkeeping.Boundary.AccountingJournal.Server,
       [name: Bookkeeping.Boundary.AccountingJournal.Server]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
