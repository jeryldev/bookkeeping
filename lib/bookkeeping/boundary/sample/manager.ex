defmodule Bookkeeping.Boundary.Sample.Manager do
  use GenServer

  alias Bookkeeping.Boundary.Sample.Worker

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    worker = Process.whereis(Worker)
    Process.link(worker)
    table = :ets.new(:give_away, [:private])
    data = {:count, 0}
    :ets.insert(table, data)
    :ets.setopts(table, {:heir, self(), data})
    :ets.give_away(table, worker, data)
    {:ok, table}
  end

  def handle_info({:EXIT, _from, _reason}, table), do: {:noreply, table}

  def handle_info({:"ETS-TRANSFER", table, _pid, data}, _table) do
    worker = wait_for_worker()
    Process.link(worker)
    :ets.give_away(table, worker, data)
    {:noreply, table}
  end

  def wait_for_worker() do
    case Process.whereis(Worker) do
      nil ->
        Process.sleep(1)
        wait_for_worker()

      pid ->
        pid
    end
  end
end
