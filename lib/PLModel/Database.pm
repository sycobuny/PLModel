use v5.14;
use warnings;

package PLModel::Database {
    use DBI;

    my ($connection);
    my ($csub);

    $csub = sub {
        unless ($connection) {
            $connection = DBI->connect('dbi:Pg:', '', '', {AutoCommit => 0});
        }

        unless ($connection->{Active}) {
            $connection = DBI->connect('dbi:Pg:', '', '', {AutoCommit => 0});
        }

        return $connection;
    };

    sub columns {
        my ($table) = @_;
        my ($sth) = $csub->()->column_info(undef, undef, $table, undef);
        my ($row, $ret);

        $ret = {};
        while ($row = $sth->fetchrow_hashref) {
            $ret->{$row->{pg_column}} = $row;
        }

        return $ret;
    }

    sub run {
        my ($query, $parameters) = @_;
        my ($sth) = $csub->()->prepare($query);

        $parameters ||= [];
        $sth->execute(@$parameters);

        return;
    }

    sub iterate {
        my ($query, $parameters, $callback) = @_;
        my ($sth) = $csub->()->prepare($query);

        $parameters ||= [];
        $sth->execute(@$parameters);

        if (ref($callback) =~ /CODE/o) {
            my ($row);
            while ($row = $sth->fetchrow_hashref) {
                $callback->($row);
            }
        }
    }
}

'Database.pm - MIT Licensed by Stephen Belcher, 2012. See LICENSE'

__END__
__MARKDOWN__
