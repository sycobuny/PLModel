use v5.14;
use warnings;

use PLModel::Inflector;

# test conditions for pluralize()
my (@test_plur);

# test conditions for singularize()
my (@test_sing);

# count of tests so we can add a test and it's automatically counted for plans
my ($tests);

# set up test conditions
BEGIN {
    # non-iterated tests
    $tests = 16;

    @test_plur = (
        # [singular, plural, test name]
        ['equipment',   'equipment',    'uncountable'],
        ['mouse',       'mice',         'irregular - suffix as word'],
        ['doormouse',   'doormice',     'irregular - suffix as suffix'],
        ['ox',          'oxen',         'irregular'],
        ['vortex',      'vortices',     'irregular - ix/ex'],
        ['calf',        'calves',       'irregular - f  => ves'],
        ['knife',       'knives',       'irregular - fe => ves'],
        ['echo',        'echoes',       'irregular - o  => oes'],
        ['larva',       'larvae',       'irregular - a  => ae'],
        ['alumnus',     'alumni',       'irregular - us => i'],
        ['addendum',    'addenda',      'irregular - um => a'],
        ['analysis',    'analyses',     'irregular - is => es'],
        ['some_person', 'some_people',  'separates words'],
        ['solliloquy',  'solliloquys',  'regular - ends in [vowel]y'],
        ['symphony',    'symphonies',   'regular - ends in [consonant]y'],
        ['quiz',        'quizzes',      'regular - ends in [vowel]z'],
        ['church',      'churches',     'regular - ends in s-like sound'],
        ['cow',         'cows',         'regular'],
    );

    # up the count of tests by the length of the pluralize() tests list.
    $tests += scalar(@test_plur);

    @test_sing = (
        # [plural, singular, test name]
        ['fish',        'fish',       'uncountable'],
        ['lice',        'louse',      'irregular - suffix as word'],
        ['barklice',    'barklouse',  'irregular - suffix as suffix'],
        ['children',    'child',      'irregular'],
        ['vortices',    'vortex',     'irregular - ix/ex'],
        ['wolves',      'wolf',       'irregular - ves => f'],
        ['wives',       'wife',       'irregular - ves => fe'],
        ['vertebrae',   'vertebra',   'irregular - ae  => a'],
        ['nuclei',      'nucleus',    'irregular - i   => us'],
        ['errata',      'erratum',    'irregular - um  => a'],
        ['hypotheses',  'hypothesis', 'irregular - es  => is'],
        ['back_teeth',  'back_tooth', 'separates words'],
        ['solliloquys', 'solliloquy', 'regular - ends in [vowel]y'],
        ['harmonies',   'harmony',    'regular - ends in [cosonant]ies'],
        ['boxes',       'box',        'regular - ends in s-like sound'],
        ['slips',       'slip',       'regular'],
    );

    # up the count of tests by the length of the pluralize() tests list.
    $tests += scalar(@test_sing);
}

# require tests with a dynamic count of tests
use Test::More tests => $tests;

# test the pluralize() method
my ($maxlen);
{
    local ($a, $b);
    $maxlen = length((sort {
         length($b->[0]) <=> length($a->[0])
    } @test_plur)[0][0]);
}
foreach my $t (@test_plur) {
    my ($s, $p, $n) = @$t;
    my ($sp) = $maxlen - length($s);
    my ($nm)   = sprintf('pluralize("%s")%' . $sp . 's - %s', $s, '', $n);

    is PLModel::Inflector::pluralize($s), $p, $nm;
}

# test the singularize() method
{
    local ($a, $b);
    $maxlen = length((sort {
        length($b->[0]) <=> length($a->[0]) 
    } @test_sing)[0][0]);
}
foreach my $t (@test_sing) {
    my ($p, $s, $n) = @$t;
    my ($sp) = $maxlen - length($p);
    my ($nm)   = sprintf('singularize("%s")%' . $sp . 's - %s', $p, '', $n);

    is PLModel::Inflector::singularize($p), $s, $nm;
}

# test the camelize() method
is PLModel::Inflector::camelize('test_camelize'), 'TestCamelize',
   'camelize("test_camelize") - upper-cases a standard string';

{
    local ($@);
    eval { PLModel::Inflector::camelize('Test_camelize') };
    like $@, qr/^Already have cached .* as test_camelize!/,
         'camelize("Test_camelize") - throws error with multiple results';
}

# test the decamelize() method
is PLModel::Inflector::decamelize('TestDeCamelize'), 'test_de_camelize',
   'decamelize("TestDeCamelize")    - lower-cases a standard string';

is PLModel::Inflector::decamelize('TestABDeCamelize'), 'test_ab_de_camelize',
   'decamelize("TestABDeCamelize")  - lower-cases an abbreviated string';

is PLModel::Inflector::camelize('test_ab_de_camelize'), 'TestABDeCamelize',
   'camelize("test_ab_de_camelize") - caches reverse of abbreviated strings';

{
    local ($@);
    eval { PLModel::Inflector::decamelize('TestAbDeCamelize') };
    like $@, qr/^Already have cached .* as TestABDeCamelize!/,
         'demamelize("TestAbDeCamelize")  - throws error with multiple results';
}

# test the add_uncountable() method
{
    local ($@);
    eval { PLModel::Inflector::singularize('quoiriflorrble') };
    like $@, qr/^Could not properly singularize/,
         "add_uncountable() - Non-existent words can't be singularized";
}

PLModel::Inflector::add_uncountable('quoiriflorrble');
is PLModel::Inflector::pluralize('quoiriflorrble'), 'quoiriflorrble',
   'add_uncountable("quoiriflorrble") - Check 1/2';
is PLModel::Inflector::singularize('quoiriflorrble'), 'quoiriflorrble',
   'add_uncountable("quoiriflorrble") - Check 2/2';

# test the add_irregular() method
is PLModel::Inflector::pluralize('sashankanoys'), 'sashankanoyses',
   'add_irregular() - Non-existent words pluralize as normal';
is PLModel::Inflector::singularize('sashankanoyses'), 'sashankanoys',
   'add_irregular() - Non-existnet words singularize as normal';

PLModel::Inflector::add_irregular('sashankanoys', 'qwapalavee');
is PLModel::Inflector::pluralize('sashankanoys'), 'qwapalavee',
   'add_irregular("sashankanoys", "qwapalavee") - Check 1/5';
is PLModel::Inflector::singularize('qwapalavee'), 'sashankanoys',
   'add_irregular("sashankanoys", "qwapalavee") - Check 2/5';
is PLModel::Inflector::pluralize('asashankanoys'), 'asashankanoyses',
   'add_irregular("sashankanoys", "qwapalavee") - Check 3/5';
is PLModel::Inflector::pluralize('a_sashankanoys'), 'a_qwapalavee',
   'add_irregular("sashankanoys", "qwapalavee") - Check 4/5';
is PLModel::Inflector::singularize('a_qwapalavee'), 'a_sashankanoys',
   'add_irregular("sashankanoys", "qwapalavee") - Check 5/5';

# inflections.t - MIT Licensed by Stephen Belcher, 2012. See LICENSE
