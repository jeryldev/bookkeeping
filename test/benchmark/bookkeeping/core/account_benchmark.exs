defmodule Bookkeeping.Core.AccountBenchmark do
  alias Bookkeeping.Core.Account

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
      struct(%Account{}, %{
        code: "1000",
        name: "Cash 0",
        type: "asset",
        description: "Cash and Cash Equivalents 0",
        audit_details: %{},
        active: true
      })
    end
  })

  Benchee.run(%{
    "validate_account/1" => fn ->
      Account.validate_account(%Account{
        code: "1003",
        name: "Cash 3",
        classification: "asset",
        description: "Cash and Cash Equivalents 3",
        audit_logs: [],
        active: true
      })
    end,
    "validate/1" => fn ->
      Account.validate(%Account{
        code: "1004",
        name: "Cash 4",
        classification: "asset",
        description: "Cash and Cash Equivalents 4",
        audit_logs: [],
        active: true
      })
    end,
    "validate2/1" => fn ->
      Account.validate2(%Account{
        code: "1005",
        name: "Cash 5",
        classification: "asset",
        description: "Cash and Cash Equivalents 5",
        audit_logs: [],
        active: true
      })
    end
  })
end
