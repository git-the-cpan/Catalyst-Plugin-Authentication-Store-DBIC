package Catalyst::Plugin::Authentication::Store::DBIC::User;

use strict;
use warnings;
use base qw/Catalyst::Plugin::Authentication::User Class::Accessor::Fast/;
use Scalar::Util;
use Set::Object ();

__PACKAGE__->mk_accessors(qw/id config obj store/);

sub new {
    my ( $class, $id, $config ) = @_;
    
    # retrieve the user from the database
    my $user_obj = $config->{auth}{user_class}->search( { $config->{auth}{user_field} => $id } )->first;

    return unless $user_obj;

    bless {
        id     => $id,
        config => $config,
        obj    => $user_obj,
    }, $class;
}

*user = \&obj;
*crypted_password = \&password;
*hashed_password = \&password;

sub hash_algorithm { shift->config->{auth}{password_hash_type} }

sub password_pre_salt { shift->config->{auth}{password_pre_salt} }

sub password_post_salt { shift->config->{auth}{password_post_salt} }

sub password {
    my $self = shift;
   
    return undef unless defined $self->user;
    my $password_field = $self->config->{auth}{password_field};
    return $self->obj->$password_field;
}

sub supported_features {
    my $self = shift;
    $self->config->{auth}{password_type} ||= 'clear';
    
    return {
        password => {
            $self->config->{auth}{password_type} => 1,
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
    if (Scalar::Util::blessed($cfg->{role_class})) {
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
    } else {
        # slow Class::DBI method
        # Retrieve only as many roles as necessary to fail the check
        my @roles;

        ROLE_CHECK:
        for my $role ( @wanted_roles ) {
            if (my $role_obj = $cfg->{role_class}->search(
                { $role_field => $role} )->first) 
            {
                if ( $cfg->{user_role_class}->search( {
                        $cfg->{user_role_user_field} => $self->user->id,
                        $cfg->{user_role_role_field} => $role_obj->id,
                    } ) ) 
                {
                    push @roles, $role;
                } else {  
                    last ROLE_CHECK;
                }
            } else {
                last ROLE_CHECK;
            }
        }
        
        return @roles;
    }
}

sub for_session {
    shift->id;
}

sub AUTOLOAD {
	my $self = shift;
	(my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
	return if $method eq "DESTROY";

	$self->obj->$method;
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

=head2 check_roles

=head2 for_session

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication::Store::DBIC>

=head1 AUTHORS

David Kamholz, <dkamholz@cpan.org>

Andy Grundman

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
