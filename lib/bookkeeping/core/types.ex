defmodule Bookkeeping.Core.Types do
  @typedoc """
  Entry is a type that indicates the type of accounting entry for a transaction.
  It can have two possible values: debit or credit.
  A debit entry means that the value of an account is increased or decreased depending on its nature (asset, liability, equity, income, expense).
  A credit entry means the opposite of a debit entry.
  A debit entry also shows that the value is flowing out of an account, while a credit entry shows that the value is flowing into an account.
  For example, if a business buys inventory for cash, it will make a debit entry for the inventory account and a credit entry for the cash account.
  This shows that the value of the inventory account increased and the value of the cash account decreased.
  It also shows that the value flowed out of the cash account and into the inventory account.
  """
  @type entry :: :debit | :credit
end
