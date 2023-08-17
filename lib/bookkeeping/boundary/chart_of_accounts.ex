defmodule Bookkeeping.Boundary.ChartOfAccounts do
  @moduledoc """
  Bookkeeping.Boundary.ChartOfAccounts is a GenServer that manages the chart of accounts.
  The chart of accounts is a list of all accounts used by a business.
  """
  use GenServer

  alias Bookkeeping.Core.Account

  @doc """
  Starts the chart of accounts GenServer.

  Returns `{:ok, pid}` if the GenServer was started successfully.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.start_link()
      {:ok, #PID<0.123.0>}
  """
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], options)
  end

  @doc """
  Creates a new account.

  Returns `{:ok, account}` if the account is valid, otherwise `{:error, :invalid_account}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.create_account(server, "1000", "Cash", %Bookkeeping.Core.AccountType{})
      {:ok, %Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: "1000", name: "Cash"}}
  """
  def create_account(server \\ __MODULE__, code, name, account_type) do
    {:ok, existing_accounts} = GenServer.call(server, {:search_matching_account, code, name})

    if existing_accounts == [],
      do: GenServer.call(server, {:create_account, code, name, account_type}),
      else: {:error, :duplicate_account}
  end

  @doc """
  Removes an account.

  Returns `:ok` if the account was removed successfully.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.remove_account(server, account)
      :ok
  """
  def remove_account(server \\ __MODULE__, account) do
    GenServer.call(server, {:remove_account, account})
  end

  @doc """
  Searches for an account by code or name.

  Returns `{:ok, accounts}` if the account was found, otherwise `{:ok, []}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.search_account(server, "1000")
      {:ok, [%Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: "1000", name: "Cash"}]}
  """
  def search_account(server \\ __MODULE__, query) do
    GenServer.call(server, {:search_account, query})
  end

  @doc """
  Returns all accounts.

  Returns `{:ok, accounts}`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.all_accounts(server)
      {:ok, [%Bookkeeping.Core.Account{account_type: %Bookkeeping.Core.AccountType{}, code: "1000", name: "Cash"}]}
  """
  def all_accounts(server \\ __MODULE__) do
    GenServer.call(server, :all_accounts)
  end

  @doc """
  Sorts accounts by code.

  Returns `:ok`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.sort_accounts_by_code(server)
      :ok
  """
  def sort_accounts_by_code(server \\ __MODULE__) do
    GenServer.cast(server, {:sort_account, :code})
  end

  @doc """
  Sorts accounts by name.

  Returns `:ok`.

  ## Examples

      iex> Bookkeeping.Boundary.ChartOfAccounts.sort_accounts_by_name(server)
      :ok
  """
  def sort_accounts_by_name(server \\ __MODULE__) do
    GenServer.cast(server, {:sort_account, :name})
  end

  @impl true
  def init(accounts), do: {:ok, accounts}

  @impl true
  def handle_call({:create_account, code, name, account_type}, _from, accounts) do
    case Account.create(code, name, account_type) do
      {:ok, account} -> {:reply, {:ok, account}, accounts ++ [account]}
      {:error, :invalid_account} -> {:reply, {:error, :invalid_account}, accounts}
    end
  end

  @impl true
  def handle_call({:remove_account, account}, _from, accounts) do
    {:reply, :ok, List.delete(accounts, account)}
  end

  @impl true
  def handle_call({:search_account, query}, _from, accounts) do
    found_accounts =
      accounts
      |> Task.async_stream(fn account ->
        found =
          String.contains?(account.name, query) or
            String.contains?(account.code, query) or
            String.contains?("#{account.code} #{account.name}", query)

        {found, account}
      end)
      |> Enum.reduce([], fn
        {:ok, {true, account}}, acc -> acc ++ [account]
        _, acc -> acc
      end)

    {:reply, {:ok, found_accounts}, accounts}
  end

  @impl true
  def handle_call({:search_matching_account, code, name}, _from, accounts) do
    found_accounts =
      accounts
      |> Task.async_stream(&{&1.code == code or &1.name == name, &1})
      |> Enum.reduce([], fn
        {:ok, {true, account}}, acc -> acc ++ [account]
        _, acc -> acc
      end)

    {:reply, {:ok, found_accounts}, accounts}
  end

  @impl true
  def handle_call(:all_accounts, _from, accounts) do
    {:reply, {:ok, accounts}, accounts}
  end

  @impl true
  def handle_cast({:sort_account, :name}, accounts) do
    {:noreply, Enum.sort_by(accounts, & &1.name)}
  end

  @impl true
  def handle_cast({:sort_account, :code}, accounts) do
    {:noreply, Enum.sort_by(accounts, & &1.code)}
  end
end
