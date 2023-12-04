defmodule Bookkeeping.Boundary.ChartOfAccountsBenchmark do
  alias Bookkeeping.Boundary.ChartOfAccounts.Server, as: ChartOfAccountsServer
  alias Bookkeeping.Boundary.ChartOfAccounts2.Supervisor, as: ChartOfAccounts2Supervisor
  alias Bookkeeping.Boundary.ChartOfAccounts2.Worker

  ChartOfAccountsServer.start_link()
  ChartOfAccounts2Supervisor.start_link()

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
    "COA Worker create/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      params = %{
        code: random_string,
        name: random_string,
        classification: "asset",
        description: "Cash and Cash Equivalents 0",
        audit_details: %{},
        active: true
      }

      IO.inspect(random_string)

      result = Worker.create(params)

      IO.inspect(result)

      result
    end
  })

  Benchee.run(%{
    "COA Server find_account_by_code/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      ChartOfAccountsServer.find_account_by_code(random_string)
    end,
    "COA Worker search_code/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      Worker.search_code(random_string)
    end
  })

  Benchee.run(%{
    "COA Server find_account_by_name/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      ChartOfAccountsServer.find_account_by_name(random_string)
    end,
    "COA Worker search_name/1" => fn ->
      random_string = for _ <- 1..10, into: "", do: <<Enum.random(~c"0123456789abcdef")>>

      Worker.search_name(random_string)
    end
  })

  Benchee.run(%{
    "COA Server import_accounts/1" => fn ->
      ChartOfAccountsServer.import_accounts("../../data/sample_chart_of_accounts.csv")
    end,
    "COA Worker import_file/1" => fn ->
      Worker.import_file("../../data/sample_chart_of_accounts.csv")
    end
  })
end
