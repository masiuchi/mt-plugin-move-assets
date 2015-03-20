package MoveAssets::Callback;
use strict;
use warnings;

sub move_assets {
    my ( $cb, $app, $obj, $orig ) = @_;

    if (   $obj->site_path eq $orig->site_path
        && $obj->archive_path eq $orig->archive_path )
    {
        return 1;
    }

    my @blog_ids
        = ( $obj->id, $obj->is_blog ? () : ( map { $_->id } $obj->blogs ), );

    require File::Copy;
    my ( %site_paths, %archive_paths );
    my @assets
        = MT->model('asset')->load( { blog_id => \@blog_ids, class => '*' } );

    for my $asset (@assets) {
        my $old_file_path = $asset->column('file_path');

        if ( $old_file_path !~ m/(%[r|a])/ ) {
            next;
        }

        if ( $1 eq '%r' ) {
            my $site_path = $site_paths{ $asset->blog_id }
                ||= MT->model('blog')->load( $asset->blog_id );
            $old_file_path =~ s/%r/$site_path/;
        }
        elsif ( $1 eq '%a' ) {
            my $archive_path = $archive_paths{ $asset->blog_id }
                ||= MT->model('blog')->load( $asset->blog_id );
            $old_file_path =~ s/%a/$archive_path/;
        }

        File::Copy::move( $old_file_path, $asset->file_path );
    }

    return 1;
}

1;
