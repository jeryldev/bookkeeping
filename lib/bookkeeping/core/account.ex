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

    @doc """
    Returns the classification struct.

    Arguments:
    - classification: The name of the classification.The account classification must be one of the following: `asset`, `liability`, `equity`, `revenue`, `expense`, `gain`, `loss`, `contra_asset`, `contra_liability`, `contra_equity`, `contra_revenue`, `contra_expense`, `contra_gain`, `contra_loss`.

    Returns `%Classification{}` if the classification is valid. Otherwise, returns `nil`.

    ## Examples

        iex> Classification.classify("asset")
        %Classification{...}

        iex> Classification.classify("invalid")
        nil
    """
    @spec classify(String.t()) :: __MODULE__.t()
    def classify("asset") do
      %Classification{
        name: "Asset",
        normal_balance: :debit,
        category: :position,
        contra: false
      }
    end

    def classify("liability") do
      %Classification{
        name: "Liability",
        normal_balance: :credit,
        category: :position,
        contra: false
      }
    end

    def classify("equity") do
      %Classification{
        name: "Equity",
        normal_balance: :credit,
        category: :position,
        contra: false
      }
    end

    def classify("revenue") do
      %Classification{
        name: "Revenue",
        normal_balance: :credit,
        category: :performance,
        contra: false
      }
    end

    def classify("expense") do
      %Classification{
        name: "Expense",
        normal_balance: :debit,
        category: :performance,
        contra: false
      }
    end

    def classify("gain") do
      %Classification{
        name: "Gain",
        normal_balance: :credit,
        category: :performance,
        contra: false
      }
    end

    def classify("loss") do
      %Classification{
        name: "Loss",
        normal_balance: :debit,
        category: :performance,
        contra: false
      }
    end

    def classify("contra_asset") do
      %Classification{
        name: "Contra Asset",
        normal_balance: :credit,
        category: :position,
        contra: true
      }
    end

    def classify("contra_liability") do
      %Classification{
        name: "Contra Liability",
        normal_balance: :debit,
        category: :position,
        contra: true
      }
    end

    def classify("contra_equity") do
      %Classification{
        name: "Contra Equity",
        normal_balance: :debit,
        category: :position,
        contra: true
      }
    end

    def classify("contra_revenue") do
      %Classification{
        name: "Contra Revenue",
        normal_balance: :debit,
        category: :performance,
        contra: true
      }
    end

    def classify("contra_expense") do
      %Classification{
        name: "Contra Expense",
        normal_balance: :credit,
        category: :performance,
        contra: true
      }
    end

    def classify("contra_gain") do
      %Classification{
        name: "Contra Gain",
        normal_balance: :debit,
        category: :performance,
        contra: true
      }
    end

    def classify("contra_loss") do
      %Classification{
        name: "Contra Loss",
        normal_balance: :credit,
        category: :performance,
        contra: true
      }
    end

    def classify(_), do: nil
  end

  @doc """
  Creates a new account struct.

  Arguments:
    - params: The parameters of the account. It must contain the following keys:
      - code: The code of the account.
      - name: The name of the account.
      - description: The description of the account.
      - classification: The classification of the account.
      - audit_details: The details of the audit log.
      - active: The status of the account.

  Returns `{:ok, %Account{...}}` if the account is valid. Otherwise, returns any of the following:
    - `{:error, :invalid_params}`
    - `{:error, :invalid_code}`
    - `{:error, :invalid_name}`
    - `{:error, :invalid_classification}`
    - `{:error, :invalid_description}`
    - `{:error, :invalid_audit_details}`
    - `{:error, :invalid_active_state}`

  ## Examples

      iex> Account.create(%{code: "10_000", name: "cash", classification: "asset", description: "", audit_details: %{}, active: true})
      {:ok, %Account{...}}

      iex> Account.create([])
      {:error, :invalid_params}

      iex> Account.create(%{code: nil, name: "cash", classification: "asset", description: "", audit_details: %{}, active: true})
      {:error, :invalid_code}

      iex> Account.create(%{code: "10_000", name: nil, classification: "asset", description: "", audit_details: %{}, active: true})
      {:error, :invalid_name}

      iex> Account.create(%{code: "10_000", name: "cash", classification: nil, description: "", audit_details: %{}, active: true})
      {:error, :invalid_classification}

      iex> Account.create(%{code: "10_000", name: "cash", classification: "asset", description: nil, audit_details: %{}, active: true})
      {:error, :invalid_description}

      iex> Account.create(%{code: "10_000", name: "cash", classification: "asset", description: "", audit_details: nil, active: true})
      {:error, :invalid_audit_details}

      iex> Account.create(%{code: "10_000", name: "cash", classification: "asset", description: "", audit_details: %{}, active: nil})
      {:error, :invalid_active_state}
  """
  @spec create(create_params()) ::
          {:ok, Account.t()}
          | {:error,
             :invalid_params
             | :invalid_code
             | :invalid_name
             | :invalid_classification
             | :invalid_description
             | :invalid_audit_details
             | :invalid_active_state}
  def create(params) do
    params
    |> validate_params()
    |> validate_classification()
    |> validate_audit_details()
    |> maybe_create()
  end

  @doc """
  Updates an account struct.

  Arguments:
    - account: The account to be updated.
    - attrs: The attributes to be updated. The editable attributes are:
      - name: The name of the account.
      - description: The description of the account.
      - active: The status of the account.
      - audit_details: The details of the audit log.

  Returns `{:ok, %Account{...}}` if the account is valid. Otherwise, returns any of the following:
    - `{:error, :invalid_account}`
    - `{:error, :invalid_name}`
    - `{:error, :invalid_description}`
    - `{:error, :invalid_audit_details}`
    - `{:error, :invalid_active_state}`
    - `{:error, :invalid_params}`

  ## Examples

      iex> {:ok, account} = Account.create(params)

      iex> Account.update(account, %{name: "cash and cash equivalents", description: "cash and cash equivalents", audit_details: %{}, active: false})
      {:ok, %Account{...}}

      iex> Account.update(%{}, %{name: "cash and cash equivalents"})
      {:error, :invalid_account}

      iex> Account.update(account, %{name: nil})
      {:error, :invalid_name}

      iex> Account.update(account, %{description: nil})
      {:error, :invalid_description}

      iex> Account.update(account, %{audit_details: nil})
      {:error, :invalid_audit_details}

      iex> Account.update(account, %{active: nil})
      {:error, :invalid_active_state}

      iex> Account.update(account, nil)
      {:error, :invalid_params}
  """
  @spec update(Account.t(), update_params()) ::
          {:ok, Account.t()}
          | {:error,
             :invalid_account
             | :invalid_name
             | :invalid_description
             | :invalid_active_state
             | :invalid_audit_details
             | :invalid_params}
  def update(account, params) do
    with {:ok, _account} <- validate(account),
         {:ok, %{}} <- validate_update_params(params) do
      {:ok, Map.merge(account, params)}
    end
  end

  @doc """
  Validates an account struct.

  Arguments:
    - account: The account to be validated.

  Returns `{:ok, %Account{...}}` if the account is valid. Otherwise, returns `{:error, :invalid_account}`.

  ## Examples

      iex> Account.validate(account)
      {:ok, %Account{...}}

      iex> Account.validate(%Account{})
      {:error, :invalid_account}
  """
  @spec validate(Account.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_account}
  def validate(account) when is_struct(account, __MODULE__) do
    validation_result =
      account
      |> validate_params()
      |> validate_classification()
      |> validate_audit_logs()

    case validation_result do
      {:ok, account} -> {:ok, account}
      {:error, _reason} -> {:error, :invalid_account}
    end
  end

  def validate(_), do: {:error, :invalid_account}

  defp validate_params(params) when is_map(params) and map_size(params) > 0 do
    with {:ok, _} <- validate_code(params),
         {:ok, _} <- validate_name(params),
         {:ok, _} <- validate_description(params),
         {:ok, _} <- validate_active_state(params) do
      {:ok, params}
    end
  end

  defp validate_params(_params), do: {:error, :invalid_params}

  defp validate_update_params(%{name: _name} = params)
       when is_map(params) and map_size(params) > 0 do
    with {:ok, _} <- validate_name(params) do
      params
      |> Map.delete(:name)
      |> maybe_validate_update_params()
    end
  end

  defp validate_update_params(%{description: _description} = params)
       when is_map(params) and map_size(params) > 0 do
    with {:ok, _} <- validate_description(params) do
      params
      |> Map.delete(:description)
      |> maybe_validate_update_params()
    end
  end

  defp validate_update_params(%{active: _active} = params)
       when is_map(params) and map_size(params) > 0 do
    with {:ok, _} <- validate_active_state(params) do
      params
      |> Map.delete(:active)
      |> maybe_validate_update_params()
    end
  end

  defp validate_update_params(%{audit_details: _audit_details} = params)
       when is_map(params) and map_size(params) > 0 do
    with {:ok, _} <- validate_audit_details(params) do
      params
      |> Map.delete(:audit_details)
      |> maybe_validate_update_params()
    end
  end

  defp validate_update_params(_params), do: {:error, :invalid_params}

  defp maybe_validate_update_params(params) when params == %{}, do: {:ok, %{}}
  defp maybe_validate_update_params(params), do: validate_update_params(params)

  defp validate_code(%{code: code} = params)
       when is_map(params) and is_binary(code) and code != "",
       do: {:ok, params}

  defp validate_code(_params), do: {:error, :invalid_code}

  defp validate_name(%{name: name} = params)
       when is_map(params) and is_binary(name) and name != "",
       do: {:ok, params}

  defp validate_name(_params), do: {:error, :invalid_name}

  defp validate_description(%{description: description} = params)
       when is_map(params) and is_binary(description),
       do: {:ok, params}

  defp validate_description(_params), do: {:error, :invalid_description}

  defp validate_active_state(%{active: active} = params)
       when is_map(params) and is_boolean(active),
       do: {:ok, params}

  defp validate_active_state(_params), do: {:error, :invalid_active_state}

  defp validate_classification({:ok, account}) when is_struct(account, __MODULE__) do
    valid_classification? =
      account
      |> Map.get(:classification)
      |> is_struct(__MODULE__.Classification)

    if valid_classification?,
      do: {:ok, account},
      else: {:error, :invalid_classification}
  end

  defp validate_classification({:ok, %{classification: classification} = params})
       when is_binary(classification) and classification in @account_classifications,
       do: {:ok, params}

  defp validate_classification({:error, reason}), do: {:error, reason}
  defp validate_classification(_account_or_params), do: {:error, :invalid_classification}

  defp validate_audit_details({:ok, %{audit_details: audit_details} = params})
       when is_map(audit_details),
       do: {:ok, params}

  defp validate_audit_details(%{audit_details: audit_details} = params)
       when is_map(audit_details),
       do: {:ok, params}

  defp validate_audit_details({:error, reason}), do: {:error, reason}
  defp validate_audit_details(_params), do: {:error, :invalid_audit_details}

  defp validate_audit_logs({:ok, %{audit_logs: audit_logs} = account})
       when is_struct(account, __MODULE__) and is_list(audit_logs) and length(audit_logs) >= 1,
       do: {:ok, account}

  defp validate_audit_logs({:error, reason}), do: {:error, reason}
  defp validate_audit_logs(_account), do: {:error, :invalid_audit_logs}

  defp maybe_create(
         {:ok,
          %{
            code: code,
            name: name,
            description: description,
            classification: classification,
            audit_details: audit_details,
            active: active
          }}
       ) do
    {:ok, audit_log} =
      AuditLog.create(%{
        record_type: "account",
        action_type: "create",
        audit_details: audit_details
      })

    classification = Classification.classify(classification)

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
end
