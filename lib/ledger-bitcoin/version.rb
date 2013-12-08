module LedgerBitcoin
  VERSION = [0,1,0]

  def self.version_string
    return VERSION.join('.')
  end
end
