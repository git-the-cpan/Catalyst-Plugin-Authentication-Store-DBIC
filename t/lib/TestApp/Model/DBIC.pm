package TestApp::Model::DBIC;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components( qw/Core DB/ );

our $db_file = $ENV{TESTAPP_DB_FILE};

__PACKAGE__->connection(
    "dbi:SQLite:$db_file",
);

1;
