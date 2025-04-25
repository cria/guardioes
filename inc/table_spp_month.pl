#===============================================================
sub table_spp_month
{ my ($cfg,$records,$report) = @_;

  my $dic = $cfg->dic();

  my $menu = search_menu({ active => $report, total => scalar keys %{$records} });

  print <<EOM;
<div id='divMain'>
<blockquote>
$menu
<h2>$dic->{$report.'_title'}</h2><ul>
EOM

  my $sql = $cfg->connect();

  my $recs = join(',',keys %$records);

  my  $cmd = <<EOM;
select a_scientificName,a_scientificNameAuthorship,p_scientificName,p_scientificNameAuthorship,eventmonth,count(1)
from (  select a.a_scientificName,a.a_scientificNameAuthorship,p.p_scientificName,p.p_scientificNameAuthorship,a.eventmonth
        from    (select iv1.record_id, iv1.scientificName as a_scientificName, iv1.scientificNameAuthorship as a_scientificNameAuthorship, substring(r1.eventdate,4,2) as eventmonth
                 from   ident_view iv1
                        left join
                        record r1 on (iv1.record_id = r1.id)
                 where  kingdom = 'animalia' and record_id in ($recs)
                ) a
                left join
                (select	iv2.record_id,iv2.scientificName as p_scientificName,iv2.scientificNameAuthorship as p_scientificNameAuthorship
		 from	ident_view iv2
		 where	iv2.kingdom = 'plantae' and record_id in ($recs)
		) p
                on (a.record_id = p.record_id)
     ) rel
group by 1,2,3,4,5
order by 6;
EOM

  my %p = $sql->query($cmd);
  my $np = $sql->nRecords;
  print STDERR $sql->message() if $sql->error;

  my %table = ();
  foreach my $i (0..$np-1)
  { my $cl = $cfg->acceptedName( { kingdom => 'animalia', scientificname => $p{$i}{'a_scientificname'} }) ? ' bold' : '';
    my $animal = "<span class='sp$cl'>$p{$i}{'a_scientificname'}</span> $p{$i}{'a_scientificnameauthorship'}"; $animal =~ s/^\s+|\s+$//g;

    $cl = $cfg->acceptedName( { kingdom => 'plantae', scientificname => $p{$i}{'p_scientificname'} }) ? ' bold' : '';
    my $plant  = "<span class='sp$cl'>$p{$i}{'p_scientificname'}</span> $p{$i}{'p_scientificnameauthorship'}"; $plant  =~ s/^\s+|\s+$//g;

    my $m = $p{$i}{'eventmonth'} + 0;
    $table{"$animal#$plant"}{$m} += $p{$i}{'count'};
  }

	  print "<table class='w90'><tr><th class='esquerda'>$dic->{'animalia'}</th><td></td><th class='esquerda'>$dic->{'plantae'}</th>";
  foreach my $m (1..12)
  { print "<th style='width: 30px'>$cfg->{'month'}[$m]</th>" }
  
  foreach my $key (sort { $a cmp $b } keys %table)
  { my ($a,$p) = split('#',$key);

    print "<tr><td>$a</td><td>&#160;&#215;&#160;</td><td>$p</td>";

    foreach my $m (1..12)
    { print "<th class='tableBodyBorder centro'>$table{$key}{$m}</th>" }
  }
  print "</table>";

  

  print $cfg->html_foot();
}
1;
