defmodule Bookkeeping.Boundary.GeneralLedger.Supervisor do
  @moduledoc """
  Bookkeeping.Boundary.ChartOfAccounts.Supervisor is responsible for starting the ChartOfAccountsServer and ChartOfAccountsBackup processes.
  It is also responsible for restarting the ChartOfAccountsServer process if it crashes.
  """
  use Supervisor

  alias Bookkeeping.Boundary.GeneralLedger.DynamicSupervisor, as: GeneralLedgerDynamicSupervisor
  alias Bookkeeping.Boundary.GeneralLedger.Registry, as: GeneralLedgerRegistry

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {DynamicSupervisor, [name: GeneralLedgerDynamicSupervisor, strategy: :one_for_one]},
      {Registry, [name: GeneralLedgerRegistry, keys: :unique]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
