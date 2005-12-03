package Catalyst::Plugin::Authentication::Store::DBIC::Backend;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Catalyst::Plugin::Authentication::Store::DBIC::User;

BEGIN { __PACKAGE__->mk_accessors(qw/config/) }

sub new {
    my ( $class, $config ) = @_;

    bless { 
        config => $config
    }, $class;
}

sub from_session {
    my ( $self, $c, $id ) = @_;
    
    return $id if ref $id;
    
    # XXX: hits the database on every request?  Not good...
    return $self->get_user( $id );
}

sub get_user {
    my ( $self, $id ) = @_;
    
    my $user = Catalyst::Plugin::Authentication::Store::DBIC::User->new( 
        $id,
        $self->config,
    );
    
    if ( $user ) {
        $user->store( $self );
        return $user;
    }
    
    return;
}

sub user_supports {
    my $self = shift;

    # this can work as a class method
    Catalyst::Plugin::Authentication::Store::DBIC::User->supports(@_);
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::DBIC::Backend - DBIx::Class
authentication storage backend.

=head1 DESCRIPTION

This class implements the storage backend for database authentication.

=head1 INTERNAL METHODS

=head2 new

=head2 from_session

=head2 get_user

=head2 user_supports

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, 
L<Catalyst::Plugin::Authorization::Roles>

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
