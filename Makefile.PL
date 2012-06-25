use v5.14;
use warnings;
use ExtUtils::MakeMaker;

my (%drivers);
if ($ENV{DBDRIVER}) {
    my (@drivers) = split(/:/, $ENV{DBDRIVER});
    foreach my $driver (@drivers) {
        $drivers{'DBD::Pg'} = 0 if ($driver =~ /^(postgres(?:ql)|pg)?$/io);
    }

    foreach my $driver (keys %drivers) {
        say "Detected dependency $driver";
    }
}

WriteMakefile(
    ABSTRACT         => 'Yet Another ORM Interface',
    AUTHOR           => [
        'Stephen Belcher <sbelcher@gmail.com>',
    ],
    NAME             => 'PLModel',
    MIN_PERL_VERSION => '5.14.2',
    PREREQ_PM        => {
        'DBI' => 0,
        %drivers,
    },
    VERSION          => '0.1',
);
