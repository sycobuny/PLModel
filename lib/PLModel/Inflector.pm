use v5.14;
use warnings;

package PLModel::Inflector {
    my (%camelized, %decamelized, %uncountable, %irregular, @suffixes);

    foreach my $ucount (qw(
        cod deer fish offspring sheep trout barracks crossroads gallows
        headquarters means series species equipment fuzz jazz razzmatazz
    )) {
        $uncountable{$ucount} = 1;
    }

    %irregular = (
        # typically foreign loan words, Old English, or other just plain weird
        # stuff in English
        words => {
            # weird English stuff
            qw(
                child            children
                ox               oxen
                corpus           corpora
                genus            genera
                buzz             buzzes
            ),

            # Italian loan words
            qw(
                libretto         libretti
                tempo            tempi
                virtuoso         virtuosi
            ),

            # Hebrew loan words
            qw(
                cherub           cherubim
                seraph           seraphim
            ),

            # Greek loan words
            qw(
                schema           schemata
            ),

            # this is a special case. typically /(ix|ex)$/ => "$1es" in English,
            # but in the originating language it's supposed to be "ices". Since
            # this is the only one that remains, we treat it as a special case.
            qw(vortex vortices),
        },

        # any weird suffixes, "doormouse" => "doormice", etc
        suffixes => {
            qw(
                man              men
                person           people
                foot             feet
                goose            geese
                louse            lice
                mouse            mice
                tooth            teeth
            )
        },
    );

    # trade memory for speed by caching the reverse lookups of irregular plurals
    foreach my $type (keys %irregular) {
        my ($hash) = ($irregular{"R$type"} = {});
        my ($plural);
        foreach my $singular (keys %{ $irregular{$type} }) {
            $plural = $irregular{$type}{$singular};
            $hash->{$plural} = $singular;
        }
    }

    @suffixes = (
        ['f', 'ves',  [qw(cal el hal hoo lea loa scar sel shea shel thie wol)]],
        ['fe', 'ves', [qw(kni li wi)]],
        ['o', 'oes',  [qw(ech embarg her potat tomat torped vet)]],
        ['a', 'ae',   [qw(alg larv nebul vertebr)]],
        ['us', 'i',   [qw(alumn bacill foc nucle radi stimul termin)]],
        ['um', 'a',   [qw(addend bacteri dat errat medi ov strat)]],
        ['is', 'es',  [qw(
            analys ax bas cris diagnos emphas hypothes neuros oas parenthes
            synops thes
        )]],
    );

    sub camelize {
        my ($string) = @_;
        return $camelized{$string} if $camelized{$string};

        local ($_, $1, $2);
        my ($out);
        $out = join('', map { s/^(.)(.*)$/uc($1).$2/oer } split(/_/, $string));

        if ($decamelized{$out}) {
            die "Already have cached (de)camelized $string($out) as " .
                "$decamelized{$out}!";
        }

        $camelized{$string} = $out;
        $decamelized{$out}  = $string;

        return $out;
    }

    sub decamelize {
        my ($string) = @_;
        return $decamelized{$string} if $decamelized{$string};

        my ($up, $out, $char, @chars) = (1, '', '', split(//, $string));
        for (my ($x) = 0; $x <= $#chars; $x++) {
            $char = $chars[$x];

            if (!$out) {
                $out = lc($char);
            }
            elsif ($char =~ /[a-z]/) {
                $out .= $char;
                $up   = 0;
            }
            elsif ($char =~ /[A-Z]/) {
                if ((!$up) || (($#chars >= $x) && ($chars[$x+1] =~ /[a-z]/))) {
                    $out .= '_';
                }

                $out .= lc($char);
                $up   = 1;
            }
            elsif ($char =~ /\s/) {
                $out .= '_';
            }
        }

        if ($camelized{$out}) {
            die "Already have cached camelized $string($out) as " .
                "$camelized{$out}!";
        }

        $decamelized{$string} = $out;
        $camelized{$out}      = $string;

        return $out;
    }

    my ($_suf) = sub {
        local ($1);
        my ($string, $stem, $row, $singular) = @_;
        my ($sing, $plur, $words) = @$row;

        foreach my $word (@$words) {
            if ($stem =~ /$word$/) {
                my ($s, $r) = $singular ? ($sing, $plur) : ($plur, $sing);
                return $string =~ s/(.*$stem)$s$/$1$r/r;
            }
        }

        return undef;
    };

    sub pluralize {
        local ($1, $2);
        my ($string) = @_;
        my ($lead, $word) = $string =~ /(^|.*_)([^_]+)$/;

        # might be something we can't pluralize?
        return $string if $uncountable{$word};

        # might be an irregular word?
        return ($lead . $irregular{words}{$word}) if $irregular{words}{$word};

        # might be an irregular suffix?
        foreach my $suffix (keys %{ $irregular{suffixes} }) {
            my ($sing, $plur) = ($suffix, $irregular{suffixes}{$suffix});
            return ($string =~ s/(.*)$sing$/$1$plur/r) if $word =~ /$suffix$/;
        }

        # might be a rule-based irregular word?
        my ($sing);
        foreach my $suf (@suffixes) {
            $sing = $suf->[0];
            if ($string =~ /(^|.*_)([^_]+)$sing$/) {
                my ($out) = $_suf->($string, $2, $suf, 1);
                return $out if $out;

                last; # won't wind up matching any of the others anyway.
            }
        }

        # just use standard crazy English rules from here on out

        # ends in y, maybe preceded by a vowel
        if ($string =~ /(.*?)([aeiou]?)y$/) {
            return ($string . 's') if $2; # just add s if preceded by a vowel
            return $1 . 'ies';            # otherwise y => ies
        }

        # ends in a z prefixed by a vowel
        if ($string =~ /(.*?[aeiou])z$/) {
            return $1 . 'zzes';
        }

        # ends in an "s"-like sound
        if ($string =~ /(.*)(s|ch|x)$/) {
            return $1 . $2 . 'es';
        }

        # give up, throw an s on it and call it done.
        return $string . 's';
    }

    sub singularize {
        local ($1, $2);
        my ($string) = @_;
        my ($lead, $word) = $string =~ /(^|.*_)([^_]+)$/;

        # might be something we can't singularize?
        return $string if $uncountable{$word};

        # might be an irregular word?
        if ($irregular{Rwords}{$word}) {
            return $lead . $irregular{Rwords}{$word};
        }

        # might be an irregular suffix?
        foreach my $suffix (keys %{ $irregular{Rsuffixes} }) {
            my ($plur, $sing) = ($suffix, $irregular{Rsuffixes}{$suffix});
            return ($string =~ s/(.*)$plur$/$1$sing/r) if $word =~ /$suffix$/;
        }

        # might be a reule-based irregular word?
        my ($plur);
        foreach my $suf (@suffixes) {
            $plur = $suf->[1];
            if ($string =~ /(^|.*_)([^_]+)$plur$/) {
                my ($out) = $_suf->($string, $2, $suf, 0);
                return $out if $out;

                # we won't skip the rest of the loop as pluralize() does as
                # there *are* ambiguous situations in this one.
            }
        }

        # just use standard crazy English rules from here on out

        # ends in ies, probably switch to a y
        if ($string =~ /(.*)ies$/) {
            return $1 . 'y';
        }

        # ends in zzes preceded by a value, switch out for just a z
        if ($string =~ /(.*[aeiou]z)zes$/) {
            return $1;
        }

        # ends in a "s"-like sound followed by "es", so chop of the "es"
        if ($string =~ /(.*)(s|ch|x)es$/) {
            return $1 . $2;
        }

        # last resort: ends in an s, so chop that off
        if ($string =~ /(.*)s$/) {
            return $1;
        }

        # no really, what? this is probably wrong.
        warn("Could not properly singularize $string, consider adding it as " .
             "an uncountable value with PLModel::Inflector::add_uncountable()");
        return $string;
    }
}

'Inflector.pm - MIT Licensed by Stephen Belcher, 2012. See LICENSE'

__END__
__MARKDOWN__

PLModel::Inflector
==================

Summary
-------

Easily convert between class names, table names, field names, or whatever other
standard language/coding mismatches are available.

Example
-------

    use PLModel::Inflector;

    my ($class_name) = 'SomeClass';
    my ($table_name) = PLModel::Inflector::pluralize(
                           PLModel::Inflector::decamelize($class_name)
                       );
    # => 'some_classes'

    my ($field) = 'id';
    my ($foreign) = PLModel::Inflector::singularize($table_name) . "_$field";
    # => 'some_class_id'

    my ($other_table) = 'some_tables';
    my ($other_class) = PLModel::Inflector::camelize(
                            PLModel::Inflector::singularize($other_table)
                        );
    # => 'SomeTable'

Functions
-------

### camelize(string) - returns string

Convert a name with underscores to a name with capitals. This caches the result
of that operation, so that calls to `decamelize()` will return a consistently
inverse result, regardless of the different rules governing the two methods.

Note this means that, for calling the following functions, the initial order
matters:

    PLModel::Inflector::camelize('abc_string');  # => 'AbcString'
    PLModel::Inflector::decamelize('ABCString'); # throws an error

When an existing cached result conflicts with a newly-calculated result, an
error is thrown.

### decamelize(string) - returns string

Convert a name with capitals, such as a package/class name, to a name with
underscores. This caches the result of that operation, so that calls to
`camelize()` will return a consistently inverse result, regardless of the
different rules governing the two methods.

Note this means that, for calling the following functions, the initial order
matters:

    PLModel::Inflector::decamelize('ABCString');  => 'abc_string'
    PLModel::Inflector::camelize('abc_string');   => 'ABCString'

### pluralize(string) - returns string

Convert a single word, optionally with multiple prefixed words separated by
underscores, into a pluralized form. This method tries its best to make sense
out of the English language, but there's always room for improvement. If a given
word does not pluralize correctly, feel free to [submit a patch][plmodel].

### singularize(string) - returns string

Convert a single word, optionally with multiple prefixed words separated by
underscores, into a singularized form. This method tries its best to make sense
out of the English language, but there's always room for improvement. If, in the
odd case that it gets to the end of the function and can't simply subtract an
's' from the string, it *will* issue a warning, but not throw an error. If a
given word does not singularize correctly for this or any other reason, feel
free to [submit a patch][plmodel].

License
-------

MIT Licensed. See the LICENSE file in the PLModel directory for the full license.

Authors
-------

* Stephen Belcher <sbelcher@gmail.com>

[plmodel]: https://github.com/sycobuny/pl_model "PLModel: Simple Perl DB Access"
