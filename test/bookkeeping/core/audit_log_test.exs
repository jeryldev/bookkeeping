defmodule Bookkeeping.Core.AuditLogTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.AuditLog

  setup do
    details = %{email: "example@example.com"}
    {:ok, details: details}
  end

  test "create a create audit log", %{details: details} do
    assert {:ok, create_log} = AuditLog.create("account", "create", details)
    assert create_log.record_type == "account"
    assert create_log.action_type == "create"
    assert create_log.details == details
    assert create_log.created_at == create_log.updated_at
    assert create_log.deleted_at == nil
  end

  test "create an update audit log", %{details: details} do
    assert {:ok, update_log} = AuditLog.create("account", "update", details)
    assert update_log.record_type == "account"
    assert update_log.action_type == "update"
    assert update_log.details == details
    assert update_log.created_at == nil
    refute update_log.updated_at == nil
    assert update_log.deleted_at == nil
  end

  test "create a delete audit log", %{details: details} do
    assert {:ok, delete_log} = AuditLog.create("account", "delete", details)
    assert delete_log.record_type == "account"
    assert delete_log.action_type == "delete"
    assert delete_log.details == details
    assert delete_log.created_at == nil
    refute delete_log.updated_at == nil
    refute delete_log.deleted_at == nil
  end

  test "create an invalid audit log" do
    assert {:error, :invalid_audit_log} = AuditLog.create("account", "invalid", %{})
  end
end
