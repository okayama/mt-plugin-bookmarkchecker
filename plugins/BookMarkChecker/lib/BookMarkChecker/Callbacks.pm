package BookMarkChecker::Callbacks;
use strict;

use BookMarkChecker::Plugin;

sub _cb_tp_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;
    return unless $app->blog;
    my $plugin = MT->component( 'BookMarkChecker' );
    my $blog_id = $app->blog->id;
    my $tmpl_id = $app->param( 'id' );
    my $tmpl_obj = MT::Template->load( $tmpl_id );
    if ( $tmpl_obj && $tmpl_obj->type eq 'index' ) {
        my $outfile = $tmpl_obj->outfile;
        my $blog = MT::Blog->load( $blog_id );
        my $site_url = $blog->site_url;
        my $permalink = $site_url . $outfile;
        if ( my $innerHTML = BookMarkChecker::Plugin::build_innerHTML( $blog_id, $permalink ) ) {
            $innerHTML = '<ul>' . $innerHTML . ' </ul>';
            my $widget = $tmpl->createElement( 'app:widget', { id => 'bookmarks-widget',
                                                               label => $plugin->translate( 'BookMarks' ),
                                                               required => 0,
                                                             }
                                             );
            $widget->innerHTML( $innerHTML );
            my $pointer = $tmpl->getElementById( 'useful-links' );
            $tmpl->insertAfter( $widget, $pointer );
        }
    }
}

sub _cb_tp_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'BookMarkChecker' );
    my $entry_id = $app->param( 'id' );
    my $entry = MT::Entry->load( $entry_id );
    if ( $entry ) {
        # create elements
        my $blog_id = $entry->blog_id;
        my $permalink = $entry->permalink;
        my $innerHTML;
        if ( my $innerHTML = BookMarkChecker::Plugin::build_innerHTML( $blog_id, $permalink ) ) {
            $innerHTML = '<ul>' . $innerHTML . ' </ul>';
            my $widget = $tmpl->createElement( 'app:widget', { id => 'bookmarks-widget',
                                                               label => $plugin->translate( 'BookMarks' ),
                                                               required => 0,
                                                             }
                                             );
            $widget->innerHTML( $innerHTML );
            my $pointer = $tmpl->getElementById( 'entry-publishing-widget' );
            $tmpl->insertBefore( $widget, $pointer );
        }
    }
}

1;
