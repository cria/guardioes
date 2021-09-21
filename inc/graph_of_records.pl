use strict;
#======================================================================
sub graph_of_records
{ my ($cfg,$records,$report) = @_;
  my $dic = $cfg->dic();

  my $menu = search_menu({ active => $report, total => scalar keys $records });

  my $caption = $dic->{$report.'_title'};

  print <<EOM;
<div id='divMain'>
<blockquote>
$menu
EOM

  my $sql = $cfg->connect();

  my $recs = join(',',keys %$records); my $list = {};

  my @colors = ('#4d4d4d', '#5da5da', '#faa43a', '#60bd68', '#f17cb0', '#b2912f', '#b276b2', '#decf3f', '#f15854');

  my $item = ''; my $cmd = ''; my $kingdom = '';
 
  my $graph_type = $report =~ /graph_of_eventtime/ ? 'radar' :
		   $report =~ /graph_of_(plant|animal)_family/ ? 'bar' : 'horizontalBar';

# defining the SQL command based on the object of the graph

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

  my $bg = ''; my $bg_not_informed = ''; my $bg_nda = ''; my $fg = ''; my $k = int(rand($#colors));

  my $scales ='ticks: { min: 0 }, gridLines: { display: false }';

  if ($item eq 'eventtime')
  { my %d = ();
    foreach (0..$np-1)
    { $d{$p{$_}{$item}} = $p{$_}{'count'} }

    for (my $i=0;$i<=22;$i+=2)
    { my $tag = sprintf('%02d a %02d',$i,$i+2);
      my $key = sprintf('%02d%02d',$i,$i+2);
      $labels .= "'$tag', ";
      $data .= $d{$key} ? "$d{$key}, " : '0, ';
    }
    $scales = 'display: false';
  }
  else
  { foreach (0..$np-1)
    { $p{$_}{$item} = 'not_informed' if !$p{$_}{$item};

      my $label = $dic->{$p{$_}{$item}} || $p{$_}{$item};

      if ($p{$_}{$item} eq 'not_informed') { $not_informed_label = "'$label', "; $not_informed_data = "$p{$_}{'count'}, "; $bg_not_informed .= "'#eee', " }
  
      elsif ($p{$_}{$item} eq 'nda')	 { $nda_label = "'$label', "; $nda_data = "$p{$_}{'count'}, " ; $bg_nda .= "'#ccc', "}

      else				 { $labels .= "'$label', "; $data .= "$p{$_}{'count'}, "; $k++; $k = 0 if  $k > $#colors; $bg .= "'$colors[$k]', " }
    }
  }

  $labels .= $nda_label.$not_informed_label;
  $data .= $nda_data.$not_informed_data;

  $labels =~ s/, $//; $data =~ s/, $//;

  if ($graph_type ne 'horizontalBar')
  { # vermelho, verde escuro, mostarda
    my @fg = ('rgb(204,  0, 51)',	    'rgb(102,153,102)',      'rgb(204,153, 51)');
    my @bg = ('rgba(204,  0, 51,0.5)','rgba(102,153,102,0.5)', 'rgba(204,153, 51,0.5)');
    my $c = int(rand(3));

    $bg = "'$bg[$c]'"; $fg = "'$fg[$c]'";
  }
  else { $bg .= $bg_nda.$bg_not_informed; $bg =~ s/, $//; $bg = "[ $bg ]"; $fg = $bg; }

  print <<EOM;
<div id="container" style="width: 90%;">
                <canvas id="canvas" style='border: 0px solid #eee'></canvas>
        </div>
        <script>
                var barChartData = {
                        labels: [$labels],
                        datasets: [{
                                label: '$dic->{'observations'}',
                                backgroundColor: $bg,
                                borderColor: $fg,
                                borderWidth: 1,
                                data: [ $data]
                        } ]

                };
                var chartOptions = {	responsive: true,
                                        legend: { display: false,
                                                position: 'bottom',
                                        },
                                        title: { display: true,
                                                text: '$dic->{$report.'_title'}',
						padding: 30,
						fontFamily: 'Helvetica',
						fontStyle: 'bold',
						fontSize: 16,
						fontColor: '$cfg->{'palette_color'}{'--title-h2'}'
                                               },
					scales: {
						xAxes: [{ $scales }],
						yAxes: [{ $scales }]
					}
                                  };

                window.onload = function() {
                        var ctx = document.getElementById('canvas').getContext('2d');
                        window.myBar = new Chart(ctx, {
                                type: '$graph_type',
                                data: barChartData,
                                options: chartOptions 
                        });

                };
        </script>

EOM

  print $cfg->html_foot();
}
1;
