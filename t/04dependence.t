use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests=> 4;}
use ContactSchema;

my $schema=ContactSchema->new;

my %dependence = $schema->dependence;

foreach my $type(keys %dependence){
    print "$type\n";
    ok $type, 'Person';
    my %type = %{$dependence{$type}};
    foreach (keys %type){
        print "\t$_\n";
        print "\t\t|". join("\t|", @{$type{$_}}) ."\n";
    }
    
}

ok exists $dependence{'Person'};

ok scalar keys %{$dependence{'Person'}}, 2;
ok ref $dependence{'Person'}->{'Email'}, 'ARRAY';
my %fks = $schema->fks;

foreach(keys %fks){
    print "$_\n";
    my %type = %{$fks{$_}};
    foreach(keys %type){
        print "\t$_\n";
        print "\t\t|". join("\t|", @{$type{$_}}) ."\n";

    }
}

