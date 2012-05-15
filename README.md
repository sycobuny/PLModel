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

package Account {
    use parent qw(PLModel::Base);

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

Documentation
-------------

> "You're not using POD? Heretic!"

I don't really care for POD. Without a POD preprocessor, it's almost impossible
to read, and it's a massive pain to write. I think markdown suffices to both be
easy to read and write, and has the added bonus of being a Perl Original
Technology™. There's no reason we can't use a different, more sane, perl library
to generate perl documentation. While I don't want this project to be an essay
on the merits of documentation styles, I imagine the topic might come up.

[pgmodel]: https://github.com/sycobuny/pg_model "PGModel - PostgreSQL for PHP"
[sequel]: https://sequel.rubyforge.org/ "Sequel - The database toolkit for Ruby"
