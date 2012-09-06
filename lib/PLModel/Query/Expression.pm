use v5.14;
use warnings;

package PLModel::Query::Expression {
    sub new {
        my ($package) = shift;
        my ($class)   = ref($package) || $package;
        my ($self)    = bless(\(my $o), $package);

        $self->initialize(@_);

        $self;
    }
}

'Expression.pm - MIT Licensed by Stephen Belcher. See LICENSE'
