defmodule Bookkeeping.Core.AuditLog do
  @moduledoc """
  Bookkeeping.Core.AuditLog is a struct that represents an audit log.
  An audit log is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  It is also used to track changes to records like accounts.
  """
  @type t :: %__MODULE__{
          id: UUID.t(),
          record_type: String.t(),
          action_type: String.t(),
          details: map(),
          created_at: nil | DateTime.t(),
          updated_at: nil | DateTime.t(),
          deleted_at: nil | DateTime.t()
        }

  defstruct id: UUID.uuid4(),
            record_type: "",
            action_type: "",
            details: %{},
            created_at: nil,
            updated_at: nil,
            deleted_at: nil

  @action_types ["create", "update", "delete"]

  @doc """
  Creates a new audit log struct.

  Arguments:
    - record_type: The type of the record.
    - action_type: The type of the action.
    - audit_details: The details of the audit log.

  Returns `{:ok, %AuditLog{}}` if the audit log is valid. Otherwise, returns `{:error, :invalid_audit_log}`.

  ## Examples

      iex> AuditLog.create("account", "create", %{email: "example@example.com"})
      {:ok, %AuditLog{...}}


      iex> Audit.create("account", "update", %{email: "example@example.com"})
      {:ok, %AuditLog{...}}

      iex> AuditLog.create("account", "delete", %{email: "example@example.com"})
      {:ok, %AuditLog{...}}

      iex> AuditLog.create("account", "invalid", %{})
      {:error, :invalid_audit_log}
  """
  @spec create(String.t(), String.t(), map()) ::
          {:ok, __MODULE__.t()} | {:error, :invalid_audit_log}
  def create(record_type, action_type, audit_details)
      when is_binary(record_type) and record_type != "" and is_binary(action_type) and
             action_type in @action_types and is_map(audit_details) do
    datetime = DateTime.utc_now()
    created_at = if action_type == "create", do: datetime, else: nil
    deleted_at = if action_type == "delete", do: datetime, else: nil

    {:ok,
     %__MODULE__{
       record_type: record_type,
       action_type: action_type,
       details: audit_details,
       created_at: created_at,
       updated_at: datetime,
       deleted_at: deleted_at
     }}
  end

  def create(_, _, _), do: {:error, :invalid_audit_log}
end
