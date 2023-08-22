defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.{AccountType, AuditLog}

  @type t :: %__MODULE__{
          code: String.t(),
          name: String.t(),
          description: String.t(),
          account_type: %AccountType{},
          audit_logs: list(AuditLog.t()),
          active: boolean()
        }

  defstruct code: "",
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
    - account_type: The type of the account.
    - description: The description of the account.
    - audit_details: The details of the audit log.

  Returns `{:ok, %Account{}}` if the account is valid. Otherwise, returns `{:error, :invalid_account}`.

  ## Examples

      iex> Account.create("10_000", "cash", "asset", "", %{})
      {:ok,
      %Account{
        code: "10_000",
        name: "cash",
        description: "",
        account_type: %AccountType{
          name: "Asset",
          normal_balance: :debit,
          primary_account_category: :balance_sheet,
          contra: false
        },
        active: true,
        audit_logs: [
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "account",
            action_type: "create",
            details: %{},
            created_at: ~U[2021-10-10 10:10:10.000000Z],
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          }
        ]
      }}

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
    new(code, name, binary_account_type, description, audit_details)
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
      {:ok,
      %Account{
        code: "10_000",
        name: "cash and cash equivalents",
        description: "",
        account_type: %AccountType{
          name: "Asset",
          normal_balance: :debit,
          primary_account_category: :balance_sheet,
          contra: false
        },
        active: true,
        audit_logs: [
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "account",
            action_type: "create",
            details: %{},
            created_at: ~U[2021-10-10 10:10:10.000000Z],
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          },
          %AuditLog{
            id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            record_type: "account",
            action_type: "update",
            details: %{},
            created_at: nil,
            updated_at: ~U[2021-10-10 10:10:10.000000Z],
            deleted_at: nil
          }
        ]
      }}
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

  defp new(code, name, binary_account_type, description, audit_details) do
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
end
