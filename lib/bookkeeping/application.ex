defmodule Bookkeeping.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Bookkeeping.Boundary.AccountingJournal.Supervisor, as: AccountingJournalSupervisor
  alias Bookkeeping.Boundary.ChartOfAccounts.Supervisor, as: ChartOfAccountsSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Bookkeeping.Worker.start_link(arg)
      # {Bookkeeping.Worker, arg}
      {ChartOfAccountsSupervisor, [name: ChartOfAccountsSupervisor]},
      {AccountingJournalSupervisor, [name: AccountingJournalSupervisor]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bookkeeping.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
