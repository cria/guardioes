#======================================================================
sub graph_of_records
{ my ($cfg,$records,$report) = @_;
  my $dic = $cfg->dic();

  my $menu = search_menu({ active => $report, total => scalar keys $records });
  my $caption = $dic->{$report.'_title'};

  print <<EOM;
<div id='divMain'>
<center>
$menu
EOM

  my $sql = $cfg->connect();

  my $recs = join(',',keys %$records); my $list = {};

  my $item = ''; my $cmd = ''; my $kingdom = '';
 
  my $graph_type = $report =~ /graph_of_eventtime/ ? 'scatterpolar' : 'bar';

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


  my $palette = int(rand(4))+1;

  my $total = 0;
  foreach (0..$np-1) { $total += $p{$_}{'count'} }

  my $not_informed_label = ''; my $nda_label = ''; my $labels = '';
  my $not_informed_data  = ''; my $nda_data  = ''; my $data = '';

  my $max_y = 0;
  foreach (0..$np-1)
  { if ($item eq 'eventtime')
    { $p{$_}{$item} = $p{$_}{$item} =~ /(\d\d)(\d\d)/ ? "$1-$2h" : $p{$_}{$item} }
    
    $p{$_}{$item} = 'not_informed' if !$p{$_}{$item};

    my $label = $dic->{$p{$_}{$item}} || $p{$_}{$item};

    if ($p{$_}{$item} eq 'not_informed') { $not_informed_label = "'$label', "; $not_informed_data = "$p{$_}{'count'}, " }

    elsif ($p{$_}{$item} eq 'nda')	 { $nda_label = "'$label', "; $nda_data = "$p{$_}{'count'}, " }

    else				 { $labels .= "'$label', "; $data .= "$p{$_}{'count'}, " }
    $max_y = $p{$_}{'count'} if $p{$_}{'count'} > $max_y;
  }

  $labels .= $nda_label.$not_informed_label;
  $data .= $nda_data.$not_informed_data;

  $labels =~ s/, $//; $data =~ s/, $//;

# vermelho, verde escuro, mostarda

#  my @fg = ('#c03',	    '#c93',      '#696');
  my @fg = ('rgb(204,  0, 51','rgb(102,153,102)', 'rgb(204,153, 51)');
  my @bg = ('rgba(204,  0, 51,0.5)','rgba(102,153,102,0.5)', 'rgba(204,153, 51,0.5)');

  my $c = int(rand(3));

  print <<EOM;
<br/><br/>
<div id="myGraph" style="width: 95%; height: 550px;"></div>
<script>
	myGraph = document.getElementById('myGraph');
EOM

if ($graph_type eq 'scatterpolar')
{ print <<EOM;
	data    =	[{ type: '$graph_type',
			   r: [ $data ],
			   theta: [ $labels ],
			   fill: 'toself'
			 }];

	layout  = {	
			polar: { radialaxis: { visible: true, range: [0, $max_y] } },
		  	showlegend: false
		  };
EOM
}
else
{ print <<EOM;
	data    =	[{ type: '$graph_type',
			   x: [ $labels ],
			   y: [ $data ],
			   marker: { color: '$bg[$c]', line: { width: 1.5 } }
			 }];

	layout  = { margin: { t: 30 }, title: '$caption', font: { size: 12 }  };
EOM
}

  print <<EOM;
	Plotly.plot ( "myGraph", data, layout, {displayModeBar: false});
//myGraph.options.displayModeBar = false;
myChart = document.getElementById('myGraph');

        </script>

</center>
EOM

  print $cfg->html_foot();
}
1;
