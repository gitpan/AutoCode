use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests=> 4;}

my ($first_name, $last_name)=qw(foo bar);

my $dbid=1234567;
use AutoCode::ModuleLoader 'ContactSchema', 'MyContact';


ok(1);

my $vp = AutoCode::ModuleLoader->load('Person');
my $instance = $vp->new(
    -first_name => $first_name,
    -last_name => $last_name,
    -emails => [qw(foo@bar.com bar@foo.com)],
    -dbid => $dbid
);

ok($instance->first_name, $first_name);
ok($instance->last_name, $last_name);
ok($instance->dbid, $dbid);


