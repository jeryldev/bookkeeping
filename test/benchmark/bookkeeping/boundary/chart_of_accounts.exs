defmodule Bookkeeping.Boundary.ChartOfAccounts do
  alias Bookkeeping.Boundary.ChartOfAccounts.Server, as: ChartOfAccountsServer
  alias Bookkeeping.Boundary.ChartOfAccounts.Server2, as: ChartOfAccountsServer2

  ChartOfAccountsServer.start_link()
  ChartOfAccountsServer2.start_link([])

  Benchee.run(%{
    "COA Server create/5" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      ChartOfAccountsServer.create_account(
        random_string,
        random_string,
        "asset",
        "Cash and Cash Equivalents 0",
        %{}
      )
    end,
    "COA Server2 create/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      params = %{
        code: random_string,
        name: random_string,
        classification: "asset",
        description: "Cash and Cash Equivalents 0",
        audit_details: %{},
        active: true
      }

      ChartOfAccountsServer2.create(params)
    end
  })

  Benchee.run(%{
    "COA Server find_account_by_code/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      ChartOfAccountsServer.find_account_by_code(random_string)
    end,
    "COA Server2 search_code/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      ChartOfAccountsServer2.search_code(random_string)
    end
  })

  Benchee.run(%{
    "COA Server find_account_by_name/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      ChartOfAccountsServer.find_account_by_name(random_string)
    end,
    "COA Server2 search_name/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      ChartOfAccountsServer2.search_name(random_string)
    end
  })
end
