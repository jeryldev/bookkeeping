defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.AuditLog

  @typedoc """
  t type is a struct that represents an account.
  """
  @type t :: %__MODULE__{
          code: account_code(),
          name: String.t(),
          description: String.t(),
          classification: __MODULE__.Classification.t(),
          audit_logs: list(AuditLog.t()),
          active: boolean()
        }

  @typedoc """
  account_code type is a string that represents the code of an account.
  """
  @type account_code :: String.t()

  @typedoc """
  create_params type is a map which represents the parameter used to create an account.
  """
  @type create_params :: %{
          code: account_code(),
          name: String.t(),
          description: String.t(),
          classification: String.t(),
          audit_details: map(),
          active: boolean()
        }

  @typedoc """
  update_params type is a map which represents the parameter used to update an account.
  """
  @type update_params :: %{
          name: String.t(),
          description: String.t(),
          active: boolean(),
          audit_details: map()
        }

  @account_classifications ~w(asset liability equity revenue expense gain loss contra_asset contra_liability contra_equity contra_revenue contra_expense contra_gain contra_loss)

  defstruct code: "",
            name: "",
            description: "",
            classification: nil,
            audit_logs: [],
            active: true

  defmodule Classification do
    @moduledoc """
    Bookkeeping.Core.Account.Classification is a struct that represents the classification of an account.
    In accounting, we use accounting types to classify and record the different transactions that affect the financial position of a business.
    Account classification help to organize the information in a systematic and logical way, and to show the relationship between the assets, liabilities, equity, revenue, expenses, and other elements of the accounting equation.
    It also help to prepare the financial statements, such as the balance sheet, income statement, and cash flow statement.
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

  @doc """
  Creates a new account struct.

  Arguments:
    - code: The unique code of the account.
    - name: The unique name of the account.
    - classification: The classification of the account. The account classification must be one of the following: `"asset"`, `"liability"`, `"equity"`, `"revenue"`, `"expense"`, `"gain"`, `"loss"`, `"contra_asset"`, `"contra_liability"`, `"contra_equity"`, `"contra_revenue"`, `"contra_expense"`, `"contra_gain"`, `"contra_loss"`.
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
  def create(code, name, classification, description, audit_details) do
    classification_mapping = accounts_classification()
    classification_keys = Map.keys(classification_mapping)

    valid_inputs? =
      is_binary(code) and is_binary(name) and is_binary(classification) and
        is_binary(description) and code != "" and name != "" and
        classification in classification_keys and is_map(audit_details)

    classification = Map.get(classification_mapping, classification)

    with true <- valid_inputs?,
         {:ok, audit_log} <- AuditLog.create("account", "create", audit_details) do
      {:ok,
       %__MODULE__{
         code: code,
         name: name,
         description: description,
         classification: classification,
         audit_logs: [audit_log]
       }}
    else
      _ -> {:error, :invalid_account}
    end
  end

  @doc """
  Creates a new account struct.

  Arguments:
    - params: The parameters of the account. The parameters must include the following fields: `code`, `name`, `description`, `classification`, `audit_details`, and `active`.

  Returns `{:ok, %Account{}}` if the account is valid. Otherwise, returns `{:error, :invalid_params}` or `{:error, :invalid_field}`.

  ## Examples

      iex> Account.create(%{code: "10_000", name: "cash", classification: "asset", description: "", audit_details: %{}, active: true})
      {:ok, %Account{...}}

      iex> Account.create([])
      {:error, :invalid_params}

      iex> Account.create(%{code: "invalid", name: "invalid", classification: "invalid", description: nil, audit_details: false, active: %{}})
      {:error, :invalid_field}
  """
  @spec create(create_params()) :: {:ok, Account.t()} | {:error, :invalid_params | :invalid_field}
  def create(params) do
    params |> validate_create_params() |> maybe_create()
  end

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

  @spec update2(Account.t(), update_params()) ::
          {:ok, Account.t()} | {:error, :invalid_account | :invalid_field | :invalid_params}
  def update2(account, params) do
    params |> validate_update_params(account) |> maybe_update(account)
  end

  @doc """
  Validates an account struct.

  Arguments:
    - account: The account to be validated.

  Returns `{:ok, %Account{}}` if the account is valid. Otherwise, returns `{:error, :invalid_account}`.

  ## Examples

      iex> Account.validate(account)
      {:ok, %Account{...}}

      iex> Account.validate(%Account{})
      {:error, :invalid_account}
  """
  @spec validate(t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_account}
  def validate(account) do
    if is_struct(account, __MODULE__) and is_binary(account.code) and account.code != "" and
         is_binary(account.name) and account.name != "" and is_binary(account.description) and
         is_boolean(account.active) and is_list(account.audit_logs) and
         is_struct(account.classification, Classification),
       do: {:ok, account},
       else: {:error, :invalid_account}
  end

  def accounts_classification do
    %{
      "asset" => %Classification{
        name: "Asset",
        normal_balance: :debit,
        category: :position,
        contra: false
      },
      "liability" => %Classification{
        name: "Liability",
        normal_balance: :credit,
        category: :position,
        contra: false
      },
      "equity" => %Classification{
        name: "Equity",
        normal_balance: :credit,
        category: :position,
        contra: false
      },
      "revenue" => %Classification{
        name: "Revenue",
        normal_balance: :credit,
        category: :performance,
        contra: false
      },
      "expense" => %Classification{
        name: "Expense",
        normal_balance: :debit,
        category: :performance,
        contra: false
      },
      "gain" => %Classification{
        name: "Gain",
        normal_balance: :credit,
        category: :performance,
        contra: false
      },
      "loss" => %Classification{
        name: "Loss",
        normal_balance: :debit,
        category: :performance,
        contra: false
      },
      "contra_asset" => %Classification{
        name: "Contra Asset",
        normal_balance: :credit,
        category: :position,
        contra: true
      },
      "contra_liability" => %Classification{
        name: "Contra Liability",
        normal_balance: :debit,
        category: :position,
        contra: true
      },
      "contra_equity" => %Classification{
        name: "Contra Equity",
        normal_balance: :debit,
        category: :position,
        contra: true
      },
      "contra_revenue" => %Classification{
        name: "Contra Revenue",
        normal_balance: :debit,
        category: :performance,
        contra: true
      },
      "contra_expense" => %Classification{
        name: "Contra Expense",
        normal_balance: :credit,
        category: :performance,
        contra: true
      },
      "contra_gain" => %Classification{
        name: "Contra Gain",
        normal_balance: :debit,
        category: :performance,
        contra: true
      },
      "contra_loss" => %Classification{
        name: "Contra Loss",
        normal_balance: :credit,
        category: :performance,
        contra: true
      }
    }
  end

  defp validate_create_params(
         %{
           code: code,
           name: name,
           description: description,
           classification: classification,
           audit_details: audit_details,
           active: active
         } = params
       ) do
    if is_binary(code) and code != "" and is_binary(name) and name != "" and
         is_binary(description) and is_binary(classification) and
         classification in @account_classifications and
         is_map(audit_details) and is_boolean(active),
       do: params,
       else: {:error, :invalid_field}
  end

  defp validate_create_params(_params), do: {:error, :invalid_params}

  defp maybe_create(%{
         code: code,
         name: name,
         description: description,
         classification: classification,
         audit_details: audit_details,
         active: active
       }) do
    {:ok, audit_log} = AuditLog.create("account", "create", audit_details)
    classification = Map.get(accounts_classification(), classification)

    {:ok,
     %__MODULE__{
       code: code,
       name: name,
       description: description,
       classification: classification,
       audit_logs: [audit_log],
       active: active
     }}
  end

  defp maybe_create({:error, reason}), do: {:error, reason}

  defp validate_update_params(params, _account) when not is_map(params),
    do: {:error, :invalid_params}

  defp validate_update_params(_params, account) when not is_struct(account, __MODULE__),
    do: {:error, :invalid_account}

  defp validate_update_params(%{audit_details: _audit_details} = params, account) do
    Enum.reduce(params, %{}, fn {key, value}, acc ->
      verify_update_field(key, value, acc, account)
    end)
  end

  defp validate_update_params(params, account) do
    params
    |> Map.put(:audit_details, %{})
    |> validate_update_params(account)
  end

  defp verify_update_field(key, value, acc, _account)
       when key in [:name, :description] and
              is_binary(value) and value != "",
       do: Map.put(acc, key, value)

  defp verify_update_field(:active, value, acc, _account) when is_boolean(value),
    do: Map.put(acc, :active, value)

  defp verify_update_field(:audit_details, value, acc, account) when is_map(value) do
    {:ok, audit_log} = AuditLog.create("account", "update", value)
    Map.put(acc, :audit_logs, [audit_log | account.audit_logs])
  end

  defp verify_update_field(key, _value, _acc, _account)
       when key in [:name, :description, :active, :audit_details],
       do: {:error, :invalid_field}

  defp verify_update_field(_key, _value, acc, _account), do: acc

  defp maybe_update({:error, reason}, _account), do: {:error, reason}
  defp maybe_update(params, account), do: {:ok, Map.merge(account, params)}
end
