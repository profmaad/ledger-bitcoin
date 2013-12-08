#!/usr/bin/env ruby

require 'pp'

require_relative 'ledger_utils'

HISTORY_REGEXP = /^[[:blank:]]*"(?<year>[[:digit:]]{4})-(?<month>[[:digit:]]{2})-(?<day>[[:digit:]]{2}) (?<hour>[[:digit:]]{2}):(?<minute>[[:digit:]]{2})  (?<label>[[:print:]]*?)[[:blank:]]{3,}(?<amount>-?[0-9.]+)  (?<balance>-?[0-9.]+)",?[[:blank:]]*$/

ELECTRUM_BIN='electrum'

BTC_CURRENCY_SYMBOL='BTC'

class ElectrumTransaction
  attr_accessor :timestamp
  attr_accessor :transaction_id
  attr_accessor :label
  attr_accessor :amount
  attr_accessor :resulting_balance

  def initialize(timestamp, amount, label, resulting_balance, transaction_id)
    self.timestamp = timestamp
    self.amount = amount
    self.label = label
    self.resulting_balance = resulting_balance
    self.transaction_id = transaction_id
  end

  def to_ledger()
    transaction = ''
    
    date = timestamp.strftime('%Y/%m/%d')

    transaction << "#{date} * () #{label}\n" # kind of a hack to guard against labels enclosed in parantheses
    transaction << ' ;import_source: electrum' << "\n"
    transaction << " ;electrum_label: #{label}\n" unless (label.nil? or label.empty?)
    transaction << " ;bitcoin_transaction_id: #{transaction_id}\n" unless (transaction_id.nil? or transaction_id.empty?)
    transaction << '  ' << (amount < 0 ? 'Expenses' : 'Income') << ":\n"
    transaction << "  #{@@wallet_asset_account}  #{BTC_CURRENCY_SYMBOL} #{amount}\n"

    return transaction
  end
end

def transactions_from_electrum_bin
  transactions = []

  electrum_history_output = %x(#{ELECTRUM_BIN} history)

  electrum_history_output.each_line do |line|
    match_data = HISTORY_REGEXP.match(line)

    if match_data
      timestamp = Time.local(match_data[:year].to_i, match_data[:month].to_i, match_data[:day].to_i, match_data[:hour].to_i, match_data[:minute].to_i)

      transactions << ElectrumTransaction.new(
                                              timestamp,
                                              match_data[:amount].to_f,
                                              match_data[:label],
                                              match_data[:balance],
                                              nil
                                              )
    end
  end

  return transactions
end

def compare_transactions(electrum, ledger)
  return (
          electrum.timestamp.strftime('%Y/%m/%d') == ledger[:posting_date] and
          electrum.label == ledger[:tags]['electrum_label'] and
          electrum.amount == ledger[:amount] and
          ledger[:tags]['import_source'] == 'electrum' and
          ledger[:account] == @@wallet_asset_account
          )
end

@@wallet_asset_account = ARGV.shift
if(@@wallet_asset_account.nil? or @@wallet_asset_account.empty?)
  $stderr.puts "Usage: #{$PROGRAM_NAME} <wallet asset account>"
  exit 1
end

last_imported_transaction = LedgerUtils.last_matching_transaction("#{@@wallet_asset_account} and %import_source=electrum").last

transactions = transactions_from_electrum_bin

last_imported_transaction_found = last_imported_transaction.nil?
transactions.each do |transaction|
  if(not last_imported_transaction_found)
    last_imported_transaction_found = compare_transactions(transaction, last_imported_transaction)
    
    next
  end
  
  puts transaction.to_ledger
end
