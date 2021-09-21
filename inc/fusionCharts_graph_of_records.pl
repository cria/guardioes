#======================================================================
sub graph_of_records
{ my ($cfg,$records,$report) = @_;
  my $dic = $cfg->dic();

  my $menu = search_menu({ active => $report, total => scalar keys $records });

  print <<EOM;
<div id='divMain'>
<blockquote>
$menu
<h3>$dic->{$report.'_title'}</h3><ul>
EOM

  my $sql = $cfg->connect();

  my $recs = join(',',keys %$records); my $list = {};

  my $item = ''; my $cmd = ''; my $kingdom = '';

  if ($report =~ /graph_of_(habit|eventtime|interaction)/)
  { $item = $1;
    my $order = $report =~ /eventtime/ ? '1 asc' : '2 desc';
    $cmd = <<EOM;
select	$item,count(1)
from	record
where	id in ($recs)
group by 1
order by $order
EOM
  }
  elsif ($report =~ /graph_of_(plant|animal)_family/)
  { $item = 'family';
    $kingdom = $1 eq 'plant' ? 'plantae' : 'animalia';
    $cmd = <<EOM;
select	family,count(1)
from	ident_view
where	record_id in ($recs)
	and kingdom = '$kingdom'
group by 1
order by 2 desc
EOM
  }

  my %p = $sql->query($cmd);
  my $np = $sql->nRecords;
  print STDERR $sql->message() if $sql->error;

  my $caption = $dic->{$report.'_title'};

  my $palette = int(rand(4))+1;

  my $xml =	"<chart palette='$palette' showToolTipShadow='1' showBorder='0' useRoundEdges='1' yAxisname='' bgColor='f0f6f0,ffffff' ".
		"caption='$caption' subCaption='' showValues='1' divLineDecimalPrecision='1' limitsDecimalPrecision='1' ".
		"numberPrefix='' formatNumberScale='0' sFormatNumberScale='0'>";

  my $total = 0;
  foreach (0..$np-1) { $total += $p{$_}{'count'} }
  $total = 1 if !$total; # prevent /0

  my $not_informed = ''; my $nda = '';
  foreach (0..$np-1)
  { if ($item eq 'eventtime')
    { $p{$_}{$item} = $p{$_}{$item} =~ /(\d\d)(\d\d)/ ? "$1-$2" : $p{$_}{$item} }
    
    my $per = int(($p{$_}{'count'}/$total)*100);

    $p{$_}{$item} = 'not_informed' if !$p{$_}{$item};
    my $label = $dic->{$p{$_}{$item}} || $p{$_}{$item};

    if ($p{$_}{$item} eq 'not_informed')
    { $not_informed .= "<set label='$label' value='$p{$_}{'count'}' displayValue='$per%'/>" }
    elsif ($p{$_}{$item} eq 'nda')
    { $nda .= "<set label='$label' value='$p{$_}{'count'}' displayValue='$per%'/>" }
    else
    { $xml .= "<set label='$label' value='$p{$_}{'count'}' displayValue='$per%'/>" }
  }

  $xml .= $nda.$not_informed."</chart>";

  print <<EOM;
<div id="${item}Div" align="left"></div>
<script type="text/javascript">

  var ${item}Chart = new FusionCharts("FusionCharts_Professional_xt/Charts/Column2D.swf", "${item}Chart1", "100%", "500", "0", "1");
      ${item}Chart.setXMLData("$xml");
      ${item}Chart.render("${item}Div");
</script>
EOM

  print $cfg->html_foot();
}
1;
