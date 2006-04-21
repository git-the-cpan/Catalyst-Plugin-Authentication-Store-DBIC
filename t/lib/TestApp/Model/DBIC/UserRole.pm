package TestApp::Model::DBIC::UserRole;

eval { require DBIx::Class }; return 1 if $@;
@ISA = qw/TestApp::Model::DBIC/;
use strict;

__PACKAGE__->table( 'user_role' );
__PACKAGE__->add_columns( qw/id user role/ );
__PACKAGE__->set_primary_key( qw/id/ );

1;
