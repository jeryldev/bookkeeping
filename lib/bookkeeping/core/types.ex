defmodule Bookkeeping.Core.Types do
  @moduledoc """
  Bookkeeping.Core.Types is a module that contains all the types used in the Bookkeeping.Core module.
  There are core types: entry and category.
  Entry is a type that indicates the type of accounting entry for a transaction (debit or credit).
  Category is a type that indicates which of the two most important financial reports an account belongs to (position or performance).
  """

  @typedoc """
  Entry is a type that indicates the type of accounting entry for a transaction.
  It can have two possible values: debit or credit.
  A debit entry means that the value of an account is increased or decreased depending on its nature (asset, liability, equity, income, expense).
  A credit entry means the opposite of a debit entry.
  For example, if a business buys inventory for cash, it will make a debit entry for the inventory account and a credit entry for the cash account.
  This shows that the value of the inventory account increased and the value of the cash account decreased.
  It also shows that the value flowed out of the cash account and into the inventory account.
  """
  @type entry :: :debit | :credit

  @typedoc """
  Category is a type that indicates which of the two most important financial reports an account belongs to.
  The two most important financial reports are the balance sheet and the profit and loss.
  They provide a comprehensive overview of the business's financial position and performance.
  A position category represents the accounts that show the assets, liabilities, and equity of the business at a point in time.
  A performance category represents the accounts that show the revenues, expenses, and profits or losses of the business over a period of time.
  """
  @type category :: :position | :performance
end
