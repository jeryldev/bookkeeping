defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.AuditLog

  @type t :: %__MODULE__{
          id: UUID.t(),
          code: account_code(),
          name: String.t(),
          description: String.t(),
          account_classification: Classification.t(),
          audit_logs: list(AuditLog.t()),
          active: boolean()
        }

  @type account_code :: String.t()

  defstruct id: UUID.uuid4(),
            code: "",
            name: "",
            description: "",
            account_classification: nil,
            audit_logs: [],
            active: true

  defmodule Classification do
    @moduledoc """
    Bookkeeping.Core.Account.Classification is a struct that represents the type of an account.
    In accounting, we use accounting types to classify and record the different transactions that affect the financial position of a business.
    Account types help to organize the information in a systematic and logical way, and to show the relationship between the assets, liabilities, equity, revenue, expenses, and other elements of the accounting equation.
    Account types also help to prepare the financial statements, such as the balance sheet, income statement, and cash flow statement.
    """
    alias Bookkeeping.Core.Types

    @type t :: %__MODULE__{
            name: String.t(),
            normal_balance: Types.entry(),
            category: Types.category(),
            contra: boolean()
          }

    defstruct name: "",
              normal_balance: nil,
              category: nil,
              contra: false
  end

  @account_classifications ~w(asset liability equity revenue expense gain loss contra_asset contra_liability contra_equity contra_revenue contra_expense contra_gain contra_loss)

  @doc """
  Creates a new account struct.

  Arguments:
    - code: The unique code of the account.
    - name: The unique name of the account.
    - binary_account_classification: The type of the account. The account classification must be one of the following: `"asset"`, `"liability"`, `"equity"`, `"revenue"`, `"expense"`, `"gain"`, `"loss"`, `"contra_asset"`, `"contra_liability"`, `"contra_equity"`, `"contra_revenue"`, `"contra_expense"`, `"contra_gain"`, `"contra_loss"`.
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
  def create(code, name, binary_account_classification, description, audit_details)
      when is_binary(code) and is_binary(name) and is_binary(binary_account_classification) and
             is_binary(description) and code != "" and name != "" and
             binary_account_classification in @account_classifications and is_map(audit_details) do
    with {:ok, account_classification} <- classify(binary_account_classification),
         {:ok, audit_log} <- AuditLog.create("account", "create", audit_details) do
      {:ok,
       %__MODULE__{
         code: code,
         name: name,
         description: description,
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
         true <- is_struct(account.account_classification, Classification) do
      {:ok, account}
    else
      _error -> {:error, :invalid_account}
    end
  end

  defp classify("asset") do
    {:ok,
     %Classification{
       name: "Asset",
       normal_balance: :debit,
       category: :position,
       contra: false
     }}
  end

  defp classify("liability") do
    {:ok,
     %Classification{
       name: "Liability",
       normal_balance: :credit,
       category: :position,
       contra: false
     }}
  end

  defp classify("equity") do
    {:ok,
     %Classification{
       name: "Equity",
       normal_balance: :credit,
       category: :position,
       contra: false
     }}
  end

  defp classify("revenue") do
    {:ok,
     %Classification{
       name: "Revenue",
       normal_balance: :credit,
       category: :performance,
       contra: false
     }}
  end

  defp classify("expense") do
    {:ok,
     %Classification{
       name: "Expense",
       normal_balance: :debit,
       category: :performance,
       contra: false
     }}
  end

  defp classify("gain") do
    {:ok,
     %Classification{
       name: "Gain",
       normal_balance: :credit,
       category: :performance,
       contra: false
     }}
  end

  defp classify("loss") do
    {:ok,
     %Classification{
       name: "Loss",
       normal_balance: :debit,
       category: :performance,
       contra: false
     }}
  end

  defp classify("contra_asset") do
    {:ok,
     %Classification{
       name: "Contra Asset",
       normal_balance: :credit,
       category: :position,
       contra: true
     }}
  end

  defp classify("contra_liability") do
    {:ok,
     %Classification{
       name: "Contra Liability",
       normal_balance: :debit,
       category: :position,
       contra: true
     }}
  end

  defp classify("contra_equity") do
    {:ok,
     %Classification{
       name: "Contra Equity",
       normal_balance: :debit,
       category: :position,
       contra: true
     }}
  end

  defp classify("contra_revenue") do
    {:ok,
     %Classification{
       name: "Contra Revenue",
       normal_balance: :debit,
       category: :performance,
       contra: true
     }}
  end

  defp classify("contra_expense") do
    {:ok,
     %Classification{
       name: "Contra Expense",
       normal_balance: :credit,
       category: :performance,
       contra: true
     }}
  end

  defp classify("contra_gain") do
    {:ok,
     %Classification{
       name: "Contra Gain",
       normal_balance: :debit,
       category: :performance,
       contra: true
     }}
  end

  defp classify("contra_loss") do
    {:ok,
     %Classification{
       name: "Contra Loss",
       normal_balance: :credit,
       category: :performance,
       contra: true
     }}
  end

  defp classify(_), do: {:error, :invalid_account_classification}
end
