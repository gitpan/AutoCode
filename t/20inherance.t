use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests=> 4; }
my ($first_name, $last_name)=qw(foo bar);
my $dbid=12234;

use AutoCode::ModuleLoader 'ContactSchema';

my $vp=AutoCode::ModuleLoader->load('DBObject');
print "$vp\n";
my $dbo=$vp->new(
    -dbid => $dbid
);
ok $dbo->dbid, $dbid;

my $o_vp =$vp;
$vp=AutoCode::ModuleLoader->load('Person');
ok $vp, 'AutoCode::Virtual::Person';

print "$vp\n";
my $dbo=$vp->new(
    -first_name => $first_name,
    -dbid => $dbid
);

# print UNIVERSAL::can($vp, 'dbid'), "\n";
ok $dbo->dbid, $dbid;
ok $dbo->first_name, $first_name;
no strict 'refs';
#print join('|', @{"$vp\::ISA"}) ."\n";
#print UNIVERSAL::isa($vp, $o_vp) ."\n";
