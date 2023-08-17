defmodule Bookkeeping.Core.AccountTypeTest do
  use ExUnit.Case, async: true
  alias Bookkeeping.Core.{AccountType, EntryType, ReportingCategory}

  test "select asset account type" do
    assert AccountType.select_account_type("asset") ==
             {:ok,
              %AccountType{
                name: "Asset",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                }
              }}
  end

  test "select liability account type" do
    assert AccountType.select_account_type("liability") ==
             {:ok,
              %AccountType{
                name: "Liability",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                }
              }}
  end

  test "select equity account type" do
    assert AccountType.select_account_type("equity") ==
             {:ok,
              %AccountType{
                name: "Equity",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                }
              }}
  end

  test "select expense account type" do
    assert AccountType.select_account_type("expense") ==
             {:ok,
              %AccountType{
                name: "Expense",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                }
              }}
  end

  test "select revenue account type" do
    assert AccountType.select_account_type("revenue") ==
             {:ok,
              %AccountType{
                name: "Revenue",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                }
              }}
  end

  test "select loss account type" do
    assert AccountType.select_account_type("loss") ==
             {:ok,
              %AccountType{
                name: "Loss",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                }
              }}
  end

  test "select gain account type" do
    assert AccountType.select_account_type("gain") ==
             {:ok,
              %AccountType{
                name: "Gain",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                }
              }}
  end

  test "select contra asset account type" do
    assert AccountType.select_account_type("contra_asset") ==
             {:ok,
              %AccountType{
                name: "Contra Asset",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                },
                contra: true
              }}
  end

  test "select contra liability account type" do
    assert AccountType.select_account_type("contra_liability") ==
             {:ok,
              %AccountType{
                name: "Contra Liability",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                },
                contra: true
              }}
  end

  test "select contra equity account type" do
    assert AccountType.select_account_type("contra_equity") ==
             {:ok,
              %AccountType{
                name: "Contra Equity",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                },
                contra: true
              }}
  end

  test "select contra expense account type" do
    assert AccountType.select_account_type("contra_expense") ==
             {:ok,
              %AccountType{
                name: "Contra Expense",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                },
                contra: true
              }}
  end

  test "select contra revenue account type" do
    assert AccountType.select_account_type("contra_revenue") ==
             {:ok,
              %AccountType{
                name: "Contra Revenue",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                },
                contra: true
              }}
  end

  test "select contra gain account type" do
    assert AccountType.select_account_type("contra_gain") ==
             {:ok,
              %AccountType{
                name: "Contra Gain",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                },
                contra: true
              }}
  end

  test "select contra loss account type" do
    assert AccountType.select_account_type("contra_loss") ==
             {:ok,
              %AccountType{
                name: "Contra Loss",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                },
                contra: true
              }}
  end

  test "disallow account type that is not in the list" do
    assert AccountType.select_account_type("invalid") ==
             {:error, :invalid_account_type}
  end

  test "create Asset account type" do
    assert AccountType.asset() ==
             {:ok,
              %AccountType{
                name: "Asset",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                }
              }}
  end

  test "create Liability account type" do
    assert AccountType.liability() ==
             {:ok,
              %AccountType{
                name: "Liability",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                }
              }}
  end

  test "create Equity account type" do
    assert AccountType.equity() ==
             {:ok,
              %AccountType{
                name: "Equity",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                }
              }}
  end

  test "create Expense account type" do
    assert AccountType.expense() ==
             {:ok,
              %AccountType{
                name: "Expense",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                }
              }}
  end

  test "create Revenue account type" do
    assert AccountType.revenue() ==
             {:ok,
              %AccountType{
                name: "Revenue",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                }
              }}
  end

  test "create Loss account type" do
    assert AccountType.loss() ==
             {:ok,
              %AccountType{
                name: "Loss",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                }
              }}
  end

  test "create Gain account type" do
    assert AccountType.gain() ==
             {:ok,
              %AccountType{
                name: "Gain",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                }
              }}
  end

  test "create Contra Asset account type" do
    assert AccountType.contra_asset() ==
             {:ok,
              %AccountType{
                name: "Contra Asset",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                },
                contra: true
              }}
  end

  test "create Contra Liability account type" do
    assert AccountType.contra_liability() ==
             {:ok,
              %AccountType{
                name: "Contra Liability",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                },
                contra: true
              }}
  end

  test "create Contra Equity account type" do
    assert AccountType.contra_equity() ==
             {:ok,
              %AccountType{
                name: "Contra Equity",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                },
                contra: true
              }}
  end

  test "create Contra Expense account type" do
    assert AccountType.contra_expense() ==
             {:ok,
              %AccountType{
                name: "Contra Expense",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                },
                contra: true
              }}
  end

  test "create Contra Revenue account type" do
    assert AccountType.contra_revenue() ==
             {:ok,
              %AccountType{
                name: "Contra Revenue",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                },
                contra: true
              }}
  end

  test "create Contra Gain account type" do
    assert AccountType.contra_gain() ==
             {:ok,
              %AccountType{
                name: "Contra Gain",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                },
                contra: true
              }}
  end

  test "create Contra Loss account type" do
    assert AccountType.contra_loss() ==
             {:ok,
              %AccountType{
                name: "Contra Loss",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :profit_and_loss,
                  primary: true
                },
                contra: true
              }}
  end

  test "allow account types that has an entry type of debit" do
    assert AccountType.new("Asset", %EntryType{type: :debit, name: "Debit"}, %ReportingCategory{
             type: :balance_sheet,
             primary: true
           }) ==
             {:ok,
              %AccountType{
                name: "Asset",
                normal_balance: %EntryType{type: :debit, name: "Debit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                }
              }}
  end

  test "allow account types that has an entry type of credit" do
    assert AccountType.new(
             "Liability",
             %EntryType{type: :credit, name: "Credit"},
             %ReportingCategory{
               type: :balance_sheet,
               primary: true
             }
           ) ==
             {:ok,
              %AccountType{
                name: "Liability",
                normal_balance: %EntryType{type: :credit, name: "Credit"},
                primary_reporting_category: %ReportingCategory{
                  type: :balance_sheet,
                  primary: true
                }
              }}
  end

  test "disallow account types that has no name" do
    assert AccountType.new(nil, %EntryType{type: :debit}, %ReportingCategory{
             type: :balance_sheet,
             primary: true
           }) ==
             {:error, :invalid_account_type}
  end

  test "disallow account types that has an entry type other than debit or credit" do
    assert AccountType.new("Invalid", %EntryType{type: :invalid_type}, %ReportingCategory{
             type: :balance_sheet,
             primary: true
           }) ==
             {:error, :invalid_account_type}
  end

  test "disallow account types that has no reporting category" do
    assert AccountType.new("Invalid", %EntryType{type: :debit}, nil) ==
             {:error, :invalid_account_type}
  end

  test "disallow account types that has empty name" do
    assert AccountType.new("", %EntryType{type: :credit, name: ""}, %ReportingCategory{
             type: :balance_sheet,
             primary: true
           }) ==
             {:error, :invalid_account_type}
  end
end
