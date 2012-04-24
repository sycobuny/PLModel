PLModel
=======

A library for providing a simple base Model class to build queries in PostgreSQL
without having to do a lot of drudgery.

(A port of [PGModel][pgmodel] from PHP to Perl, which is itself inspired by
[Sequel][sequel] for Ruby)

For Example
-----------

```perl
### Account.pm
use v5.14;
use warnings;
use PLModel;

PLModel::Database::add_connection(
    host => 'localhost',
    user => 'steve',
);

package Account {
    our (@ISA) = qw(PLModel::Base);

    sub debit {
        my ($self) = shift;
        my ($amt)  = @_;

        $this->balance -= $amt;
    }
}

1;

### debit.pl
use v5.14;
use warnings;
use Account;
my ($id, $amount) = @ARGV;

my ($account) = Account->load($id);
$account->debit($amount);
$account->save();
```

License
-------

MIT Licensed. See LICENSE for details.
