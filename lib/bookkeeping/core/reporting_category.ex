defmodule Bookkeeping.Core.ReportingCategory do
  @moduledoc """
  Bookkeeping.Core.ReportingCategory is a struct that represents the reporting category of an account.
  A reporting category is a category that is used to group accounts together for reporting purposes.
  Reporting categories are used to generate financial statements.
  There are two types of primary reporting categories: balance sheet and profit and loss.
  We can also create custom reporting categories.
  """
  defstruct type: nil, primary: false
  @primary_reporting_categories [:balance_sheet, :profit_and_loss]

  @doc """
  Creates a new primary reporting category of type :balance_sheet.

  Returns `{:ok, %Bookkeeping.Core.ReportingCategory{type: :balance_sheet, primary: true}}`.

  ## Examples:

      iex> Bookkeeping.Core.ReportingCategory.balance_sheet()
      {:ok, %Bookkeeping.Core.ReportingCategory{type: :balance_sheet, primary: true}}
  """
  def balance_sheet, do: new(:balance_sheet)

  @doc """
  Creates a new primary reporting category of type :profit_and_loss.

  Returns `{:ok, %Bookkeeping.Core.ReportingCategory{type: :profit_and_loss, primary: true}}`.

  ## Examples:

      iex> Bookkeeping.Core.ReportingCategory.profit_and_loss()
      {:ok, %Bookkeeping.Core.ReportingCategory{type: :profit_and_loss, primary: true}}
  """
  def profit_and_loss, do: new(:profit_and_loss)

  def new(type) when is_atom(type) and type in @primary_reporting_categories,
    do: {:ok, %__MODULE__{type: type, primary: true}}

  def new(type) when is_atom(type), do: {:ok, %__MODULE__{type: type, primary: false}}

  def new(_type), do: {:error, :invalid_reporting_category_type}
end
