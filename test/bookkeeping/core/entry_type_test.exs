defmodule Bookkeeping.Core.EntryTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.EntryType

  test "create debit entry type" do
    assert EntryType.create("debit") == {:ok, %EntryType{type: :debit, name: "Debit"}}
  end

  test "create credit entry type" do
    assert EntryType.create("credit") ==
             {:ok, %EntryType{type: :credit, name: "Credit"}}
  end

  test "disallow invalid entry type" do
    assert EntryType.create("invalid") == {:error, :invalid_entry_type}
  end
end
