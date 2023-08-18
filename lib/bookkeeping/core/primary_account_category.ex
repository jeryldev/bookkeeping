defmodule Bookkeeping.Core.PrimaryAccountCategory do
  @moduledoc """
  Bookkeeping.Core.PrimaryAccountCategory is a struct that represents the primary category of an account.
  Primary account category is a category that is used to group accounts based on the type of information they provide.
  There are two types of primary account categories: balance sheet and profit and loss.
  """
  defstruct type: nil

  @primary_reporting_categories [:balance_sheet, :profit_and_loss]

  @doc """
  Creates a new account category struct.

  Returns `{:ok, %PrimaryAccountCategory{}}` if the primary account category is valid. Otherwise, returns `{:error, :invalid_primary_account_category}`.

  ## Examples

      iex> PrimaryAccountCategory.create("balance_sheet")
      {:ok, %PrimaryAccountCategory{type: :balance_sheet}}
      iex> PrimaryAccountCategory.create("profit_and_loss")
      {:ok, %PrimaryAccountCategory{type: :profit_and_loss}}
      iex> PrimaryAccountCategory.create("invalid")
      {:error, :invalid_primary_account_category}
  """
  def create("balance_sheet"), do: new(:balance_sheet)
  def create("profit_and_loss"), do: new(:profit_and_loss)
  def create(binary_type), do: new(binary_type)

  defp new(type) when type in @primary_reporting_categories, do: {:ok, %__MODULE__{type: type}}
  defp new(_type), do: {:error, :invalid_primary_account_category}
end
