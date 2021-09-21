package CFG;
use strict;

sub new
{ my ($class,$par) = @_;

  my $cfg = {   domain                  => 'guardioes.cria.org.br',

                home_url                => 'https://guardioes.cria.org.br',
                home_dir                => '/system/guardioes/docs',

                lib_dir                 => '/system/guardioes/lib',     # full path to the main GUARDIOES module and dictionary file

                curl_path               => '/usr/bin/curl',     # full path to the curl utility

                user_dir                => '/system/guardioes/users',   # full path to the users data home
                user_url                => '/html/users',       # realtive path to the users data home 

                db_host                 => 'localhost',         # database hostname
                db_user                 => 'postgres',          # database user name
                db_name                 => 'guardioes',         # database name

                db_api_host             => 'localhost',         # api database hostname
                db_api_user             => 'postgres',          # api database user name
                db_api_name             => 'guardioes_api',     # api database name

                sp_dic_host             => 'localhost',         # database hostname
                sp_dic_user             => 'postgres',          # database user name
                sp_dic_name             => 'sp_dic',            # database name

                user_lang               => 'pt',                # default lang, overwritten by user's profile or temporarily by cookie_lang
                cookie_lang             => '',
                dictionary              => undef,
                user_id                 => '',                  # user_id currently active in browser
                session_id              => '',                  # session_id currently active in browser
                session_email           => '',                  # session_email currently active in browser
                network                 => '',
                sql                     => undef,               # preserves the sql connection to the database
                debug                   => $par->{'debug'} ? '/system/guardioes/work/dSQL.dbg' : '',    # activates sql commands debug
                param                   => undef,
                rand                    => rand(),
                tip_symbol              => "<img src='/imgs/info.png'/>",
                tip_symbol              => "<sup class='tip_symbol'>info</sup>",        # ... 

# google stuff
                google_id               => 'PREENCHER',
                google_secret           => 'PREENCHER',

                google_maps_api_key     => 'PREENCHER',

# twitter stuff
                twitter_id              => 'PREENCHER', # Consumer Key (API Key)
                twitter_secret          => 'PREENCHER', # Consumer Secret (API Secret)

# instagram stuff
                instagram_id            => 'PREENCHER',
                instagram_secret        => 'PREENCHER',

# facebool stuff
                facebook_id             => 'PREENCHER',
                facebook_secret         => 'PREENCHER',

                svg_last_color          => '',
                svg_prev_color          => '',
                nSVG                    => 0,
                mobile                  => length($ENV{'REQUEST_URI'}) > 6 && substr($ENV{'REQUEST_URI'}, 0, 7) eq '/mobile' ? 1 : 0,

# maximum number of records to be displayed in a page when searching the database
                records_per_page        => 50,

# color palette to use  

                palette_id              => 1,
                palette_color           => {},
                windowWidth             => 0,
                windowHeight            => 0,
            };

  my $cfg2 = bless $cfg;

  return $cfg2;
}

1;
