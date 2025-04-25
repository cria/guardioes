#===============================================================
sub download_records
{ my ($cfg,$records) = @_;
  my $dic = $cfg->dic();

  #----------------------------------
  sub cleanXLS
  { my $st = shift;
    $st =~ s/\s+/ /g;
    $st =~ s/\\+//g;
    Encode::_utf8_on($st);
   return $st;
  }
  #----------------------------------

  my $menu = search_menu({ active => 'download_records', total => scalar keys %{$records} });
  print <<EOM;
<div id='divMain'>
<blockquote>
$menu
<h3>$dic->{'download_records'}</h3>
EOM

  my $fn = "excel_".time()."_".$$.".xlsx";
  my $workbook = Excel::Writer::XLSX->new("$cfg->{'home_dir'}/html/tmp/$fn");
  $workbook->set_optimization();

  my $worksheet = $workbook->add_worksheet(cleanXLS('Guardiões'));

  my $head = $workbook->add_format( bold => 1, bg_color => '#f0f0f0' );

  my $col = -1; my $row = 0;
  foreach my $fld (qw (	eventID
			animal:order animal:family animal:genus animal:scientificName animal:commonName animal:identifiedBy animal:dateIdentified
			plant:family plant:genus plant:scientificName plant:commonName plant:identifiedBy plant:dateIdentified
			eventDate eventTime
			country stateProvince municipality locality
			decimalLatitude decimalLongitude minimumElevationInMeters
			eventRemarks ))
  { $worksheet->write_string($row,++$col,(cleanXLS($fld) || ''),$head) }


  foreach my $record_id (keys %{$records})
  { $row++; $col = -1;

    my $rec = $cfg->get_record($record_id,1); # last parameter here is to ask for single (last) identification only

    $worksheet->write_string($row,++$col,cleanXLS("$cfg->{'home_url'}/".$cfg->format_record_id($rec->{'id'})) || '');

    if ($#{$rec->{'ident'}} > -1)
    { foreach my $ident (@{$rec->{'ident'}})
      { if ($ident->{'identifiedby_id'})
 	{ my $u = $cfg->get_user_info({ user_id => $ident->{'identifiedby_id'} });
	  $ident->{'identifiedby'} = $u->{'name'};
	}

	if ($ident->{'kingdom'} eq 'animalia')
        { $col = 0;
  	  foreach my $fld (qw (	order family genus scientificname vernacularname identifiedby dateidentified ))
	  { $worksheet->write_string($row,++$col,cleanXLS($ident->{$fld}) || '') }
	}
	else
        { $col = 7;
  	  foreach my $fld (qw (	family genus scientificname vernacularname identifiedby dateidentified ))
	  { $worksheet->write_string($row,++$col,cleanXLS($ident->{$fld}) || '') }
	}
      }
    }

    if ($rec->{'eventtime'} =~ /(\d\d)(\d\d)/) { $rec->{'eventtime'} = "$1:00 - $2:00" }

    $col = 13;
    foreach my $fld (qw ( eventdate eventtime
			  country stateprovince municipality locality
			  decimallatitude decimallongitude elevation
			  eventremarks ))
    { $worksheet->write_string($row,++$col,cleanXLS($rec->{$fld}) || '') }
  }
  $workbook->close();

  print <<EOM;
<a href='$cfg->{'home_url'}/html/tmp/$fn'><img src='/imgs/download_records.png' height='32px' hspace='10px'/></a>
$dic->{'clickToDownload'}
EOM

  print $cfg->html_foot();
}
1;
