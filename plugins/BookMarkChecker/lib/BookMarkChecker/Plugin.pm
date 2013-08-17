package BookMarkChecker::Plugin;
use strict;

use Digest::MD5 qw( md5_hex );
use JSON;
use MT::Util qw( encode_url );

sub build_innerHTML {
    my ( $blog_id, $permalink, $object_id, $options ) = @_;
    return unless $blog_id;
    return unless $permalink;
    my $plugin = MT->component( 'BookMarkChecker' );
    my $screen = $options ? $options->{ screen } : 'edit';
    my $innerHTML;
    if ( $plugin->get_config_value( $screen eq 'listing' ? 'check_delicious_at_listing' : 'check_delicious', 'blog:' . $blog_id ) ) {
        $innerHTML .= _delicious_tmpl( $permalink, $object_id );
    }
    if ( $plugin->get_config_value( $screen eq 'listing' ? 'check_hatena_at_listing' : 'check_hatena', 'blog:' . $blog_id ) ) {
        $innerHTML .= _hatena_tmpl( $permalink );
    }
    if ( $plugin->get_config_value( $screen eq 'listing' ? 'check_yahoo_at_listing' : 'check_yahoo', 'blog:' . $blog_id ) ) {
        $innerHTML .= _yahoo_tmpl( $permalink );
    }
    if ( $plugin->get_config_value( $screen eq 'listing' ? 'check_buzzurl_at_listing' : 'check_buzzurl', 'blog:' . $blog_id ) ) {
        $innerHTML .= _buzzurl_tmpl( $permalink );
    }
    if ( $plugin->get_config_value( $screen eq 'listing' ? 'check_livedoor_at_listing' : 'check_livedoor', 'blog:' . $blog_id ) ) {
        $innerHTML .= _livedoor_tmpl( $permalink );
    }
    return $innerHTML;
}

sub _delicious_tmpl {
    my ( $url, $object_id ) = @_;
    my $plugin = MT->component( 'BookMarkChecker' );
    my $label = $plugin->translate( 'del.icio.us' );
    my $url_hash = md5_hex( $url );

    $url = 'http://badges.del.icio.us/feeds/json/url/data?hash=' . $url_hash;
    my $ua = MT->new_ua or return;
    my $request = new HTTP::Request( GET => $url );
    my $res = $ua->request( $request );
    my $count = 0;
    if ( $res->is_success() ) {
        if ( my $content = $res->content() ) {
            my $json = JSON->new->utf8( 0 );
            my $result = $json->decode( $content );
            if ( ( ref $result ) eq 'ARRAY' ) {
                $count = $$result[ 0 ]->{ total_posts };
            }
        }
    }
    return '<li><a href="http://del.icio.us/url/' . $url_hash . '" target="_blank" class="icon-left icon-related">' . $label . ': ' . $count . '</a></li>';
}

sub _hatena_tmpl {
    my ( $url ) = @_;
    my $plugin = MT->component( 'BookMarkChecker' );
    my $label = $plugin->translate( 'Hatena' );
    return<<TMPL;
<li><a href="http://b.hatena.ne.jp/entry/$url" target="_blank" class="icon-left icon-related">$label: <img src="http://b.hatena.ne.jp/entry/image/$url" /></a></li>
TMPL
}

sub _livedoor_tmpl {
    my ( $url ) = @_;
    my $plugin = MT->component( 'BookMarkChecker' );
    my $label = $plugin->translate( 'Livedoor' );
    return<<TMPL;
<li><a hrf="http://clip.livedoor.com/page/$url" class="icon-left icon-related">$label: <img src="http://image.clip.livedoor.com/counter/$url"></a></li>
TMPL
}

sub _yahoo_tmpl {
    my ( $url ) = @_;
    my $plugin = MT->component( 'BookMarkChecker' );
    my $label = $plugin->translate( 'Yahoo!' );
    my $url_encoded = encode_url( $url );
    return<<TMPL;
<li><a href="http://bookmarks.yahoo.co.jp/url?url=$url_encoded" target="_blank" class="icon-left icon-related">$label: <img src="http://num.bookmarks.yahoo.co.jp/ybmimage.php?disptype=small&url=$url_encoded" /></a></li>
TMPL
}

sub _buzzurl_tmpl {
    my ( $url ) = @_;
    my $plugin = MT->component( 'BookMarkChecker' );
    my $label = $plugin->translate( 'Buzzurl' );
    my $url_encoded = encode_url( $url );
    return<<TMPL;
<li><a href="http://buzzurl.jp/entry/$url" target="_blank" class="icon-left icon-related">$label: <img src="http://api.buzzurl.jp/api/counter/v1/image?url=$url_encoded" /></a></li>
TMPL
}

1;
