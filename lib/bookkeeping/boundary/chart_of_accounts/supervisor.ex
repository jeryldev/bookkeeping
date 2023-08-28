defmodule Bookkeeping.Boundary.ChartOfAccounts.Supervisor do
  @moduledoc """
  Bookkeeping.Boundary.ChartOfAccounts.Supervisor is responsible for starting the ChartOfAccountsServer and ChartOfAccountsBackup processes.
  It is also responsible for restarting the ChartOfAccountsServer process if it crashes.
  """
  use Supervisor

  alias Bookkeeping.Boundary.ChartOfAccounts.Backup, as: ChartOfAccountsBackup
  alias Bookkeeping.Boundary.ChartOfAccounts.Server, as: ChartOfAccountsServer

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {ChartOfAccountsBackup, %{}},
      {ChartOfAccountsServer, [name: ChartOfAccountsServer]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
