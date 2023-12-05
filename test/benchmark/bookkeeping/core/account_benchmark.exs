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
    "create/5" => fn ->
      Account.create("1001", "Cash 1", "asset", "Cash and Cash Equivalents 1", %{})
    end,
    "create/1 struct only" => fn ->
      classification = Account.accounts_classification()["asset"]
      audit_log = AuditLog.create("account", "create", %{})

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

  # Benchee.run(%{
  #   "validate_account/1" => fn ->
  #     Account.validate_account(%Account{
  #       code: "1003",
  #       name: "Cash 3",
  #       classification: "asset",
  #       description: "Cash and Cash Equivalents 3",
  #       audit_logs: [],
  #       active: true
  #     })
  #   end,
  #   "validate/1" => fn ->
  #     Account.validate(%Account{
  #       code: "1004",
  #       name: "Cash 4",
  #       classification: "asset",
  #       description: "Cash and Cash Equivalents 4",
  #       audit_logs: [],
  #       active: true
  #     })
  #   end,
  #   "validate2/1" => fn ->
  #     Account.validate2(%Account{
  #       code: "1005",
  #       name: "Cash 5",
  #       classification: "asset",
  #       description: "Cash and Cash Equivalents 5",
  #       audit_logs: [],
  #       active: true
  #     })
  #   end
  # })

  {:ok, cash_account} =
    Account.create(%{
      code: "1000",
      name: "Cash 0",
      classification: "asset",
      description: "Cash and Cash Equivalents 0",
      audit_details: %{},
      active: true
    })

  Benchee.run(%{
    "current update/2" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      Account.update(cash_account, %{
        code: random_string,
        name: random_string,
        description: "Cash and Cash Equivalents 1",
        audit_details: %{email: "test@test.com"},
        active: false
      })
    end,
    "new update/2" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      Account.update(cash_account, %{
        code: random_string,
        name: random_string,
        classification: "asset",
        description: "Cash and Cash Equivalents 2",
        audit_details: %{},
        active: true
      })
    end
  })
end
