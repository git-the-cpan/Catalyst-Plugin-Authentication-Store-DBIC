package TestApp::Model::Role;

use strict;
use warnings;
use base 'TestApp::Model::DBIC';

__PACKAGE__->table( 'role' );
__PACKAGE__->add_columns( qw/id role/ );    
__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(
    map_user_role => 'TestApp::Model::UserRole' => 'role' );

1;
