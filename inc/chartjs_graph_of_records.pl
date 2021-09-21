use strict;
#======================================================================
# parameters:
#	records		hash of record_ids 
#	report 		[ graph_of_habit | graph_of_interaction | graph_of_eventtime | graph_of_months | graph_of_plant_family | graph_of_animal_family |
#			  table_of_habit | table_of_interaction | table_of_eventtime | table_of_months | table_of_plant_family | table_of_animal_family ]
#	graph_type	[ bar | doughnut | horizontalBar | pie | polarArea | radar ]
#	order		[ item | count ]
#======================================================================
sub graph_of_records
{ my ($cfg,$records,$report,$graph_type,$order_by) = @_;

  # colors 

  my @colors = ('#603', '#903', '#c03', '#6c6', '#696', '#993', '#c93', '#c63', '#9c9');
  my $i_color = int(rand($#colors)); # randomize first color
  sub next_color { $i_color++; $i_color = 0 if  $i_color > $#colors; return $colors[$i_color] }

  # colors

  my $table_of = $report; $table_of =~ s/graph_of/table_of/;
  my $show_table = ($report =~ s/table_of/graph_of/);

  my $dic = $cfg->dic();

  my $menu = search_menu({ active => $report, total => scalar keys $records });

  my $sql = $cfg->connect();

  my $recs = join(',',keys %$records); my $list = {};

  my $item = ''; my $cmd = ''; my $kingdom = '';
 
# defining the SQL command based on the object of the graph

  my $sort = $order_by eq 'item' ? '1 asc' : '2 desc';
  if ($report =~ /graph_of_(habit|eventtime|interaction)/)
  { $item = $1;
    $cmd = <<EOM;
select	$item,count(1)
from	record
where	id in ($recs)
group by 1
order by $sort
EOM
  }
  elsif ($report =~ /graph_of_months/)
  { $item = 'month';
    $cmd = <<EOM;
select	substr(eventdate,4,2) as month,count(1)
from	record
where	id in ($recs)
group by 1
order by $sort
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
order by $sort
EOM
  }

  my %p = $sql->query($cmd);
  my $np = $sql->nRecords;
  print STDERR $sql->message() if $sql->error;

  my $total = 0;
  foreach (0..$np-1) { $total += $p{$_}{'count'} }

  my $label_ni = ''; my $label_nda = ''; my $labels = '';
  my $data_ni  = ''; my $data_nda  = ''; my $data = '';

  my %labels = (); my %data = (); my %per = (); my %bg_color = (); my %border_color = ();

# -------------------------------------------------------------------------------------------
  if ($item eq 'eventtime')	# graph_of_eventtime
  { my %d = ();
    foreach (0..$np-1)
    { $d{$p{$_}{$item}} = $p{$_}{'count'} }

    for (my $i=0;$i<=22;$i+=2)
    { my $tag = sprintf('%02d a %02d',$i,$i+2);
      my $key = sprintf('%02d%02d',$i,$i+2);

      $labels{$i}	= $tag;
      $data{$i}		= $d{$key} || 0;
      $bg_color{$i}	= next_color();
      $per{$i}		= int(($d{$key}/$total)*100);
    }
  }
# -------------------------------------------------------------------------------------------
  elsif ($item eq 'month')	# graph_of_months
  { my %d = ();
    foreach (0..$np-1) { $d{$p{$_}{$item}+0} = $p{$_}{'count'} }

    foreach my $i (1..12)
    { my $tag = $cfg->{'month'}[$i];
      $labels{$i}	= $tag;
      $data{$i}		= $d{$i} || 0;
      $bg_color{$i}	= next_color();
      $per{$i} 		= int(($d{$i}/$total)*100);
    }
  }
# -------------------------------------------------------------------------------------------
  elsif ($report =~ /_family$/ && !$show_table)
  { my $limit = 14;	# máximum number of bars to display + NI & NDA
    foreach (0..$np-1)
    { $p{$_}{$item} = 'not_informed' if !$p{$_}{$item};

      my $label = $dic->{$p{$_}{$item}} || $p{$_}{$item};

      if ($p{$_}{$item} eq 'not_informed')
      {	$labels{$np+1}	= $dic->{'not_informed_graph'};
	$data{$np+1}	= $p{$_}{'count'} || 0;
	$bg_color{$np+1}= '#ddd';
        $per{$np+1}	= int(($p{$_}{'count'}/$total)*100);
      }
      elsif ($_ > $limit)
      { $labels{$np}	 = $dic->{'others'};
	$data{$np}	+= $p{$_}{'count'} || 0;
	$bg_color{$np}	 = '#ccc';
        $per{$np}	 = int(($data{$np}/$total)*100);
      }
      else
      { $labels{$_}	= $label;
	$data{$_}	= $p{$_}{'count'} || 0;
	$bg_color{$_}	= next_color();
        $per{$_}	= int(($p{$_}{'count'}/$total)*100);
      }
    }
  }
# -------------------------------------------------------------------------------------------
  else
  { foreach (0..$np-1)
    { $p{$_}{$item} = 'not_informed' if !$p{$_}{$item};

      my $label = $dic->{$p{$_}{$item}} || $p{$_}{$item};

      if ($p{$_}{$item} eq 'nda')
      { $labels{$np}	= $dic->{'nda_graph'};
	$data{$np}	= $p{$_}{'count'} || 0;
	$bg_color{$np}	= '#ccc';
        $per{$np}	= int(($p{$_}{'count'}/$total)*100);
      }
      elsif ($p{$_}{$item} eq 'not_informed')
      {	$labels{$np+1}	= $dic->{'not_informed_graph'};
	$data{$np+1}	= $p{$_}{'count'} || 0;
	$bg_color{$np+1}= '#ddd';
        $per{$np+1}	= int(($p{$_}{'count'}/$total)*100);
      }
      else
      { $labels{$_}	= $label;
	$data{$_}	= $p{$_}{'count'} || 0;
	$bg_color{$_}	= next_color();
        $per{$_}	= int(($p{$_}{'count'}/$total)*100);
      }
    }
  }

  print <<EOM;
<div id='divMain'>
<blockquote>
$menu
<table class='w100'>
<tr><td id="container" class="w90">
EOM

  if ($show_table)	# ===================================== TABLE
  { print <<EOM;
<h2>$dic->{$report.'_title'}</h2>
	<blockquote>
	<table class='w60' cellpadding='5px'>
	<tr><th></th>
	    <th class='tableHeadBorder'>qtd</th>
	    <th class='tableHeadBorder'>%</th>
	</tr>
EOM
    foreach my $i (sort { $a <=> $b } keys %data)
    { print <<EOM;
	<tr><td class='tableBodyBorder bold'>$labels{$i}</td>
	    <td class='tableBodyBorder centro'>$data{$i}</td>
	    <td class='tableBodyBorder centro'>$per{$i}%</td>
	</tr>
EOM
    }
    print "</table></blockquote></td>";
  }
  else 	# ===================================== GRAPH
  { my %graph = ();

    foreach (sort { $a <=> $b } keys %data)	{ $graph{'data'}  .= "$data{$_}," }
    foreach (sort { $a <=> $b } keys %labels)	{ $graph{'label'} .= "'$labels{$_}'," }
    foreach (sort { $a <=> $b } keys %per)	{ $graph{'per'}   .= "'$per{$_}'," }

    $graph{'data'} =~ s/,$//;	$graph{'data'}  = "[$graph{'data'}]";
    $graph{'label'} =~ s/,$//;	$graph{'label'} = "[$graph{'label'}]";
    $graph{'per'} =~ s/,$//;	$graph{'per'}   = "[$graph{'per'}]";

    # radar graphs use a single color
    if ($graph_type eq 'radar')
    { my $c = int(rand(3));
      $graph{'bg_color'}     = ('rgba(204,  0, 51,0.5)','rgba(102,153,102,0.5)', 'rgba(204,153, 51,0.5)')[$c];
      $graph{'border_color'} = ('rgba(204,  0, 51,0.5)','rgba(102,153,102,0.5)', 'rgba(204,153, 51,0.5)')[$c];

      $graph{'bg_color'}     = "'$graph{'bg_color'}'";
      $graph{'border_color'} = "'$graph{'border_color'}'";
    }
    else
    { foreach (sort { $a <=> $b } keys %bg_color) { $graph{'bg_color'} .= "'$bg_color{$_}'," }
      $graph{'bg_color'} =~ s/,$//; $graph{'bg_color'} = "[$graph{'bg_color'}]";

      $graph{'border_color'} = $graph{'bg_color'};
    }

# labels nos eixos

    $graph{'plugin'} = 0; $graph{'plugin_color'} = '#fff'; $graph{'legend_display'} = 'false';

    if ($graph_type eq 'bar')
    { $graph{'xAxes'} = 'display: false';
      $graph{'yAxes'} = 'ticks: { min: 0 }, gridLines: { display: false }';
      $graph{'plugin'} = 1;
      $graph{'plugin_color'} = '#222';
    }
    elsif ($graph_type eq 'horizontalBar')
    { $graph{'xAxes'} = $graph{'yAxes'} = 'ticks: { min: 0 }, gridLines: { display: false }';
      $graph{'plugin'} = 0;
    }
    elsif ($graph_type =~ /^doughnut|pie|polarArea$/)
    { $graph{'xAxes'} = $graph{'yAxes'} = 'display: false';
      $graph{'plugin'} = 1;
      $graph{'plugin_color'} = '#fff';
      $graph{'border_color'} = '[]';
      $graph{'legend_display'} = 'true';
    }
    elsif ($graph_type eq 'radar')
    { $graph{'xAxes'} = $graph{'yAxes'} = 'display: false';
      $graph{'plugin'} = 0;
    }
    else
    { $graph{'xAxes'} = $graph{'yAxes'} = 'ticks: { min: 0 }, gridLines: { display: false }';
    }

    print <<EOM;
	<canvas id="canvas" style='border: 0px solid #eee'></canvas>
EOM

  print <<EOM;
        <script>
		var ctx = document.getElementById('canvas').getContext('2d');

                var barChartData =
			{ labels: $graph{'label'},
                          datasets: [
				{ label: '$dic->{$report}',
				  backgroundColor: $graph{'bg_color'},
				  borderColor: $graph{'border_color'},
				  borderWidth: 1,
				  data: $graph{'data'},
				  labels: $graph{'label'},
				  per: $graph{'per'}
				} ]

                	};
                var chartOptions = { responsive: true,
                                     legend: { display: $graph{'legend_display'}, position: 'bottom' },
                                     title: { display: true, text: '$dic->{$report.'_title'}', padding: 30, fontFamily: 'Helvetica', fontStyle: 'bold', fontSize: 14, fontColor: '$cfg->{'palette_color'}{'--title-h2'}' },
				     scales: { xAxes: [{ $graph{'xAxes'} }], yAxes: [{ $graph{'yAxes'} }] }
                                   };
EOM

  if ($graph{'plugin'})
  { print <<EOM;
// Define a plugin to provide data labels
		Chart.plugins.register({
			afterDatasetsDraw: function(chart) {
				var ctx = chart.ctx;

				chart.data.datasets.forEach(function(dataset, i) {
					var meta = chart.getDatasetMeta(i);
					if (!meta.hidden) {
						meta.data.forEach(function(element, index) {
							// Draw the text in black, with the specified font
							ctx.fillStyle = '$graph{'plugin_color'}';

							var fontSize = 12;
							var fontStyle = 'normal';
							var fontFamily = 'Arial';
							ctx.font = Chart.helpers.fontString(fontSize, fontStyle, fontFamily);

							// Just naively convert to string for now
EOM
    if ($graph_type =~ /pie|doughnut/)
    { print <<EOM;
		var dataString = dataset.per[index].toString() + '%';
EOM
    }
    else
    { print <<EOM;
		var dataString = dataset.labels[index].toString();
EOM
    }
    print <<EOM;

							// Make sure alignment settings are correct
							ctx.textAlign = 'center';
							ctx.textBaseline = 'middle';

							var padding = 5;
							var position = element.tooltipPosition();
							ctx.fillText(dataString, position.x, position.y - (fontSize / 2) - padding);
						});
					}
				});
			}
		});
EOM
  }

  print <<EOM;

                window.onload = function() {
                        window.myBar = new Chart(ctx, {
                                type: '$graph_type',
                                data: barChartData,
                                options: chartOptions 
                        });

                };
        </script>
</td>
EOM
  }

  print <<EOM;
<td class='w10' style='vertical-align: middle; text-align: center'>
<a href="javascript:submitSearchForm({ report: '$report', graph_type: 'bar' })"><img src='/imgs/chart_icons/bar.png'				width='30px' height='30px'/></a><br/>
<a href="javascript:submitSearchForm({ report: '$report', graph_type: 'doughnut' })"><img src='/imgs/chart_icons/doughnuts.png'		width='30px' height='30px'/></a><br/>
<a href="javascript:submitSearchForm({ report: '$report', graph_type: 'horizontalBar' })"><img src='/imgs/chart_icons/horizontalbar.png'	width='30px' height='30px'/></a><br/>
<a href="javascript:submitSearchForm({ report: '$report', graph_type: 'pie' })"><img src='/imgs/chart_icons/pie.png'				width='30px' height='30px'/></a><br/>
EOM

  if ($report =~ /graph_of_(eventtime|months)/)
  { print <<EOM;
<a href="javascript:submitSearchForm({ report: '$report', graph_type: 'polarArea' })"><img src='/imgs/chart_icons/polarArea.png'		width='30px' height='30px'/></a><br/>
<a href="javascript:submitSearchForm({ report: '$report', graph_type: 'radar' })"><img src='/imgs/chart_icons/radar.png'			width='30px' height='30px'/></a><br/>
EOM
  }

  print <<EOM;
<br/><br/><br/>
EOM
  if ($report =~ /graph_of_(animal|plant)_family/ && $show_table)
  { if ($order_by eq 'item')
    { print <<EOM;
<a href="javascript:submitSearchForm({ report: '$table_of', graph_type: '$graph_type', order_by: 'count' })"><img src='/imgs/chart_icons/sort_1_9.png'		width='20px'/></a><p/>
EOM
    }
    else
    { print <<EOM;
<a href="javascript:submitSearchForm({ report: '$table_of', graph_type: '$graph_type', order_by: 'item' })"><img src='/imgs/chart_icons/sort_a_z.png'		width='20px'/></a><p/>
EOM
    }
  }
  print <<EOM;
<a href="javascript:submitSearchForm({ report: '$table_of', graph_type: '$graph_type', order_by: '$order_by' })"><img src='/imgs/chart_icons/table.png'		width='30px' height='30px'/></a><p/>
</td></tr>
</table>
EOM

  print $cfg->html_foot();
}
1;
