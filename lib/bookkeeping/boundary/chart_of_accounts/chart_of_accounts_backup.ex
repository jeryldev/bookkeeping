defmodule Bookkeeping.Boundary.ChartOfAccounts.ChartOfAccountsBackup do
  use Agent

  def start_link(initial_value \\ %{}) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def get do
    chart_of_accounts = Agent.get(__MODULE__, fn state -> state end)
    {:ok, chart_of_accounts}
  end

  def update(new_value) do
    Agent.update(__MODULE__, fn _state -> new_value end)
    {:ok, :backup_updated}
  end
end
