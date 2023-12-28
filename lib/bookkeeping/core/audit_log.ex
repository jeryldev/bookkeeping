defmodule Bookkeeping.Core.AuditLog do
  @moduledoc """
  Bookkeeping.Core.AuditLog is a struct that represents an audit log.
  An audit log is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  It is also used to track changes to records like accounts.
  """

  @typedoc """
  t type is a struct that represents an audit log.
  """
  @type t :: %__MODULE__{
          record: String.t(),
          action: String.t(),
          details: map(),
          created_at: nil | integer(),
          updated_at: nil | integer(),
          deleted_at: nil | integer()
        }

  @typedoc """
  create_params type is a map that represents the params of the create function.
  """
  @type create_params :: %{
          record: String.t(),
          action: String.t(),
          details: map()
        }

  defstruct record: "",
            action: "",
            details: %{},
            created_at: nil,
            updated_at: nil,
            deleted_at: nil

  @records ~w(account journal_entry)
  @actions ~w(create update delete)

  @doc """
    Creates a new audit log struct.

    Arguments:
      - params: The params of the audit log. It must contain the following keys:
        - record: The type of the record.
        - action: The type of the action.
        - details: The details of the audit log.

    Returns `{:ok, %AuditLog{}}` if the audit log is valid. Otherwise, returns any of the following:
      - `{:error, :invalid_record}`
      - `{:error, :invalid_action}`
      - `{:error, :invalid_details}`
      - `{:error, :invalid_params}`

    ## Examples

        iex> AuditLog.create(%{record: "account", action: "create", details: %{email: "test@test.com"}})
        {:ok, %AuditLog{...}}

        iex> AuditLog.create(%{record: nil, action: "create", details: %{email: "test@test.com"}})
        {:error, :invalid_record}

        iex> AuditLog.create(%{record: "account", action: nil, details: %{email: "test@test.com"}})
        {:error, :invalid_action}

        iex> AuditLog.create(%{record: "account", action: "create", details: nil})
        {:error, :invalid_details}

        iex> AuditLog.create(nil)
        {:error, :invalid_params}
  """
  @spec create(create_params()) ::
          {:ok, __MODULE__.t()}
          | {:error,
             :invalid_record
             | :invalid_action
             | :invalid_details
             | :invalid_params}
  def create(params) do
    with {:ok, params} <- validate_params(params) do
      unix_datetime = DateTime.to_unix(DateTime.utc_now())
      created_at = if params.action == "create", do: unix_datetime, else: nil
      deleted_at = if params.action == "delete", do: unix_datetime, else: nil

      {:ok,
       %__MODULE__{
         record: params.record,
         action: params.action,
         details: params.details,
         created_at: created_at,
         updated_at: unix_datetime,
         deleted_at: deleted_at
       }}
    end
  end

  defp validate_params(
         %{
           record: record,
           action: action,
           details: details
         } = params
       ) do
    with {:ok, _record} <- validate_record(record),
         {:ok, _action} <- validate_action(action),
         {:ok, _details} <- validate_details(details) do
      {:ok, params}
    end
  end

  defp validate_params(_), do: {:error, :invalid_params}

  defp validate_record(record) when record in @records, do: {:ok, record}
  defp validate_record(_record), do: {:error, :invalid_record}
  defp validate_action(action) when action in @actions, do: {:ok, action}
  defp validate_action(_action), do: {:error, :invalid_action}
  defp validate_details(details) when is_map(details), do: {:ok, details}
  defp validate_details(_details), do: {:error, :invalid_details}
end
