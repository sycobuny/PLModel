use v5.14;
use warnings;

package PLModel::Query::Identifier {
    use parent qw(PLModel::Query::Expression);
    use Hash::Util::FieldHash qw();

    my (%identifier);
    my ($id) = *Hash::Util::FieldHash::id{CODE};
    my ($nq) = qr/^
        [a-z\_]     # starts with underscore or a-z
        [a-z0-9\_]* # any number of a-z, underscores, or numbers
    $/xo;

    sub initialize {
        my ($self) = shift;
        my ($identifier) = @_;

        $identifier{$self->$id} = $identifier;
    }

    sub sql {
        my ($self) = shift;
        my ($identifier) = $identifier{$self->$id};

        if ($identifier =~ $nq) {
            $identifier;
        }
        else {
            '"' . ($identifier =~ s/\"/\"\"/gr) . '"';
        }
    }

    sub name {
    }
}

'Identifier.pm - MIT Licensed by Stephen Belcher, 2012. See LICENSE'
