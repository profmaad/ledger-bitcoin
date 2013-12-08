require 'csv'

module LedgerBitcoin
  module Ledger
    TAG_KEY_VALUE_REGEXP = /^[[:blank:]]*(?<key>[[:graph:]]*?): (?<value>[[:print:]]*)[[:blank:]]*$/
    TAG_REGEXP = /^[[:blank:]]*:(?<tag>[[:graph:]]*?):[[:blank:]]*$/

    CSV_OPTIONS = {
      :col_sep => ',',
      :row_sep => :auto,
      :quote_char => '"',
      :headers => false,  
    }

    def self.ledger_base_command(ledger_file)
      command = LEDGER_BIN
      
      if(ledger_file)
        command << " --file #{ledger_file}"
      elsif(not(LEDGER_FILE.nil? or LEDGER_FILE.empty?))
        command << " --file #{LEDGER_FILE}"
      end
      
      return command
    end
    
    def self.parse_metadata_tags(comment_string)
      tags = {}

      lines = comment_string.split('\n')

      lines.each do |line|
        key_value_match_data = TAG_KEY_VALUE_REGEXP.match(line)
        tag_match_data = TAG_REGEXP.match(line)

        if(key_value_match_data)
          tags[key_value_match_data[:key]] = key_value_match_data[:value]
        elsif(tag_match_data)
          tags[tag_match_data[:tag]] = true
        end
      end

      return tags
    end

    def self.parse_csv(csv_string)
      positions = []

      CSV.parse(csv_string) do |row|
        positions << {
          :posting_date => row[0],
          :clearing_date => row[1],
          :payee => row[2],
          :account => row[3],
          :currency => row[4],
          :amount => row[5].to_f,
          :cleared => row[6] == '*',
          :comment => row[7],
          :tags => parse_metadata_tags(row[7]),
        }
      end

      return positions
    end

    def self.last_matching_transaction(query, ledger_file = nil)
      csv_result = %x(#{ledger_base_command(ledger_file)} -S date --last 1 csv #{query})

      return parse_csv(csv_result)
    end
  end
end
