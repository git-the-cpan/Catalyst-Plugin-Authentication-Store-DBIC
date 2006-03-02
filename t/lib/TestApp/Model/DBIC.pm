package TestApp::Model::DBIC;

eval { require DBIx::Class }; return 1 if $@;
@ISA = qw/DBIx::Class/;
use strict;

__PACKAGE__->load_components( qw/Core DB/ );

our $db_file = $ENV{TESTAPP_DB_FILE};

__PACKAGE__->connection(
    "dbi:SQLite:$db_file",
);

1;
