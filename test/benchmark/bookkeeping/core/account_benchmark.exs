defmodule Bookkeeping.Core.AccountBenchmark do
  alias Bookkeeping.Core.Account

  Benchee.run(%{
    "create/1" => fn ->
      Account.create(%{
        code: "1000",
        name: "Cash 0",
        type: "asset",
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
end
