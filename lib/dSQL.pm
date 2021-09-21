package dSQL;

#use lib "/system/CRIALIB/DICS";
use DBD::Pg;
use DATE;

init_handler();

#------------------------------------------------------------------
sub new
#------------------------------------------------------------------
{ my ($class,%param) = @_;

  my $host	= $param{'host'}	? $param{'host'}	: 'localhost';
  my $port	= $param{'port'}	? $param{'port'}	: '5432';
  my $database	= $param{'database'}	? $param{'database'}	: '';
  my $user	= $param{'user'}	? $param{'user'}	: 'postgres';
  my $logfile	= $param{'logFile'}	? $param{'logFile'}	: '';
  my $fnamecase	= $param{'fnamecase'}	? $param{'fnamecase'}	: 'lc';
  my $boolean	= $param{'boolean'}	? $param{'boolean'} 	: 'digit';
  my $debug	= $param{'debug'}	? $param{'debug'}	: '';


  my $error	= 0;
  my $message	= '';
  my $command	= '';
  my $sth;

  my $dbh = DBI->connect("dbi:Pg:host=$host;port=$port;dbname=$database",$user,$pass,
	{ PrintError => 0, # warn() on errors
          AutoCommit => 1, # commit executes immediately
          RaiseError => 0, # don't die on error
       }
) || undef;

  if (!$dbh)
  { $error   = $DBI::err;
    $message = $DBI::errstr;
    return undef;
  }

  $dbh->{'PrintError'} = 0;
  $dbh->{'AutoCommit'} = 1;
  $dbh->{'RaiseError'} = 0;

  return bless { host		=> $host,
  		 port		=> $port,
  		 database	=> $database,
  		 user		=> $user,
  		 error		=> $error,
  		 message	=> $message,
  		 command	=> $command,
  		 dbh		=> $dbh,
  		 sth		=> $sth,
  		 logFile	=> $logfile,
  		 fnamecase	=> $fnamecase,
  		 boolean	=> $boolean,
  		 debug		=> $debug,
  		 totalRecords	=> 0,
  		 nRecords	=> 0,
  		 nFields	=> 0,
		 fieldName	=> [],
		 fieldType	=> [],
		 fieldSize	=> []	}, $class;
}

#----------------------------------------------------------------
sub host	{ $_[0]->{'host'} }
sub port	{ $_[0]->{'port'} }
sub database	{ $_[0]->{'database'} }
sub error	{ $_[0]->{'error'} }
sub message	{ my $m = "$_[0]->{'message'}\n$_[0]->{'command'}"; $_[0]->reset(); return $m }
sub command	{ $_[0]->{'command'} }
sub nRecords	{ $_[0]->{'nRecords'} }
sub nFields	{ $_[0]->{'nFields'} }
sub fieldName	{ @{$_[0]->{'fieldName'}} }
sub fieldType	{ @{$_[0]->{'fieldType'}} }
sub fieldSize	{ @{$_[0]->{'fieldSize'}} }

#------------------------------------------------------------------
sub DESTROY
#------------------------------------------------------------------
{ 
  $_[0]->{'sth'}->finish if $_[0]->{'sth'};
  $_[0]->{'dbh'}->disconnect if $_[0]->{'dbh'};
  undef $_[0]->{'dbh'} if $_[0]->{'dbh'};
}

#------------------------------------------------------------------
sub printError
#------------------------------------------------------------------
{ print <<EOM;
Host    : $_[0]->{'host'}
DB      : $_[0]->{'database'}
Command : $_[0]->{'command'}
Error   : $_[0]->{'error'}
Message : $_[0]->{'message'}
EOM
  undef $_[0]->{'dbh'} if $_[0]->{'dbh'};
  exit 0;
}

