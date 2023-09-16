defmodule Bookkeeping.Boundary.ChartOfAccounts.Supervisor do
  @moduledoc """
  Bookkeeping.Boundary.ChartOfAccounts.Supervisor is responsible for starting the ChartOfAccountsServer and ChartOfAccountsBackup processes.
  It is also responsible for restarting the ChartOfAccountsServer process if it crashes.
  """
  use Supervisor

  alias Bookkeeping.Boundary.ChartOfAccounts.Backup, as: ChartOfAccountsBackup
  alias Bookkeeping.Boundary.ChartOfAccounts.Server, as: ChartOfAccountsServer

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
      {ChartOfAccountsBackup, %{}},
      {ChartOfAccountsServer, [name: ChartOfAccountsServer]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
