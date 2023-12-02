defmodule Bookkeeping.Core.Account do
  @moduledoc """
  Bookkeeping.Core.Account is a struct that represents an account in the chart of accounts.
  An account is a record of all relevant business transactions in terms of money or a record
  in the general ledger that is used to sort and store transactions.
  """
  alias Bookkeeping.Core.AuditLog

  @type t :: %__MODULE__{
          code: account_code(),
          name: String.t(),
          description: String.t(),
          classification: __MODULE__.Classification.t(),
          audit_logs: list(AuditLog.t()),
          active: boolean()
        }

  @type account_code :: String.t()

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

  def create(params) do
    params |> check_fields() |> transform_params() |> maybe_create_account()
  end

  defp check_fields(params) when is_map(params) do
    fields = [:code, :name, :description, :classification, :audit_details, :active]
    if Enum.all?(fields, &Map.has_key?(params, &1)), do: params, else: {:error, :invalid_params}
  end

  defp check_fields(_params), do: {:error, :invalid_params}

  defp transform_params(params) when is_map(params),
    do: Enum.reduce(params, %{params: %{}, errors: []}, &validate_field/2)

  defp transform_params(_params), do: {:error, :invalid_params}

  defp maybe_create_account(%{params: params, errors: []}), do: {:ok, struct(__MODULE__, params)}
  defp maybe_create_account(%{errors: errors}), do: List.first(errors)
  defp maybe_create_account(_params), do: {:error, :invalid_params}

  defp validate_field({key, value}, acc) when key in [:code, :name, :description] do
    if is_binary(value) and value != "" do
      params = Map.get(acc, :params, %{})
      updated_params = Map.put(params, key, value)
      Map.put(acc, :params, updated_params)
    else
      Map.put(acc, :errors, [{:error, :invalid_field} | acc.errors])
    end
  end

  defp validate_field({:classification, value}, acc) do
    if is_binary(value) and value in @account_classifications do
      params = Map.get(acc, :params, %{})
      updated_params = Map.put(params, :classification, Map.get(accounts_classification(), value))
      Map.put(acc, :params, updated_params)
    else
      Map.put(acc, :errors, [{:error, :invalid_field} | acc.errors])
    end
  end

  defp validate_field({:audit_details, value}, acc) do
    if is_map(value) do
      params = Map.get(acc, :params, %{})
      current_audit_logs = Map.get(params, :audit_logs, [])
      {:ok, audit_log} = AuditLog.create("account", "create", value)
      updated_params = Map.put(params, :audit_logs, [audit_log | current_audit_logs])
      Map.put(acc, :params, updated_params)
    else
      Map.put(acc, :errors, [{:error, :invalid_field} | acc.errors])
    end
  end

  defp validate_field({:active, value}, acc) do
    if is_boolean(value) do
      params = Map.get(acc, :params, %{})
      updated_params = Map.put(params, :active, value)
      Map.put(acc, :params, updated_params)
    else
      Map.put(acc, :errors, [{:error, :invalid_field} | acc.errors])
    end
  end

  defp validate_field({_key, _value}, acc), do: acc

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
         true <- is_struct(account.classification, Classification) do
      {:ok, account}
    else
      _error -> {:error, :invalid_account}
    end
  end

  defp accounts_classification do
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
end
