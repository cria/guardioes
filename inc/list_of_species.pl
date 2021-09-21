#===============================================================
sub list_of_species
{ my ($cfg,$records,$list) = @_;
  my $dic = $cfg->dic();

  my ($primary_kingdom,$secondary_kingdom) =
		$list eq 'list_of_animals'		? ('animalia','') :
		$list eq 'list_of_plants'		? ('plantae','') :			
		$list eq 'list_of_animals_x_plants'	? ('animalia','plantae') :
		$list eq 'list_of_plants_x_animals' 	? ('plantae','animalia') : ();			

  my $menu = search_menu({ active => $list, total => scalar keys $records });
  print <<EOM;
<div id='divMain'>
<blockquote>
$menu
<h2>$dic->{$list.'_title'}</h2><ul>
EOM

  my $sql = $cfg->connect();

  my $recs = join(',',keys %$records); my $list = {};

  my $cmd = <<EOM;
select	distinct on (scientificName) scientificName, scientificNameAuthorship
from	ident_view
where	kingdom = E'$primary_kingdom'
	and record_id in ($recs)
	and scientificname != ''
order by 1
EOM

  my %p = $sql->query($cmd);
  my $np = $sql->nRecords;
  print STDERR $sql->message() if $sql->error;

  foreach my $i (0..$np-1)
  { my $cl = $cfg->acceptedName( { kingdom => $primary_kingdom, scientificname => $p{$i}{'scientificname'} }) ? ' bold' : '';
    print "<li> <span class='sp$cl'>$p{$i}{'scientificname'}</span> $p{$i}{'scientificnameauthorship'}<ul>";
    $cmd = <<EOM;
select	distinct on (scientificName) scientificName, scientificNameAuthorship
from	ident_view a
where	a.kingdom = E'$secondary_kingdom'
	and exists (select 1 from ident_view b where b.scientificname = '$p{$i}{'scientificname'}' and a.record_id = b.record_id)
	and scientificname != ''
EOM
    my %q = $sql->query($cmd);
    my $nq = $sql->nRecords;

    foreach my $k (0..$nq-1)
    { my $cl = $cfg->acceptedName( { kingdom => $secondary_kingdom, scientificname => $q{$k}{'scientificname'} }) ? ' bold' : '';
      print "<li> <span class='sp$cl'>$q{$k}{'scientificname'}</span> $q{$k}{'scientificnameauthorship'}</li>";
    }
    print "</ul></li>";
  }

  print "</ul></blockquote>";

  print $cfg->html_foot();
}
1;
