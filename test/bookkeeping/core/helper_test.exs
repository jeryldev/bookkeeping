defmodule Bookkeeping.Core.HelperTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.Helper

  test "converts string to snake_case" do
    input0 = "Balance Sheet"
    expected_output0 = "balance_sheet"

    assert Helper.to_snake_case(input0) == {:ok, expected_output0}

    input1 = "Owner's Equity"
    expected_output1 = "owner's_equity"
    assert Helper.to_snake_case(input1) == {:ok, expected_output1}
  end
end
