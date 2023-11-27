defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.{AccountClassification, AuditLog}

  @type t :: %__MODULE__{
          id: UUID.t(),
          code: account_code(),
          name: String.t(),
          account_description: String.t(),
          account_classification: %AccountClassification{},
          audit_logs: list(AuditLog.t()),
          active: boolean()
        }

  @type account_code :: String.t()

  defstruct id: UUID.uuid4(),
            code: "",
            name: "",
            account_description: "",
            account_classification: nil,
            audit_logs: [],
            active: true

  @account_classifications [
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
    - binary_account_classification: The type of the account. The account classification must be one of the following: `"asset"`, `"liability"`, `"equity"`, `"revenue"`, `"expense"`, `"gain"`, `"loss"`, `"contra_asset"`, `"contra_liability"`, `"contra_equity"`, `"contra_revenue"`, `"contra_expense"`, `"contra_gain"`, `"contra_loss"`.
    - account_description: The description of the account.
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
  def create(code, name, binary_account_classification, account_description, audit_details)
      when is_binary(code) and is_binary(name) and is_binary(binary_account_classification) and
             is_binary(account_description) and code != "" and name != "" and
             binary_account_classification in @account_classifications and is_map(audit_details) do
    with {:ok, account_classification} <-
           AccountClassification.create(binary_account_classification),
         {:ok, audit_log} <- AuditLog.create("account", "create", audit_details) do
      {:ok,
       %__MODULE__{
         code: code,
         name: name,
         account_description: account_description,
         account_classification: account_classification,
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
    account_description = Map.get(attrs, :account_description, account.account_description)
    active = Map.get(attrs, :active, account.active)
    audit_details = Map.get(attrs, :audit_details, %{})

    valid_fields? =
      is_binary(name) and name != "" and is_binary(account_description) and
        is_boolean(active) and is_map(audit_details)

    with true <- valid_fields?,
         {:ok, audit_log} <- AuditLog.create("account", "update", audit_details) do
      existing_audit_logs = Map.get(account, :audit_logs, [])

      update_params = %{
        name: name,
        account_description: account_description,
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
         true <- is_binary(account.account_description),
         true <- is_boolean(account.active),
         true <- is_list(account.audit_logs),
         true <- is_struct(account.account_classification, AccountClassification) do
      {:ok, account}
    else
      _error -> {:error, :invalid_account}
    end
  end
end
