defmodule Bookkeeping.Core.AccountTypeBenchmark do
  Benchee.run(%{
    "create asset account type function" => fn ->
      Bookkeeping.Core.AccountType.create("asset")
    end,
    "declare asset account type" => fn ->
      %Bookkeeping.Core.AccountType{
        name: "asset",
        normal_balance: :debit,
        primary_account_category: :balance_sheet,
        contra: false
      }
    end
  })

  Benchee.run(%{
    "create liability account type function" => fn ->
      Bookkeeping.Core.AccountType.create("liability")
    end,
    "declare liability account type" => fn ->
      %Bookkeeping.Core.AccountType{
        name: "liability",
        normal_balance: :credit,
        primary_account_category: :balance_sheet,
        contra: false
      }
    end
  })

  Benchee.run(%{
    "create equity account type function" => fn ->
      Bookkeeping.Core.AccountType.create("equity")
    end,
    "declare equity account type" => fn ->
      %Bookkeeping.Core.AccountType{
        name: "equity",
        normal_balance: :credit,
        primary_account_category: :balance_sheet,
        contra: false
      }
    end
  })

  Benchee.run(%{
    "create revenue account type function" => fn ->
      Bookkeeping.Core.AccountType.create("revenue")
    end,
    "declare revenue account type" => fn ->
      %Bookkeeping.Core.AccountType{
        name: "revenue",
        normal_balance: :credit,
        primary_account_category: :profit_and_loss,
        contra: false
      }
    end
  })

  Benchee.run(%{
    "create expense account type function" => fn ->
      Bookkeeping.Core.AccountType.create("expense")
    end,
    "declare expense account type" => fn ->
      %Bookkeeping.Core.AccountType{
        name: "expense",
        normal_balance: :debit,
        primary_account_category: :profit_and_loss,
        contra: false
      }
    end
  })
end
