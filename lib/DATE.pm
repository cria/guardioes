package DATE;
require Exporter;

our @ISA        = qw(Exporter);
our @EXPORT     = qw(DATE_format
		     DATE_isdate
		     DATE_bound
                     DATE_month
		     DATE_week
                     DATE_time
                    );
our @EXPORT_OK  = ();
our $VERSION    = 1.00;
our $DATE       = '18/01/2001';

# use DATE qw(DATE_format DATE_isdate DATE_month DATE_week DATE_time)

#require "timelocal.pl";

#========================================================================
sub DATE_time
#========================================================================
{ return time }

#========================================================================
sub DATE_format
#========================================================================
# ROTINA DE FORMATACAO DE DATA E HORA
#
# Uso: $var = DATE_format([time],[format],[language]);
#
# format : hh     - hora
#          mm     - minutos
#          ss     - segundos
#          DD     - dia
#          MM     - mes (numerico)
#          MMM    - mes (alfabetico abreviado (ex. Fev))
#          MMMM   - mes (alfabetico completo)
#          YY     - ano (dois digitos)
#          YYYY   - ano (quatro digitos)
#          WW     - dia da semana (um digito: 0 = Dom);
#          WWW    - dia da semana (alfabetico abreviado (ex. Mon))
#          WWWW   - dia da semana (alfabetico completo)
# language: pt, en
#
#          exemplo: 'DD de MMMM de YYYY. hh horas e mm minutos.' 
#------------------------------------------------------------------------
{ my $time = $_[0] || DATE_time();
  my $pic  = $_[1] || 'DD/MM/YY';
  my $lang = lc $_[2] || 'pt';

  my ($sec,$min,$hour,$day,$imon,$syear,$wday,$yday,$isdst) = localtime($time);

  my $mon = $imon+1;

  $mon  = sprintf('%02d',$mon);
  $day  = sprintf('%02d',$day);
  $hour = sprintf('%02d',$hour);
  $min  = sprintf('%02d',$min);
  $sec  = sprintf('%02d',$sec);

  my $year = $syear + 1900;
  $syear -= 100 if $syear > 99; 
  $syear = sprintf('%02d',$syear);

  if ($lang eq 'en')
  { my $tmp =(Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday)[$wday];
    $pic =~ s/WWWW/$tmp/;
    $tmp = (Sun,Mon,Tue,Wed,Thu,Fri,Sat)[$wday];
    $pic =~ s/WWW/$tmp/;

    $tmp = (January,February,March,April,May,June,July,August,September,October,November,December)[$imon];
    $pic =~ s/MMMM/$tmp/;
    $tmp = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$imon];
    $pic =~ s/MMM/$tmp/;

  }
  else
  { my $tmp = ('Domingo','Segunda','Ter&ccedil;a','Quarta','Quinta','Sexta','S&aacute;bado')[$wday];
    $pic =~ s/WWWW/$tmp/;
    $tmp = (Dom,Seg,Ter,Qua,Qui,Sex,Sab)[$wday];
    $pic =~ s/WWW/$tmp/;

    $tmp = (Janeiro,Fevereiro,'Mar&ccedil;o',Abril,Maio,Junho,
               Julho,Agosto,Setembro,Outubro,Novembro,Dezembro)[$imon];
    $pic =~ s/MMMM/$tmp/;
    $tmp = (Jan,Fev,Mar,Abr,Mai,Jun,Jul,Ago,Set,Out,Nov,Dez)[$imon];
    $pic =~ s/MMM/$tmp/;
  }
  $pic =~ s/MM/$mon/;
  $pic =~ s/WW/$wday/;
  $pic =~ s/YYYY/$year/;
  $pic =~ s/YY/$syear/;
  $pic =~ s/DD/$day/;
  $pic =~ s/hh/$hour/;
  $pic =~ s/mm/$min/;
  $pic =~ s/ss/$sec/;

  return $pic;
}

