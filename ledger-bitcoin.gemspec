$:.push File.expand_path('../lib', __FILE__)
require 'ledger-bitcoin/version.rb'

Gem::Specification.new do |s|
  s.name = 'ledger-bitcoin'
  s.version = LedgerBitcoin.version_string
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = 'Scripts to interface the ledger accounting system with various bitcoin systems'
  s.description = 'ledger-bitcoin is a collection of scripts/tools, that interface the ledger accounting system (http://www.ledger-cli.org) with various bitcoin-related system. Currently, export of transactions from an electrum wallet to a ledger file is implemented.'
  s.authors = ['Maximilian Wolter']
  s.email = 'himself at prof-maad dot org'
  s.license = 'MIT'

  s.add_runtime_dependency 'trollop', '>= 2.0'

  s.files = %x(git ls-files).split("\n")
  s.executables = %x(git ls-files -- bin/*).split("\n").map {|f| File.basename(f)}
end
