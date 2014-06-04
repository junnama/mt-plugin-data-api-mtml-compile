package DataAPIMTMLCompile::DataAPI;

use strict;
use warnings;

use MT::DataAPI::Endpoint::Common;

sub _handler_mtmlcompile {
    my ( $app, $endpoint ) = @_;
    my ( $blog ) = context_objects( @_ );
    my $user = $app->user;
    if (! $user || $user->is_anonymous ) {
        return $app->print_error( 'Unauthorized', 401 );
    } else {
        my $perm = $user->is_superuser;
        if (! $perm ) {
            if ( $blog ) {
                my $admin = 'can_administer_blog';
                $perm = $user->permissions( $blog->id )->$admin;
                $perm = $user->permissions( $blog->id )->edit_template unless $perm;
            } else {
                $perm = $user->permissions()->edit_template;
            }
        }
        if (! $perm ) {
            return $app->print_error( 'Permission denied.', 401 );
        }
    }
    my $res;
    my $mtml = $app->param( 'mtml' ) || $app->param( 'MTML' );
    if (! $mtml ) {
        $res->{ code } = 200;
        $res->{ message } = 'No MTML given.';
        return $res;
    }
    my $template = MT->model( 'template' )->new;
    my $blog_id = 0;
    $blog_id = $blog->id if $blog ;
    $template->blog_id( $blog_id );
    $template->text( $mtml );
    $template->compile;
    if ( $template->{ errors } && @{ $template->{ errors } } ) {
        $res->{ error }->{ code } = 500;
        $res->{ error }->{ message } = MT->translate( 'One or more errors were found in this template.' );
        my @errors;
        foreach my $err ( @{ $template->{ errors } } ) {
            push( @errors, $err->{ message } );
        }
        $res->{ errors } = \@errors;
        return $res;
    }
    $res->{ code } = 200;
    $res->{ message } = 'Template compile successfully.';
    $res;
}

1;