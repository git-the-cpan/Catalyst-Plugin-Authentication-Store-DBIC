package TestApp::Model::CDBI::User;

use strict;
use warnings;
use base 'TestApp::Model::CDBI::CDBI';

__PACKAGE__->table  ( 'user' );
__PACKAGE__->columns( Primary   => qw/id/ );
__PACKAGE__->columns( Essential => qw/username password/ );

1;
