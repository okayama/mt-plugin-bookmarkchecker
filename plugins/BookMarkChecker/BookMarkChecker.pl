package MT::Plugin::BookMarkChecker;
use strict;
use MT;
use MT::Plugin;
use base qw( MT::Plugin );
@MT::Plugin::BookMarkChecker::ISA = qw( MT::Plugin );

use MT::Util qw( encode_url );

use Digest::MD5 qw( md5_hex );

our $VERSION = '0.3';

my $plugin = __PACKAGE__->new( {
    id => 'BookMarkChecker',
    key => 'bookmarkchecker',
    name => 'BookMarkChecker',
    author_name => 'okayama', 
    author_link => 'http://weeeblog.net/',
    description => '<MT_TRANS phrase=\'_PLUGIN_DESCRIPTION\'>',
    version => $VERSION,
    l10n_class => 'BookMarkChecker::L10N',
    settings => new MT::PluginSettings( [
        [ 'check_delicious', { Default => 1 } ],
        [ 'check_hatena', { Default => 1 } ],
        [ 'check_livedoor', { Default => 1 } ],
        [ 'check_yahoo', { Default => 1 } ],
        [ 'check_buzzurl', { Default => 1 } ],
    ] ),
    blog_config_template => 'bookmarkchecker_config.tmpl',
} );
MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;
    $plugin->registry( {
        callbacks => {
            'MT::App::CMS::template_param.edit_entry'
                => \&_cb_tp_edit_entry,
            'MT::App::CMS::template_param.edit_template'
                => \&_cb_tp_edit_template,
            'MT::App::CMS::template_output.header'
                => \&_cb_to_header,
        },
    } );
}

sub _cb_tp_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $tmpl_id = $app->param( 'id' );
    my $blog_id = $app->param( 'blog_id' );
    my $tmpl_obj = MT::Template->load( $tmpl_id );
    if ( $tmpl_obj && $tmpl_obj->type eq 'index' && $blog_id ) {
        my $outfile = $tmpl_obj->outfile;
        my $blog = MT::Blog->load( $blog_id );
        my $site_url = $blog->site_url;
        my $permalink = $site_url . $outfile;
        if ( my $innerHTML = _build_innerHTML( $blog_id, $permalink ) ) {
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
    my $entry_id = $app->param( 'id' );
    my $entry = MT::Entry->load( $entry_id );
    if ( $entry_id ) {
        # create elements
        my $blog_id = $entry->blog_id;
        my $permalink = $entry->permalink;
        my $innerHTML;
        if ( my $innerHTML = _build_innerHTML( $blog_id, $permalink ) ) {
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

sub _build_innerHTML {
    my ( $blog_id, $permalink ) = @_;
    return unless $blog_id;
    return unless $permalink;
    my $innerHTML;
    if ( $plugin->get_config_value( 'check_delicious', 'blog:' . $blog_id ) ) {
        $innerHTML .= _delicious_tmpl( $permalink );
    }
    if ( $plugin->get_config_value( 'check_hatena', 'blog:' . $blog_id ) ) {
        $innerHTML .= _hatena_tmpl( $permalink );
    }
    if ( $plugin->get_config_value( 'check_yahoo', 'blog:' . $blog_id ) ) {
        $innerHTML .= _yahoo_tmpl( $permalink );
    }
    if ( $plugin->get_config_value( 'check_buzzurl', 'blog:' . $blog_id ) ) {
        $innerHTML .= _buzzurl_tmpl( $permalink );
    }
    if ( $plugin->get_config_value( 'check_livedoor', 'blog:' . $blog_id ) ) {
        $innerHTML .= _livedoor_tmpl( $permalink );
    }
    return $innerHTML;
}

sub _delicious_tmpl {
    my ( $url ) = @_;
    my $label = $plugin->translate( 'del.icio.us' );
    my $url_hash = md5_hex( $url );
    return<<TMPL;
<script type="text/javascript">
document.write('<li id="delicious"></li>');
function getDeliciousNum( data ) {
    var totalPosts;
    var target;
    totalPosts = data[0] ? data[0].total_posts: 0;
    target = document.getElementById( 'delicious' );
    target.innerHTML = '<a href="http://del.icio.us/url/$url_hash" target="_blank" class="icon-left icon-related">$label: ' + totalPosts + '</a>';
}
</script>
<script src="http://badges.del.icio.us/feeds/json/url/data?hash=$url_hash&callback=getDeliciousNum"></script>
TMPL
} 


sub _hatena_tmpl {
    my ( $url ) = @_;
    my $label = $plugin->translate( 'Hatena' );
    return<<TMPL;
<li><a href="http://b.hatena.ne.jp/entry/$url" target="_blank" class="icon-left icon-related">$label: <img src="http://b.hatena.ne.jp/entry/image/$url" /></a></li>
TMPL
}

sub _livedoor_tmpl {
    my ( $url ) = @_;
    my $label = $plugin->translate( 'Livedoor' );
    return<<TMPL;
<script type="text/javascript">
    document.write('<li id="bookmark-livedoor-list">');
    Livedoor.Clip.location = "$url";
    Livedoor.Clip.linktarget = 1;
    Livedoor.Clip.image_counter( "small" );
    document.write('</li>');
</script>
<script type="text/javascript">
    target = document.getElementById( 'bookmark-livedoor-list' );
    anchor = target.getElementsByTagName( 'a' );
    anchor[0].setAttribute( 'class', 'icon-left icon-related' );
    anchor[0].innerHTML = '$label: ' + anchor[0].innerHTML;
</script>
TMPL
}

sub _yahoo_tmpl {
    my ( $url ) = @_;
    my $label = $plugin->translate( 'Yahoo!' );
    my $url_encoded = encode_url( $url );
    return<<TMPL;
<li><a href="http://bookmarks.yahoo.co.jp/url?url=$url_encoded" target="_blank" class="icon-left icon-related">$label: <img src="http://num.bookmarks.yahoo.co.jp/ybmimage.php?disptype=small&url=$url_encoded" /></a></li>
TMPL
}

sub _buzzurl_tmpl {
    my ( $url ) = @_;
    my $label = $plugin->translate( 'Buzzurl' );
    my $url_encoded = encode_url( $url );
    return<<TMPL;
<li><a href="http://buzzurl.jp/entry/$url" target="_blank" class="icon-left icon-related">$label: <img src="http://api.buzzurl.jp/api/counter/v1/image?url=$url_encoded" /></a></li>
TMPL
}

sub _cb_to_header {
    my ( $cb, $app, $tmpl ) = @_;
    if (
         !( $app->param( '_type' ) eq 'entry' ) &&
         !( $app->param( '_type' ) eq 'page' ) &&
         !( $app->param( '_type' ) eq 'template' )
    ) {
        return 1;
    }
    my $head_etc =<<'HEAD';
<script type="text/javascript" src="http://clip.livedoor.com/js/utils.js"></script>
HEAD
    $$tmpl =~ s/(<\/head>)/$head_etc$1/;
}
1;
