defmodule Bookkeeping.Core.EntryTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.EntryType

  test "debit entry type" do
    assert EntryType.debit() == {:ok, %EntryType{type: :debit}}
  end

  test "credit entry type" do
    assert EntryType.credit() == {:ok, %EntryType{type: :credit}}
  end

  test "allow entry types of :debit and :credit" do
    assert EntryType.new(:debit) == {:ok, %EntryType{type: :debit}}
    assert EntryType.new(:credit) == {:ok, %EntryType{type: :credit}}
  end

  test "disallow entry types other than :debit and :credit" do
    assert EntryType.new(:invalid) == {:error, %EntryType{type: :invalid_type}}
  end
end
