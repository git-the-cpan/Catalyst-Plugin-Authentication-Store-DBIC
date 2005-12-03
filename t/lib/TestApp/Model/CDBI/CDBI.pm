package TestApp::Model::CDBI::CDBI;

use strict;
use warnings;
use base 'Class::DBI';

our $db_file = $ENV{TESTAPP_DB_FILE};

unlink '/tmp/andy.trace';
DBI->trace( 1, '/tmp/andy.trace' );

__PACKAGE__->connection(
    "dbi:SQLite:$db_file",
);

1;
