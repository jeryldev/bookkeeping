defmodule Bookkeeping.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Bookkeeping.Worker.start_link(arg)
      # {Bookkeeping.Worker, arg}
      # {Bookkeeping.Boundary.ChartOfAccounts, []},
      {Bookkeeping.Boundary.ChartOfAccounts.ChartOfAccountsSupervisor,
       [name: Bookkeeping.Boundary.ChartOfAccounts.ChartOfAccountsSupervisor]},
      {Bookkeeping.Boundary.AccountingJournal, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bookkeeping.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
