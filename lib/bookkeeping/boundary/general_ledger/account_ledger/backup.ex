defmodule Bookkeeping.Boundary.GeneralLedger.AccountLedger.Backup do
  @moduledoc """
  Bookkeeping.Boundary.GeneralLedger.AccountLedger.Backup is responsible for storing the account ledger in a backup file.
  """
  use Agent

  alias Bookkeeping.Boundary.GeneralLedger.AccountLedger.Server, as: AccountLedgerServer
  alias Bookkeeping.Boundary.GeneralLedger.Registry, as: GeneralLedgerRegistry

  @type account_code_t :: String.t()
  @type account_name_t :: String.t()

  @doc """
  Starts the AccountLedgerBackup agent.

  ## Examples

      iex> {:ok, pid} = Bookkeeping.Boundary.GeneralLedger.AccountLedger.Backup.start_link()
      {:ok, #PID<0.0.0>}
  """

  def start_link({account, backup_state}) do
    Agent.start_link(fn -> backup_state end, name: process_name(account))
  end

  @doc """
  Gets the account ledger from the AccountLedgerBackup agent.

  ## Examples

      iex> Bookkeeping.Boundary.GeneralLedger.AccountLedger.Backup.get()
      {:ok, account_ledger}
  """
  # @spec get :: {:ok, AccountLedgerServer.account_ledger_state()}
  def get(account) do
    account_ledger = Agent.get(process_name(account), fn state -> state end)
    {:ok, account_ledger}
  end

  @doc """
  Updates the account ledger in the AccountLedgerBackup agent.

  ## Examples

      iex> Bookkeeping.Boundary.GeneralLedger.AccountLedger.Backup.update(%{})
      {:ok, :backup_updated}
  """
  # @spec update(AccountLedgerServer.account_ledger_state()) :: {:ok, :backup_updated}
  def update(account, new_value) do
    IO.inspect("this is called")
    Agent.update(process_name(account), fn _state -> new_value end)
    {:ok, :backup_updated}
  end

  defp process_name(account) do
    GeneralLedgerRegistry.via_tuple({__MODULE__, account.code})
  end
end
