defmodule Bookkeeping.Core.EntryTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.EntryType

  test "create debit entry type" do
    assert EntryType.debit() == {:ok, %EntryType{type: :debit}}
  end

  test "create credit entry type" do
    assert EntryType.credit() == {:ok, %EntryType{type: :credit}}
  end

  test "allow entry types of :debit and :credit" do
    assert EntryType.new(:debit) == {:ok, %EntryType{type: :debit}}
    assert EntryType.new(:credit) == {:ok, %EntryType{type: :credit}}
  end

  test "disallow entry types other than :debit and :credit" do
    assert EntryType.new(:invalid) == {:error, :invalid_entry_type}
  end
end
