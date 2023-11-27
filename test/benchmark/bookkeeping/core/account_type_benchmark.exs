defmodule Bookkeeping.Core.AccountClassificationBenchmark do
  Benchee.run(%{
    "create asset account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("asset")
    end,
    "declare asset account classification" => fn ->
      %Bookkeeping.Core.AccountClassification{
        name: "asset",
        normal_balance: :debit,
        statement_category: :balance_sheet,
        contra: false
      }
    end
  })

  Benchee.run(%{
    "create liability account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("liability")
    end,
    "declare liability account classification" => fn ->
      %Bookkeeping.Core.AccountClassification{
        name: "liability",
        normal_balance: :credit,
        statement_category: :balance_sheet,
        contra: false
      }
    end
  })

  Benchee.run(%{
    "create equity account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("equity")
    end,
    "declare equity account classification" => fn ->
      %Bookkeeping.Core.AccountClassification{
        name: "equity",
        normal_balance: :credit,
        statement_category: :balance_sheet,
        contra: false
      }
    end
  })

  Benchee.run(%{
    "create revenue account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("revenue")
    end,
    "declare revenue account classification" => fn ->
      %Bookkeeping.Core.AccountClassification{
        name: "revenue",
        normal_balance: :credit,
        statement_category: :profit_and_loss,
        contra: false
      }
    end
  })

  Benchee.run(%{
    "create expense account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("expense")
    end,
    "declare expense account classification" => fn ->
      %Bookkeeping.Core.AccountClassification{
        name: "expense",
        normal_balance: :debit,
        statement_category: :profit_and_loss,
        contra: false
      }
    end
  })
end
