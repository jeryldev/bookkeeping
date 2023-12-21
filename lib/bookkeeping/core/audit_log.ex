defmodule Bookkeeping.Core.AuditLog do
  @moduledoc """
  Bookkeeping.Core.AuditLog is a struct that represents an audit log.
  An audit log is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  It is also used to track changes to records like accounts.
  """
  alias Bookkeeping.Core.AuditLog

  @typedoc """
  t type is a struct that represents an audit log.
  """
  @type t :: %__MODULE__{
          id: UUID.t(),
          record_type: String.t(),
          action_type: String.t(),
          details: map(),
          created_at: nil | integer(),
          updated_at: nil | integer(),
          deleted_at: nil | integer()
        }

  @typedoc """
  create_params type is a map that represents the params of the create function.
  """
  @type create_params :: %{
          record_type: String.t(),
          action_type: String.t(),
          audit_details: map()
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
      - params: The params of the audit log. It must contain the following keys:
        - record_type: The type of the record.
        - action_type: The type of the action.
        - audit_details: The details of the audit log.

    Returns `{:ok, %AuditLog{}}` if the audit log is valid. Otherwise, returns `{:error, :invalid_field}` or `{:error, :invalid_params}`.

    ## Examples

        iex> AuditLog.create(%{record_type: "account", action_type: "create", audit_details: %{email: "test@test.com"}})
        {:ok, %AuditLog{...}}

        iex> AuditLog.create(%{record_type: nil, action_type: "update", audit_details: %{}})
        {:error, :invalid_field}

        iex> AuditLog.create(nil)
        {:error, :invalid_params}
  """
  @spec create(create_params()) ::
          {:ok, AuditLog.t()} | {:error, :invalid_field | :invalid_params}
  def create(params) do
    params |> validate_create_params() |> maybe_create()
  end

  defp validate_create_params(
         %{
           record_type: record_type,
           action_type: action_type,
           audit_details: audit_details
         } =
           params
       ) do
    if is_binary(record_type) and record_type != "" and is_binary(action_type) and
         action_type in @action_types and is_map(audit_details),
       do: params,
       else: {:error, :invalid_field}
  end

  defp validate_create_params(_), do: {:error, :invalid_params}

  defp maybe_create(%{
         record_type: record_type,
         action_type: action_type,
         audit_details: audit_details
       }) do
    unix_datetime = DateTime.to_unix(DateTime.utc_now())
    created_at = if action_type == "create", do: unix_datetime, else: nil
    deleted_at = if action_type == "delete", do: unix_datetime, else: nil

    {:ok,
     %__MODULE__{
       record_type: record_type,
       action_type: action_type,
       details: audit_details,
       created_at: created_at,
       updated_at: unix_datetime,
       deleted_at: deleted_at
     }}
  end

  defp maybe_create({:error, reason}), do: {:error, reason}
end
