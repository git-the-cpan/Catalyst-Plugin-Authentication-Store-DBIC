package TestApp::Model::User;

use strict;
use warnings;
use base 'TestApp::Model::DBIC';

__PACKAGE__->table( 'user' );
__PACKAGE__->add_columns( qw/id username password/ );
__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(
    map_user_role => 'TestApp::Model::UserRole' => 'user' ); 

1;
