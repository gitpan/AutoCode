package AutoCode::Root;
use strict;
use AutoCode::Root0;
our @ISA=qw(AutoCode::Root0);
our $VERSION='0.01';
our $DEBUG;
# our $debug;
use AutoCode::SymbolTableUtils;
our $accessor_maker;
use AutoCode::AccessorMaker;
BEGIN{
    $accessor_maker = AutoCode::AccessorMaker->new;
}

sub _add_scalar_accessor {
    my ($self, $accessor, $pkg)=@_;
    $pkg ||= ref(caller) || caller;
    $accessor_maker->make_scalar_accessor($accessor, $pkg);
}

sub _add_array_accessor {
    my ($self, $accessor, $pkg)=@_;
    $pkg ||= ref(caller) || caller;
    $accessor_maker->make_array_accessor($accessor, $pkg);
}

sub _find_super {
    my ($dummy, $method)=@_;
    my $ref=ref($dummy) || $dummy;
    no strict 'refs';

    foreach(@{"$ref\::ISA"}){
        next if $_ eq 'UNIVERSAL';
        return $_ if defined &{"$_\::$method"};
        my $super = _find_super($_, $method);
        return $super if defined $super;
    }
    return undef;
}

1;
