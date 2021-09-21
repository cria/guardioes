sub images_of_species
{ my ($cfg,$records,$report) = @_;

  my $dic = $cfg->dic();

  my $image_of = $report eq 'images_of_animals'		? 'interacao' : 'planta';

  my $menu = search_menu({ active => $report, total => scalar keys $records });
  print <<EOM;
<div id='divMain'>
<blockquote>
$menu
<h2>$dic->{$report.'_title'}</h2>
EOM

  my $sql = $cfg->connect();

  my $recs = join(',',keys %$records); my $list = {};

  my $cmd = <<EOM;
select	*
from	image
where	record_id in ($recs) and image_of = '$image_of' order by record_id,sequence;
EOM

  my %p = $sql->query($cmd);
  my $np = $sql->nRecords;
  print STDERR $sql->message() if $sql->error;

  foreach my $i (0..$np-1)
  { my $r = $cfg->format_user_id($p{$i}{'user_id'});
    my $svg = '';

    if ($p{$i}{'image_of'} eq 'interacao') #HEXAGONO
    { $svg =
	 $cfg->build_svg_hex( {	thumb_url	=> "$cfg->{'user_url'}/$r/$p{$i}{'code'}_thumb.$p{$i}{'format'}",
                                large_url	=> "$cfg->{'user_url'}/$r/$p{$i}{'code'}_large.$p{$i}{'format'}",
				record_id	=> $p{$i}{'record_id'},
                                radius		=> 60,
                                mode		=> 'flat',
				slideGroup	=> 1
                             } );
    }
    else #CIRCULO
    { $svg = 
         $cfg->build_svg_circ( { thumb_url	=> "$cfg->{'user_url'}/$r/$p{$i}{'code'}_thumb.$p{$i}{'format'}",
                                large_url	=> "$cfg->{'user_url'}/$r/$p{$i}{'code'}_large.$p{$i}{'format'}",
				record_id	=> $p{$i}{'record_id'},
                                radius		=> 56,
				slideGroup	=> 1
                              } );
    }
    print $svg;
  }

  print "</blockquote>";

  print $cfg->html_foot();
}
1;
