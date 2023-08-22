defmodule Bookkeeping.Core.PrimaryAccountCategory do
  @moduledoc """
  Bookkeeping.Core.PrimaryAccountCategory is a module that represents the primary category of an account.
  Primary account category is a category that is used to group accounts based on the type of information they provide.
  There are two types of primary account categories: balance sheet and profit and loss.
  """
  @type t :: :balance_sheet | :profit_and_loss

  @primary_account_categories [:balance_sheet, :profit_and_loss]

  @doc """
  Creates a new account category type.

  Returns `{:ok, :balance_sheet}` or `{:ok, :profit_and_loss}` if the account category type is valid. Otherwise, returns `{:error, :invalid_primary_account_category}`.

  ## Examples

      iex> PrimaryAccountCategory.create(:balance_sheet)
      {:ok, :balance_sheet}

      iex> PrimaryAccountCategory.create(:profit_and_loss)
      {:ok, :profit_and_loss}

      iex> PrimaryAccountCategory.create("invalid")
      {:error, :invalid_primary_account_category}
  """
  @spec create(__MODULE__.t()) ::
          {:ok, __MODULE__.t()} | {:error, :invalid_primary_account_category}
  def create(atom_primary_account_category)
      when atom_primary_account_category in @primary_account_categories,
      do: {:ok, atom_primary_account_category}

  def create(_), do: {:error, :invalid_primary_account_category}

  @doc """
  Returns a list of all primary account categories.

  ## Examples

      iex> PrimaryAccountCategory.all_primary_account_categories()
      [:balance_sheet, :profit_and_loss]
  """
  def all_primary_account_categories, do: @primary_account_categories
end
