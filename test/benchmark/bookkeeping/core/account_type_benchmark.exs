defmodule Bookkeeping.Core.AccountClassificationBenchmark do
  Benchee.run(%{
    "create asset account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("asset")
    end,
    "classify asset account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.classify("asset")
    end,
    "declare asset account classification" => fn ->
      {:ok,
       %Bookkeeping.Core.AccountClassification{
         name: "asset",
         normal_balance: :debit,
         category: :position,
         contra: false
       }}
    end
  })

  Benchee.run(%{
    "create liability account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("liability")
    end,
    "classify liability account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.classify("liability")
    end,
    "declare liability account classification" => fn ->
      {:ok,
       %Bookkeeping.Core.AccountClassification{
         name: "liability",
         normal_balance: :credit,
         category: :position,
         contra: false
       }}
    end
  })

  Benchee.run(%{
    "create equity account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("equity")
    end,
    "classify equity account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.classify("equity")
    end,
    "declare equity account classification" => fn ->
      {:ok,
       %Bookkeeping.Core.AccountClassification{
         name: "equity",
         normal_balance: :credit,
         category: :position,
         contra: false
       }}
    end
  })

  Benchee.run(%{
    "create revenue account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("revenue")
    end,
    "classify revenue account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.classify("revenue")
    end,
    "declare revenue account classification" => fn ->
      {:ok,
       %Bookkeeping.Core.AccountClassification{
         name: "revenue",
         normal_balance: :credit,
         category: :performance,
         contra: false
       }}
    end
  })

  Benchee.run(%{
    "create expense account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.create("expense")
    end,
    "classify expense account classification function" => fn ->
      Bookkeeping.Core.AccountClassification.classify("expense")
    end,
    "declare expense account classification" => fn ->
      {:ok,
       %Bookkeeping.Core.AccountClassification{
         name: "expense",
         normal_balance: :debit,
         category: :performance,
         contra: false
       }}
    end
  })
end
