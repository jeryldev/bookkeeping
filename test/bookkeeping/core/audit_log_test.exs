defmodule Bookkeeping.Core.AuditLogTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.AuditLog

  setup do
    params = %{
      record_type: "account",
      action_type: "create",
      audit_details: %{email: "example@example.com"}
    }

    invalid_params = %{
      record_type: "account",
      action_type: "invalid",
      audit_details: %{}
    }

    {:ok, params: params, invalid_params: invalid_params}
  end

  describe "create/1" do
    test "with valid params", %{params: params} do
      assert {:ok, audit_log} = AuditLog.create(params)
      assert audit_log.record_type == "account"
      assert audit_log.action_type == "create"
      assert audit_log.details == %{email: "example@example.com"}
    end

    test "with invalid field", %{invalid_params: invalid_params} do
      assert {:error, :invalid_field} = AuditLog.create(invalid_params)
    end

    test "with invalid params" do
      assert {:error, :invalid_params} = AuditLog.create(nil)
    end
  end
end
