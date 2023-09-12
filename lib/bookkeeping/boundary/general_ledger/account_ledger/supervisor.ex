defmodule Bookkeeping.Boundary.GeneralLedger.AccountLedger.Supervisor do
  use Supervisor

  alias Bookkeeping.Boundary.GeneralLedger.AccountLedger.Backup, as: AccountLedgerBackup
  alias Bookkeeping.Boundary.GeneralLedger.AccountLedger.Server, as: AccountLedgerServer
  alias Bookkeeping.Boundary.GeneralLedger.Registry, as: GeneralLedgerRegistry
  alias Bookkeeping.Core.Account

  @type account_code_t :: String.t()
  @type account_name_t :: String.t()

  # def child_spec(%Account{} = account) do
  #   %{
  #     id: {__MODULE__, {account.code, account.name}},
  #     start: {__MODULE__, :start_link, [account]},
  #     name: via({account.code, account.name})
  #   }
  # end

  # def create_account_ledger(%Account{} = account) do
  #   DynamicSupervisor.start_child(
  #     GeneralLedgerDynamicSupervisor,
  #     {__MODULE__, account}
  #   )
  # end

  # def start_link(%Account{} = account) do
  #   Supervisor.start_link(
  #     __MODULE__,
  #     account,
  #     name: via({account.code, account.name})
  #   )
  # end

  def start_link(account) do
    Supervisor.start_link(__MODULE__, {:ok, account},
      # name: via({account.code, account.name, "AccountLedgerSupervisor"})
      name: process_name(account)
    )
  end

  # def start_link(options \\ []) do
  #   IO.inspect("options")
  #   IO.inspect(options)

  #   Supervisor.start_link(__MODULE__, :ok, options)
  # end

  # def start_link(options \\ []) do
  #   Supervisor.start_link(__MODULE__, :ok, options)
  # end

  @impl true
  def init({:ok, account}) do
    children = [
      # {AccountLedgerBackup, %{account: account}},
      # {AccountLedgerServer, [name: via({account.code, account.name, "AccountLedgerServer"})]}
      {AccountLedgerBackup, {account, %{}}},
      {AccountLedgerServer, account}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  # defp process_name(%Account{} = account, type) when type in ["supervisor", "server", "backup"] do
  #   # via({account.code, account.name, "AccountLedgerSupervisor"})
  #   String.to_atom("#{account.code}_#{account.name}_#{type}")
  # end

  defp process_name(%Account{} = account) do
    GeneralLedgerRegistry.via_tuple({__MODULE__, account.code})
  end
end
