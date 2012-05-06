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

    # these are irregular endings and the various word stems they're tied to.
    # they're much like the irregular suffixes earlier, but they follow their
    # own internal logic.
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

        # we're good stewards of our global variables :)
        local ($_, $1, $2);

        # split on '_' and upper case the first letter of each element
        my ($out);
        $out = join('', map { s/^(.)(.*)$/uc($1).$2/oer } split(/_/, $string));

        # this means someone decamelized something that conflicts with what we
        # just got back. this probably means they're going to wind up with
        # namespace conflicts, so make a big racket about it.
        if ($decamelized{$out}) {
            die "Already have cached (de)camelized $string($out) as " .
                "$decamelized{$out}!";
        }

        # cache the results so we can quickly look them up later (also so we
        # can raise errors in decamelize()).
        $camelized{$string} = $out;
        $decamelized{$out}  = $string;

        return $out;
    }

    sub decamelize {
        my ($string) = @_;
        return $decamelized{$string} if $decamelized{$string};

        my ($up, $out, $char, @chars) = (1, '', '', split(//, $string));

        # do this as an old-school for loop cause the position we're at matters
        for (my ($x) = 0; $x <= $#chars; $x++) {
            $char = $chars[$x];

            # first character - always lowercase this
            if (!$out) {
                $out = lc($char);
            }

            # we're on a lowercase letter. just add it, and make sure we know
            # that we aren't dealing with a word boundary
            elsif ($char =~ /[a-z]/) {
                $out .= $char;
                $up   = 0;
            }

            # we're on an uppercase letter
            elsif ($char =~ /[A-Z]/) {
                # if the last letter was lowercase and/or we're a) not at the
                # end of the string and b) the next letter isn't uppercase, then
                # add an underscore before continuing.
                if ((!$up) || (($#chars >= $x) && ($chars[$x+1] =~ /[a-z]/))) {
                    $out .= '_';
                }

                # downcase the char, add it, and mark we just did it.
                $out .= lc($char);
                $up   = 1;
            }

            # this probably shouldn't happen, but if we hit a whitespace,
            # replace it with an underscore.
            elsif ($char =~ /\s/) {
                $out .= '_';
            }
        }

        # this means someone camelized something that conflicts with what we
        # just got back. this probably means they're going to wind up with
        # namespace conflicts, so make a big racket about it.
        if ($camelized{$out}) {
            die "Already have cached camelized $string($out) as " .
                "$camelized{$out}!";
        }

        # cache the results so we can quickly look them up later (also so we
        # can raise errors in camelize()).
        $decamelized{$string} = $out;
        $camelized{$out}      = $string;

        return $out;
    }

    # we do very similar things in both pluralize() and singularize() to deal
    # with the @suffixes list, so it's abstracted here as a private closure
    my ($_suf) = sub {
        local ($1);
        my ($string, $stem, $row, $singular) = @_;
        my ($sing, $plur, $words) = @$row;

        # check each word to see if it matches
        foreach my $word (@$words) {
            # if the word stem is in this list, do the substitution
            if ($stem =~ /$word$/) {
                my ($s, $r) = $singular ? ($sing, $plur) : ($plur, $sing);
                return $string =~ s/(.*$stem)$s$/$1$r/r;
            }
        }

        # explicitly return undef to signify nothing matched.
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
        die("Could not properly singularize $string, consider adding it as " .
            "an uncountable value with PLModel::Inflector::add_uncountable()");
        return $string;
    }

    sub add_uncountable {
        my ($uncountable) = @_;
        $uncountable{$uncountable} = 1;
    }

    sub add_irregular {
        my ($singular, $plural) = @_;

        $irregular{words}{$singular} = $plural;
        $irregular{Rwords}{$plural}  = $singular;
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
---------

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
word does not pluralize correctly, feel free to [submit a patch][plmodel], or
(if it is specific to your project, use `add_uncountable()` or
`add_irregular()`).

### singularize(string) - returns string

Convert a single word, optionally with multiple prefixed words separated by
underscores, into a singularized form. This method tries its best to make sense
out of the English language, but there's always room for improvement. If, in the
odd case that it gets to the end of the function and can't simply subtract an
's' from the string, it will throw an error, which will cause the program to
exit unless caught. If a given word does not singularize correctly for this or
any other reason, feel free to [submit a patch][plmodel], or (if it is specific
to your project, use `add_uncountable()` or `add_irregular()`).

### add_uncountable(string)

Register a word as being uncountable. This function modifies the behavior of
`singularize()` and `pluralize()`, in case there is an instance where a given
word, be it a proper name, non-English word, or other, can not be pluralized.
The function has no valid return value.

### add_irregular(string, string)

* arg 1: the singular form
* arg 2: the plural form

Register a word as having an irregular pluralization. This function modifies the
behavior of `singularize()` and `pluralize()`, in case there is an instance
where a given word, be it a proper name, non-English word, or other, can not be
normally pluralized. The function has no valid return value. The registered word
behaves like the existing 'child' => 'children'. That is to say, it must be a
complete word separated by at least an underscore from anything before it, and
not a suffix, as 'man' => 'men' ('fireman' => 'firemen').

License
-------

MIT Licensed. See the LICENSE file in the PLModel directory for the full license.

Authors
-------

* Stephen Belcher <sbelcher@gmail.com>

[plmodel]: https://github.com/sycobuny/pl_model "PLModel: Simple Perl DB Access"
