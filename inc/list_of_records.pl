#==========================================================================
sub list_of_records
{ my ($cfg, $records,$offset) = @_;
  my $dic = $cfg->dic();
  my $par = $cfg->parameters();
  my $user = $cfg->get_user_info();

  my $work_mode = $par->{'mode'} eq 'work';

  print "<div id='divMain'><center>".search_menu({ active => 'list_of_records', offset => $offset, total => scalar keys $records } ) if ! $par->{'ajax'};

  # RECORDS LOOP START
  my $nrec = -1;
  foreach my $record_id (reverse sort { $a <=> $b } keys %{$records})
  { $nrec++;
    next if $nrec < $offset;
    last if $nrec >= $offset + $cfg->{'records_per_page'};

    print "<div id='divRec$record_id'>" if ! $par->{'ajax'};
    print "<TABLE cellpadding='0px' cellspacing='0px' border='0' class='noBorder w90 bgLightGray'>\n";
    my $data = $cfg->get_record($record_id,!$work_mode);

    my $gap = $data->{'relation_strength'} ?
	"<img src='/imgs/transp.png' style='width: $data->{'relation_strength'}px; height: 120px; padding: 0px 0px 0px 0px; margin: 0px 0px 0px 0px; border: 0px 0px 0px 0px;'/>" : '';

    my $fid = $cfg->format_record_id($data->{'id'});

    print "<TR><TD class='recordMarker'>&#160;</TD><TD colspan='4' class='esquerda recordHeadBorder pad5'><a class='ids' id='REC$data->{'id'}' href='/$fid'>$fid</a>";

    if ($work_mode && (($user->{'user_id'} == $data->{'user_id'} && $data->{'can_be_deleted'}) || $user->{'user_level'} > 3))
    { print <<EOM;
&#160;<a href='javascript:deleteRecord($record_id)' class='action'>$dic->{'record_delete'}</a>
EOM
    }

    if ($cfg->{'user_level'} > 1 || $cfg->{'user_id'} == $data->{'user_id'}) # security issues
    { if ($par->{'mode'} eq 'work')
      { print "<span style='float: right'><a href='javascript:doneRecord($record_id)' class='action'>$dic->{'done'}</a></span>";
        print "<br/><br/><span style='float: right'><a href='javascript:openNotifyForm($record_id)' class='action'>$dic->{'notify'}</a></span>" if $cfg->{'user_level'} > 1;
      }
      else
      { print "<span style='float: right'><a href='javascript:editRecord($record_id)' class='action'>$dic->{'edit'}</a></span>" }
    }

    print "<br/>";
    print $cfg->format_record($data);
    print "</TD></TR>\n";

#interaction
    print <<EOM;
<TR><TD class='recordMarkerTransp'></TD><TD colspan='2' class='w50 direita recordHeadBorderLeft recordHeadBorderBottom' style='font-size: 0.9em'>$dic->{'tag_interaction'}: <b class='interaction'>
EOM
#    if ($work_mode && ($cfg->{'user_level'} > 1 || $cfg->{'user_id'} == $data->{'user_id'}))
    if ($work_mode && (($user->{'category'} eq 'especialista') || ($cfg->{'user_id'} == $data->{'user_id'})))
    { print "<select onChange=changeInteraction($record_id,this[this.selectedIndex].value)>";
      print "<option value=''/>";
      my ($interaction) = $cfg->interaction();
      foreach (sort { $interaction->{$a} <=> $interaction->{$b} } keys %$interaction)
      { my $sel = $_ eq $data->{'interaction'} ? " selected='true'" : '';
        print <<EOM;
<option value='$_'$sel>$dic->{$_}</option>
EOM
      }
      print "</select><br/>";
    }
    else
    { print "$dic->{$data->{'interaction'}}<br/>" if $data->{'interaction'} ne 'nda' }


    print "</b></TD><TD colspan='2' class='w50 esquerda recordHeadBorderRight recordHeadBorderBottom'>&#160;</TD></TR>\n";

# images
    my $svg = $cfg->build_svg($data->{'photo'});
    my $svg_i = join('',@{$svg->{'interacao'}}) || '&#160;';
    my $svg_p = join('',@{$svg->{'planta'}}) || '&#160;';
    my $delta = $data->{'relation_strength'}/2;
       $delta .='px';
    print <<EOM;
<TR><TD class='recordMarkerTransp'></TD>
    <TD colspan='1' style='width: calc(50% - $delta); vertical-align: middle; text-align: right' class='recordBodyBorderLeft'>$svg_i</TD>
    <TD colspan='2' style='text-align: center; width: $data->{'relation_strength'}px;'>$gap</TD>
    <TD colspan='1' style='width: calc(50% - $delta); vertical-align: middle; text-align: left' class='recordBodyBorderRight'>$svg_p</TD>
</TR>
EOM

#-----------------
#taxgrp
      my $a_text = '';
      if ($work_mode && (($user->{'category'} eq 'especialista') || ($cfg->{'user_id'} == $data->{'user_id'})))
      { $a_text .= "<select onChange=changeGroup($record_id,this[this.selectedIndex].value)>";
        my $expertise = $cfg->expertise();
        foreach (sort keys %$expertise)
        { next if $expertise->{$_}{'group'} ne 'animalia';
          my $sel = $expertise->{$_}{'key'} eq $data->{'taxgrp'} ? " selected='true'" : '';
          $a_text .= <<EOM;
<option value='$expertise->{$_}{'key'}'$sel>$dic->{$expertise->{$_}{'key'}}</option>
EOM
        }

	$a_text .= <<EOM;
	</select>
	<a id='a_ident_$data->{'id'}'
        href="javascript:showIdentForm('a_ident_$data->{'id'}',$data->{'user_id'},$record_id,'animalia')" class='action'>
        $dic->{'newIdent'}</a>&#160;<br/>
EOM
      }
      else
      { $a_text .= "$dic->{$data->{'taxgrp'}}" }
#-----------------

#habit
      my $p_text = '';
#      if ($work_mode && ($cfg->{'user_level'} > 1 || $cfg->{'user_id'} == $data->{'user_id'}))
      if ($work_mode && (($user->{'category'} eq 'especialista') || ($cfg->{'user_id'} == $data->{'user_id'})))
      { $p_text .= "<select onChange=changeHabit($record_id,this[this.selectedIndex].value)>";
        $p_text .= "<option value=''/>";
        my $habit = $cfg->habit();
        foreach (sort { $habit->{$a} <=> $habit->{$b} } keys %$habit)
        { my $sel = $_ eq $data->{'habit'} ? " selected='true'" : '';
          $p_text .= <<EOM;
<option value='$_'$sel>$dic->{$_}</option>
EOM
        }

	$p_text .= <<EOM;
	</select>
	<a id='p_ident_$data->{'id'}'
        href="javascript:showIdentForm('p_ident_$data->{'id'}',$data->{'user_id'},$record_id,'plantae')" class='action'>
        $dic->{'newIdent'}</a>&#160;<br/>
EOM

      }
      else
      { $p_text .= "$dic->{$data->{'habit'}}<br/>" if $data->{'habit'} ne 'nda' }

      print <<EOM;
<TR><TD class='recordMarkerTransp'></TD><TD class='w50 recordBodyBorderLeft recordBodyBorderBottom recordBodyBorderTop esquerda'  colspan='2' style='font-size: 0.9em'>$dic->{'animal'}: <b>$a_text</b></TD>
    <TD class='w50 recordBodyBorderRight recordBodyBorderBottom recordBodyBorderTop esquerda' colspan='2' style='font-size: 0.9em'>$dic->{'planta'}: <b>$p_text</b></TD>
</TR>
EOM
my @ident_table = ();
# -------------------------------
    if ($#{$data->{'ident'}} > -1) # se tem alguma identificação
    { my $i = -1; my $max_i = -1;

# animais
      my $cl = 'identBgCurrent'; my $arrow = '<span class="arrow">&#5125;</span>';
      foreach my $ident (@{$data->{'ident'}})
      { next if $ident->{'kingdom'} ne 'animalia';
        $cl = 'identBgFamily' if $cl && !$ident->{'scientificname'};
        $i++;
	$ident_table[0][$i] = <<EOM;
<TD class='$cl recordBodyBorderLeft recordBodyBorderBottom padIdentCell' colspan='2'>
<table id='a_idents' class='w100'>
EOM
        my $st = $cfg->format_ident($ident,$work_mode);
 	my $v1 = validated($ident,$work_mode,$record_id);
        my $v2 = validate($ident,$work_mode,$record_id);

        $ident_table[0][$i] .= "<tr><td width='1px'>$arrow</td>" if $st.$v1.$v2;
        $ident_table[0][$i] .= "<td>$st$v1</td>" if $st.$v1;
        $ident_table[0][$i] .= "<td>$v2</td>" if $v2;
        $ident_table[0][$i] .= "</tr>\n" if $st.$v1.$v2;
 	$cl = ''; $arrow = '<span class="arrow">&#5123;</span>';
        $ident_table[0][$i] .= <<EOM;
</table>
</TD>
EOM
      }
      $max_i = $i;

#plantas
      $i = -1;

      my $cl ='identBgCurrent'; my $arrow = '<span class="arrow">&#5125;</span>';
      foreach my $ident (@{$data->{'ident'}})
      { next if $ident->{'kingdom'} ne 'plantae';
        $cl = 'identBgFamily' if $cl && !$ident->{'scientificname'};
        $i++;
        $ident_table[1][$i] = <<EOM;
		<TD class='$cl recordBodyBorderRight recordBodyBorderBottom padIdentCell' colspan='2'>
<table id='p_idents' class='w100'>
EOM
        my $st = $cfg->format_ident($ident,$work_mode);
 	my $v1 = validated($ident,$work_mode,$record_id);
        my $v2 = validate($ident,$work_mode,$record_id);

        $ident_table[1][$i] .= "<tr><td width='1px'>$arrow</td>" if $st.$v1.$v2;
        $ident_table[1][$i] .= "<td>$st$v1</td>" if $st.$v1;
        $ident_table[1][$i] .= "<td>$v2</td>" if $v2;
        $ident_table[1][$i] .= "</tr>\n" if $st.$v1.$v2;
 	$cl = ''; $arrow = '<span class="arrow">&#5123;</span>';
	$ident_table[1][$i] .= <<EOM;
</table>
</TD>
EOM
      }
  
      $max_i = $i > $max_i ? $i : $max_i;
      foreach my $i (0..$max_i)
      { print $ident_table[0][$i] ? "<TR><TD class='recordMarkerTransp'></TD>$ident_table[0][$i]" :
				    "<TR><TD class='recordMarkerTransp'></TD><TD colspan='2' class='recordBodyBorderLeft recordBodyBorderBottom padIdentCell'></TD>";
        print $ident_table[1][$i] ? "$ident_table[1][$i]</TR>"	:
				    "<TD colspan='2' class='recordBodyBorderRight recordBodyBorderBottom padIdentCell'></TD></TR>";
      }
    }
    print "</TABLE>";
    return if $par->{'ajax'};

    print "</div>";
    print "<br/><br/>\n";
  }
  # RECORDS LOOP END

  print <<EOM;
</center>
EOM

  if ($cfg->current_session_id())
  { my $ucs	 = $par->{'ucs'};
    my $prj	 = $par->{'prj'};
    my $ufs	 = $par->{'ufs'};
    my $usr	 = $par->{'usr'};
    my $idf	 = $par->{'idf'};
    my $animalia = $par->{'animalia'};
    my $plantae	 = $par->{'plantae'};
    my $report	 = $par->{'report'};
    my $mode	 = $par->{'mode'};

    print <<EOM;
<div id='divIdent'>
<form name='identForm' id='identForm' method='post' enctype='multipart/form-data' action='$PRG'> 
<input type='hidden' name='action'	value='identify'/>
<input type='hidden' name='report'	value='$report'/>
<input type='hidden' name='user_id'	value=''/>
<input type='hidden' name='ident_id'	value=''/>
<input type='hidden' name='record_id'	value=''/>
<input type='hidden' name='kingdom'	value=''/>
<input type='hidden' name='taxgrp'	value=''/>
<input type='hidden' name='habit'	value=''/>
<input type='hidden' name='interaction'	value=''/>
<input type='hidden' name='ucs'		value='$ucs'/>
<input type='hidden' name='prj'		value='$prj'/>
<input type='hidden' name='ufs'		value='$ufs'/>
<input type='hidden' name='usr'		value='$usr'/>
<input type='hidden' name='idf'		value='$idf'/>
<input type='hidden' name='animalia'	value='$animalia'/>
<input type='hidden' name='plantae'	value='$plantae'/>
<input type='hidden' name='mode'	value='$mode'/>
<center>
<table class='w90'>
<tr><td colspan='2' class='mainMenuBg direita'><a href='javascript:hideIdentForm()' class='alert grande'>&#xd7;</a>&#160;&#160;</td></tr>
<tr><td colspan='2'><h3>$dic->{'new_identification_title'}</h3></td></tr>

<tr><td colspan='2'><label for='family'>$dic->{'family'}</label><br/>
        <input type='text' name='family' id='family' value='' class='w100' required='true'/>
    </td>
</tr>
<tr><td colspan='2'><label for='scientificname'>$dic->{'scientificName'}</label><br/>
        <input type='text' name='scientificname' id='scientificname' value='' class='w100'/>
    </td>
</tr>
<tr><td colspan='2'><label for='vernacularname'>$dic->{'vernacular'}</label><br/>
        <input type='text' name='vernacularname' value='' class='w100'/>
    </td>
</tr>
<tr><td colspan='2'><label for='identificationremarks'>$dic->{'notes'}</label><br/>
        <textarea name='identificationremarks' class='w100'></textarea>
    </td>
</tr>
<tr><td align='right' colspan='2'><input type='button' class='send' value='$dic->{'send'}' onClick="submitIdentForm('$PRG');"/></td></tr>
</table>
</center>
<script type='text/javascript'>
var s_s; var s_f;
</script>
</form>
</div>
EOM
  }

  print $cfg->html_foot();
}
1;
