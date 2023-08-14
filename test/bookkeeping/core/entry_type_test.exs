defmodule Bookkeeping.Core.EntryTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.EntryType

  test "create debit entry type" do
    assert EntryType.debit() == {:ok, %EntryType{type: :debit, name: "Debit"}}
  end

  test "create credit entry type" do
    assert EntryType.credit() == {:ok, %EntryType{type: :credit, name: "Credit"}}
  end

  test "allow entry types of :debit and :credit" do
    assert EntryType.new(:debit, "Debit") == {:ok, %EntryType{type: :debit, name: "Debit"}}
    assert EntryType.new(:credit, "Credit") == {:ok, %EntryType{type: :credit, name: "Credit"}}
  end

  test "disallow entry types other than :debit and :credit" do
    assert EntryType.new(:invalid, "Invalid") == {:error, :invalid_entry_type}
  end

  test "only allow Atom type of entry type" do
    assert EntryType.new("invalid", "invalid") == {:error, :invalid_entry_type}
  end

  test "only allow String type of entry type name" do
    assert EntryType.new(:debit, :invalid) == {:error, :invalid_entry_type}
  end
end
