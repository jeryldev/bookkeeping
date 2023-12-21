defmodule Bookkeeping.Core.LineItem do
  @moduledoc """
  Bookkeeping.Core.LineItem is a struct that represents a line item in a journal entry.
  A line item is a record of a single account and the amount of money that is either debited or credited.
  """
  alias Bookkeeping.Core.LineItem
  alias Bookkeeping.Core.{Account, Types}

  @typedoc """
  t type is a struct that represents a line item in a journal entry.
  """
  @type t :: %__MODULE__{
          account: Account.t(),
          amount: Decimal.t(),
          entry_type: Types.entry(),
          description: String.t()
        }

  defstruct account: nil,
            amount: 0,
            entry_type: nil,
            description: ""

  @doc """
  Creates a new line item struct.

  Arguments:
    - params: The params of the line item. It must contain the following keys:
      - account: The account of the line item.
      - amount: The amount of the line item.
      - entry_type: The entry type of the line item.
      - description: The description of the line item.

  Returns `{:ok, %LineItem{}}` if the line item is valid. Otherwise, returns `{:error, :invalid_account}`, `{:error, :invalid_amount}`, `{:error, :invalid_entry_type}`, `{:error, :invalid_description}`, or `{:error, :invalid_params}`.

  ## Examples

      iex> Account.create(%{code: "10_000", name: "cash", classification: "asset", description: "", audit_details: %{}, active: true})
      {:ok, asset_account}

      iex> LineItem.create(%{account: asset_account, amount: Decimal.new(100), entry_type: :debit, description: ""})
      {:ok, %LineItem{...}}

      iex> LineItem.create(%{account: nil, amount: Decimal.new(100), entry_type: :debit, description: ""})
      {:error, :invalid_account}

      iex> LineItem.create(%{account: asset_account, amount: 100, entry_type: :debit, description: ""})
      {:error, :invalid_amount}

      iex> LineItem.create(%{account: asset_account, amount: Decimal.new(100), entry_type: :invalid, description: ""})
      {:error, :invalid_entry_type}

      iex> LineItem.create(%{account: asset_account, amount: Decimal.new(100), entry_type: :debit, description: nil})
      {:error, :invalid_description}

      iex> LineItem.create(%{account: asset_account, amount: Decimal.new(100), entry_type: :debit})
      {:error, :invalid_params}
  """
  @spec create(LineItem.t()) ::
          {:ok, __MODULE__.t()}
          | {:error,
             :invalid_account
             | :invalid_amount
             | :invalid_entry_type
             | :invalid_description
             | :invalid_params}
  def create(params) do
    params |> validate_params() |> maybe_create()
  end

  def validate(line_item)
      when is_struct(line_item, LineItem) do
    case validate_params(line_item) do
      {:error, _reason} -> {:error, :invalid_line_item}
      _params -> {:ok, line_item}
    end
  end

  def validate(_), do: {:error, :invalid_line_item}

  defp validate_params(
         %{
           account: account,
           amount: amount,
           entry_type: entry_type,
           description: description
         } = params
       ) do
    with {:ok, _account} <- Account.validate(account),
         {:ok, _amount} <- validate_amount(amount),
         {:ok, _entry_type} <- validate_entry_type(entry_type),
         {:ok, _description} <- validate_description(description) do
      params
    end
  end

  defp validate_params(_), do: {:error, :invalid_params}

  defp maybe_create(%{
         account: account,
         amount: amount,
         entry_type: entry_type,
         description: description
       }) do
    {:ok,
     %__MODULE__{
       account: account,
       amount: amount,
       entry_type: entry_type,
       description: description
     }}
  end

  defp maybe_create({:error, reason}), do: {:error, reason}

  defp validate_amount(amount) when is_struct(amount, Decimal) do
    if Decimal.gt?(amount, Decimal.new(0)),
      do: {:ok, amount},
      else: {:error, :invalid_amount}
  end

  defp validate_amount(_), do: {:error, :invalid_amount}

  defp validate_entry_type(type) when type in [:debit, :credit], do: {:ok, type}
  defp validate_entry_type(_), do: {:error, :invalid_entry_type}

  defp validate_description(description) when is_binary(description), do: {:ok, description}
  defp validate_description(_), do: {:error, :invalid_description}
  # @typedoc """
  # t_accounts type is a map that represents the debit and credit lists of line amount data.
  # """
  # @type t_accounts :: %{
  #         left: list(line_amount_data()),
  #         right: list(line_amount_data())
  #       }

  # @typedoc """
  # line_amount_data type is a map that represents the account, amount, and description of a line item.
  # """
  # @type line_amount_data :: %{
  #         account: Account.t(),
  #         amount: Decimal.t(),
  #         description: String.t()
  #       }

  # @doc """
  # Creates a list of line item structs.

  # Arguments:
  #   - t_accounts: The map of line items. The map must have the following keys:
  #     - left: The list of maps with account, amount, and description field and represents the entry type of debit.
  #     - right: The list of maps with account, amount, and description field and represents the entry type of credit.

  # Returns `{:ok, [%LineItem{}, ...]}` if the line item is valid. Otherwise, returns `{:error, :invalid_line_items}`.

  # ## Examples

  #     iex> LineItem.bulk_create(%{left: [%{account: expense_account, amount: Decimal.new(100), description: ""}], right: [%{account: asset_account, amount: Decimal.new(100), description: ""}]})
  #     {:ok, [%LineItem{...}, %LineItem{...}]}

  #     iex> LineItem.bulk_create(%{left: [%{account: expense_account, amount: Decimal.new(100)}], right: []})
  #     {:error, :unbalanced_line_items}
  # """
  # @spec bulk_create(t_accounts()) ::
  #         {:ok, list(__MODULE__.t())}
  #         | {:error, %{message: :invalid_line_items, errors: list(atom())}}
  #         | {:error, :invalid_line_items}
  # def bulk_create(%{left: left, right: right} = t_accounts) when left != [] and right != [] do
  #   bulk_create_result =
  #     t_accounts
  #     |> Task.async_stream(fn
  #       {:left, debit_items} -> Task.async_stream(debit_items, &create(&1, :debit))
  #       {:right, credit_items} -> Task.async_stream(credit_items, &create(&1, :credit))
  #     end)
  #     |> Enum.reduce(
  #       %{
  #         debit_balance: Decimal.new(0),
  #         credit_balance: Decimal.new(0),
  #         balanced: false,
  #         created_line_items: [],
  #         errors: []
  #       },
  #       &validate_line_items/2
  #     )

  #   case bulk_create_result.created_line_items do
  #     [] ->
  #       {:error, %{message: :invalid_line_items, errors: bulk_create_result.errors}}

  #     created_line_items ->
  #       cond do
  #         bulk_create_result.errors != [] -> {:error, bulk_create_result.errors}
  #         bulk_create_result.balanced == false -> {:error, :unbalanced_line_items}
  #         true -> {:ok, created_line_items}
  #       end
  #   end
  # end

  # def bulk_create(_), do: {:error, :invalid_line_items}

  # @doc """
  #   Creates a new line item struct.

  #   Arguments:
  #     - account_amount_pair: The map with account and amount field.
  #     - atom_entry_type: The atom that represents the entry type of the line item. The atom must be either `:debit` or `:credit`.
  #     - description (optional): The description of the line item.

  #   Returns `{:ok, %LineItem{}}` if the line item is valid. Otherwise, returns `{:error, :invalid_line_items}`, `{:error, :unbalanced_line_items}`, or `{:error, list(:invalid_amount | :invalid_account | :inactive_account)}`.

  #   ## Examples

  #       iex> LineItem.create(line_amount_data(), :debit)
  #       {:ok, %LineItem{...}}
  # """
  # @spec create(line_amount_data(), Types.entry()) ::
  #         {:ok, __MODULE__.t()}
  #         | {:error, :invalid_line_items}
  #         | {:error, :unbalanced_line_items}
  #         | {:error, list(:invalid_amount | :invalid_account | :inactive_account)}
  # def create(account_amount_pair, atom_entry_type) do
  #   with {:ok, %{account: account, amount: amount}} <-
  #          validate_account_and_amount(account_amount_pair),
  #        {:ok, entry_type} <- validate_entry_type(atom_entry_type) do
  #     description = Map.get(account_amount_pair, :description, "")

  #     {:ok,
  #      %__MODULE__{
  #        account: account,
  #        amount: amount,
  #        entry_type: entry_type,
  #        description: description
  #      }}
  #   else
  #     {:error, message} -> {:error, message}
  #     _ -> {:error, :invalid_line_items}
  #   end
  # end

  # defp validate_line_items({:ok, line_items}, acc) do
  #   Enum.reduce(line_items, acc, fn
  #     {:ok, {:ok, line_item}}, acc -> process_line_item(acc, line_item)
  #     {:ok, {:error, message}}, acc -> Map.put(acc, :errors, [message | acc.errors])
  #   end)
  # end

  # defp validate_account_and_amount(account_amount_pair) when is_map(account_amount_pair) do
  #   account = Map.get(account_amount_pair, :account)
  #   amount = Map.get(account_amount_pair, :amount)

  #   with {:ok, account} <- validate_account(account),
  #        {:ok, amount} <- validate_amount(amount) do
  #     {:ok, %{account: account, amount: amount}}
  #   else
  #     {:error, message} -> {:error, message}
  #     _ -> {:error, :invalid_line_items}
  #   end
  # end

  # defp validate_account_and_amount(_), do: {:error, :invalid_account_and_amount_map}

  # defp validate_account(account)
  #      when is_struct(account, Account) and not account.active,
  #      do: {:error, :inactive_account}

  # defp validate_account(account)
  #      when is_struct(account, Account) and account.active,
  #      do: {:ok, account}

  # defp validate_account(_), do: {:error, :invalid_account}

  # defp validate_amount(amount) when is_struct(amount, Decimal) do
  #   if Decimal.gt?(amount, Decimal.new(0)),
  #     do: {:ok, amount},
  #     else: {:error, :invalid_amount}
  # end

  # defp validate_amount(_), do: {:error, :invalid_amount}

  # defp validate_entry_type(:debit), do: {:ok, :debit}
  # defp validate_entry_type(:credit), do: {:ok, :credit}

  # defp process_line_item(acc, line_item) do
  #   entry_type = line_item.entry_type

  #   updated_debit_balance =
  #     if entry_type == :debit,
  #       do: Decimal.add(acc.debit_balance, line_item.amount),
  #       else: acc.debit_balance

  #   updated_credit_balance =
  #     if entry_type == :credit,
  #       do: Decimal.add(acc.credit_balance, line_item.amount),
  #       else: acc.credit_balance

  #   %{
  #     debit_balance: updated_debit_balance,
  #     credit_balance: updated_credit_balance,
  #     balanced: Decimal.equal?(updated_debit_balance, updated_credit_balance),
  #     created_line_items: [line_item | acc.created_line_items],
  #     errors: acc.errors
  #   }
  # end
end
