defmodule Bookkeeping.Core.Helper do
  def to_snake_case(input) do
    transformed_string =
      input
      |> String.downcase()
      |> String.replace(~r/\s+/, "_")

    {:ok, transformed_string}
  end
end
