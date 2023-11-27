defmodule Bookkeeping.MixProject do
  use Mix.Project

  def project do
    [
      app: :bookkeeping,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_applications(Mix.env()),
      mod: {Bookkeeping.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:decimal, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:excoveralls, "~> 0.10", only: :test},
      {:nimble_csv, "~> 1.2"},
      {:jason, "~> 1.4"},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp extra_applications(env) when env in [:dev, :test],
    do: [:logger, :runtime_tools, :observer, :wx, :os_mon]

  defp extra_applications(_env), do: [:logger]
end
