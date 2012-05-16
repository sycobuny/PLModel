use v5.14;
use warnings;

package PLModel::Base::Column {
    use Hash::Util::FieldHash qw();
    use Scalar::Util qw();

    my (%in_handlers, %out_handlers, %db_in_handlers, %db_out_handlers);
    my (%class, %name, %type, %is_null, %is_pk, %handlers);
    my ($id, $handle_in, $handle_out);

    sub new {
        my ($package) = shift;
        my ($refclass, $name, $type, $is_null, $is_pk) = @_;
        my ($class) = ref($package) || $package;
        my ($self)  = bless(\(my $o), $class);

        $id = Hash::Util::FieldHash::id($self);

        $class{$id}   = $refclass;
        $name{$id}    = $name;
        $type{$id}    = $type;
        $is_null{$id} = $is_null;
        $is_pk{$id}   = $is_pk;

        return $self;
    }

    $handle_in = sub {
        my ($self) = shift;
        my ($first, $second, $value, $adapter) = @_;
        my ($type, $handler);

        $id = Hash::Util::FieldHash::id($self);
        $type = $type{$id};

        if ($first->{$adapter} && $first->{$adapter}{$type}) {
            $handler = $first->{$adapter}{$type};
        }
        elsif ($second->{$adapter} && $second->{$adapter}{$type}) {
            $handler = $second->{$adapter}{$type};
        }

        if ($handler) {
            return $handler->($value, $class{$id}, $name{$id}, $is_null{$id},
                              $is_pk{$id});
        }
        else {
            return $value;
        }
    };

    $handle_out = sub {
        my ($self) = shift;
        my ($first, $second, $value, $adapter) = @_;
        my ($type, $handler);

        $id = Hash::Util::FieldHash::id($self);
        $type = $type{$id};

        if ($first->{$adapter} && $first->{$adapter}{$type}) {
            $handler = $first->{$adapter}{$type};
        }
        elsif ($second->{$adapter} && $second->{$adapter}{$type}) {
            $handler = $second->{$adapter}{$type};
        }

        if ($handler) {
            return $handler->($value, $class{$id}, $name{$id}, $is_null{$id},
                              $is_pk{$id});
        }
        elsif (Scalar::Util::blessed($value) && $value->can('to_s')) {
            return $value->to_s();
        }
        else {
            return "$value";
        }
    };

    sub from_input {
        my ($self) = shift;
        $self->$handle_in(\%in_handlers, \%db_in_handlers, @_);
    }

    sub to_output {
        my ($self) = shift;
        $self->$handle_out(\%out_handlers, \%db_out_handlers, @_);
    }

    sub from_database {
        my ($self) = shift;
        $self->$handle_in(\%db_in_handlers, \%in_handlers, @_);
    }

    sub to_database {
        my ($self) = shift;
        $self->$handle_out(\%db_out_handlers, \%out_handlers, @_);
    }

    sub add_handler {
        my ($package) = shift;
        my ($type, $direction, $handler, $adapter, $overwrite) = @_;
        my ($handlers);

        $adapter = 'postgres' unless $adapter;
        $handlers->{$adapter} ||= {};

        given ($direction) {
            when ('input')     { $handlers = \%in_handlers     }
            when ('output')    { $handlers = \%out_handlers    }
            when ('db_input')  { $handlers = \%db_in_handlers  }
            when ('db_output') { $handlers = \%db_out_handlers }
            default {
                die "Unknown handler direction: $direction";
            }
        }

        if ($handlers->{$adapter}{$type} && !$overwrite) {
            die "Already registered a $direction handler for $type in " .
                "$adapter connections. If you want to force the new handler, " .
                "provide an `overwrite` parameter.";
        }

        $handlers->{$adapter}{$type} = $handler;
    }

    sub DESTROY {
        my ($self) = shift;
        $id = Hash::Util::FieldHash::id($self);

        foreach my $h (\(%class, %name, %type, %is_null, %is_pk, %handlers)) {
            delete $h->{$id};
        }
    }
}

'Column.pm - MIT Licensed by Stephen Belcher, 2012. See LICENSE'

__END__
__MARKDOWN__

PLModel::Base::Column
=====================

Summary
-------

Provide column conversions for mapping database fields to perl object members.

Example
-------

License
-------

MIT Licensed. See the LICENSE file in the root directory for the full license.

Authors
-------

* Stephen Belcher <sbelcher@gmail.com>
