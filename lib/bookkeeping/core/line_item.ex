defmodule Bookkeeping.Core.LineItem do
  @moduledoc """
  Bookkeeping.Core.LineItem is a struct that represents a line item in a journal entry.
  A line item is a record of a single account and the amount of money that is either debited or credited.
  """
  alias Bookkeeping.Core.{Account, Types}

  @type t :: %__MODULE__{
          account: Account.t(),
          amount: Decimal.t(),
          entry_type: Types.entry(),
          line_item_description: String.t()
        }

  @type t_accounts :: %{
          left: list(account_amount_pair()),
          right: list(account_amount_pair())
        }

  @type account_amount_pair :: %{
          account: Account.t(),
          amount: Decimal.t(),
          line_item_description: String.t()
        }

  defstruct account: %Account{},
            amount: 0,
            entry_type: nil,
            line_item_description: ""

  @doc """
  Creates a list of line item structs.

  Arguments:
    - t_accounts: The map of line items. The map must have the following keys:
      - left: The list of maps with account, amount, and description field and represents the entry type of debit.
      - right: The list of maps with account, amount, and description field and represents the entry type of credit.

  Returns `{:ok, [%LineItem{}, ...]}` if the line item is valid. Otherwise, returns `{:error, :invalid_line_items}`.

  ## Examples

      iex> LineItem.bulk_create(%{left: [%{account: expense_account, amount: Decimal.new(100), line_item_description: ""}], right: [%{account: asset_account, amount: Decimal.new(100), line_item_description: ""}]})
      {:ok, [%LineItem{...}, %LineItem{...}]}

      iex> LineItem.bulk_create(%{left: [%{account: expense_account, amount: Decimal.new(100)}], right: []})
      {:error, :unbalanced_line_items}
  """
  @spec bulk_create(t_accounts()) ::
          {:ok, list(__MODULE__.t())}
          | {:error, %{message: :invalid_line_items, errors: list(atom())}}
          | {:error, :invalid_line_items}
  def bulk_create(%{left: left, right: right} = t_accounts) when left != [] and right != [] do
    bulk_create_result =
      t_accounts
      |> Task.async_stream(fn
        {:left, debit_items} -> Task.async_stream(debit_items, &create(&1, :debit))
        {:right, credit_items} -> Task.async_stream(credit_items, &create(&1, :credit))
      end)
      |> Enum.reduce(
        %{
          debit_balance: Decimal.new(0),
          credit_balance: Decimal.new(0),
          balanced: false,
          created_line_items: [],
          errors: []
        },
        &validate_line_items/2
      )

    case bulk_create_result.created_line_items do
      [] ->
        {:error, %{message: :invalid_line_items, errors: bulk_create_result.errors}}

      created_line_items ->
        cond do
          bulk_create_result.errors != [] -> {:error, bulk_create_result.errors}
          bulk_create_result.balanced == false -> {:error, :unbalanced_line_items}
          true -> {:ok, created_line_items}
        end
    end
  end

  def bulk_create(_), do: {:error, :invalid_line_items}

  @doc """
    Creates a new line item struct.

    Arguments:
      - account_amount_pair: The map with account and amount field.
      - atom_entry_type: The atom that represents the entry type of the line item. The atom must be either `:debit` or `:credit`.
      - line_item_description (optional): The description of the line item.

    Returns `{:ok, %LineItem{}}` if the line item is valid. Otherwise, returns `{:error, :invalid_line_items}`, `{:error, :unbalanced_line_items}`, or `{:error, list(:invalid_amount | :invalid_account | :inactive_account)}`.

    ## Examples

        iex> LineItem.create(account_amount_pair(), :debit)
        {:ok, %LineItem{...}}
  """
  @spec create(account_amount_pair(), Types.entry()) ::
          {:ok, __MODULE__.t()}
          | {:error, :invalid_line_items}
          | {:error, :unbalanced_line_items}
          | {:error, list(:invalid_amount | :invalid_account | :inactive_account)}
  def create(account_amount_pair, atom_entry_type) do
    with {:ok, %{account: account, amount: amount}} <-
           validate_account_and_amount(account_amount_pair),
         {:ok, entry_type} <- validate_entry_type(atom_entry_type) do
      line_item_description = Map.get(account_amount_pair, :line_item_description, "")

      {:ok,
       %__MODULE__{
         account: account,
         amount: amount,
         entry_type: entry_type,
         line_item_description: line_item_description
       }}
    else
      {:error, message} -> {:error, message}
      _ -> {:error, :invalid_line_items}
    end
  end

  defp validate_line_items({:ok, line_items}, acc) do
    Enum.reduce(line_items, acc, fn
      {:ok, {:ok, line_item}}, acc -> process_line_item(acc, line_item)
      {:ok, {:error, message}}, acc -> Map.put(acc, :errors, [message | acc.errors])
    end)
  end

  defp validate_account_and_amount(account_amount_pair) when is_map(account_amount_pair) do
    account = Map.get(account_amount_pair, :account)
    amount = Map.get(account_amount_pair, :amount)

    with {:ok, account} <- validate_account(account),
         {:ok, amount} <- validate_amount(amount) do
      {:ok, %{account: account, amount: amount}}
    else
      {:error, message} -> {:error, message}
      _ -> {:error, :invalid_line_items}
    end
  end

  defp validate_account_and_amount(_), do: {:error, :invalid_account_and_amount_map}

  defp validate_account(account)
       when is_struct(account, Account) and not account.active,
       do: {:error, :inactive_account}

  defp validate_account(account)
       when is_struct(account, Account) and account.active,
       do: {:ok, account}

  defp validate_account(_), do: {:error, :invalid_account}

  defp validate_amount(amount) when is_struct(amount, Decimal) do
    if Decimal.gt?(amount, Decimal.new(0)),
      do: {:ok, amount},
      else: {:error, :invalid_amount}
  end

  defp validate_amount(_), do: {:error, :invalid_amount}

  defp validate_entry_type(:debit), do: {:ok, :debit}
  defp validate_entry_type(:credit), do: {:ok, :credit}

  defp process_line_item(acc, line_item) do
    entry_type = line_item.entry_type

    updated_debit_balance =
      if entry_type == :debit,
        do: Decimal.add(acc.debit_balance, line_item.amount),
        else: acc.debit_balance

    updated_credit_balance =
      if entry_type == :credit,
        do: Decimal.add(acc.credit_balance, line_item.amount),
        else: acc.credit_balance

    %{
      debit_balance: updated_debit_balance,
      credit_balance: updated_credit_balance,
      balanced: Decimal.equal?(updated_debit_balance, updated_credit_balance),
      created_line_items: [line_item | acc.created_line_items],
      errors: acc.errors
    }
  end
end
