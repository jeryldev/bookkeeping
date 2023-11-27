defmodule Bookkeeping.Core.PrimaryAccountCategoryBenchmark do
  Benchee.run(%{
    "create balance sheet primary account category function" => fn ->
      Bookkeeping.Core.PrimaryAccountCategory.create(:balance_sheet)
    end,
    "declare balance sheet primary account category" => fn ->
      :balance_sheet
    end
  })

  Benchee.run(%{
    "create profit and loss primary account category function" => fn ->
      Bookkeeping.Core.PrimaryAccountCategory.create(:profit_and_loss)
    end,
    "declare profit and loss primary account category" => fn ->
      :profit_and_loss
    end
  })
end
