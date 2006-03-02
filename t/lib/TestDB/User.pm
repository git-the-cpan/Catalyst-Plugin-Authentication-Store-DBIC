package TestDB::User;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table( 'user' );
__PACKAGE__->add_columns( qw/id username password/ );
__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(
    map_user_role => 'TestDB::UserRole' => 'user' ); 

1;
