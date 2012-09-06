use v5.14;
use warnings;

package PLModel::Base {
    use Hash::Util::FieldHash qw();
    use Scalar::Util qw();

    use PLModel::Inflector;
    use PLModel::Database;
    use PLModel::Base::Column;
    use PLModel::Accessor;

    my (%class_columns, %class_pkeys, %class_tables);
    my (%clean, %dirty);
    my ($setup_columns);
    my ($id) = *Hash::Util::FieldHash::id{CODE};

    sub new {
        my ($package) = shift;
        my ($class)   = ref($package) || $package;
        my ($table)   = $class->table();
        my ($id, $clean, $dirty, $self) = $self->$id;

        $class->$setup_columns($table);
        $self  = bless(\(my $o), $class);
        $clean = $clean{$id} = {};
        $dirty = $dirty{$id} = {};

        foreach my $colname (keys %{ $class_columns{$class} }) {
            $clean->{$colname} = undef;
            $dirty->{$colname} = undef;
        }

        return $self;
    }

    $setup_columns = sub {
        my ($package) = shift;
        my ($table)   = @_;
        my ($class)   = ref($package) || $package;
        my ($id, $pkeys, $columns, $col_objs) = $self->$id;

        $pkeys   = {};
        $columns = PLModel::Database::columns($table);
        $class_pkeys{$class}   = PLModel::Database::primary_keys($table);
        $class_columns{$class} = $col_objs = {};

        foreach my $pkey (@{ $class_pkeys{$class} }) { $pkeys->{$pkey} = 1 }
        foreach my $name (keys %$columns) {
            no strict 'refs';
            my ($method)  = $class . '::' . $name;
            my ($conf)    = $columns->{$name};
            my ($col_obj) = PLModel::Base::Column->new(
                $class, $name, $conf->{TYPE_NAME}, $conf->{NULLABLE},
                $pkeys->{$name}
            );

            $col_objs->{$name} = $col_obj;

            unless (*{$method}{CODE}) {
                *{$method} = sub : lvalue {
                    my ($self) = shift;
                    my ($value);
                    $id = Hash::Util::FieldHash::id($self);

                    $value = $dirty{$id}{$name};

                    tie $value, 'PLModel::Accessor', $value, $name, $self;
                    $value;
                };
            }
        }
    };

    sub table {
        my ($self) = shift;
        my ($table) = @_;
        my ($class) = ref($self) || $self;

        if ($class_tables{$class}) {
            return $class_tables{$class};
        }
        else {
            if ($table) {
                return $class_tables{$class} = $table;
            }

            my ($l) = PLModel::Inflector::decamelize($class);
            my ($p) = PLModel::Inflector::pluralize($l);

            return $class_tables{$class} = $p;
        }
    }

    sub set_column {
        my ($self) = shift;
        my ($name, $value) = @_;

        $id = Hash::Util::FieldHash::id($self);
        return $dirty{$id}{$name} = $value;
    }

    sub get_column {
        my ($self) = shift;
        my ($name) = @_;

        $id = Hash::Util::FieldHash::id($self);
        return $dirty{$id}{$name};
    }
}

'Base.pm - MIT Licensed by Stephen Belcher, 2012. See LICENSE'

__END__
__MARKDOWN__

PLModel::Base
=============

Summary
-------

The base class that any models should inherit from.

Example
-------

    # assuming accounts table with fields id(int), name(text), and bal(float)
    package Account { use parent qw(PLModel::Base) }

    my ($id, $credit);
    ... # retrieve account ID and amount to credit

    my ($account) = Account->load($id);
    $account->bal += $credit;
    $account->save();
    say "@{[ $account->name ]}'s current balance is @{[ $account-bal ]}.";