#========================================================================
sub DATE_isdate
#========================================================================
# ROTINA DE FORMATACAO DE DATA E HORA
#
# Uso: if ( DATE_isdate(date,format,[language])) { ... } 
#
# format : DD     - dia
#          MM     - mes (numerico)
#          MMM    - mes (alfabetico abreviado (ex. Fev))
#          YY     - ano (dois digitos)
#          YYYY   - ano (quatro digitos)
# language: pt, en
#
#          exemplo: 'DD de MMMM de YYYY. hh horas e mm minutos.' 
# Exemplo: if ( DATE_isdate('27-Fev-2000','DD/MMM/YYYY',pt)) { ... } 
#------------------------------------------------------------------------
#
#      ATENCAO! Cuidado ao usar a saida para o DATE_format para anos
#               menores que 01/01/1970 pois o time nao entende...
#
# quarto parametro adicionado em 27/02/2007 para permitir o retorno do time no inicio ou final do dia.
# valor: 'begin' | 'end'. Default 'begin'
#
{ my $date = $_[0];	return () if !$date;
  my $pic  = uc $_[1];	return () if !$pic;
  my $lang = lc $_[2];	$lang = 'pt' if !$lang;

  my $sec = my $min = my $hour = 0;
  if ($_[3] =~ /end/i) { $sec = 59; $min = 59; $hour = 23 }

  my $i = my $mon  = my $day  = my $year = 0;

     if (($i = index($pic,'YYYY')) != -1) { $year = substr($date,$i,4) }
  elsif (($i = index($pic,'YY'))   != -1) { $year = substr($date,$i,2) + 1900 }

  return () if $year < 1900;
  
  if (($i = index($pic,'MMM')) != -1)
  { $mon = lc substr($date,$i,3);
    
    my %tmp = ();
    %tmp = ('jan',1,'feb',2,'mar',3,'apr',4,'may',5,'jun',6,
            'jul',7,'aug',8,'sep',9,'oct',10,'nov',11,'dec',12) if $lang eq 'en';
    %tmp = ('jan',1,'fev',2,'mar',3,'abr',4,'mai',5,'jun',6,
            'jul',7,'ago',8,'set',9,'out',10,'nov',11,'dez',12) if $lang eq 'pt';

    $mon = $tmp{$mon};
  }
  elsif (($i = index($pic,'MM'))   != -1) { $mon = substr($date,$i,2) }

  return () if $mon < 1 || $mon > 12;

  if (($i = index($pic,'DD')) != -1) { $day = substr($date,$i,2) }

  return () if $day < 1 || $day > 31;

  if ($year > 1581)
  { if ($mon == 1 || $mon == 3  || $mon == 5  || $mon == 7 ||
        $mon == 8 || $mon == 10 || $mon == 12)
    { if ($day >= 1  &&  $day <= 31)
      { return ($day,$mon,$year,timelocal($sec,$min,$hour,$day,$mon-1,$year-1900)) }
    }
    else
    { if ($mon == 4 || $mon == 6 || $mon == 9 || $mon == 11)
      { if ($day >= 1  &&  $day <= 30)
        { return ($day,$mon,$year,timelocal($sec,$min,$hour,$day,$mon-1,$year-1900)) }
      }
      else
      { if ($mon == 2)
        { if ((($year  % 4) == 0) && ((($year % 100) != 0)) || (($year % 400) == 0) )
          { if ($day >= 1 && $day <= 29)
            { return ($day,$mon,$year,timelocal($sec,$min,$hour,$day,$mon-1,$year-1900))}}
          else
          { if ($day >= 1 && $day <= 28)
            { return ($day,$mon,$year,timelocal($sec,$min,$hour,$day,$mon-1,$year-1900))}}
        }
      }
    }
  }
  return ()
}

#========================================================================
sub DATE_bound  # (mes,ano)
#========================================================================
{ my $mes = $_[0]-1;
  my $ano = $_[1];
  
  $ano -= 1900 if $ano > 1900;
  $ano +=  100 if $ano < 50;

  my $start = timelocal(0,0,0,1,$mes,$ano);
  my $stop  = timelocal(0,0,0,28,$mes,$ano);

  do
  { $stop += 86400 }
  until (localtime($stop))[4] != $mes;

  return ($start,$stop-1);
}

#========================================================================
sub DATE_month # ( month, [format], [language])
#========================================================================
{ my $mon  = $_[0]; return if !$mon;
  my $pic  = uc $_[1]; $pic = 'MMM' if !$pic;
  my $lang = lc $_[2]; $lang = 'pt' if !$lang;
  my @tmp = ();

  if ($lang eq 'pt')
  { if ($pic eq 'MMMM')
    { @tmp = ('Janeiro','Fevereiro','Mar&ccedil;o','Abril',
              'Maio','Junho','Julho','Agosto','Setembro',
              'Outubro','Novembro','Dezembro');
    }
    else
    { @tmp = ('Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez') }
  }
  elsif ($lang eq 'en')
  { if ($pic eq 'MMMM')
    { @tmp = ('January','February','March','April','May','June',
              'July','August','September','October','November','December');
    }
    else
    { @tmp = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec') }
  }
  return $tmp[$mon-1];
}
#========================================================================
sub DATE_week # ( week, [format], [language]) 0 = domingo
#========================================================================
{ my $wk   = $_[0]; return if !$wk;
  my $pic  = uc $_[1]; $pic = 'MMM' if !$pic;
  my $lang = lc $_[2]; $lang = 'pt' if !$lang;
  my @tmp = ();

  if ($lang eq 'pt')
  { if ($pic eq 'WWWW')
    { @tmp = ('Domingo','Segunda','Ter&ccedil;a','Quarta',
              'Quinta','Sexta','S&aacute;bado');
    }
    else
    { @tmp = ('Dom','Seg','Ter','Qua','Qui','Sex','Sab') }
  }
  elsif ($lang eq 'en')
  { if ($pic eq 'WWWW')
    { @tmp = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday') }
    else
    { @tmp = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat') }
  }
  return $tmp[$wk];
}

1;
