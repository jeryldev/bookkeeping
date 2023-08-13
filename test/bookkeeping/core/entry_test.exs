defmodule Bookkeeping.Core.EntryTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.Entry

  test "allow entry types of :debit and :credit" do
    assert Entry.new(:debit) == {:ok, %Entry{type: :debit}}
    assert Entry.new(:credit) == {:ok, %Entry{type: :credit}}
  end

  test "disallow entry types other than :debit and :credit" do
    assert Entry.new(:invalid) == {:error, %Entry{type: :invalid_type}}
  end
end