#------------------------------------------------------------------
sub query
#------------------------------------------------------------------
{ $_[0]->exec(@_[1..$#_]);
  $_[0]->fetch(@_[1..$#_]);
}

#------------------------------------------------------------------
sub begin
#------------------------------------------------------------------
{ $_[0]->{'dbh'}->{AutoCommit} = 0;
  $_[0]->{'dbh'}->{RaiseError} = 0;
  $_[0]->{'error'} = 0;
  $_[0]->{'message'} = '';
}


#------------------------------------------------------------------
sub end
#------------------------------------------------------------------
{ if ($_[0]->{'dbh'}->commit)
  { $_[0]->{'dbh'}->{AutoCommit} = 1;
    $_[0]->{'dbh'}->{RaiseError} = 0;
  }
  else
  {$_[0]->{'dbh'}->rollback;
   $_[0]->{'error'} = $DBI::err;
   $_[0]->{'message'} = $DBI::errstr;
  }
}


#------------------------------------------------------------------
sub fetch
#------------------------------------------------------------------
{ my $self = shift;

  my %p = ();

  $self->{'totalRecords'}  = 0;
  $self->{'nFields'}       = $self->{'sth'}->{'NUM_OF_FIELDS'};

  $self->{'fieldName'} = $self->{'fieldType'} = $self->{'fieldSize'} = ();
  
  $self->{'fieldName'} = $self->{'sth'}->{'NAME_'.$self->{'fnamecase'}};
  $self->{'fieldType'} = $self->{'sth'}->{'TYPE'};

  my $k = -1;
  while (@x = $self->{'sth'}->fetchrow_array)
  { $k++;
    for (my $i=0;$i<$self->{'nFields'};$i++)
    { $p{$k}{$self->{'fieldName'}[$i]} = $x[$i];
      if ($self->{'fieldType'}[$i] == 16 && $self->{'boolean'} eq 'letter')
      { if ($p{$k}{$self->{'fieldName'}[$i]}) { $p{$k}{$self->{'fieldName'}[$i]} = 't' }
        else			              { $p{$k}{$self->{'fieldName'}[$i]} = 'f' }
      }
    }
  }

  $self->{'nRecords'} = $k+1;
  $self->{'sth'}->finish;
  $self->{'error'}   = $DBI::err    if !$self->{'error'};
  $self->{'message'} = $DBI::errstr if !$self->{'message'};

  return %p;
}

#------------------------------------------------------------------
sub fetch1
#------------------------------------------------------------------
{ my $self = shift;

  my %p = ();

  $self->{'totalRecords'}  = 0;
  $self->{'nFields'}       = $self->{'sth'}->{'NUM_OF_FIELDS'};

  $self->{'fieldName'} = $self->{'fieldType'} = $self->{'fieldSize'} = ();

  $self->{'fieldName'} = $self->{'sth'}->{'NAME_'.$self->{'fnamecase'}};
  $self->{'fieldType'} = $self->{'sth'}->{'TYPE'};

  if (@x = $self->{'sth'}->fetchrow_array)
  { for (my $i=0;$i<$self->{'nFields'};$i++)
    { $p{0}{$self->{'fieldName'}[$i]} = $x[$i];
      if ($self->{'fieldType'}[$i] == 16 && $self->{'boolean'} eq 'letter')
      { if ($p{0}{$self->{'fieldName'}[$i]}) { $p{0}{$self->{'fieldName'}[$i]} = 't' }
        else			             { $p{0}{$self->{'fieldName'}[$i]} = 'f' }
      }
    }
    $self->{'nRecords'} = 1;
    $self->{'error'}   = $DBI::err    if !$self->{'error'};
    $self->{'message'} = $DBI::errstr if !$self->{'message'};
  }
  else
  { $self->{'sth'}->finish;
    $self->{'nRecords'} = 0;
    $self->{'error'}   = $DBI::err    if !$self->{'error'};
    $self->{'message'} = $DBI::errstr if !$self->{'message'};
  }
  return %p;
}
#------------------------------------------------------------------
sub exec
#------------------------------------------------------------------
{ my $self = $_[0];

  $self->{'command'} = $_[1];

  $self->{'command'} =~ s/^\s+|\s+$//g;

  open(DBG,">>$self->{'debug'}") if $self->{'debug'};

  print DBG "\n\n-------------------\n" if $self->{'debug'};
  my $dbg_cmd = $self->{'command'}; $dbg_cmd =~ s/\s+/ /g;
  print DBG "SQL COMMAND:\n$dbg_cmd\n" if $self->{'debug'};
  my $time = time;

  $self->{'sth'}     = $self->{'dbh'}->prepare($self->{'command'});

  $self->{'error'}   = $DBI::err    if !$self->{'error'};
  $self->{'message'} = $DBI::errstr if !$self->{'message'};

  $self->{'sth'}->execute;

  $self->{'error'}   = $DBI::err    if !$self->{'error'};
  $self->{'message'} = $DBI::errstr if !$self->{'message'};

  $time = time - $time;
  print DBG "RESULT STATUS:\nERROR: [$self->{'error'}]\nMESSAGE: [$self->{'message'}]\n $time secs\n" if $self->{'debug'} && $self->{'error'};

  print STDERR $self->{'message'} if $self->{'error'};
}

#------------------------------------------------------------------
sub reset
#------------------------------------------------------------------
{ $_[0]->{'error'} = 0;
  $_[0]->{'message'} = '';
}

#------------------------------------------------------------------
sub init_handler 
#------------------------------------------------------------------
{ $SIG{'HUP'}  = sub { exit 0 };
  $SIG{'INT'}  = sub { exit 0 };
  $SIG{'QUIT'} = sub { exit 0 };
}

#------------------------------------------------------------------
sub next_sequence # ($sequence_name)
#------------------------------------------------------------------
{ my %nv = $_[0]->query("select nextval('$_[1]')");
  return $nv{0}{'nextval'};
}

#------------------------------------------------------------------
sub log
#------------------------------------------------------------------
{ my ($self) = @_; 
  return if !$self->{'logFile'};

  my $date = DATE_format(time,'DD/MM/YYYY hh:mm:ss');
  my $LOG;
  open($LOG,">>$self->{'logFile'}");
  print $LOG "\n", $date," $_[1] [$self->{'message'}]\n";
  close($LOG);
}
# ------------------------ LOG END
1;

