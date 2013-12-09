ledger-bitcoin
==============

Scripts to interface the ledger accounting system with various bitcoin systems

Available tools/scripts
=======================

electrum2ledger
---------------
```electrum2ledger``` extracts the transaction history from an electrum wallet as ledger transactions.
It can directly call ```electrum``` to get the history or parse a csv file exported from electrum.

To extract directly via electrum, electrum must be installed and in the path (alternatively, the path to the binary can be set in the electrum2ledger script).

bitstamp2ledger
---------------
```bitstamp2ledger``` retrieves the transaction history from a Bitstamp account via the Bitstamp API and outputs it as ledger transactions.
It can also parse a csv file exported from the Bitstamp website.

To retrieve the transaction history directly via the Bitstamp API, an API key with the "User Transactions" permission must be supplied.
