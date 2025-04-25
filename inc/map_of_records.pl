use utf8;
binmode STDOUT, ":utf8";

#====================================================
sub map_of_records
{ my ($cfg,$par) = @_;
  my $records	= $par->{'records'};
  my $ucs	= $par->{'ucs'};
  my $prj	= $par->{'prj'};
  my $ufs	= $par->{'ufs'};

  my $xml = "html/tmp/map_".time()."_".$$.".xml";
  open(OUT,">:encoding(UTF-8)","$cfg->{'home_dir'}/$xml");
  print OUT "<markers>";
  foreach my $id (keys %{$records})
  { my $data = $cfg->get_record($id,1); # single id
    my $addr  = "[$id] ";
       $addr .= "$data->{'locality'}, "		if $data->{'locality'};
       $addr .= "$data->{'municipality'}, "	if $data->{'municipality'};
       $addr .= "$data->{'stateprovince'}"	if $data->{'stateprovince'};
       $addr .= "($data->{'eventdate'})"	if $data->{'eventdate'};

    my $name = ''; my $nnames = 0;
    foreach (0..$#{$data->{'ident'}})
    { $name .= ($data->{'ident'}[$_]{'scientificname'} || $data->{'ident'}[$_]{'family'})." x ";
      $nnames++ if $data->{'ident'}[$_]{'scientificname'};
    }
    $name =~ s/ x $//;

    my $type = $nnames ? $nnames == 1 ? 'halfident' : 'ident' : 'unident';
    print OUT <<EOM;
<marker id="$id" sciname="$name" location="$addr" lat="$data->{'decimallatitude'}" lng="$data->{'decimallongitude'}" type="$type"/> 
EOM
  }
  print OUT "</markers>";
  close(OUT);

######################
# desenhando layers

# unidades de conservacao federais

  my $layers = ''; my $lat = -12.8732; my $lng = -41.3751; my $zoom = 4;

# estados do brasil

  if ($ufs)
  { $layers .= "map.data.loadGeoJson('$cfg->{'home_url'}/geojson?map_ufs+$ufs');";
    my $c = $cfg->get_centroid('map_ufs',$ufs);
    $lat = $c->{'lat'};
    $lng = $c->{'lng'};
    $zoom = 6;
  }

  if ($ucs)
  { $layers .= "map.data.loadGeoJson('$cfg->{'home_url'}/geojson?map_ucsfi+$ucs');";
    my $c = $cfg->get_centroid('map_ucsfi',$ucs);
    $lat = $c->{'lat'};
    $lng = $c->{'lng'};
    $zoom = 9;
  }

# projetos associados - sempre aparecem

  $layers .= "map.data.loadGeoJson('$cfg->{'home_url'}/geojson?map_projects+$prj');";
  if ($prj)
  { #$layers .= "map.data.loadGeoJson('$cfg->{'home_url'}/geojson?map_projects+$prj');";
    my $c = $cfg->get_centroid('map_projects',$prj);
    $lat = $c->{'lat'};
    $lng = $c->{'lng'};
    $zoom = 7;
  }


#https://developers.google.com/maps/documentation/javascript/examples/full/images/beachflag.png
#http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|00D900

  my $menu = search_menu({ active => 'map_of_records', total => scalar keys %{$records} });
  print <<EOM;
<div id='divMain' style='height: calc(100% - 180px) !important'>
$menu

<div id="search_map"></div>
<div id="search_map_legend">
<table class='w100'>
<tr><td width='21px'><img src='/imgs/pin/green.png' width='15px'/></td><td class='embaixo'>espécies identificadas</td>
    <td width='21px'><img src='/imgs/pin/yellow.png' width='15px'/></td><td class='embaixo'>apenas uma espécie identificada</td>
    <td width='21px'><img src='/imgs/pin/red.png' width='15px'/></td><td class='embaixo'>espécies não identificadas</td>
</tr>
</table>
</div>

    <script>
      var map;
var customLabel = { ident:	{ label: '', fillColor: '#0F0', image: '$cfg->{'home_url'}/imgs/pin/green.png' },
		    unident:	{ label: '', fillColor: '#F00', image: '$cfg->{'home_url'}/imgs/pin/red.png' },
		    halfident:	{ label: '', fillColor: '#FC0', image: '$cfg->{'home_url'}/imgs/pin/yellow.png' }
		  };

	function initMap()
	{ map = new google.maps.Map(document.getElementById('search_map'), { center: { lat: $lat, lng: $lng }, zoom: $zoom });

// the strokeColor of the map comes from the geojson feature color

	  map.data.setStyle(function(feature)
	  { var stroke_color = 'red';
	    if (feature.getProperty('color'))
	    { stroke_color = feature.getProperty('color'); }

	    var fill_color = 'wheat';
	    if (feature.getProperty('fillColor'))
	    { fill_color = feature.getProperty('fillColor'); }


  	    return ({ fillColor: fill_color, strokeColor: stroke_color, fillOpacity: 0.05, strokeWeight: 1.0 });
	  });

	  $layers

	  var infoWindow = new google.maps.InfoWindow;

	  downloadUrl('$cfg->{'home_url'}/$xml', function(data)
	  { var xml = data.responseXML;
	    var markers = xml.documentElement.getElementsByTagName('marker');
	    Array.prototype.forEach.call(markers, function(markerElem)
	    { var sciname = markerElem.getAttribute('sciname');
	      var location = markerElem.getAttribute('location');
	      var type = markerElem.getAttribute('type');
	      var point = new google.maps.LatLng( parseFloat(markerElem.getAttribute('lat')), parseFloat(markerElem.getAttribute('lng')));

	      var infowincontent = document.createElement('div');
	      var strong = document.createElement('strong');
	      var italic = document.createElement('i');
	      italic.textContent = sciname
	      strong.appendChild(italic);
	
	      infowincontent.appendChild(strong);
	      infowincontent.appendChild(document.createElement('br'));

	      var text = document.createElement('text');
	      text.textContent = location
	      infowincontent.appendChild(text);
	      var icon = customLabel[type] || {};
	      var marker = new google.maps.Marker({
			map: map,
			position: point,
			icon: icon.image,
			label: icon.label
		});
	      marker.addListener('click', function()
	      	{ infoWindow.setContent(infowincontent);
		  infoWindow.open(map, marker);
	        });
	    });
	  });
	}

	function downloadUrl(url, callback) {
        var request = window.ActiveXObject ?
            new ActiveXObject('Microsoft.XMLHTTP') :
            new XMLHttpRequest;

        request.onreadystatechange = function() {
          if (request.readyState == 4) {
            request.onreadystatechange = doNothing;
            callback(request, request.status);
          }
        };

        request.open('GET', url, true);
        request.send(null);
      }

      function doNothing() {}

    </script>
    <script src="https://maps.googleapis.com/maps/api/js?key=$cfg->{'google_maps_api_key'}&callback=initMap" async defer></script>
EOM
  print $cfg->html_foot();
}
1;
