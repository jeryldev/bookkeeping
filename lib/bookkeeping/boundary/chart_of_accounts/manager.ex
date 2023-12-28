defmodule Bookkeeping.Boundary.ChartOfAccounts.Manager do
  use GenServer

  alias Bookkeeping.Boundary.ChartOfAccounts.Worker

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, any()}
  def start_link(_) do
    case GenServer.start_link(__MODULE__, :ok, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end

  @spec init(any()) :: {:ok, atom() | :ets.tid()}
  @impl true
  def init(_) do
    Process.flag(:trap_exit, true)
    setup_table()
  end

  @impl true
  def handle_info({:EXIT, _from, _reason}, table) do
    {:noreply, table}
  end

  @impl true
  def handle_info({:"ETS-TRANSFER", table, _pid, data}, _table) do
    worker = wait_for_worker()
    Process.link(worker)
    :ets.give_away(table, worker, data)
    {:noreply, table}
  end

  defp wait_for_worker do
    case Process.whereis(Worker) do
      nil ->
        Process.sleep(1)
        wait_for_worker()

      pid ->
        pid
    end
  end

  defp setup_table do
    case Process.whereis(Worker) do
      nil ->
        Process.sleep(1)
        setup_table()

      worker ->
        Process.link(worker)

        table =
          :ets.new(:chart_of_accounts, [
            :ordered_set,
            :private,
            write_concurrency: true,
            read_concurrency: true
          ])

        data = {:count, 0}
        :ets.insert(table, data)
        :ets.setopts(table, {:heir, self(), data})
        :ets.give_away(table, worker, data)
        {:ok, table}
    end
  end
end
