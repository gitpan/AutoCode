package AutoCode::ModuleFactory;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
use AutoCode::ModuleModel;

sub _initialize {
    my ($self, @args)=@_;

    $self->_add_scalar_accessor('schema');
    $self->_add_scalar_accessor('package_prefix');
    my ($schema, $package_prefix)=
        $self->_rearrange([qw(SCHEMA PACKAGE_PREFIX)], @args);
    defined $schema or $self->throw("NO Schema set");
    $self->schema($schema);
    $package_prefix ||= $schema->package_prefix;
    $package_prefix ||= 'AutoCode';
    $self->package_prefix($package_prefix);
}

*make_virtual_module = \&make_module;

sub make_module {
    my ($self, $type, $isa) =@_;
    ## this is added due to AutoSQL::ModuleFactory
    $isa='AutoCode::Root' unless defined $isa; 
    my $schema=$self->schema;
    my $package_prefix=$self->package_prefix;
    my $vp = $self->_get_virtual_package($type);
    
    my $model = $schema->get_module_model($type);
    # generate its parents modules if any.
    my @isa=$model->get_isas($type);
    if(@isa){
        no strict 'refs';
        foreach(@isa){
            push @{"$vp\::ISA"}, $self->make_virtual_module($_);
        }   
    }

    # virtual package is with the consideration of schema name and type.    
    my $vp = $self->_get_virtual_package($type);
    no strict 'refs';                                         
    push @{"$vp\::ISA"}, $isa unless @{"$vp\::ISA"};                     
#    $self->_add_scalar_accessor(@scalar_accessors);           
    $self->debug("making $type in $vp");
    
#    map {*{"$vp\::$_"} = \&{__PACKAGE__."::$_"}} @scalar_accessors;         
    map {$self->_add_scalar_accessor($_, $vp);} $model->get_scalar_attributes;
    map {$self->_add_array_accessor([$_, $schema->get_plural($_)], $vp);} 
        $model->get_array_attributes;
    $self->_make_initialize($type);
    return $vp;
}


sub _make_initialize {
    my ($self, $type)=@_;
    my $schema = $self->schema;
    my $package_prefix=$self->package_prefix;
    my $model = $self->schema->get_module_model($type);
    my @scalar_attrs = $model->get_scalar_attributes;
    my @array_attrs  = $model->get_array_attributes;
    my @array_attrs_plural= map {$schema->get_plural($_)} @array_attrs;
    my $vp = $self->_get_virtual_package($type);
    my $source = 'sub { my($dummy, @args)=@_;'."\n";
# The line below is for debug. It will run only when the made module is working
#    $source .= "print 'I am in _init of '. ref(\$dummy) . '_____';";
    
#    $source .= "\$dummy->SUPER::_initialize(\@args);\n";
    if(@scalar_attrs || @array_attrs){
        $source .= 'my ('. join ',',  map{"\$$_"} @scalar_attrs;
        $source .= ', '. join ',', map{"\$$_"} @array_attrs_plural;
        $source .= ')='."\n".'$dummy->_rearrange([qw(';
        $source .= join ' ', @scalar_attrs;
        $source .= ' '. join ' ', @array_attrs_plural;
        $source .= ')], @args);'."\n";
        map {$source .= 
            "defined \$$_ and \$dummy->$_(\$$_);\n"} @scalar_attrs;

    # if the array ref is defined, assign the dereferenced into array, 
    # otherwise initialize the array by invoking remove_$plural
        map {my ($singular, $plural)=($_, $schema->get_plural($_));
            $source .= <<END_OF_ARRAY_ACCESSORS;
if(ref(\$$plural) eq'ARRAY'){
    \$dummy->add_$singular(\$_) foreach (\@{\$$plural});
}else{
    \$dummy->remove_$plural;
}
END_OF_ARRAY_ACCESSORS
        }@array_attrs;
    }
# The following 3 lines are to replace 'the not-working USPER with eval'
# It spends almost a whole afternoon of the second day of 2004.
    $source .= "no strict 'refs';\n";
    $source .= 'my $super=AutoCode::Root::_find_super("'. $vp .'", "_initialize");'."\n";
    $source .= '&{$super. "::_initialize"}($dummy, @args);'."\n";

#    $source .= "\$dummy->SUPER::_initialize(\@args);\n";
#    $source .= "print '______' \. *{\$dummy->SUPER::_initialize} \. \"\\n\"";
    $source .= '};'."\n";
    $self->debug("$source");
#    print "$source\n";
    no strict 'refs';
    $_ = $source;
    *{"$vp\::_initialize"} = eval $source;
    $self->throw( "Error when eval'ing _initialize\n$@") if($@);
}

sub _get_virtual_package {
    my ($self, $type)=@_;
    my $package_prefix=$self->package_prefix;
    return "$package_prefix\::Virtual::$type"; # 'virtual package'
}

1;
