ledger_bitcoin
==============

Scripts to interface the ledger accounting system with various bitcoin systems

Available tools/scripts
=======================

electrum2ledger
---------------
```electrum2ledger``` extracts the transaction history from an electrum wallet as ledger transactions.
It can directly call ```electrum``` to get the history or parse a csv file exported from electrum (planned feature).

To extract directly via electrum, electrum must be installed and in the path (alternatively, the path to the binary can be set in the electrum2ledger script).
