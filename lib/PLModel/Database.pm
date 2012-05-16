use v5.14;
use warnings;

package PLModel::Database {
    use DBI;

    my ($connection);
    my ($csub);
    my (%configuration) = (
        adapter  => 'postgres',
    );

    $csub = sub {
        my ($un) = ($configuration{username} || '');
        my ($pw) = ($configuration{password} || '');
        my ($dsn, %dsn);

        if ($configuration{adapter} eq 'postgres') {
            $dsn = 'dbi:Pg:';

            if ($configuration{hostname} || $configuration{host}) {
                $dsn{host} = $configuration{hostname} || $configuration{host};
            }
            if ($configuration{database} || $configuration{db} ||
                $configuration{dbname}) {
                $dsn{db} = $configuration{database} || $configuration{db} ||
                           $configuration{dbname};
            }
            if ($configuration{port}) {
                $dsn{port} = $configuration{port};
            }

            $dsn .= join(';', map { $_ . '=' . $dsn{$_} } keys(%dsn));
        }

        unless ($connection && $connection->{Active}) {
            $connection = DBI->connect($dsn, $un, $pw, {AutoCommit => 0});
        }

        return $connection;
    };

    sub configure {
        my (%options) = (%configuration, @_);

        unless ($options{adapter} eq 'postgres') {
            die "Currently only the 'postgres' adapter is supported.";
        }

        %configuration = %options;
    }

    sub import {
        my ($package, %options) = @_;
        configure(%options);
    }

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

    sub primary_keys {
        my ($table) = @_;
        return [ $csub->()->primary_key(undef, undef, $table) ];
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
