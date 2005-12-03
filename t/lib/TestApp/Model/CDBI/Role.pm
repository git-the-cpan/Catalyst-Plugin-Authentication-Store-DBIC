package TestApp::Model::CDBI::Role;

use strict;
use warnings;
use base 'TestApp::Model::CDBI::CDBI';

__PACKAGE__->table  ( 'role' );
__PACKAGE__->columns( Primary   => qw/id/ );
__PACKAGE__->columns( Essential => qw/role/ );

1;
