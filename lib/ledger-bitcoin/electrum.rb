# -*- coding: utf-8 -*-
require 'csv'
require 'time'

require_relative 'electrum_transaction'

module LedgerBitcoin
  module Electrum
    HISTORY_REGEXP = /^[[:blank:]]*"(?<year>[[:digit:]]{4})-(?<month>[[:digit:]]{2})-(?<day>[[:digit:]]{2}) (?<hour>[[:digit:]]{2}):(?<minute>[[:digit:]]{2})  (?<label>[[:print:]]*?)[[:blank:]]{3,}(?<amount>-?[0-9.]+)  (?<balance>-?[0-9.]+)",?[[:blank:]]*$/

    HISTORY_CSV_OPTIONS = {
      :col_sep => ',',
      :row_sep => :auto,
      :headers => true,
      :return_headers => false,
    }
    
    def self.electrum_command(command, wallet_path = nil, electrum_bin = nil)
      command_string = ''

      if(electrum_bin)
        command_string << electrum_bin
      else
        command_string << $config[:electrum][:binary]
      end

      if(wallet_path)
        command_string << ' --wallet="' << wallet_path << '"'
      end

      command_string << ' ' << command

      return command_string
    end

    def self.transactions_from_electrum_bin(asset_account, wallet_path = nil)
      transactions = []

      electrum_command_string = electrum_command('history', wallet_path)
      electrum_history_output = %x(#{electrum_command_string})

      electrum_history_output.each_line do |line|
        match_data = HISTORY_REGEXP.match(line)

        if match_data
          timestamp = Time.local(match_data[:year].to_i, match_data[:month].to_i, match_data[:day].to_i, match_data[:hour].to_i, match_data[:minute].to_i)

          transactions << ElectrumTransaction.new(
                                                  timestamp,
                                                  asset_account,
                                                  match_data[:amount].to_f,
                                                  match_data[:label],
                                                  match_data[:balance],
                                                  nil
                                                  )
        end
      end

      return transactions
    end


    def self.transactions_from_csv(csv_file, asset_account)
      rows = nil
      File.open(csv_file, 'r') do |f|
        csv = CSV.new(f, HISTORY_CSV_OPTIONS)
        rows = csv.read
      end

      transactions = []

      rows.each do |row|
        transaction_id = row['transaction_hash']
        label = row['label']
        confirmed = (row['confirmations'].to_i > 0)

        amount = row['value'].to_f
        balance = row['balance'].to_f

        timestamp = Time.strptime(row['timestamp'], '%Y-%m-%d %H:%M')

        transactions << ElectrumTransaction.new(
                                                timestamp,
                                                asset_account,
                                                amount,
                                                label,
                                                balance,
                                                transaction_id,
                                                confirmed
                                                )
      end

      return transactions
    end
  end
end
