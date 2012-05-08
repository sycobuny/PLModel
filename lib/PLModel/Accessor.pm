use v5.14;
use warnings;

package PLModel::Accessor {
    my ($set) = \&PLModel::Base::set_column;

    sub TIESCALAR {
        my ($class) = shift;
        my ($curval, $colname, $object) = @_;

        return bless({
            curval  => $curval,
            colname => $colname,
            object  => $object
        }, $class);
    }

    sub FETCH {
        my ($self) = shift;
        return $self->{curval};
    }

    sub STORE {
        my ($self) = shift;
        my ($newval) = @_;

        $newval = $self->{object}->$set($self->{colname}, $newval);
        $self->{curval} = $newval;

        return $self;
    }
}

'Accessor.pm - MIT Licensed by Stephen Belcher, 2012. See LICENSE'

__END__
__MARKDOWN__

PLModel::Accessor
=================

Summary
-------

Make accessors which automatically process values on assignment; handy for
building lvalue subs for syntactic sugar.

Example
-------

    package ANeatClass {
        use Hash::Util::FieldHash qw(id);
        use PLModel::Accessor;

        sub new { bless(\(my $o), shift) }

        my (%fields);
        sub set_column { $fields{id $_[0]}{$_[1]} = $_[2] }

        sub some_field : lvalue {
            my ($field) = $field{id $self}{'some_field'};
            tie($field, 'PLModel::Accessor', $field, 'some_field');

            $field;
        }
    }

    my ($neat_class) = ANeatClass->new();
    $neat_class->some_field = 'some_value';
    say "A neat class's some_field is " . $neat_class->some_field;
    # => A neat class's some_field is some_value
