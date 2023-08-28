defmodule Bookkeeping.Boundary.ChartOfAccounts.Supervisor do
  @moduledoc """
  Bookkeeping.Boundary.ChartOfAccounts.Supervisor is responsible for starting the ChartOfAccountsServer and ChartOfAccountsBackup processes.
  It is also responsible for restarting the ChartOfAccountsServer process if it crashes.
  """
  use Supervisor

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Bookkeeping.Boundary.ChartOfAccounts.Backup, %{}},
      {Bookkeeping.Boundary.ChartOfAccounts.Server,
       [name: Bookkeeping.Boundary.ChartOfAccounts.Server]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
