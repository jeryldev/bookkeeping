defmodule Bookkeeping.Core.PrimaryAccountCategoryTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.PrimaryAccountCategory

  test "create a primary account category of type :balance_sheet" do
    assert PrimaryAccountCategory.create("balance_sheet") ==
             {:ok, %PrimaryAccountCategory{type: :balance_sheet}}
  end

  test "create a primary account category of type :profit_and_loss" do
    assert PrimaryAccountCategory.create("profit_and_loss") ==
             {:ok, %PrimaryAccountCategory{type: :profit_and_loss}}
  end

  test "disallow invalid primary account category type" do
    assert PrimaryAccountCategory.create("invalid") ==
             {:error, :invalid_primary_account_category_type}
  end
end
