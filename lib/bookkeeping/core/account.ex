defmodule Bookkeeping.Core.Account do
  alias Bookkeeping.Core.{AccountType}

  defstruct code: nil,
            name: nil,
            account_type: %AccountType{}

  def new(code, name, %AccountType{} = account_type)
      when is_integer(code) and is_binary(name) do
    {:ok,
     %__MODULE__{
       code: code,
       name: name,
       account_type: account_type
     }}
  end

  def new(_code, _name, _account_type), do: {:error, :invalid_account}
end
