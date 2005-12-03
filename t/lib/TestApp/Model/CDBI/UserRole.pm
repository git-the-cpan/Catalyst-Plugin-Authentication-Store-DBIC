package TestApp::Model::CDBI::UserRole;

use strict;
use warnings;
use base 'TestApp::Model::CDBI::CDBI';

__PACKAGE__->table  ( 'user_role' );
__PACKAGE__->columns( Primary   => qw/id/ );
__PACKAGE__->columns( Essential => qw/user role/ );

1;
