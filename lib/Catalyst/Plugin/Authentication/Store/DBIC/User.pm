package Catalyst::Plugin::Authentication::Store::DBIC::User;

use strict;
use warnings;
use base qw/Catalyst::Plugin::Authentication::User Class::Accessor::Fast/;

use Set::Object ();

BEGIN { __PACKAGE__->mk_accessors(qw/id config user store/) }

sub new {
    my ( $class, $id, $config ) = @_;
    
    # retrieve the user from the database
    my ($user) = $config->{auth}->{user_class}->search( {
        $config->{auth}->{user_field} => $id
    } );
    
    return unless $user;

    bless {
        id     => $id,
        config => $config,
        user   => $user,
    }, $class;
}

sub crypted_password { $_[0]->password(@_) }

sub hashed_password { $_[0]->password(@_) }

sub hash_algorithm { shift->config->{auth}->{password_hash_type} }

sub password_pre_salt { shift->config->{auth}->{password_pre_salt} }

sub password_post_salt { shift->config->{auth}->{password_post_salt} }

sub password {
    my $self = shift;
    
    my $password_field = $self->config->{auth}->{password_field};
    return $self->user->$password_field;
}

sub supported_features {
    my $self = shift;
    $self->config->{auth}->{password_type} ||= 'clear';
    
    return {
        password => {
            $self->config->{auth}->{password_type} => 1,
        },
        session  => 1,
        roles    => { self_check => 1 },
    };
}

sub check_roles {
    my ( $self, @wanted_roles ) = @_;

    my $have = Set::Object->new( $self->roles( @wanted_roles ) );
    my $need = Set::Object->new( @wanted_roles );

    $have->superset( $need );
}

sub roles {
    my ( $self, @wanted_roles ) = @_;
    
    my $cfg = $self->config->{authz};
    
    unless ( $cfg ) {
        Catalyst::Exception->throw( 
            message => 'No authorization configuration defined'
        );
    }
    
    my $role_field = $cfg->{role_field} ||= 'role';
    $cfg->{user_role_user_field} ||= $cfg->{user_field};
    $cfg->{user_role_role_field} ||= $cfg->{role_field};
    
    # optimized join if using DBIC
    if ( $cfg->{role_class}->isa( 'DBIx::Class' ) ) {
        my $search = { 
            $cfg->{role_rel} . '.' . $cfg->{user_role_user_field} 
                => $self->user->id
        };
        if ( @wanted_roles ) {
            $search->{ 'me.' . $role_field } = {
                -in => \@wanted_roles
            };
        }
        my $rs = $cfg->{role_class}->search(
            $search,
            { join => $cfg->{role_rel},
              cols => [ 'me.' . $role_field ], 
            }
        );
        return map { $_->$role_field } $rs->all;
    }
    else {
        # slow Class::DBI method
        # Retrieve only as many roles as necessary to fail the check
        my @roles;

        ROLE_CHECK:
        for my $role ( @wanted_roles ) {
            if ( 
                my $role_obj = $cfg->{role_class}->search( {
                    $role_field => $role
                } )->first
            ) {
                if ( 
                    $cfg->{user_role_class}->search( {
                        $cfg->{user_role_user_field} => $self->user->id,
                        $cfg->{user_role_role_field} => $role_obj->id,
                    } )
                ) {
                    push @roles, $role;
                }
                else {  
                    last ROLE_CHECK;
                }
            }
            else {
                last ROLE_CHECK;
            }
        }
        
        return @roles;
    }
}

sub for_session {
    my $self = shift;
    
    return $self->id;
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::DBIC::User - A user object
representing an entry in a database.

=head1 SYNOPSIS

    use Catalyst::Plugin::Authentication::Store::DBIC::User;

=head1 DESCRIPTION

This class implements a user object.

=head1 INTERNAL METHODS

=head2 new

=head2 crypted_password

=head2 hashed_password

=head2 hash_algorithm

=head2 password_pre_salt

=head2 password_post_salt

=head2 password

=head2 supported_features

=head2 roles

=head2 for_session

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication::Store::DBIC>

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
