package AutoCode::Schema;
use strict;
use vars qw(@ISA);
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
our %PLURALS;
use AutoCode::ModuleModel;

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    $self->_add_scalar_accessor('modules', __PACKAGE__);
    $self->_add_scalar_accessor('package_prefix');
    
    my ($modules, $package_prefix, $plurals)=
        $self->_rearrange(
            [qw(MODULES PACKAGE_PREFIX PLURALS)], @args);
    
    (ref($modules) eq 'HASH') and $self->modules($modules);
    $self->package_prefix($package_prefix);
    if(defined $plurals){
        if(ref($plurals) eq 'HASH'){
            # not directly assign to the package variable, avoiding overwrite
            $PLURALS{$_}=$plurals->{$_} foreach keys %$plurals;
        }else{
            $self->throw("plurals must be a hash reference");
        }
    } # else{ %PLURALS=();} wrongly to initialize the package variable.

}

# Only be invoked by ModuleModel.
# 
sub _get_module_definition {
    my ($self, $type)=@_;
    $self->_check_type($type);
    return $self->modules->{$type};
}

sub get_all_types {
    my $self=shift;
    return grep !/^\W/, keys %{$self->modules};
}

sub get_friends {
    return @{shift->modules->{'~friends'}};
}

sub dependence {
    my $self=shift;
    my %dependance=();
    my %modules=%{$self->modules};
    my @types = keys %modules;
    foreach my $type(@types){
        my $module = $self->get_module_model($type);
        foreach my $tag ($module->get_all_value_attributes){
            my ($context, $kind, $content, $required) =
                $module->_classify_value_attribute($tag);
            if($kind eq 'M'){
                $dependance{$type} = {} unless exists $dependance{$type};
                $dependance{$type}->{$content} = [$context, $tag];
            }
        }
    }

    return %dependance;
}

sub has_a {
    my ($self, $type)=@_;
    my %dependence = $self->dependence;
    return ${$dependence{$type}};
}

sub fks {
    my ($self)=@_;
    my %has_a=$self->dependence;
    my %fks;
    foreach my $type(keys %has_a){
        my %type=%{$has_a{$type}};
        foreach(keys %type){
            $fks{$_}={} unless exists $fks{$_};
            $fks{$_}->{$type}=$type{$_};
        }
    }
    return %fks;
}

our %MODULE_MODELS;
sub get_module_model {
    my ($self, $type)=@_;
    return $MODULE_MODELS{$type} if exists $MODULE_MODELS{$type};
    my $model=AutoCode::ModuleModel->new(
        -schema => $self,
        -type => $type
    );
    $MODULE_MODELS{$type} = $model;
    return $model;
}

sub _check_type {
    my ($self, $type)=@_;
    $self->throw("[$type] does not exist in the schema")
        unless exists $self->modules->{$type};
}

sub get_plural {
    my ($self, $singular)=@_;
    return (exists $PLURALS{$singular})?$PLURALS{$singular}:"${singular}s";
}
1;
