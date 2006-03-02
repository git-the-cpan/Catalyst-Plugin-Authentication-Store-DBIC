package TestApp::Model::DBIC::Role;

eval { require DBIx::Class }; return 1 if $@;
@ISA = qw/TestApp::Model::DBIC/;
use strict;

__PACKAGE__->table( 'role' );
__PACKAGE__->add_columns( qw/id role/ );    
__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(
    map_user_role => 'TestApp::Model::DBIC::UserRole' => 'role' );

1;
