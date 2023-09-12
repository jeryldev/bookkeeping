defmodule Bookkeeping.Boundary.GeneralLedger.AccountLedger.Server do
  use GenServer

  alias Bookkeeping.Boundary.GeneralLedger.AccountLedger.Backup, as: AccountLedgerBackup
  alias Bookkeeping.Boundary.GeneralLedger.Registry, as: GeneralLedgerRegistry
  alias Bookkeeping.Core.Account

  @type account_ledger_state() :: map()

  @type chart_of_account_server_pid :: atom() | pid() | {atom, any} | {:via, atom, any}

  def start_link(account) do
    GenServer.start_link(__MODULE__, account, name: process_name(account))
  end

  def reset_account_ledger(account) do
    GenServer.call(process_name(account), {:reset_account_ledger, account})
  end

  @impl true
  # @spec init(Keyword.t()) :: {:ok, account_ledger_state()}
  def init(account) do
    AccountLedgerBackup.get(account)
  end

  @impl true
  def handle_call({:reset_account_ledger, account}, _from, _account_ledger) do
    AccountLedgerBackup.update(account, %{})
    {:reply, {:ok, %{}}, %{}}
  end

  @impl true
  def terminate(_reason, account_ledger) do
    # AccountLedgerBackup.update(account_ledger)
    {:ok, account_ledger}
  end

  defp process_name(%Account{} = account) do
    GeneralLedgerRegistry.via_tuple({__MODULE__, account.code})
  end
end
