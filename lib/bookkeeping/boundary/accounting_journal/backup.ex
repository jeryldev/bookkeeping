defmodule Bookkeeping.Boundary.AccountingJournal.Backup do
  @moduledoc """
  Bookkeeping.Boundary.AccountingJournal.Backup is responsible for storing the chart of accounts in a backup file.
  """
  use Agent

  alias Bookkeeping.Boundary.AccountingJournal.Server, as: AccountingJournalServer

  @doc """
  Starts the AccountingJournalBackup agent.

  ## Examples

      iex> {:ok, pid} = Bookkeeping.Boundary.AccountingJournal.Backup.start_link()
      {:ok, #PID<0.0.0>}
  """
  @spec start_link(AccountingJournalServer.accounting_journal_state()) ::
          {:error, any} | {:ok, pid}
  def start_link(initial_value \\ %{}) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  @doc """
  Gets the chart of accounts from the AccountingJournalBackup agent.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Backup.get()
      {:ok, chart_of_accounts}
  """
  @spec get :: {:ok, AccountingJournalServer.chart_of_account_state()}
  def get do
    chart_of_accounts = Agent.get(__MODULE__, fn state -> state end)
    {:ok, chart_of_accounts}
  end

  @doc """
  Updates the chart of accounts in the AccountingJournalBackup agent.

  ## Examples

      iex> Bookkeeping.Boundary.AccountingJournal.Backup.update(%{})
      {:ok, :backup_updated}
  """
  @spec update(AccountingJournalServer.chart_of_account_state()) :: {:ok, :backup_updated}
  def update(new_value) do
    Agent.update(__MODULE__, fn _state -> new_value end)
    {:ok, :backup_updated}
  end
end
