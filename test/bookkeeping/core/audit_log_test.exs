defmodule Bookkeeping.Core.AuditLogTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.AuditLog

  setup do
    params = %{
      record: "account",
      action: "create",
      details: %{email: "example@example.com"}
    }

    {:ok, params: params}
  end

  describe "create/1" do
    test "with valid params", %{params: params} do
      assert {:ok, audit_log} = AuditLog.create(params)
      assert audit_log.record == "account"
      assert audit_log.action == "create"
      assert audit_log.details == %{email: "example@example.com"}
    end

    test "with invalid record", %{params: params} do
      params = Map.put(params, :record, nil)
      assert {:error, :invalid_record} = AuditLog.create(params)
    end

    test "with invalid action", %{params: params} do
      params = Map.put(params, :action, nil)
      assert {:error, :invalid_action} = AuditLog.create(params)
    end

    test "with invalid details", %{params: params} do
      params = Map.put(params, :details, nil)
      assert {:error, :invalid_details} = AuditLog.create(params)
    end

    test "with invalid params" do
      assert {:error, :invalid_params} = AuditLog.create(nil)
    end
  end
end
