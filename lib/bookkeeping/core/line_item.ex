defmodule Bookkeeping.Core.LineItem do
  @moduledoc """
  Bookkeeping.Core.LineItem is a struct that represents a line item in a journal entry.
  A line item is a record of a single account and the amount of money that is either debited or credited.
  """
  alias Bookkeeping.Core.{Account, Types}

  @typedoc """
  t type is a struct that represents a line item in a journal entry.
  """
  @type t :: %__MODULE__{
          account: Account.t(),
          amount: Decimal.t(),
          entry: Types.entry(),
          particulars: String.t()
        }

  defstruct account: nil,
            amount: 0,
            entry: nil,
            particulars: ""

  @doc """
  Creates a new line item struct.

  Arguments:
    - params: The params of the line item. It must contain the following keys:
      - account: The account of the line item.
      - amount: The amount of the line item.
      - entry: The entry type of the line item.
      - particulars: The particulars of the line item.

  Returns `{:ok, %LineItem{...}}` if the line item is valid. Otherwise, returns any of the following:
    - `{:error, :invalid_account}`
    - `{:error, :invalid_amount}`
    - `{:error, :invalid_entry}`
    - `{:error, :invalid_particulars}`
    - `{:error, :invalid_params}`.

  ## Examples

      iex> Account.create(%{code: "10_000", name: "cash", classification: "asset", particulars: "", audit_details: %{}, active: true})
      {:ok, asset_account}

      iex> LineItem.create(%{account: asset_account, amount: Decimal.new(100), entry: :debit, particulars: ""})
      {:ok, %LineItem{...}}

      iex> LineItem.create(%{account: nil, amount: Decimal.new(100), entry: :debit, particulars: ""})
      {:error, :invalid_account}

      iex> LineItem.create(%{account: asset_account, amount: 100, entry: :debit, particulars: ""})
      {:error, :invalid_amount}

      iex> LineItem.create(%{account: asset_account, amount: Decimal.new(100), entry: :invalid, particulars: ""})
      {:error, :invalid_entry}

      iex> LineItem.create(%{account: asset_account, amount: Decimal.new(100), entry: :debit, particulars: nil})
      {:error, :invalid_particulars}

      iex> LineItem.create(%{account: asset_account, amount: Decimal.new(100), entry: :debit})
      {:error, :invalid_params}
  """
  @spec create(LineItem.t()) ::
          {:ok, __MODULE__.t()}
          | {:error,
             :invalid_account
             | :invalid_amount
             | :invalid_entry
             | :invalid_particulars
             | :invalid_params}
  def create(params) do
    with {:ok, params} <- validate_params(params) do
      {:ok, Map.merge(%__MODULE__{}, params)}
    end
  end

  @doc """
  Validates a line item struct.

  Arguments:
    - line item: The line item to be validated

  Returns `{:ok, %LineItem{...}}` if the account is valid. Otherwise, returns `{:error, :invalid_line_item}`.

  ## Examples

      iex> LineItem.validate(line_item)
      {:ok, %LineItem{...}}

      iex> LineItem.validate(%LineItem{})
      {:error, :invalid_line_item}
  """
  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_line_item}
  def validate(line_item)
      when is_struct(line_item, __MODULE__) do
    case validate_params(line_item) do
      {:ok, _line_item} -> {:ok, line_item}
      {:error, _reason} -> {:error, :invalid_line_item}
    end
  end

  def validate(_), do: {:error, :invalid_line_item}

  defp validate_params(
         %{
           account: account,
           amount: amount,
           entry: entry,
           particulars: particulars
         } = params
       ) do
    with {:ok, _account} <- validate_account(account),
         {:ok, _amount} <- validate_amount(amount),
         {:ok, _entry} <- validate_entry(entry),
         {:ok, _particulars} <- validate_particulars(particulars) do
      {:ok, params}
    end
  end

  defp validate_params(_), do: {:error, :invalid_params}

  defp validate_account(account) do
    case Account.validate(account) do
      {:ok, _account} -> {:ok, account}
      {:error, _reason} -> {:error, :invalid_account}
    end
  end

  defp validate_amount(amount) when is_struct(amount, Decimal) do
    if Decimal.gt?(amount, Decimal.new(0)),
      do: {:ok, amount},
      else: {:error, :invalid_amount}
  end

  defp validate_amount(_amount), do: {:error, :invalid_amount}

  defp validate_entry(entry) when entry in [:debit, :credit],
    do: {:ok, entry}

  defp validate_entry(_entry), do: {:error, :invalid_entry}

  defp validate_particulars(particulars) when is_binary(particulars),
    do: {:ok, particulars}

  defp validate_particulars(_particulars), do: {:error, :invalid_particulars}
end
