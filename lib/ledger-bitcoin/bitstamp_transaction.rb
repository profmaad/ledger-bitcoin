require 'time'

module LedgerBitcoin
  module Bitstamp
    class BitstampTransaction
      attr_accessor :timestamp
      attr_accessor :bitstamp_transaction_index
      attr_accessor :bitstamp_transaction_id
      attr_accessor :order_id
      attr_accessor :type
      attr_accessor :usd_amount, :btc_amount
      attr_accessor :btc_usd_exchange_rate
      attr_accessor :fee
      attr_accessor :asset_account, :fee_account

      def self.create_from_api(api_transaction, transaction_index, asset_account, fee_account)
        timestamp = datetime_to_timestamp(api_transaction['datetime'])

        type = type_to_sym(api_transaction['type'])

        return BitstampTransaction.new(
                                       timestamp,
                                       transaction_index,
                                       api_transaction['id'],
                                       api_transaction['order_id'],
                                       type,
                                       api_transaction['usd'].to_f,
                                       api_transaction['btc'].to_f,
                                       api_transaction['btc_usd'].to_f,
                                       api_transaction['fee'].to_f,
                                       asset_account,
                                       fee_account
                                       )                                       
      end
      def self.create_from_csv(csv_transaction, transaction_index, asset_account, fee_account)
        timestamp = datetime_to_timestamp(csv_transaction['Datetime'])

        type = type_to_sym(csv_transaction['Type'].to_i)

        return BitstampTransaction.new(
                                       timestamp,
                                       transaction_index,
                                       nil,
                                       nil,
                                       type,
                                       csv_transaction['USD'].to_f,
                                       csv_transaction['BTC'].to_f,
                                       csv_transaction['BTC Price'].to_f,
                                       csv_transaction['FEE'].to_f,
                                       asset_account,
                                       fee_account
                                       )                                       
      end

      def self.type_to_sym(type_int)
        case type_int
               when 0 then :deposit
               when 1 then :withdrawal
               when 2 then :trade
               else :unknown
        end
      end
      def self.datetime_to_timestamp(datetime)
        Time.strptime(datetime, '%Y-%m-%d %H:%M:%S')
      end

      def initialize(timestamp, bitstamp_transaction_index, bitstamp_transaction_id, order_id, type, usd_amount, btc_amount, btc_usd_exchange_rate, fee, asset_account, fee_account)
        self.timestamp = timestamp
        self.asset_account = asset_account
        self.fee_account = fee_account
        self.bitstamp_transaction_index = bitstamp_transaction_index
        self.bitstamp_transaction_id = bitstamp_transaction_id
        self.order_id = order_id
        self.type = type
        self.usd_amount = usd_amount
        self.btc_amount = btc_amount
        self.btc_usd_exchange_rate = btc_usd_exchange_rate
        self.fee = fee
      end

      def label
        case type
        when :deposit then 'Bitstamp Deposit'
        when :withdrawal then 'Bitstamp Withdrawal'
        when :trade then 'Bitstamp Market Trade'
        else 'Bitstamp'
        end
      end

      def to_ledger()
        transaction = ''
        
        date = timestamp.strftime('%Y/%m/%d')

        # the '()' iskind of a hack to guard against labels enclosed in parantheses
        transaction << date << ' * () ' << label << "\n" 
        transaction << ' ;import_source: bitstamp' << "\n"
        transaction << " ;bitstamp_transaction_index: #{bitstamp_transaction_index}\n"
        transaction << " ;bitstamp_transaction_id: #{bitstamp_transaction_id}\n" unless bitstamp_transaction_id.nil?
        transaction << " ;bitstamp_order_id: #{order_id}\n" unless order_id.nil?
        transaction << " ;bitstamp_type: #{type.to_s}\n"
        transaction << " ;btc_usd_exchange_rate: #{btc_usd_exchange_rate}\n" unless btc_usd_exchange_rate == 0
        case type
        when :trade
          transaction << '  ' << fee_account   << '  ' << USD_CURRENCY_SYMBOL << ' ' << fee.to_s        << "\n" unless fee == 0
          transaction << '  ' << asset_account << '  ' << USD_CURRENCY_SYMBOL << ' ' << (-fee).to_s     << "\n" unless fee == 0
          transaction << '  ' << asset_account << '  ' << BTC_CURRENCY_SYMBOL << ' ' << btc_amount.to_s << "\n" unless btc_amount == 0
          transaction << '  ' << asset_account << '  ' << USD_CURRENCY_SYMBOL << ' ' << usd_amount.to_s << "\n" unless usd_amount == 0
        when :deposit, :withdrawal
          transaction << '  ' << 'Assets:' << "\n"
          if btc_amount == 0
            transaction << '  ' << asset_account << '  ' << USD_CURRENCY_SYMBOL << ' ' << usd_amount.to_s << "\n"
          else
            transaction << '  ' << asset_account << '  ' << BTC_CURRENCY_SYMBOL << ' ' << btc_amount.to_s << "\n"
          end
        end

        return transaction
      end

      def is_equal_to_ledger_posting?(ledger_posting)
        return (
                timestamp.strftime('%Y/%m/%d') == ledger_posting[:posting_date] and
                ledger_posting[:tags]['import_source'] == 'bitstamp' and
                ledger_posting[:account] == asset_account and
                ledger_posting[:tags]['bitstamp_transaction_index'].to_i == bitstamp_transaction_index and
                (bitstamp_transaction_id.nil? or ledger_posting[:tags]['bitstamp_transaction_id'].nil? or (bitstamp_transaction_id == ledger_posting[:tags]['bitstamp_transaction_id'].to_i))
                )
      end
    end
  end
end
