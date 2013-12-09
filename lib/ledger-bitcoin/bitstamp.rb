require 'csv'
require 'time'

require_relative 'bitstamp_api_consumer'
require_relative 'bitstamp_transaction'

module LedgerBitcoin
  module Bitstamp
    TRANSACTIONS_CSV_OPTIONS = {
      :col_sep => ',',
      :row_sep => :auto,
      :headers => true,
      :return_headers => false,
    }

    def self.transactions_from_api(asset_account, fee_account, client_id, api_key, api_secret, last_imported_transaction)
      api_consumer = Bitstamp::APIConsumer.new(client_id, api_key, api_secret)

      if(last_imported_transaction.nil? or last_imported_transaction[:tags]['bitstamp_transaction_index'].nil? or last_imported_transaction[:tags]['bitstamp_transaction_index'].empty?)
        offset = 0
      else
        offset = last_imported_transaction[:tags]['bitstamp_transaction_index'].to_i + 1
      end

      transactions = []
      loop do
        api_transactions = api_consumer.user_transactions(offset, BITSTAMP_API_TRANSACTIONS_BATCH_SIZE, 'asc')
        break if api_transactions.empty?

        api_transactions.each_with_index do |api_transaction, index|
          transactions << BitstampTransaction.create_from_api(api_transaction, offset + index, asset_account, fee_account)
        end

        offset += api_transactions.size
      end

      return transactions
    end

    def self.transactions_from_csv(csv_file, asset_account, fee_account)
      rows = nil
      File.open(csv_file, 'r') do |f|
        csv = CSV.new(f, TRANSACTIONS_CSV_OPTIONS)
        rows = csv.read
      end

      transactions = []

      rows.each_with_index do |row, index|
        transactions << BitstampTransaction.create_from_csv(row, index, asset_account, fee_account)
      end

      return transactions
    end
  end
end
