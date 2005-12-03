package TestApp::Model::UserRole;

use strict;
use warnings;
use base 'TestApp::Model::DBIC';

__PACKAGE__->table( 'user_role' );
__PACKAGE__->add_columns( qw/user role/ );                                 
__PACKAGE__->set_primary_key( qw/user role/ );

1;
