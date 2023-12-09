defmodule Bookkeeping.Boundary.ChartOfAccounts.Supervisor do
  use Supervisor

  alias Bookkeeping.Boundary.ChartOfAccounts.Worker
  alias Bookkeeping.Boundary.ChartOfAccounts.Manager

  @type init_options_t :: list()
  @type sup_flags_t :: map()
  @type children_specs_t :: list(:supervisor.child_spec())

  @spec start_link(init_options_t()) ::
          {:ok, pid} | {:error, {:already_started, pid()} | {:shutdown, term()} | term()}

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  @spec init(any()) :: {:ok, {sup_flags_t(), children_specs_t}}
  @impl true
  def init(_init_arg) do
    children = [
      {Worker, [name: Worker]},
      {Manager, %{}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
