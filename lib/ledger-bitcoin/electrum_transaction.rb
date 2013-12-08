module LedgerBitcoin
  module Electrum
    class ElectrumTransaction
      attr_accessor :timestamp
      attr_accessor :transaction_id
      attr_accessor :label
      attr_accessor :amount
      attr_accessor :resulting_balance
      attr_accessor :asset_account
      attr_accessor :confirmed

      def initialize(timestamp, asset_account, amount, label, resulting_balance, transaction_id = nil, confirmed = true)
        self.timestamp = timestamp
        self.asset_account = asset_account
        self.amount = amount
        self.label = label
        self.resulting_balance = resulting_balance
        self.transaction_id = transaction_id
        self.confirmed = confirmed
      end

      def to_ledger()
        transaction = ''
        
        date = timestamp.strftime('%Y/%m/%d')

        # the '()' iskind of a hack to guard against labels enclosed in parantheses
        transaction << date << ' ' << (confirmed ? '*' : '') << ' () ' << label << "\n" 
        transaction << ' ;import_source: electrum' << "\n"
        transaction << " ;electrum_label: #{label}\n" unless (label.nil? or label.empty?)
        transaction << " ;bitcoin_transaction_id: #{transaction_id}\n" unless (transaction_id.nil? or transaction_id.empty?)
        transaction << '  ' << (amount < 0 ? 'Expenses' : 'Income') << ":\n"
        transaction << "  #{asset_account}  #{BTC_CURRENCY_SYMBOL} #{amount}\n"

        return transaction
      end

      def is_equal_to_ledger_posting?(ledger_posting)
        return (
                timestamp.strftime('%Y/%m/%d') == ledger_posting[:posting_date] and
                label == ledger_posting[:tags]['electrum_label'] and
                amount == ledger_posting[:amount] and
                ledger_posting[:tags]['import_source'] == 'electrum' and
                ledger_posting[:account] == asset_account and
                (transaction_id.nil? or ledger_posting[:tags]['bitcoin_transaction_id'].nil? or (transaction_id == ledger_posting[:tags]['bitcoin_transaction_id']))
                )
      end
    end
  end
end
