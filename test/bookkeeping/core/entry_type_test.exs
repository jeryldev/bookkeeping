defmodule Bookkeeping.Core.EntryTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.EntryType

  test "create debit entry type" do
    assert EntryType.create(:debit) == {:ok, :debit}
  end

  test "create credit entry type" do
    assert EntryType.create(:credit) == {:ok, :credit}
  end

  test "disallow invalid entry type" do
    assert EntryType.create("invalid") == {:error, :invalid_entry_type}
  end

  test "list entry types" do
    assert EntryType.all_entry_types() == [:debit, :credit]
  end
end
