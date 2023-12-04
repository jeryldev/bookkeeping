defmodule Bookkeeping.Boundary.Sample.Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_info({:"ETS-TRANSFER", table, _pid, _data}, _table) do
    {:noreply, table}
  end

  def handle_call({:get, key}, _from, table) do
    case :ets.lookup(table, key) do
      [] ->
        {:reply, nil, table}

      [{_key, value}] ->
        {:reply, value, table}
    end
  end

  def handle_call({:put, key, value}, _from, table) do
    result = :ets.insert(table, {key, value})
    {:reply, result, table}
  end

  def handle_cast(:die, table) do
    {:stop, table, :killed}
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  def die() do
    GenServer.cast(__MODULE__, :die)
  end
end
