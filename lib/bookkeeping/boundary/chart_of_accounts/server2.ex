defmodule Bookkeeping.Boundary.ChartOfAccounts.Server2 do
  use GenServer

  alias Bookkeeping.Core.Account

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_init_arg) do
    :ets.new(__MODULE__, [
      :named_table,
      :public,
      write_concurrency: true,
      read_concurrency: true
    ])

    {:ok, nil}
  end

  def create(params) do
    code = Map.get(params, :code, "")
    name = Map.get(params, :name, "")

    with {:error, :not_found} <- search_code(code),
         {:error, :not_found} <- search_name(name),
         {:ok, account} <- Account.create(params) do
      :ets.insert(__MODULE__, {account.code, account.name, account})
      {:ok, account}
    end
  end

  def search_code(code) do
    case :ets.lookup(__MODULE__, code) do
      [{_, _, account}] -> {:ok, account}
      [] -> {:error, :not_found}
    end
  end

  def search_name(name) do
    result = :ets.match(__MODULE__, {:_, name, :"$1"}) |> List.flatten()

    if result == [], do: {:error, :not_found}, else: {:ok, result}
  end

  def update(server \\ __MODULE__) do
    GenServer.call(server, :update)
    # case Account.update(params) do
    #   {:ok, account} ->
    #     :ets.insert(__MODULE__, {account.code, account.name, account})
    #     {:ok, account}

    #   {:error, _} ->
    #     {:error, :invalid_account}
    # end
  end

  def handle_call(:update, _from, state) do
    raise "not implemented"

    {:noreply, state}
  end
end
