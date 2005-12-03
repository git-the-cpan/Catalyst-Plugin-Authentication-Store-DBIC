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
        
    eval { require Catalyst::Plugin::Session::Store::Dummy }
        or plan skip_all =>
        "Catalyst::Plugin::Session >= 0.02 is required for this test";

    plan tests => 6;
    
    $ENV{TESTAPP_DB_FILE} = "$FindBin::Bin/auth.db";
    
    $ENV{TESTAPP_CONFIG} = {
        name => 'TestApp',
        authentication => {
            dbic => {
                user_class     => 'TestApp::Model::User',
                user_field     => 'username',
                password_field => 'password',
                password_type  => 'clear',
            },
        },
    };
    
    $ENV{TESTAPP_PLUGINS} = [
        qw/Authentication
           Authentication::Store::DBIC
           Authentication::Credential::Password
           Session
           Session::Store::Dummy
           Session::State::Cookie
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
    INSERT INTO user VALUES (1, 'andyg', 'hackme')
};
$dbh->do( $_ ) for split /;/, $sql;
$dbh->disconnect;

use Catalyst::Test 'TestApp';

# log a user in
{
    ok( my $res = request('http://localhost/user_login_session?username=andyg&password=hackme'), 'request ok' );
    is( $res->content, 'andyg', 'user logged in ok' );
}

# log the user out
{
    ok( my $res = request('http://localhost/user_logout'), 'request ok' );
    is( $res->content, 'logged out', 'user logged out ok' );
}

# verify there is no session
{
    ok( my $res = request('http://localhost/get_session_user'), 'request ok' );
    is( $res->content, '', 'user session deleted' );
}

# clean up
unlink $db_file;
