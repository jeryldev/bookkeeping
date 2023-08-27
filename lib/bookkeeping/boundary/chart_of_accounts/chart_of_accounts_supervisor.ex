defmodule Bookkeeping.Boundary.ChartOfAccounts.ChartOfAccountsSupervisor do
  use Supervisor

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Bookkeeping.Boundary.ChartOfAccounts.ChartOfAccountsBackup, %{}},
      {Bookkeeping.Boundary.ChartOfAccounts.ChartOfAccountsServer,
       [name: Bookkeeping.Boundary.ChartOfAccounts.ChartOfAccountsServer]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
