defmodule Bookkeeping.Core.EntryTypeBenchmark do
  Benchee.run(%{
    "create debit function" => fn ->
      Bookkeeping.Core.EntryType.create(:debit)
    end,
    "declare entry type" => fn -> :debit end
  })

  Benchee.run(%{
    "create credit function" => fn ->
      Bookkeeping.Core.EntryType.create(:credit)
    end,
    "declare entry type" => fn -> :credit end
  })

  Benchee.run(%{
    "return all entry types function" => fn ->
      Bookkeeping.Core.EntryType.all_entry_types()
    end,
    "declare entry types" => fn -> [:debit, :credit] end
  })
end
