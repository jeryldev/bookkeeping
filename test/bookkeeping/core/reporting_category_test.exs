defmodule Bookkeeping.Core.ReportingCategoryTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.ReportingCategory

  test "create a primary reporting category of type :balance_sheet" do
    assert ReportingCategory.balance_sheet() ==
             {:ok,
              %ReportingCategory{
                type: :balance_sheet,
                primary: true
              }}
  end

  test "create a primary reporting category of type :profit_and_loss" do
    assert ReportingCategory.profit_and_loss() ==
             {:ok,
              %ReportingCategory{
                type: :profit_and_loss,
                primary: true
              }}
  end

  test "creating reporting category types of :balance_sheet and :profit_and_loss will automatically set primary field to true" do
    assert ReportingCategory.new(:balance_sheet) ==
             {:ok,
              %ReportingCategory{
                type: :balance_sheet,
                primary: true
              }}

    assert ReportingCategory.new(:profit_and_loss) ==
             {:ok,
              %ReportingCategory{
                type: :profit_and_loss,
                primary: true
              }}
  end

  test "creating reporting category types other than :balance_sheet and :profit_and_loss will automatically set primary field to false" do
    assert ReportingCategory.new(:other) ==
             {:ok,
              %ReportingCategory{
                type: :other,
                primary: false
              }}
  end

  test "only allow Atom type of reporting category" do
    assert ReportingCategory.new("invalid") ==
             {:error, :invalid_reporting_category_type}
  end
end
