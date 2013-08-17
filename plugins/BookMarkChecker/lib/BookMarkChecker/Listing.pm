package BookMarkChecker::Listing;
use strict;

use BookMarkChecker::Plugin;

sub _html_bookmark {
    my ( $prop, $obj, $app ) = @_;
    my $blog_id = $obj->blog_id;
    my $permalink = $obj->permalink;
    return BookMarkChecker::Plugin::build_innerHTML( $blog_id, $permalink, $obj->id, { screen => 'listing' } );
}

1;
