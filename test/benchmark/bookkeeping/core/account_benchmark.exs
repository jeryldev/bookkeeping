defmodule Bookkeeping.Core.AccountBenchmark do
  alias Bookkeeping.Core.{Account, AuditLog}

  Benchee.run(%{
    "create/1" => fn ->
      Account.create(%{
        code: "1000",
        name: "Cash 0",
        classification: "asset",
        description: "Cash and Cash Equivalents 0",
        audit_details: %{},
        active: true
      })
    end,
    "create/1 struct only" => fn ->
      audit_log =
        AuditLog.create(%{
          record: "account",
          action: "create",
          details: %{}
        })

      classification = Account.Classification.classify("asset")

      struct(%Account{}, %{
        code: "1000",
        name: "Cash 0",
        type: classification,
        description: "Cash and Cash Equivalents 0",
        audit_details: [audit_log],
        active: true
      })
    end
  })

  {:ok, cash_account_1} =
    Account.create(%{
      code: "1000",
      name: "Cash 0",
      classification: "asset",
      description: "Cash and Cash Equivalents 0",
      audit_details: %{},
      active: true
    })

  Benchee.run(%{"validate/1" => fn -> Account.validate(cash_account_1) end})

  {:ok, cash_account_2} =
    Account.create(%{
      code: "1000",
      name: "Cash 0",
      classification: "asset",
      description: "Cash and Cash Equivalents 0",
      audit_details: %{},
      active: true
    })

  Benchee.run(%{
    "update/2" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      Account.update(cash_account_2, %{
        code: random_string,
        name: random_string,
        classification: "asset",
        description: "Cash and Cash Equivalents 2",
        audit_details: %{email: "test@test.com"},
        active: false
      })
    end
  })
end
