use v5.14;
use warnings;

package PLModel::SQL::String {
    use Hash::Util::FieldHash qw();
    my ($id);
    my (%bind, %adapter, %connection, %name, %statement);
    my ($parse_options);

    $parse_options = sub {
        my ($self)    = shift;
        my ($options) = @_;
        my ($val);

        $id = Hash::Util::FieldHash::id($self);

        if ($val = $options->{adapter}) {
            $adapter{$id} = $val;
        }

        if ($val = $options->{prepared_name}) {
            $name{$id} = $val;
        }

        if (exists($options->{connection}) {
            $val = $options->{connection};
            unless ($val) {
                $val = PLModel::Database::default_connection();
            }

            if ($adapter{$id}) {
                unless ($val->adapter() eq $adapter{$id}) {
                    die "Query is written for $adapter{$id}, but the given " .
                        "connection for preparing is " . $val->adapter();
                }
            }

            $statement{$id} = $val->prepare($$self, $name{$id});
        }
    };

    sub new {
        my ($package) = shift;
        my ($class)   = ref($package) || $package;
        my ($query, $bind, $options) = @_;

        my ($self) = bless(\$query, $class);
        $id = Hash::Util::FieldHash::id($self);

        $bind{$id} = $bind;
        $self->$parse_options($options);

        return $self;
    }

    sub prepare {
        my ($self) = shift;
        my ($connection, $name) = @_;

        $id = Hash::Util::FieldHash::id($self);

        if ($name) {
            $name{$id} = $name;
        }

        if ($adapter{$id}) {
            unless ($connection->adapter() eq $adapter{$id}) {
                die "Query is written for $adapter{$id}, but the given " .
                    "connection for preparing is " . $connection->adapter();
            }
        }

        $statement{$id} = $connection->prepare($$self, $name{$id});
    }

    sub bind_count {
        my ($self) = shift;
        $id = Hash::Util::FieldHash::id($self);

        if (ref($bind{$id}) =~ /ARRAY/o) {
            return scalar(@{ $bind{$id} });
        }
        else {
            return $bind{$id} || 0;
        }
    }

    sub adapter {
        $adapter{Hash::Util::FieldHash::id($_[0])};
    }

    sub connection {
        $connection{Hash::Util::FieldHash::id($_[0])};
    }

    sub prepared_name {
        $name{Hash::Util::FieldHash::id($_[0])};
    }

    sub prepared_statement {
        $statement{Hash::Util::FieldHash::id($_[0])};
    }

    sub DESTROY {
        my ($self) = shift;
        $id = Hash::Util::FieldHash::id($self);

        foreach my $h (\(%bind, %adapter, %connection, %name, %statement)) {
            delete($h->{$id});
        }
    }
}

'String.pm - MIT Licensed by Stephen Belcher, 2012. See LICENSE'

__END__
__MARKDOWN__

PLModel::SQL::String
====================

Summary
-------

A basic object representing an SQL string with some additional parameters that
can be used to hint to the database connection what to do when querying it. It
represents a fully-formed query that can be executed, unlike
`PLModel::SQL::Fragment`.

Example
-------

    use PLModel::Database;
    use PLModel::SQL::String;

    my ($string)  PLModel::SQL::String->new(
        'SELECT * FROM users WHERE first_name = ? AND last_name = ?',
        2
    );

    PLModel::Database::iterate($string, ['Stephen', 'Belcher'], sub {
        my ($row) = @_;
        say "Stephen Belcher's ID is " . $row->{id};
    });

Class Methods
-------------

### new(string, integer|arrayref, [hashref]) - returns PLModel::SQL::String

Creates a new PLModel::SQL::String object, taking the SQL string and the
number of bind parameters the SQL will require, either specified as an integer,
or as an arrayref containing the names of the bind paramters. It takes an
optional hash reference with any additional configuration options. Currently
accepted keys are:

 * `adapter` - The string representing which adapter this query was written
   for. If it is passed to a call to any query functions on a different
   database connection, an error will be raised.
 * `connection` - The PLModel::Database::Connection this query should be
   prepared for. It short-circuits the need to call prepare() later. If this
   key is provided but the value is `undef`, the default connection will be
   used. See PLModel::Database and PLModel::Database::Connection for further
   discussion of the default connection.
 * `prepared_name` - The name to use when preparing this string. Its presence
   does not automatically prepare the statement, the `connection` parameter
   must also be provided. However, it stores the name of the statement for a
   later call to `prepare()`.

Instance Methods
----------------

### prepare(PLModel::Database::Connection, [string]) - returns PLModel::PreparedStatement

### bind_count() - returns integer

Returns the count of bind variables this query expects.

### adapter() - returns string

Returns the name of the adapter that this query was written for. It is useful,
if there are syntactical differences (identifier quoting, for instance), to
specify which adapter is intended, so that no unexpected bugs from
technically-valid but still incorrect for an adapater queries are prepared. If
no adapter was specified, `undef` will be returned.

### connection() - returns PLModel::Database::Connection

Returns the connection on which this query was prepared. If it has not been
prepared yet, `undef` will be returned.

### prepared_name() - returns string

Returns the name of the string that was or will be used to prepare this string.
If no prepared name string was given, `undef` will be returned.

### prepared_statement() - returns PLModel::PreparedStatement

Returns the fully-prepared statement object for this query. If it has not been
prepared yet, then `undef` will be returned.

License
-------

MIT Licensed. See the included LICENSE file for the full license.

Authors
-------

* Stephen Belcher <sbelcher@gmail.com>
