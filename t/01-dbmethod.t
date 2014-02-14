package PGOTest;
use PGObject::Util::DBMethod;

sub call_dbmethod {
    my $self = shift @_;
    %args = @_;
    my @retarray = (\%args);
    return @retarray;
}

sub new {
    my ($self) = shift @_;
    my %args = @_;
    $self = \%args if %args;
    $self ||= {};
    bless $self;
}

dbmethod(strictargtest => 
    strict_args => 1,
    funcname => 'foo',
    funcschema => 'foo2',
    args => {id => 1}
);

dbmethod nostrictargtest => (
    funcname => 'foo',
    funcschema => 'foo2',
    args => {id => 1}
);

dbmethod objectstest => (
    returns_objects => 1,
    funcname => 'foo',
    funcschema => 'foo2',
    args => {id => 1}
);

package main;
use Test::More tests => 17;

ok(my $test = PGOTest::new({}), 'Test object constructor success');

ok(my ($ref) = $test->strictargtest(args => {id => 2, foo => 1}), 
     'Strict Arg Test returned results.');

is($ref->{funcname}, 'foo', 'strict arg test, funcname correctly set');
is($ref->{funcschema}, 'foo2', 'strict arg test, funcschema correctly set');
is($ref->{args}->{id}, 1, 'strict arg test, id arg correctly set');
is($ref->{args}->{foo}, 1, 'strict arg test, foo arg correctly set');

ok(($ref) = $test->nostrictargtest(args => {id => 2, foo => 1}), 
     'No Strict Arg Test returned results.');

is($ref->{funcname}, 'foo', 'no strict arg test, funcname correctly set');
is($ref->{funcschema}, 'foo2', 'no strict arg test, funcschema correctly set');
is($ref->{args}->{id}, 2, 'no strict arg test, id arg correctly set');
is($ref->{args}->{foo}, 1, 'no strict arg test, foo arg correctly set');

ok(($ref) = $test->objectstest(args => {id => 2, foo => 1}), 
     'Objects Test returned results.');

is($ref->{funcname}, 'foo', 'no strict arg test, funcname correctly set');
is($ref->{funcschema}, 'foo2', 'no strict arg test, funcschema correctly set');
is($ref->{args}->{id}, 2, 'no strict arg test, id arg correctly set');
is($ref->{args}->{foo}, 1, 'no strict arg test, foo arg correctly set');
isa_ok($ref, 'PGOTest', 'Return reference is blessed');
