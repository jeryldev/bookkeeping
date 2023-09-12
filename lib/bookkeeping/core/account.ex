defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.{AccountType, AuditLog}

  @type t :: %__MODULE__{
          id: UUID.t(),
          code: account_code(),
          name: String.t(),
          description: String.t(),
          account_type: %AccountType{},
          audit_logs: list(AuditLog.t()),
          active: boolean()
        }

  @type account_code :: String.t()

  defstruct id: UUID.uuid4(),
            code: "",
            name: "",
            description: "",
            account_type: nil,
            audit_logs: [],
            active: true

  @account_types [
    "asset",
    "liability",
    "equity",
    "revenue",
    "expense",
    "gain",
    "loss",
    "contra_asset",
    "contra_liability",
    "contra_equity",
    "contra_revenue",
    "contra_expense",
    "contra_gain",
    "contra_loss"
  ]

  @doc """
  Creates a new account struct.

  Arguments:
    - code: The unique code of the account.
    - name: The unique name of the account.
    - binary_account_type: The type of the account. The account type must be one of the following: `"asset"`, `"liability"`, `"equity"`, `"revenue"`, `"expense"`, `"gain"`, `"loss"`, `"contra_asset"`, `"contra_liability"`, `"contra_equity"`, `"contra_revenue"`, `"contra_expense"`, `"contra_gain"`, `"contra_loss"`.
    - description: The description of the account.
    - audit_details: The details of the audit log.

  Returns `{:ok, %Account{}}` if the account is valid. Otherwise, returns `{:error, :invalid_account}`.

  ## Examples

      iex> Account.create("10_000", "cash", "asset", "", %{})
      {:ok, %Account{...}}

      iex> Account.create("invalid", "invalid", "invalid", nil, false, %{})
      {:error, :invalid_account}
  """
  @spec create(String.t(), String.t(), String.t(), String.t(), map()) ::
          {:ok, Account.t()} | {:error, :invalid_account}
  def create(code, name, binary_account_type, description, audit_details)
      when is_binary(code) and is_binary(name) and is_binary(binary_account_type) and
             is_binary(description) and code != "" and name != "" and
             binary_account_type in @account_types and
             is_binary(description) and is_map(audit_details) do
    with {:ok, account_type} <- AccountType.create(binary_account_type),
         {:ok, audit_log} <- AuditLog.create("account", "create", audit_details) do
      {:ok,
       %__MODULE__{
         code: code,
         name: name,
         description: description,
         account_type: account_type,
         audit_logs: [audit_log]
       }}
    else
      {:error, message} -> {:error, message}
      _ -> {:error, :invalid_account}
    end
  end

  def create(_, _, _, _, _), do: {:error, :invalid_account}

  @doc """
  Updates an account struct.

  Arguments:
    - account: The account to be updated.
    - attrs: The attributes to be updated. The editable attributes are `name`, `description`, `active`, and `audit_details`.

  Returns `{:ok, %Account{}}` if the account is valid. Otherwise, returns `{:error, :invalid_account}`.

  ## Examples

      iex> {:ok, account} = Account.create("10_000", "cash", "asset")

      iex> Account.update(account, %{name: "cash and cash equivalents"})
      {:ok, %Account{name: "cash and cash equivalents", ...}}
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, Account.t()} | {:error, :invalid_account}
  def update(account, attrs) when is_map(attrs) do
    name = Map.get(attrs, :name, account.name)
    description = Map.get(attrs, :description, account.description)
    active = Map.get(attrs, :active, account.active)
    audit_details = Map.get(attrs, :audit_details, %{})

    valid_fields? =
      is_binary(name) and name != "" and is_binary(description) and
        is_boolean(active) and is_map(audit_details)

    with true <- valid_fields?,
         {:ok, audit_log} <- AuditLog.create("account", "update", audit_details) do
      existing_audit_logs = Map.get(account, :audit_logs, [])

      update_params = %{
        name: name,
        description: description,
        active: active,
        audit_logs: [audit_log | existing_audit_logs]
      }

      {:ok, Map.merge(account, update_params)}
    else
      _ -> {:error, :invalid_account}
    end
  end

  @doc """
  Validates an account struct.

  Arguments:
    - account: The account to be validated.

  Returns `{:ok, %Account{}}` if the account is valid. Otherwise, returns `{:error, :invalid_account}`.

  ## Examples

      iex> {:ok, account} = Account.create("10_000", "cash", "asset")

      iex> Account.validate_account(account)
      {:ok, %Account{...}}

      iex> Account.validate_account(%Account{})
      {:error, :invalid_account}
  """
  @spec validate_account(map()) :: {:ok, __MODULE__.t()} | {:error, :invalid_account}
  def validate_account(account) do
    with true <- is_struct(account, __MODULE__),
         true <- is_binary(account.code) and account.code != "",
         true <- is_binary(account.name) and account.name != "",
         true <- is_binary(account.description),
         true <- is_boolean(account.active),
         true <- is_list(account.audit_logs),
         true <- is_struct(account.account_type, AccountType) do
      {:ok, account}
    else
      _error -> {:error, :invalid_account}
    end
  end
end
