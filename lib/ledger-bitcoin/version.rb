module LedgerBitcoin
  VERSION = [0,3,1]

  def self.version_string
    return VERSION.join('.')
  end
end
