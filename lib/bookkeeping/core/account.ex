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
          audit_log: AuditLog.t(),
          active: boolean()
        }

  defstruct code: "",
            name: "",
            description: "",
            account_type: nil,
            audit_log: %{},
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
    - code: The code of the account.
    - name: The name of the account.
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
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
          contra: false
        },
        active: true,
        audit_log: %AuditLog{
          id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
          record_type: "account",
          action_type: "create",
          details: %{},
          created_at: ~U[2021-10-10 10:10:10.000000Z],
          updated_at: ~U[2021-10-10 10:10:10.000000Z],
          deleted_at: nil
        }
      }}

      iex> Account.create("invalid", "invalid", "invalid", nil, false, %{})
      {:error, :invalid_account}
  """
  @spec create(String.t(), String.t(), String.t(), String.t(), map()) ::
          {:ok, %__MODULE__{}} | {:error, :invalid_account}
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
    - attrs: The attributes to be updated. The editable attributes are `name`, `description`, and `active`.

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
          normal_balance: %EntryType{type: :debit, name: "Debit"},
          primary_account_category: %PrimaryAccountCategory{type: :balance_sheet},
          contra: false
        },
        active: true,
        audit_log: %AuditLog{
          id: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
          record_type: "account",
          action_type: "update",
          details: %{},
          created_at: nil,
          updated_at: ~U[2021-10-10 10:10:10.000000Z],
          deleted_at: nil
        }
      }}
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, :invalid_account}
  def update(account, attrs) when is_map(attrs) do
    name = Map.get(attrs, :name, account.name)
    description = Map.get(attrs, :description, account.description)
    active = Map.get(attrs, :active, account.active)
    audit_details = Map.get(account.audit_log, :audit_details, %{})
    {:ok, audit_log} = AuditLog.create("account", "update", audit_details)

    if is_binary(name) and name != "" and
         is_binary(description) and is_boolean(active) do
      update_params = %{
        name: name,
        description: description,
        active: active,
        audit_log: audit_log
      }

      {:ok, Map.merge(account, update_params)}
    else
      {:error, :invalid_account}
    end
  end

  defp new(code, name, binary_account_type, description, audit_details) do
    {:ok, account_type} = AccountType.create(binary_account_type)
    {:ok, audit_log} = AuditLog.create("account", "create", audit_details)

    {:ok,
     %__MODULE__{
       code: code,
       name: name,
       description: description,
       account_type: account_type,
       audit_log: audit_log
     }}
  end
end
