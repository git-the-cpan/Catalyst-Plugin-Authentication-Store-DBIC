#!perl

use strict;
use warnings;
use DBI;
use File::Path;
use FindBin;
use Test::More;
use lib "$FindBin::Bin/lib";

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all =>
        "DBD::SQLite is required for this test";
        
    eval { require DBIx::Class }
        or plan skip_all =>
        "DBIx::Class is required for this test";      

    plan tests => 2;
    
    $ENV{TESTAPP_DB_FILE} = "$FindBin::Bin/auth.db";
    
    $ENV{TESTAPP_CONFIG} = {
        name => 'TestApp',
        authentication => {
            dbic => {
                user_class         => 'TestApp::Model::User',
                user_field         => 'username',
                password_field     => 'password',
                password_type      => 'hashed',
                password_hash_type => 'SHA-1',
            },
        },
    };
    
    $ENV{TESTAPP_PLUGINS} = [
        qw/Authentication
           Authentication::Store::DBIC
           Authentication::Credential::Password
           /
    ];
}

# create the database
my $db_file = $ENV{TESTAPP_DB_FILE};
unlink $db_file if -e $db_file;

my $dbh = DBI->connect( "dbi:SQLite:$db_file" ) or die $DBI::errstr;
my $sql = qq{
    CREATE TABLE user (
        id       INTEGER PRIMARY KEY,
        username TEXT,
        password TEXT
    );
    INSERT INTO user VALUES (1, 'andyg', 'cc9597d31f0503bded5df310eb5f28fb4d49fb0f')
};
$dbh->do( $_ ) for split /;/, $sql;
$dbh->disconnect;

use Catalyst::Test 'TestApp';

# log a user in
{
    ok( my $res = request('http://localhost/user_login?username=andyg&password=hackme'), 'request ok' );
    is( $res->content, 'logged in', 'user logged in ok' );
}

# clean up
unlink $db_file;
