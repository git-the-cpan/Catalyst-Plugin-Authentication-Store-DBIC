package Catalyst::Plugin::Authentication::Store::DBIC;

use strict;
use warnings;

our $VERSION = '0.02';

use Catalyst::Plugin::Authentication::Store::DBIC::Backend;

sub setup {
    my $c = shift;
    
    # default values
    $c->config->{authentication}->{dbic}->{user_field}     ||= 'user';
    $c->config->{authentication}->{dbic}->{password_field} ||= 'password';

    $c->default_auth_store(
        Catalyst::Plugin::Authentication::Store::DBIC::Backend->new( {
            auth  => $c->config->{authentication}->{dbic},
            authz => $c->config->{authorization}->{dbic}
        } )
    );

    $c->NEXT::setup(@_);
}

sub user_object {
    my $c = shift;
    
    return ( $c->user_exists ) ? $c->user->user : undef;
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::DBIC - Authentication and
authorization against a DBIx::Class or Class::DBI model.

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication
        Authentication::Store::DBIC
        Authentication::Credential::Password
        Authorization::Roles                                # if using roles
        /;

    # Authentication
    __PACKAGE__->config->{authentication}->{dbic} = {
        user_class         => 'MyApp::Model::User',
        user_field         => 'username',
        password_field     => 'password',
        password_type      => 'hashed',
        password_hash_type => 'SHA-1',
    };
    
    # Authorization using a many-to-many role relationship
    # For more detailed instructions on setting up role-based auth, please
    # see the section below titled L<"Roles">.
    __PACKAGE__->config->{authorization}->{dbic} = {
        role_class           => 'MyApp::Model::Role',
        role_field           => 'role',
        role_rel             => 'map_user_role',            # DBIx::Class only        
        user_role_user_field => 'user',
        user_role_class      => 'MyApp::Model::UserRole',   # Class::DBI only        
        user_role_role_field => 'role',                     # Class::DBI only
    };

    # log a user in
    sub login : Global {
        my ( $self, $c ) = @_;

        $c->login( $c->req->param("email"), $c->req->param("password"), );
    }
    
    # verify a role
    if ( $c->check_user_roles( 'admin' ) ) {
        $model->delete_everything;
    }

=head1 DESCRIPTION

This plugin uses a DBIx::Class (or Class::DBI) object to authenticate a user.

=head1 AUTHENTICATION CONFIGURATION

Authentication is configured by setting an authentication->{dbic} hash
reference in your application's config method.  The following configuration
options are supported.

=head2 user_class

The name of the class that represents a user object.

=head2 user_field

The name of the column holding the user identifier (defaults to "C<user>")

=head2 password_field

The name of the column holding the user's password (defaults to "C<password>")

=head2 password_type

The type of password your user object stores.  One of: clear, crypted, or
hashed.  Defaults to clear.

=head2 password_hash_type

If using a password_type of hashed, this option specifies the hashing method
being used.  Any hashing method supported by the L<Digest> module may be used.

=head2 password_pre_salt

Use this option if your passwords are hashed with a prefix salt value.

=head2 password_post_salt

Use this option if your passwords are hashed with a postfix salt value.

=head1 AUTHORIZATION CONFIGURATION

Role-based authorization is configured by setting an authorization->{dbic}
hash reference in your application's config method.  The following options
are supported.  For more detailed instructions on setting up roles, please
see the section below titled L<"Roles">.

=head2 role_class

The name of the class that contains the list of roles.

=head2 role_field

The name of the field in L<"role_class"> that contains the role name.

=head2 role_rel

DBIx::Class models only.  This field specifies the name of the
relationship in L<"role_class"> that refers to the mapping table between
users and roles.  Using this relationship, DBIx::Class models can retrieve
the list of roles for a user in a single SQL statement using a join.

=head2 user_role_class

Class::DBI models only.  The name of the class that contains the many-to-many
linking data between users and roles.

=head2 user_role_user_field

The name of the field in L<"user_role_class"> that contains the user ID.
This is required for both DBIx::Class and Class::DBI.

=head2 user_role_role_field

Class::DBI models only.  The name of the field in L<"user_role_class"> that
contains the role ID.

=head1 METHODS

=head2 user_object

Returns the DBIx::Class or Class::DBI object representing the user in the
database.

=head1 INTERNAL METHODS

=head2 setup

=head1 ROLES

This section will attempt to provide detailed instructions for configuring
role-based authorization in your application.

=head2 Database Schema

The basic database structure for roles consists of the following 3 tables.
This syntax is for SQLite, but can be easily adapted to other databases.

    CREATE TABLE user (
        id       INTEGER PRIMARY KEY,
        username TEXT,
        password TEXT
    );

    CREATE TABLE role (
        id   INTEGER PRIMARY KEY,
        role TEXT
    );

    # DBIx::Class can handle multiple primary keys
    CREATE TABLE user_role (
        user INTEGER,
        role INTEGER,
        PRIMARY KEY (user, role)
    );
    
    # Class::DBI may need the following user_role table
    CREATE TABLE user_role (
        id   INTEGER PRIMARY KEY,
        user INTEGER,
        role INTEGER,
        UNIQUE (user, role)
    );

=head2 DBIx::Class

For best performance when using roles, DBIx::Class models are recommended.
By using DBIx::Class you will benefit from optimized SQL using joins that
can retrieve roles for a user with a single SQL statement.

The steps for setting up roles with DBIx::Class are:

=head3 1. Create Model classes and define relationships

    # Example User Model
    package MyApp::Model::User;

    use strict;
    use warnings;
    use base 'MyApp::Model::DBIC';

    __PACKAGE__->table( 'user' );
    __PACKAGE__->add_columns( qw/id username password/ );
    __PACKAGE__->set_primary_key( 'id' );

    __PACKAGE__->has_many(
        map_user_role => 'MyApp::Model::UserRole' => 'user' ); 

    1;
    
    # Example Role Model
    package MyApp::Model::Role;
    
    use strict;
    use warnings;
    use base 'MyApp::Model::DBIC';
    
    __PACKAGE__->table( 'role' );
    __PACKAGE__->add_columns( qw/id role/ );    
    __PACKAGE__->set_primary_key( 'id' );
    
    __PACKAGE__->has_many(
        map_user_role => 'MyApp::Model::UserRole' => 'role' );

    1;
    
    # Example UserRole Model
    package MyApp::Model::UserRole;
    
    use strict;
    use warnings;
    use base 'MyApp::Model::DBIC';
    
    __PACKAGE__->table( 'user_role' );
    __PACKAGE__->add_columns( qw/user role/ );                                 
    __PACKAGE__->set_primary_key( qw/user role/ );

    1;

=head3 2. Specify authorization configuration settings

For the above DBIx::Class model classes, the configuration would look like
this:

    __PACKAGE__->config->{authorization}->{dbic} = {
        role_class           => 'MyApp::Model::Role',
        role_field           => 'role',
        role_rel             => 'map_user_role',    
        user_role_user_field => 'user',
    };

=head2 Class::DBI

Class::DBI models are also supported but require slightly more configuration.
Performance will also suffer as more SQL statements must be run to retrieve
all roles for a user.

The steps for setting up roles with Class::DBI are:

=head3 1. Create Model classes

    # Example User Model
    package MyApp::Model::User;

    use strict;
    use warnings;
    use base 'MyApp::Model::CDBI';

    __PACKAGE__->table  ( 'user' );
    __PACKAGE__->columns( Primary   => qw/id/ );
    __PACKAGE__->columns( Essential => qw/username password/ );

    1;
    
    # Example Role Model
    package MyApp::Model::Role;
    
    use strict;
    use warnings;
    use base 'MyApp::Model::CDBI';
    
    __PACKAGE__->table  ( 'role' );
    __PACKAGE__->columns( Primary   => qw/id/ );
    __PACKAGE__->columns( Essential => qw/role/ );
    
    1;
    
    # Example UserRole Model
    package MyApp::Model::UserRole;
    
    use strict;
    use warnings;
    use base 'MyApp::Model::CDBI';
    
    __PACKAGE__->table  ( 'user_role' );
    __PACKAGE__->columns( Primary   => qw/id/ );
    __PACKAGE__->columns( Essential => qw/user role/ );

    1;

=head3 2. Specify authorization configuration settings

For the above Class::DBI model classes, the configuration would look like
this:

    __PACKAGE__->config->{authorization}->{dbic} = {
        role_class           => 'MyApp::Model::Role',
        role_field           => 'role',
        user_role_class      => 'MyApp::Model::UserRole',
        user_role_user_field => 'user',        
        user_role_role_field => 'role',
    };

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, 
L<Catalyst::Plugin::Authorization::Roles>

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
