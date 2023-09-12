defmodule Bookkeeping.Boundary.GeneralLedger.DynamicSupervisor do
  use DynamicSupervisor

  alias Bookkeeping.Boundary.GeneralLedger.AccountLedger.Supervisor, as: AccountLedgerSupervisor
  alias Bookkeeping.Core.Account

  @type account_code_t :: String.t()
  @type account_name_t :: String.t()

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def child_spec(account) do
    %{
      id: __MODULE__,
      start: {
        __MODULE__,
        :start_link,
        [account]
      },
      type: :supervisor
    }
  end

  def create_account_ledger(%Bookkeeping.Core.Account{} = account) do
    case start_child(account) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp start_child(%Account{} = account) do
    DynamicSupervisor.start_child(__MODULE__, {AccountLedgerSupervisor, account})
  end
end
