package GUARDIOES;
use strict;
use utf8;
use Digest::SHA1  qw(sha1_hex);
use CFG;
use dSQL;
use PARAMETERS;
use Data::Dumper;
use Mail::Sendmail;

#===================================================================== NEW
# construtor do CFG
#=====================================================================
sub new # ({ loginRequired => 0|1 })
{ my ($class,$par) = @_;

# ================ START OF CONFIGURABLE PARAMETERS

  my $cfg = bless new CFG();

# ================ END OF CONFIGURABLE PARAMETERS

# retrieve session cookie information

  my $session_id = '';
  my $session_cookie_name = 'GuardioesSessionId';
  if ($cfg->{'home_url'} =~ /^https:\/\//)
  { 
    $session_cookie_name = ' __Host-' . $session_cookie_name;
  }

  if ($ENV{'HTTP_COOKIE'})
  { my @cookie = split(';',$ENV{'HTTP_COOKIE'});
    foreach(@cookie)
    { $_ =~ s/^\s+|\s+$//;
      my ($a,$b) = split('=');
      $session_id		= $b if $a eq $session_cookie_name        && $b;
      $cfg->{'search_string'}	= $b if $a eq 'guardioesSearchString'	  && $b;
      $cfg->{'cookie_lang'}	= $b if $a eq 'guardioesCookieLang'	  && $b;
      $cfg->{'palette_id'}	= $b if $a eq 'guardioesPalette'	  && $b;
      $cfg->{'windowWidth'}	= $b if $a eq 'guardioesWindowWidth'	  && $b;
      $cfg->{'windowHeight'}	= $b if $a eq 'guardioesWindowHeight'	  && $b;
    }
  }

  # deletes all sessions older than a month requiring a new login

  $cfg->{'sql'} = GUARDIOES::connect(bless $cfg);

  $cfg->{'sql'}->exec("delete from session where age(now(),last_seen) > '1 month'");

  # reads the palette colors to be used in perl context

  open(IN,"$cfg->{'home_dir'}/css/colors_v$cfg->{'palette_id'}.css");
  while (my $L = <IN>)
#  { if ($L =~ /\s+(\-\-[a-z0-9\-]+)\s+:\s*(#[0-9a-f]+)/i)
  { if ($L =~ /\s+(\-\-[a-z0-9\-]+)\s+:\s*([^;]+);/i)
    { $cfg->{'palette_color'}{$1} = $2 }
    elsif ($L =~ /\s+(\-\-[a-z0-9\-]+)\s+:\s+var\((\-\-[a-z0-9\-]+)\)/i)
    { $cfg->{'palette_color'}{$1} = $cfg->{'palette_color'}{$2} }
  }
  close(IN);

  # expand #xyz to #xxyyzz (makes it easier to append the opacity 00 - FF
  foreach my $c (keys %{$cfg->{'palette_color'}})
  { $cfg->{'palette_color'}{$c} = "#$1$1$2$2$3$3" if $cfg->{'palette_color'}{$c} =~ /^#([0-9a-f])([0-9a-f])([0-9a-f])$/i; }

  foreach my $c (keys %{$cfg->{'palette_color'}})
  { $cfg->{'palette_color'}{$c} = $cfg->{'palette_color'}{$1} if $cfg->{'palette_color'}{$c} =~ /var\(([^\)]+)\)/ }

  # checks if the session_id reported by the cookie is still valid

  if ($session_id)
  { my %p = $cfg->{'sql'}->query("select u.email,u.terms_guardiao,s.* from session s left join users u on s.user_id = u.id where s.session_id = E'$session_id';");
    if ($cfg->{'sql'}->nRecords)
    { $cfg->{'session_id'}	= $p{0}{'session_id'};
      $cfg->{'user_id'}		= $p{0}{'user_id'};
      $cfg->{'network'}		= $p{0}{'network'};
      $cfg->{'sql'}->exec("update session set last_seen = now() where session_id = E'$session_id';");
      $cfg->{'sql'}->exec("update users set last_seen = now() where id = $p{0}{'user_id'};");
      $p{0}{'email'} =~ s/^\s+|\s+$//g;

# nao permite ao usuário fazer nada se nao tiver um email registrado
      if (!$p{0}{'email'} && $0 !~ /\/register$/)
      { print "Location: $cfg->{'home_url'}/register\n\n" }

# nao permite ao usuário fazer nada se nao tiver assinado o termo de compromisso
      if (!$p{0}{'terms_guardiao'} && $0 !~ /\/register$/)
      { print "Location: $cfg->{'home_url'}/register\n\n" }
    }
  }

  # if the page requires a login, do not allow if not logged in
  # redirects the user to the login page instead of the requested one

  if ($par->{'loginRequired'} && !$cfg->{'session_id'})
  { print "Location: $cfg->{'home_url'}/login\n\n";
    exit 0;
  }
  #---

  $cfg->{'user_lang'} = $cfg->{'cookie_lang'} if $cfg->{'cookie_lang'};

  $cfg->{'month'} = $cfg->{'user_lang'} eq 'en' ?
			['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'] :
			['','Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];

  $cfg->{'param'} = new PARAMETERS();

  get_user_info(bless $cfg);

  $cfg->{'user_level'}	= $cfg->{$cfg->{'user_id'}}{'user_level'};
  $cfg->{'is_super'}	= $cfg->{$cfg->{'user_id'}}{'is_super'};
  $cfg->{'is_admin'}	= $cfg->{$cfg->{'user_id'}}{'is_admin'};
  $cfg->{'is_especialista'}	= $cfg->{$cfg->{'user_id'}}{'category'} eq 'especialista' && $cfg->{$cfg->{'user_id'}}{'status'} eq 'ativo' ;

  $cfg->log( { user_id => $cfg->{'user_id'}, action => $ENV{'SCRIPT_NAME'}, detail => $ENV{'REQUEST_URI'} }) if $ENV{'SCRIPT_NAME'} !~ /apisrv/;

  return bless $cfg;
}
#===================================================================== LOG
# logs the basic activity of users
# uses a specific database guardioes_log with month tables inherited 
# by a main one
# 
#=====================================================================
sub log # ({ user_id => 1, action => <script_name>, detail => whatever })
{ my ($cfg,$par) = @_;

  return if $par->{'action'} =~ /notfound/;
  my $sql = $cfg->connect_log();

  my @now = localtime(time());
  my $today = sprintf("%04d%02d%02d",$now[5]+1900,$now[4]+1,$now[3]);
  my $table = sprintf("log_%04d%02d",$now[5]+1900,$now[4]+1);

  $par->{'user_id'}	= 0 if !$par->{'user_id'};
  $par->{'action'}	=~ s/\///;
  $par->{'action'}	=~ s/'+//g;
  $par->{'detail'}	=~ s/'+//g;

  $sql->exec("insert into $table (user_id,action,detail) values ($par->{'user_id'},'$par->{'action'}','$par->{'detail'}');");
  if ($sql->error() && $sql->message() =~ /does not exist/)
  { my $ytable = sprintf("log_%04d",$now[5]+1900);
    $sql->exec("create table $ytable () inherits (log);");
    $sql->exec("create table $table () inherits ($ytable);");

    $sql->exec("insert into $table (user_id,action,detail) values ($par->{'user_id'},'$par->{'action'}','$par->{'detail'}');");
  }
}
#===================================================================== LOGOFF
# finished the user session by removing its id from the session table
#=====================================================================
sub logoff # ()
{ my ($cfg,$par) = @_;

  my $session_id = $cfg->current_session_id();

  if ($session_id)
  { my $sql = $cfg->connect();
    $sql->exec("delete from session where session_id = E'$session_id';");
    return 0 if $sql->error; # fail
  }

# cleanup $cfg->{'home_url'}/html/tmp/ dir deleting files 2 days old or older
# the choice of doing it here is just to avoid doing it all the time...
# temp files are deleted after 2 days old

  foreach my $f (glob "$cfg->{'home_dir'}/html/tmp/*")
  { if (-f $f && -M $f > 2 ) { unlink $f } }

  return 1; # success
}

#===================================================================== CONNECT
# returns an existing main database connection or creates a new one and 
# returns it
#=====================================================================
sub connect # ()
{ my ($cfg,$par) = @_;

  $cfg->{'sql'} = new dSQL(host => $cfg->{'db_host'}, user => $cfg->{'db_user'}, database => $cfg->{'db_name'}, debug => $cfg->{'debug'}) if !$cfg->{'sql'};
  return $cfg->{'sql'};
}

#===================================================================== CONNECT_LOG
# returns an existing log database connection or creates a new one and 
# returns it
#=====================================================================
sub connect_log # ()
{ my ($cfg,$par) = @_;

  $cfg->{'sql_log'} = new dSQL(host => $cfg->{'db_host'}, user => $cfg->{'db_user'}, database => $cfg->{'db_name'}.'_log', debug => $cfg->{'debug'}) if !$cfg->{'sql_log'};
  return $cfg->{'sql_log'};
}

#===================================================================== CONNECT_DIC
# returns an existing log database connection or creates a new one and 
# returns it
#=====================================================================
sub connect_dic # ()
{ my ($cfg,$par) = @_;

  $cfg->{'sql_dic'} = new dSQL(	host	 => $cfg->{'sp_dic_host'},
				user	 => $cfg->{'sp_dic_user'},
				database => $cfg->{'sp_dic_name'},
				debug	 => $cfg->{'debug'}) if !$cfg->{'sql_dic'};
  return $cfg->{'sql_dic'};
}

#===================================================================== CURRENT_USER_ID
# returns the id of the currently logged user
#=====================================================================
sub current_user_id # ()
{ my ($cfg,$par) = @_;

  return $cfg->{'user_id'};
}

#===================================================================== CURRENT_SESSION_ID
# returns the id of the current session
#=====================================================================
sub current_session_id # ()
{ my ($cfg,$par) = @_;

  return $cfg->{'session_id'};
}

#===================================================================== PARAM
# returns the object created by PARAMETERS package
#=====================================================================
sub param # ()
{ my ($cfg,$par) = @_;

  return $cfg->{'param'};
}

#===================================================================== PARAM
# returns the values retrieved by PARAMETERS package as a hash
#=====================================================================
sub parameters # ()
{ my ($cfg) = @_;

  my $par = { _method => $cfg->{'param'}->method() };
  foreach ($cfg->{'param'}->keys()) { $par->{$_} = $cfg->{'param'}->data($_) }

  return $par;
}
#===================================================================== FORMAT_DATE
# returns a formated date. The format depends on the user language.
# dd-mmm-yyy for pt, mmm dd, yyy for en
#=====================================================================
sub format_date	# ({ day => 16, month => 9, year => 1958 })
{ my ($cfg,$par) = @_;

  return $cfg->{'user_lang'} eq 'en' ?	
	sprintf("%s %02d, %04d",
		('','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$par->{'month'}],
		$par->{'day'}, $par->{'year'}) :
	sprintf("%02d-%s-%04d",$par->{'day'},
		('','jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez')[$par->{'month'}],
		$par->{'year'});
}
#===================================================================== AGE
# returns the number of years elapsed between a date and now
#=====================================================================
sub age	# ({date => '19581609'}) || ({ day => 16, month => 9, year => 1958 })
{ my ($cfg,$par) = @_;
  my @now = localtime(time());
  my $today = sprintf("%04d%02d%02d",$now[5]+1900,$now[4]+1,$now[3]);

  if ($par->{'year'})
  { $par->{'date'} = sprintf("%04d%02d%02d",$par->{'year'},$par->{'month'},$par->{'day'}) }

  return int(($today - $par->{'date'})/10000);
}
#===================================================================== FORMAT_USER_ID
# returns the user id formated as u0000000000 (u+10 digits)
#=====================================================================
sub format_user_id # (user_id)
{ return sprintf("u%010d",$_[1]) }
#===================================================================== FORMAT_RECORD_ID
# returns the record id formated as r0000000000 (r+10 digits)
#=====================================================================
sub format_record_id # (record_id)
{ return sprintf("r%010d",$_[1]) }
#===================================================================== FORMAT_IDENT_ID
# returns the ident id formated as i00000000000000000000 (i+20 digits)
#=====================================================================
sub format_ident_id # (ident_id)
{ return sprintf("i%020d",$_[1]) }
#===================================================================== GET_USER_INFO
# returns a hash with all information available about the user
# if the user_id is not provided as a parameter, the current user_id
# is used instead
# parameters are passed as hash
#=====================================================================
sub get_user_info # ( { user_id => 23 } )
{ my ($cfg,$par) = @_;

  my $user_id = $par->{'user_id'} || $cfg->current_user_id();

  return undef if !$user_id;	# user_id was not specified nor found out

  # checks if the information is already available in memory. returns it if so
  return $cfg->{$user_id} if $cfg->{$user_id};
  
  # retrieves the information from the database 
  my $sql =  $cfg->connect();
  my $cmd = "select *,unaccent(name) as uname from users where id = $user_id;";
  my %p = $sql->query($cmd);
  return undef if !$sql->nRecords;	# user_id does not exist in database

  my $user = {}; # hash to hold all info about the user

  foreach ($sql->fieldName()) { $user->{$_} = $p{0}{$_} }  # copy all db table fields to the hash

  $user->{'user_id'}  = $user->{'id'};
  $user->{'user_key'} = $cfg->format_user_id($user->{'id'});

  $user->{'user_level'} =
				$user->{'status'}	eq 'inativo'		?  0 :
				$user->{'is_super'}				? 15 :
				$user->{'is_admin'}				?  7 :
				$user->{'status'}	eq 'pendente'		?  1 :
				$user->{'category'}	eq 'especialista'	?  3 : 1;

  $user->{'nickname'} = $user->{'name'} if !$user->{'nickname'};

  # caso não haja imagem do usuário definida, copia o 'nopic' para o dir do usuário e atualiza o bd
  if (!$user->{'picture'})
  { my $f_user_id = $cfg->format_user_id($user->{'id'});
    my $picture = $f_user_id.'_'.time().'.jpg';
    system "cp $cfg->{'user_dir'}/nopic.jpg $cfg->{'user_dir'}/$f_user_id/$picture";
    $sql->exec("update users set picture = '$picture' where id = $user->{'id'}");
    $user->{'picture'} = $picture;
  }
  $user->{'picture_url'} = "$cfg->{'user_url'}/$user->{'user_key'}/$user->{'picture'}"; # if $user->{'picture'};

  if ($user->{'birthday'} =~ /(\d{4})(\d{2})(\d{2})/)
  { $user->{'birth_day'} = $3; $user->{'birth_month'} = $2; $user->{'birth_year'} = $1 }

  if ($user->{'birthday'})
  { $user->{'formatted_birthday'} = $cfg->format_date({ day => $user->{'birth_day'}, month => $user->{'birth_month'}, year => $user->{'birth_year'} });
    $user->{'age'} = $cfg->age({date => $user->{'birthday'}});
  }

  if ($user->{'since'} =~ /(\d{4})\-(\d{2})\-(\d{2})/)
  { $user->{'formatted_since'} = $cfg->format_date({ day => $3, month => $2, year => $1 }) }

  if ($user->{'last_seen'} =~ /(\d{4})\-(\d{2})\-(\d{2})/)
  { $user->{'formatted_last_seen'} = $cfg->format_date({ day => $3, month => $2, year => $1 }) }

  $cfg->{$user_id}{'user_lang'} = $p{0}{'language'};

# getting the network_ids associated with the user
# the result is a hash { google => xxxxxxx, facebook => zzzzz } stored in $user->{'netids'} 

  $cmd = "select * from netids where user_id = $user_id;";
  %p = $sql->query($cmd);

  $user->{'netids'} = {};
  foreach (0..$sql->nRecords-1)
  { $user->{'netids'}{$p{$_}{'network'}} = $p{$_}{'netid'} }

# getting the expertises associated with the user
# e.g. $user->{'expertise'}{220} = 'abelha_vespa'

  $cmd = "select * from expertises_view where user_id = $user_id;";
  %p = $sql->query($cmd);
  $user->{'expertise'} = {};
  foreach (0..$sql->nRecords-1)
  { $user->{'expertise'}{$p{$_}{'expertise_id'}} = $p{$_}{'expertise'} }

  $cfg->{$user_id} = $user; # saves data in memory for later use

  return $user;
}

#============================================
# prepares hash with user data to be used in 
# methods to update user info.
#============================================
sub prepare_user_data
{ my ($cfg,$par) = @_;
  my $data = {};
  $data->{'name'}		= $par->{'name'}; $data->{'name'} =~ s/^\s+|\s+$//g;
  $data->{'nickname'}		= $par->{'nickname'};
  $data->{'email'}		= $par->{'email'};
  $data->{'password'}		= $par->{'password'} ? crypt($par->{'password'},time()) : '';
  $data->{'gender'}		= $par->{'gender'};
  $data->{'education'}		= $par->{'education'};
  $data->{'agreement'}		= $par->{'agreement'} || 0;
#20180911  $data->{'terms_guardiao'}	= $par->{'terms_guardiao'} || 0;
  $data->{'curriculum'}		= $par->{'curriculum'};
  $data->{'comments'}		= $par->{'comments'};
  $data->{'language'}		= $par->{'language'};
  $data->{'alert_period'}	= $par->{'alert_period'};

  if ($par->{'birth_day'} && $par->{'birth_month'} && $par->{'birth_year'})
  { $data->{'birthday'} = $par->{'birth_year'} . $par->{'birth_month'} . $par->{'birth_day'};
  }
  $data->{'expertise'} = {};
  if ($par->{'expertise'} && ref($par->{'expertise'}) eq 'ARRAY')
  {
    while(my $exp_id = shift(@{$par->{'expertise'}}))
    { $data->{'expertise'}{$exp_id} = 1; 
    }
  }

  return $data;
}

#===================================================================== USERS_LIST
# returns a hash with the all info for all users
#=====================================================================
sub users_list
{ my $cfg = shift;

  my $user = $cfg->get_user_info();

  my $sql = $cfg->connect();

  my $cmd = "select id from users";
  if (!$user || $user->{'user_level'} < 7) { $cmd .= " where status != E'inativo'" }

  my %p = $sql->query($cmd);

  return undef if !$sql->nRecords;

  my $users = {};
  foreach my $i (0..$sql->nRecords-1)
  { $users->{$p{$i}{'id'}} = $cfg->get_user_info({ user_id => $p{$i}{'id'} }) }

  return $users;
}

#===================================================================== GET_FAMILIES
#=====================================================================
sub get_families
{ my ($cfg,$kingdom) = @_;

  my $sql = $cfg->connect();

  my $table = $cfg->{'user_level'} <= 1 ? 'ident_view' : 'ident';
  my $cmd = "select family,count(1) from $table where kingdom = '$kingdom' and  family != '' group by 1";

  my %p = $sql->query($cmd);

  return undef if !$sql->nRecords;

  my $names = {};
  foreach my $i (0..$sql->nRecords-1)
  { $names->{$p{$i}{'family'}} = $p{$i}{'count'} }

  return $names;
}

#===================================================================== GET_GENERA
#=====================================================================
sub get_genera
{ my ($cfg,$kingdom) = @_;

  my $sql = $cfg->connect();

  my $table = $cfg->{'user_level'} <= 1 ? 'ident_view' : 'ident';
  my $cmd = "select genus,count(1) from $table where kingdom = '$kingdom' and  genus != '' group by 1";

  my %p = $sql->query($cmd);

  return undef if !$sql->nRecords;

  my $names = {};
  foreach my $i (0..$sql->nRecords-1)
  { $names->{$p{$i}{'genus'}} = $p{$i}{'count'} }

  return $names;
}

#===================================================================== GET_SCIENTIFICNAMES
#=====================================================================
sub get_scientificnames
{ my ($cfg,$kingdom) = @_;

  my $sql = $cfg->connect();

  my $table = $cfg->{'user_level'} <= 1 ? 'ident_view' : 'ident';
  my $cmd = "select scientificname,count(1) from $table where kingdom = '$kingdom' and  scientificname != '' group by 1";

  my %p = $sql->query($cmd);

  return undef if !$sql->nRecords;

  my $names = {};
  foreach my $i (0..$sql->nRecords-1)
  { $names->{$p{$i}{'scientificname'}} = $p{$i}{'count'} }

  return $names;
}

#===================================================================== DIC
#=====================================================================
sub dic
{ my ($cfg,$par) = @_;
  my $user = $cfg->get_user_info;

  return $cfg->{'dictionary'} if !$par->{'forced'} && defined $cfg->{'dictionary'}; # quando mudar a lingua, tratar isso. Chamar dic de novo. Faz sentido?

  my $lang = $par->{'language'} || $cfg->{'user_lang'} || 'pt';

  my $dic = {}; my $tok = ''; my $txt = ''; my $lan;

  open(IN,$par->{'dictionary'} ? "$cfg->{'lib_dir'}/$par->{'dictionary'}" : "$cfg->{'lib_dir'}/guardioes.dic");

  while (my $L = <IN>)
  { chomp $L;
    next if $L =~ /^\s*#/;
    next if $L =~ /^\s*$/;

    if ($L =~ /^([^\s]+)\s*$/) # token starts in the first column, no space allowed
    { $tok = $1; $tok =~ s/^\s+|\s+$//g }
    elsif ($L =~ /^(pt|en)\s+(.+)/ && $tok)
    { $lan = $1; $txt = $2;
      if ($lan eq $lang)
      { $txt =~ s/^\s+|\s+$//g; $dic->{$tok} = $txt }
    }
    elsif ($L =~ /^\s+/ && $lan eq $lang && $tok)
    { $L =~ s/^\s+|\s+$//g; $dic->{$tok} .= " ".$L }
  }
  close(IN);

  # replaces variable of the form %name%, %nickname% from within the text with the actual values
  foreach my $key (keys %$dic)
  { while ($dic->{$key} =~ /\%([^\%]+)\%/)
    { my $k = $1;
      if ($user->{$k})
      { $dic->{$key} =~ s/\%$k\%/$user->{$k}/ }
      else
      { $dic->{$key} =~ s/\%$k\%/#$k#/ }
    }

    # create the lowercase version of strings that are marked as lower-case-able with :lc

    if ($key =~ /^([^:]+):/)
    { my $k = $1; my $val = $dic->{$key};
      delete $dic->{$key};

      $dic->{$k} = $val;

      $dic->{"$k:lc"} = lc $val if $key =~ /:lc/;

      $dic->{"$k:uc"} = uc $val if $key =~ /:uc/;

      $dic->{"$k:ucfirst"} = ucfirst lc $val if $key =~ /:ucfirst/;	# implies ucfirst lc
    }
  }

# levando em conta o gênero do usuário ( male | female )
  if ($user->{'gender'} eq 'female' || $par->{'gender'} eq 'female')
  { foreach my $key (keys %$dic) { while ($dic->{$key} =~ s/\[[^\|]*\|([^\]]*)\]/$1/g) { } } }
  else
  { foreach my $key (keys %$dic) { while ($dic->{$key} =~ s/\[([^\|]*)\|[^\]]*\]/$1/g) { } } }

  $cfg->{'dictionary'} = $dic;
  return $dic;
}
#===================================================================== FILL_VARIABLES
# troca variáveis inseridas em textos antes que sejam apresentados.
# variáveis do usuário são resolvidas na leitura do dic
# aqui, são vars mais genéricas como num_recs, etc.
#=====================================================================
sub fill_variables
{ my ($cfg,$text,$vars) = @_;

  foreach my $key (keys %$vars)
  { while ($text =~ /\#([^\#]+)\#/) { my $k = $1; $text =~ s/\#$k\#/$vars->{$k}/ } }

  return $text;
}
#===================================================================== NETWORKS
# returns a hash with the available networks for login as keys
# the hash values are used for sorting
#=====================================================================
sub networks
{ my $cfg = shift;

  return { google => 2, facebook => 1, instagram => 3, twitter => 4 }
}
#===================================================================== CATEGORY
# returns a hash with the available users categories as keys
# the hash values are used for sorting
#=====================================================================
sub category
{ my $cfg = shift;

  return { guardiao => 1, especialista => 2, admin => 3, super => 4 }
}
#===================================================================== STATUS
# returns a hash with the available users status values as keys
# the hash values are used for sorting
#=====================================================================
sub status
{ my $cfg = shift;

  return { ativo => 1, inativo => 3, pendente => 2 }
}
#===================================================================== EDUCATION
# returns a hash with the available users education values as keys
# the hash values are used for sorting
#=====================================================================
sub education
{ my $cfg = shift;

  return { fundamental => 1, medio => 2, superior => 3, pos => 4 }
}
#===================================================================== GET_DEF_VERSION
# returns the version of the three def_ tables: habit, interaction, expertise
# controled by the def_version table
#=====================================================================
sub get_def_version
{ my $cfg = shift;
  my $sql = $cfg->connect();

  my %p = $sql->query("select version from def_version;");

  return $p{0}{'version'};
}

#===================================================================== HABIT
# returns a hash with the possible values for plants habit as keys
# the hash values can be used for sorting
#=====================================================================
sub habit
{ my $cfg = shift;
  my $sql = $cfg->connect();

  my %p = $sql->query("select * from def_habit;");
  my $h = {};
  foreach (0..$sql->nRecords-1) { $h->{$p{$_}{'key'}}   = $p{$_}{'id'} }

  return $h;
} 
#===================================================================== INTERACTION
# returns a hash with the possible values for animal and plants
# interactions as keys
# the hash values can be used for sorting
#=====================================================================
sub interaction
{ my $cfg = shift;
  my $sql = $cfg->connect();

  my %p = $sql->query("select * from def_interaction;");
  my $i = {}; my $s = {};
  foreach (0..$sql->nRecords-1)
  { $i->{$p{$_}{'key'}} = $p{$_}{'id'};
    $s->{$p{$_}{'key'}} = $p{$_}{'strength'};

  }

  return ($i,$s);
} 
#=====================================================================	EXPERTISE
# returns a hash with the defined values for users expertises
# the key is an integer and the values are the actual expertise key and
# taxonomic group.
# e.g. $ex{230}{'key'} = 'formiga'; $ex{230}{'group'} = 'animalia';
#=====================================================================
sub expertise
{ my $cfg = shift;
  my $sql = $cfg->connect();

  my %p = $sql->query("select * from def_expertise");
  my $ex = {};
  foreach (0..$sql->nRecords-1)
  { $ex->{$p{$_}{'id'}}{'key'}   = $p{$_}{'key'};
    $ex->{$p{$_}{'id'}}{'group'} = $p{$_}{'grupo'}; #Note: in lib, group. In db, grupo
  }

  return $ex;
}
#===================================================================== LANGUAGES
# returns a hash containing the languages available in dictionary as keys.
# e.g. $ln->{'pt'} = 1
# the hash values can be used for sorting
#=====================================================================
sub languages
{ my $cfg = shift;

  return { pt => 1, en => 2 }
}
#===================================================================== DOWNLOAD_USER_PICTURE
# downloads and stores localy a user picture when available in the
# social network used to login
# updates the database to inform the new picture
#
# depends on /usr/bin/curl
#=====================================================================
sub download_user_picture # ( { user_id => 1, url => 'http://...' } )
{ my ($cfg,$par) = @_;

  my $picture = '';
  my $f_user_id = $cfg->format_user_id($par->{'user_id'});

  my $sql = $cfg->connect();

  if ($par->{'url'} && $par->{'url'} =~ /https?:\/\//)
  { $picture = $f_user_id; 
    if ($par->{'url'} =~ /(\.[a-z]{3})$/i) { $picture .= '_'.time().lc $1 } else { $picture .= '_'.time().'.jpg' }

    my @old_imgs = glob "$cfg->{'user_dir'}/$f_user_id/$f_user_id*"; # saves the old user pictures

    # to use curl in this context is just convenient as the picture is to be stored in a file, not used internally 
    # can be changed by any other method, anyway

    system "$cfg->{'curl_path'} --silent --retry 3 --location --output $cfg->{'user_dir'}/$f_user_id/$picture '$par->{'url'}'";

    foreach (@old_imgs) { unlink $_ } # deletes the old user pictures
  }
  else # no picture available for user, so uses a dummy one if none is registered
  { my %p = $sql->query("select picture from users where id = $par->{'user_id'};");

    if (!$sql->nRecords)
    { $picture = $f_user_id.'_'.time().'.jpg';
      my @old_imgs = glob "$cfg->{'user_dir'}/$f_user_id/$f_user_id*";
      system "cp $cfg->{'user_dir'}/nopic.jpg $cfg->{'user_dir'}/$f_user_id/$picture";
      foreach (@old_imgs) { unlink $_ }
    }
  }

  if ($picture)
  { my $cmd = <<EOM;
update users set picture = E'$picture' where id = $par->{'user_id'};
EOM
    $sql->exec($cmd);
  }
}
#===================================================================== EMAIL_EXISTS
# checks if a given email is already registered
# returns user_id if exists, 0 if not
#=====================================================================
sub email_exists # ( { email => 'name@domain' } )
{ my ($cfg,$par) = @_;

  my $sql = $cfg->connect();
  my %p = $sql->query("select id from users where lower(email) = lower(E'$par->{'email'}')");

  return $p{0}{'id'}+0; # 0 = notFound, user_id = found
}
#===================================================================== PASSWORD_MATCHES
# for a given email, checks if a password matches the registered one
# returns crypted password if matches or '' if not
#=====================================================================
sub password_matches # ( { email => 'name@domain', password => 'string' } )
{ my ($cfg,$par) = @_;

  my $sql = $cfg->connect();
  my %p = $sql->query("select password from users where lower(email) = lower(E'$par->{'email'}')");

  return 0 if !$sql->nRecords; # email not found, so return false

  my $cpass = crypt($par->{'password'},$p{0}{'password'});
  
  return $cpass eq $p{0}{'password'} ? $cpass : '';
}

#===================================================================== NEW_KEY
sub reset_password
{ my ($cfg,$key) = @_;

  $key =~ s/[^a-z0-9]+//g;

  my $sql = $cfg->connect();

  my %p = $sql->query("select * from users where flags like '%resetPassword:$key:%'");

  my $pass = '';
  if ($sql->nRecords == 1)
  { if ($p{0}{'flags'} =~ s/resetPassword:$key:(\d+);//)
    { my $ttl = $1;
      if ((time - $ttl) < 86400)
      { srand(time || $$);
        my $l = 1;
        while ($l < 6) { $l = int(rand(8)) }
   
       my @chars = (48..57,97..107,109..122,76);

       foreach (0..$l) { $pass .= chr($chars[int(rand($#chars+1))]) }
      
       my $cpass = crypt($pass,$$);

       $sql->exec("update users set password = '$cpass', flags = '$p{0}{'flags'}' where	id = $p{0}{'id'}");
       return (1,$pass);
     }
     else
     { $sql->exec("update users set flags = '$p{0}{'flags'}' where id = $p{0}{'id'}");
       return (-1,'');
     }
   }
  }

  return (0,'');
}

#===================================================================== MONTH
sub month
{ my ($cfg,$mon,$lang) = @_;
  return '' if $mon < 1 || $mon > 12;

  return ($lang eq 'en') ?
            ('','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')[$mon] :
            ('','Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez')[$mon];
}
#===================================================================== NEW_KEY
sub send_reset_password_email
{ my ($cfg,$par) = @_;
  
  my $sql = $cfg->connect();

  my %p = $sql->query("select * from users where upper(email) = upper('$par->{'email'}')");

  if ($sql->nRecords == 1)
  { my $dic = $cfg->dic();
    my $reset_password_key = $cfg->new_key();


    my $now = time()+86400;
    my @time = localtime($now);

    my $ttl_pt = sprintf("%02d-%s-%04d %02d:%02d",$time[3],$cfg->month($time[4],'pt'),$time[5]+1900,$time[2],$time[1]);
    my $ttl_en = sprintf("%s %02d, %04d %02d:%02d",$cfg->month($time[4],'en'),$time[3],$time[5]+1900,$time[2],$time[1]);

    my $link = "$cfg->{'home_url'}/resetPassword/$reset_password_key";

    my $message = $cfg->get_page({ page		=> 'reset_password_message',
				   TTL_PT	=> $ttl_pt,
				   TTL_EN	=> $ttl_en,
				   NOME		=> $p{0}{'name'},
				   EMAIL	=> $p{0}{'email'},
				   LINK		=> $link
				});

    $p{0}{'flags'} =~ s/resetPassword:([^:]+):([0-9]+);//;
    $p{0}{'flags'} .= "resetPassword:$reset_password_key:$now;";
    $sql->exec("update users set flags = '$p{0}{'flags'}' where id = $p{0}{'id'}");

    my %mail = (	To		=> $p{0}{'email'},
			From		=> 'web@guardioes.cria.org.br',
			Subject		=> $dic->{'reset_password_subject'},
			Message		=> $message,
			'Content-type'	=> 'text/html; charset=utf-8',
			smtp		=> 'zimbra.cria.org.br'
	       );

    sendmail(%mail);

#        if (sendmail(%mail) ) { print STDERR "email sent OK\n".$Mail::Sendmail::log }
#        else
#        { print STDERR $Mail::Sendmail::error } # if $Mail::Sendmail::error;

  } 
}
#===================================================================== NEW_KEY
# returns a new random SHA1_HEX key
#=====================================================================
sub new_key
{ my $cfg = shift; $cfg->{'rand'} += $$;
  return sha1_hex($cfg->{'rand'}.time());
}
#===================================================================== LOGIN
# login an existing user or register a new one
# basic login data is passed as a hash
# parameters depend on the caller
# for email/password login
# ( { email => 'name@domain', 
#     network => 'guardioes', 
#     password => 'crypted pass', 
#     appcode => 'app code'
# } )
# 
# when registering a new user, or updating user data directly, other key - pairs 
# should be present (see the user form fields)
#
# for social network
# ( {	network		=> 'facebook|instagram|google|twitter',	
#	netid		=> 'userIdOnNetwork',			
#	name		=> 'userName',
#	email		=> 'name@domain',
#	picture		=> 'http://...',
#	birthday	=> 'date',
#	nickname	=> 'userNickname',
#	access_token	=> 'string',
#       appcode         => 'app code'
# } )
#=====================================================================
sub login # ( see above )
{ my ($cfg,$data) = @_;

  my $session_id = $cfg->{'session_id'};

  my $sql = $cfg->connect();
  my $status = 'new'; my $user_id = '';

  # logging in with email/password
  if ($data->{'network'} eq 'guardioes' && $data->{'email'})
  { my %p = $sql->query("select id from users where lower(email) = lower(E'$data->{'email'}')");
    
    $user_id = $p{0}{'id'} if $sql->nRecords;
    $cfg->{'user_id'} = $user_id;
  }
  # logging in with a social network id
  elsif ($data->{'netid'})
  { if ($session_id) # not a login, but an account linking
    { my $cmd = "insert into netids (user_id,netid,network) values ($cfg->{'user_id'},E'$data->{'netid'}',E'$data->{'network'}');";
      $sql->exec($cmd);
      $user_id = $cfg->{'user_id'};
    }
    else
    { my %p = $sql->query("select user_id from netids where netid = E'$data->{'netid'}' and network = E'$data->{'network'}'");
      if ($sql->nRecords)
      { $user_id = $p{0}{'user_id'};
        $cfg->{'user_id'} = $user_id;
      }
      else
      { if ($data->{'email'})
        { # Check if user is already registered by email
          my %p = $sql->query("select id from users where lower(email) = lower(E'$data->{'email'}')");
          if ($sql->nRecords)
          { $user_id = $p{0}{'id'};
            $cfg->{'user_id'} = $user_id;
            # link new netid
            my $cmd = "insert into netids (user_id,netid,network) values ($user_id,E'$data->{'netid'}',E'$data->{'network'}');";
            $sql->exec($cmd);
          }
        }
      }
    }
  }

  $session_id = $cfg->new_key() if !$session_id; # sets only if already logged, case of accounts linking

  # -------------------------------------------------
  # user already registered
  # -------------------------------------------------
  if ($user_id)
  { my %u = $sql->query("select * from users where id = $user_id;");

    if ($u{0}{'status'} ne 'inativo' &&	# can be active or pending
	((($data->{'network'} eq 'guardioes') && ($data->{'password'} eq $u{0}{'password'})) || ($data->{'network'} ne 'guardioes'))
       )
    { $status = 'old'; 
      my $cmd = <<EOM;
insert into session (session_id,user_id,network) values (E'$session_id',$user_id,E'$data->{'network'}');
EOM
      $sql->exec($cmd);

      # saving a new picture, if picture did not exist
      $cfg->download_user_picture( { url => $data->{'picture'}, user_id => $user_id } ) if $data->{'picture'};
    }
    else # user exist, password mismatch
    { $session_id = ''; $status = 'retry' }
  }
# -------------------------------------------------
# new user. Registering...
# -------------------------------------------------
  else
  {
   

#-------- for debug purposes only - start
#my $fuser_id = $cfg->format_user_id($user_id);
#open(DBG,">>$cfg->{'user_dir'}/$fuser_id/$data->{'network'}.data");
#print DBG "---------------------------------------\n";
#print DBG Dumper $data,"\n";
#close(DBG);
#-------- for debug purposes only - stop

    foreach (keys %$data) { clean($data->{$_}) } 
    $data->{'birthday'}  = 'null' if !$data->{'birthday'};
    $data->{'language'}  = 'pt'   if !$data->{'language'};
    $data->{'education'} = 'fundamental' if !$data->{'education'};

    $data->{'agreement'} = $data->{'agreement'} =~ /^(1|true)$/ ? 'true' : 'false';
    if ($data->{'agreement'} eq 'true')
    { ($data->{'category'},$data->{'status'}) =  ('especialista','pendente');
      $data->{'terms_especialista'} = 'now()';
    }
    else
    { ($data->{'category'},$data->{'status'}) =  ('guardiao','ativo');
      $data->{'terms_especialista'} = 'NULL';
    }

    my $cmd = <<EOM;
insert into users (name,nickname,email,password,birthday,gender,language,education,
		   curriculum,category,status,comments,alert_period,agreement,terms_guardiao,terms_especialista)
	values (
fixInitCap('$data->{'name'}'),
fixInitCap(	'$data->{'nickname'}'),
	'$data->{'email'}',
	'$data->{'password'}',
	$data->{'birthday'},
	'$data->{'gender'}',
	'$data->{'language'}',
	'$data->{'education'}',
	'$data->{'curriculum'}',
	'$data->{'category'}',
	'$data->{'status'}',
	'$data->{'comments'}',
	'$data->{'alert_period'}',
	$data->{'agreement'},
	now(),
	$data->{'terms_especialista'}
);
EOM

    $sql->begin();
    $sql->exec($cmd);
    my %p = $sql->query("select currval('users_id_seq') as id;");
    $user_id = $p{0}{'id'};
    $cfg->{'user_id'} = $user_id;
    $sql->end();

    # creating user's work dir 
    my $fuser_id = $cfg->format_user_id($user_id);
    mkdir "$cfg->{'user_dir'}/$fuser_id" if !-d "$cfg->{'user_dir'}/$fuser_id";

    $cfg->download_user_picture( { url => $data->{'picture'}, user_id => $user_id } );

    # saving the netid
    if ($data->{'network'} ne 'guardioes')
    { $cmd = "insert into netids (user_id,netid,network) values ($user_id,E'$data->{'netid'}',E'$data->{'network'}');";
      $sql->exec($cmd);
    }

    # saving the expertises
    foreach (keys %{$data->{'expertise'}})
    { $cmd = "insert into expertises (user_id,expertise_id) values ($user_id,$_);";
      $sql->exec($cmd);
    }

    # creating user session
    $cmd = "insert into session (session_id,user_id,network) values (E'$session_id',$user_id,E'$data->{'network'}');";
    $sql->exec($cmd);
  }

  # app code
  if ($data->{'appcode'})
  { my %p = $sql->query("select user_id from device where appcode = E'$data->{'appcode'}'");
    if ($sql->nRecords)
    { my $app_user_id = $p{0}{'user_id'};
      print STDERR 'Installation already registered to another user' if $app_user_id != $user_id;
      $status = 'invalid_app';
    }
    else
    { my $cmd = "insert into device (user_id,appcode) values ($user_id,E'$data->{'appcode'}');";
      $sql->exec($cmd);
    }
  }

#-------- for debug purposes only - start
my $fuser_id = $cfg->format_user_id($user_id);
open(DBG,">>$cfg->{'user_dir'}/$fuser_id/$data->{'network'}.data");
print DBG "---------------------------------------\n";
print DBG Dumper $data,"\n";
close(DBG);
#-------- for debug purposes only - stop

  return ($session_id,$status);
}

#===================================================================== UNSUBSCRIBE
# used by the unsubscribe operation, when the user decides to close the
# account. It just changes the user status to 'inativo'
#===================================================================== 
sub unsubscribe
{ my ($cfg,$par) = @_;
  my $sql = $cfg->connect();

  $sql->exec("update users set status = 'inativo' where email = '$par->{'email'}';");

  return !$sql->error; # true if OK, false otherwise
}

#===================================================================== SET_COOKIE
# sets the session cookie and redirects the user to a new page
#=====================================================================
sub set_cookie
{ my ($cfg,$session_id,$location) = @_;
  my $secure = '';
  my $cookie_name = 'GuardioesSessionId';
  if ($cfg->{'home_url'} =~ /^https:\/\//)
  { $secure =' Secure;';
    $cookie_name = ' __Host-' . $cookie_name;
  }
  return <<EOM;
Set-Cookie: $cookie_name=$session_id;$secure HttpOnly; SameSite=Lax; Path=/; Max-Age=2592000
Location: $cfg->{'home_url'}/$location

EOM
}
#===================================================================== UPDATE_USER_STATUS_CATEGORY
# update user status or category
#=====================================================================
sub update_user_status_category
{ my ($cfg,$par) = @_;
  return if $cfg->{'user_level'} < 7; # not even admin
  my $user_id = $par->{'user_id'};  return if !$user_id;
  my $change_field = $par->{'field'}; return if $change_field !~ /^(category|status)$/;
  my $change_value = $par->{'value'}; return if !$change_value;

  my $sql = $cfg->connect();
  $sql->exec("update users set $change_field = E'$change_value' where id = $user_id;");

  my $cmd = <<EOM;
update	users
set	is_admin = ((category = 'admin' or category = 'super') and status = 'ativo'),
	is_super = (category = 'super' and status = 'ativo')
where	id = $user_id;
EOM
  $sql->exec($cmd);
}
#===================================================================== UPDATE_USER_INFO
# update user info
#=====================================================================
sub update_user_info
{ my ($cfg,$new_data) = @_;

  my $user_id = $new_data->{'user_id'} || $cfg->current_user_id();

  return undef if !$user_id;    # user_id was not specified nor found out

  foreach (keys %{$new_data}) { $new_data->{$_} = clean($new_data->{$_}) }

  my $old_data = $cfg->get_user_info({user_id => $user_id});

  my $sql = $cfg->connect();

  $new_data->{'birthday'}	= 'null' if !$new_data->{'birthday'};
  $new_data->{'agreement'}	= $new_data->{'agreement'} =~ /^(1|true)$/ ? 'true' : 'false';

  $new_data->{'category'}	= $old_data->{'category'};
  $new_data->{'status'}		= $old_data->{'status'};

# apenas duas situações que precisam de atenção:

  my $set_terms_especialista = '';

  if (	$new_data->{'agreement'} eq 'true' &&
	$old_data->{'category'}  eq 'guardiao' &&
	$old_data->{'status'}    eq 'ativo')
  { ($new_data->{'category'},$new_data->{'status'}) =  ('especialista','pendente');
    $set_terms_especialista = 'terms_especialista = now(),'; 
  }
  elsif ( $new_data->{'agreement'} eq 'false' &&
	  $old_data->{'status'}    ne 'inativo' &&
	  $old_data->{'category'}  eq 'especialista')
  { $new_data->{'category'}	= 'guardiao';
    $new_data->{'status'}	= 'ativo';
    $new_data->{'expertise'}	= {};
    $new_data->{'curriculum'}	= '';
    $new_data->{'alert_period'}	= 'never';
  }

  my $set_terms_guardiao = '';
  if ( $new_data->{'agreement'} && !$old_data->{'terms_guardiao'} )
  { $set_terms_guardiao = 'terms_guardiao = now(),';
  }

  my $cmd = <<EOM;
update users set
	name		= fixInitCap('$new_data->{'name'}'),
	nickname	= fixInitCap('$new_data->{'nickname'}'),
	email		= '$new_data->{'email'}',
	birthday	= $new_data->{'birthday'},
	gender		= '$new_data->{'gender'}',
	education	= '$new_data->{'education'}',
	curriculum	= '$new_data->{'curriculum'}',
	comments	= '$new_data->{'comments'}',
	agreement	=  $new_data->{'agreement'},
	$set_terms_especialista
	$set_terms_guardiao
	category	= '$new_data->{'category'}',
	status		= '$new_data->{'status'}',
	language	= '$new_data->{'language'}',
	alert_period	= '$new_data->{'alert_period'}'
where id = $old_data->{'user_id'};
EOM
  $sql->exec($cmd);
  return 0 if $sql->error;

  if ($new_data->{'password'})
  { $cmd = "update users set password = E'$new_data->{'password'}' where id = $old_data->{'user_id'};";
    $sql->exec($cmd);
    return 0 if $sql->error;
  }

# replacing the user expertises

  $sql->exec("delete from expertises where user_id = $old_data->{'user_id'}");
  foreach my $exp (keys %{$new_data->{'expertise'}})
  { next if !$exp;
    $cmd = "insert into expertises (user_id,expertise_id) values ($old_data->{'user_id'},$exp);";
    $sql->exec($cmd);
    return 0 if $sql->error;
  }
  return 1;
}
#===================================================================== BOOTSTRAP_JS
#=====================================================================
sub bootstrap_js
{ my ($cfg,$par) = @_;
  if ($cfg->{'mobile'})
  { return <<EOM;
<script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.9/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>
EOM
  }
  return '';
}
#===================================================================== HTML_HEAD
#=====================================================================
sub html_head
{ my ($cfg,$par) = @_;
  my $dic = $cfg->dic();
  # Use bootstrap for mobile pages
  my $bootstrap_css = '';
  my $mobile_class = '';
  my $viewport = '';
  if ($cfg->{'mobile'})
  { $viewport = '<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">';
    $bootstrap_css = '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">';
    $mobile_class = " class='mobile'";
  }
  my $http_status = '';
  my $data_status = '';
  if ($par->{'status'})
  { $http_status = 'Status: '.$par->{'status'}."\n";
    $data_status = " data-status='".$par->{'status'}."'";
  }

  return <<EOM
Content-type: text/html; charset=UTF-8
$http_status
<!DOCTYPE html>
<html>
<head>
<script language='text/javascript'>onload = function { var userLang = '$cfg->{'user_lang'}' }</script>
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>
<title>+$dic->{'Guardioes_Title'}</title>
$viewport
$bootstrap_css
<link href="https://fonts.googleapis.com/css?family=Roboto+Condensed" rel="stylesheet"> 
<link rel='stylesheet' id='pageColors' href='/css/colors_v$cfg->{'palette_id'}.css'/>
<link rel='stylesheet' href='/css/main_v2.css'/>
<script src='/js/main_v2.js'></script>
$par->{'script'}
</head>
<body$mobile_class$data_status $par->{'body'}>
<div id='divMsg'></div>
EOM
}
#<body$mobile_class$data_status $par->{'body'} onLoad="userLang='$cfg->{'user_lang'}'">
#===================================================================== HTML_FOOT
#=====================================================================
sub html_foot
{ my ($cfg,$par) = @_;
  my $user = $cfg->get_user_info();
  my $dic = $cfg->dic();
  # Use bootstrap for mobile pages
  my $bootstrap_js = $cfg->bootstrap_js();
  my $visibility = $cfg->{'mobile'} ? ' style="display:none;"' : '';

  my $lang = $cfg->{'lang'} eq 'en' ? 'en' : 'pt_BR';
  return <<EOM;
  <div id='divFoot'$visibility>
    <center>
    <table class='w95'>
    <tr>
        <td class='esquerda w33'>$dic->{'Guardioes_Title'}, 2018</td>
        <td class='centro w33'><a href='http://w2.cria.org.br/feedback/pt/index?guardioes.cria.org.br' target='talktous'>$dic->{'faleconosco'}</a></td>
        <td class='direita w33'><a href='https://creativecommons.org/licenses/by-nc/4.0/deed.$lang' target='cc'><img
	     src='/imgs/cc_by_nc.png' align='right' height='25px'/></a></td>
    </tr>
    </table>
    </center>
  </div>
</div>
$bootstrap_js
</body>
</html>
EOM
}

#===================================================================== LIST_RECORD
#=====================================================================
sub list_records # ( $user_id )		# REVER
{ my ($cfg,$user_id) = @_;

  $user_id = $cfg->{'user_id'} if !$user_id;

  my $sql = $cfg->connect();
  my $cmd = "select * from record where user_id = $user_id";
  my %p = $sql->query($cmd);

  my $data = {};
  foreach (0..$sql->nRecords-1)
  { $data->{$p{$_}{'id'}}{'record_date'} = $p{$_}{'record_date'};  # ????????
  }
  return $data;
}

#===================================================================== SAVE_IMAGE
#=====================================================================
sub save_image		# REVER
{ my ($cfg,$data) = @_;
 
  my $code = $cfg->new_key();
  my $f_user_id = $cfg->format_user_id($cfg->{'user_id'});

# seria interessante usar /usr/bin/identify -format "%[width] %[height] %[exif:orientation] %m" $dir/$fn
# para verificar o real formato da imagem (PNG, JPEG, TIF, etc) 

  my $ext = $data->{'content'} =~ /png/i ? 'png' : 'jpg';

  my $fn	= $code.'.'.$ext;
  my $thumb 	= $code.'_thumb.'.$ext;
  my $large 	= $code.'_large.'.$ext;

  my $dir =  "$cfg->{'user_dir'}/$f_user_id";
  mkdir $dir if ! -d $dir;

  open(OUT,'|-',"/usr/bin/convert -auto-orient - $dir/$fn"); binmode OUT; print OUT $data->{'data'}; close(OUT);
  
  my $tmp = `/usr/bin/identify -format "%[width] %[height] %[exif:orientation]" $dir/$fn`;
  chomp $tmp;
  my ($width,$height,$orientation) = split(' ',$tmp);
  $width = 1 if !$width; $height = 1 if !$height; # prevent division by zero

  if ($width < $height)
  { my $margin = int(((($height * 240)/$width) - 240)/2);
    system "/usr/bin/convert -resize  240 $dir/$fn - | convert -crop 240x240+0+$margin - $dir/$thumb";
    system "/usr/bin/convert -resize 1024 $dir/$fn $dir/$large";
  }
  else
  { my $margin = int(((($width * 240)/$height) - 240)/2);
    system "/usr/bin/convert -resize x240 $dir/$fn - | convert -crop 240x240+$margin+0 - $dir/$thumb";
    system "/usr/bin/convert -resize x1024 $dir/$fn $dir/$large";
  }

  return { code => $code, format => $ext, image_of => $data->{'image_of'} };
}
#===================================================================== REMOVE_IMAGE
#=====================================================================
sub remove_image
{ my ($cfg,$img) = @_;

  my $sql = $cfg->connect();

  my $cmd = "select * from image where code = E'$img';";
  my %p = $sql->query($cmd);
  return if $sql->error || !$sql->nRecords;

  my $f_user_id = $cfg->format_user_id($p{0}{'user_id'});
 
  unlink "$cfg->{'user_dir'}/$f_user_id/$p{0}{'code'}.$p{0}{'format'}";
  unlink "$cfg->{'user_dir'}/$f_user_id/$p{0}{'code'}_thumb.$p{0}{'format'}";
  unlink "$cfg->{'user_dir'}/$f_user_id/$p{0}{'code'}_large.$p{0}{'format'}";
}
#===================================================================== PUT_RECORD
#=====================================================================
sub put_record
{ my ($cfg,$data) = @_;

  my $sql = $cfg->connect();

  my $field = $cfg->get_table_fields('record');

  my $names = ''; my $values = '';
  foreach my $fld (keys %$field)
  { next if $fld eq 'id';
    next if $fld =~ /eventday|eventmonth|eventyear/;	# filled by trigger

    next if $field->{$fld} =~ /timestamp/;	# default now()

    $names .= "$fld,";

    if ($field->{$fld} eq 'array') 
    { $values .= "E'{\"".join('","',@{$data->{$fld}})."\"}'," } # array
    elsif ($field->{$fld} =~ /(integer|boolean|bigint)/ || $fld eq 'point') 
    { $values .= $data->{$fld}."," }
    else
    { $values .= "E'".clean($data->{$fld})."'," }
  }
  $names =~ s/,$//; $values =~ s/,$//;

  my $cmd = "insert into record ($names) values ($values);";

  
  $sql->begin();
  $sql->exec($cmd);
#print STDERR "$cmd\n".$sql->message() if $sql->error;
  my %p = $sql->query("select currval('record_id_seq') as record_id;");
  $sql->end();

  my $k = 0;
  foreach my $img (@{$data->{'images'}})
  { $k++;
    $cmd = <<EOM;
insert into image (id, record_id, user_id, code, format, sequence, image_of)
        values (default,$p{0}{'record_id'},$data->{'user_id'},'$img->{'code'}','$img->{'format'}',$k,'$img->{'image_of'}');
EOM
    $sql->exec($cmd);
  }

  return $p{0}{'record_id'};
}
#===================================================================== UPDATE_RECORD
#=====================================================================
sub update_record	# DEPRECATED
{ my ($cfg,$data) = @_;

  my $sql = $cfg->connect();

  my $field = $cfg->get_table_fields('record');

  my $cmd = "update record set ";
  foreach my $fld (keys %$field)
  { next if $fld eq 'id';
    next if $field->{$fld} =~ /timestamp/;	# default now()
#    next if $fld =~ /^(i|v)_(animalia|plantae)_count/;	# default 0

    if ($field->{$fld} eq 'array') 
    { $cmd .= "$fld = E'{\"".join('","',@{$data->{$fld}})."\"}'," } # array
    elsif ($field->{$fld} =~ /(integer|boolean|bigint)/) 
    { $cmd .= "$fld = $data->{$fld}," }
    else
    { $cmd .= " $fld = E'".clean($data->{$fld})."'," }
  }
  $cmd =~ s/,$//;
  $cmd .= " where id = $data->{'record_id'};";

  $sql->exec($cmd);
 
  return $data->{'record_id'};
}
#===================================================================== FORMAT_SCIENTIFICNAME
#=====================================================================
sub format_scientificname
{ my ($cfg,$sciname) = @_;

}

#===================================================================== PUT_IDENT
#=====================================================================
sub put_ident
{ my ($cfg,$data) = @_;

  return 0 if ($cfg->{'user_level'} < 3) && ($cfg->{'user_id'} != $data->{'user_id'});

  if ($data->{'scientificname'})
  { $data->{'scientificname'} =~ s/^\s+|\s+$//g;
    $data->{'scientificname'} =~ s/\s+/ /g;

    if ($data->{'scientificname'} =~ s/^([A-Za-z\-]+)(\s+([a-z\-]+))?(\s+((var\.|subsp\.)\s+)?([a-z\-]+))?//)
    { $data->{'genus'}			= ucfirst lc $1;
      $data->{'specificepithet'}	= lc $3;
      $data->{'taxonrank'}		= lc $6;
      $data->{'infraspecificepithet'}	= lc $7; 

      $data->{'specificepithet'}	= '' if $data->{'specificepithet'} =~ /^s+p+$/;
      $data->{'infraspecificepithet'}	= '' if $data->{'infraspecificepithet'} eq 'ssp'; 

      $data->{'scientificnameauthorship'} = $data->{'scientificname'};
      $data->{'scientificnameauthorship'} =~ s/^\s+|\s+$//g; $data->{'scientificnameauthorship'} =~ s/\s+/ /g;

      $data->{'scientificname'} = "$data->{'genus'} $data->{'specificepithet'} $data->{'taxonrank'} $data->{'infraspecificepithet'}";
      $data->{'scientificname'} =~ s/^\s+|\s+$//g; $data->{'scientificname'} =~ s/\s+/ /g;
    }
  }
  $data->{'vernacularname'} = lc $data->{'vernacularname'};
  $data->{'infraspecificepithet'} = lc $7; 

  my $sql = $cfg->connect();

  my $field = $cfg->get_table_fields('ident');

  my $names = ''; my $values = '';
  foreach my $fld (keys %$field)
  { next if $fld eq 'id';
#    next if $fld =~ /^(i|v)_(animalia|plantae)_count/;	# default 0
    next if $fld eq 'validatedby_id' && !$data->{'validatedby_id'};

    if ($fld eq 'datevalidated')
    { if ($data->{'validatedby_id'}) { $data->{'datevalidated'} = 'now()'; $data->{'status'} = 'valido' }
      else { next }
    } 
    else 
    { next if $field->{$fld} =~ /timestamp/ }	# outros timestamps que default to now()

    $names .= "$fld,";

    if ($field->{$fld} eq 'array') 
    { $values .= "E'{\"".join('","',@{$data->{$fld}})."\"}'," } # array
    elsif ($field->{$fld} =~ /(integer|boolean|bigint,timestamp)/) 
    { $values .= $data->{$fld}."," }
    else
    { $values .= "E'".clean($data->{$fld})."'," }
  }
  $names =~ s/,$//; $values =~ s/,$//;

  my $cmd = "insert into ident ($names) values ($values);";

  $sql->begin();
  $sql->exec($cmd);
  my %p = $sql->query("select currval('ident_id_seq') as ident_id;");
  $sql->end();

  return $p{0}{'ident_id'};
}

#===================================================================== CHANGE_GROUP
#=====================================================================
sub change_group
{ my ($cfg,$record_id,$group) = @_;
  my $sql = $cfg->connect();

  if ($cfg->{'user_level'} > 1 || $cfg->get_record_owner($record_id) == $cfg->{'user_id'})
  { my $cmd = "update record set taxgrp = E'$group' where id = $record_id;";
    $sql->exec($cmd);
    return 1;
  }
  return 0;
}
#===================================================================== CHANGE_HABIT
#=====================================================================
sub change_habit
{ my ($cfg,$record_id,$habit) = @_;
  my $sql = $cfg->connect();

  if ($cfg->{'user_level'} > 1 || $cfg->get_record_owner($record_id) == $cfg->{'user_id'})
  { my $cmd = "update record set habit = E'$habit' where id = $record_id;";
    $sql->exec($cmd);
    return 1;
  }
  return 0;
}
#===================================================================== CHANGE_INTERACTION
#=====================================================================
sub change_interaction
{ my ($cfg,$record_id,$interaction) = @_;
  my $sql = $cfg->connect();

  if ($cfg->{'user_level'} > 1 || $cfg->get_record_owner($record_id) == $cfg->{'user_id'})
  { my $cmd = "update record set interaction = E'$interaction' where id = $record_id;";
    $sql->exec($cmd);
    return 1;
  }
  return 0;
}
#===================================================================== DELETE_RECORD
#=====================================================================
sub delete_record
{ my ($cfg,$record_id) = @_;
  my $sql = $cfg->connect();

  my $data = $cfg->get_record($record_id,0);

  if ($cfg->{'user_level'} > 3 || (($cfg->{'user_id'} == $data->{'user_id'}) && $data->{'can_be_deleted'})) # admin/super or owner
  { my %q = $sql->query("select code from image where record_id = $record_id");
    my $nq = $sql->nRecords;
    foreach (0..$nq-1) { $cfg->remove_image($q{$_}{'code'}); }	# apaga as imagens do disco

    my $cmd = "delete from record where id = $record_id;";
    $sql->exec($cmd);

    return 1;
  }
  return 0;
}
#===================================================================== DELETE_IDENT
#=====================================================================
sub delete_ident
{ my ($cfg,$ident_id) = @_;
  my $sql = $cfg->connect();

  my %p = $sql->query("select * from ident where id = $ident_id;");
  return 0 if !$sql->nRecords;  

  if ($cfg->{'user_level'} > 3 || ($cfg->{'user_id'} == $p{0}{'identifiedby_id'})) # admin/super or owner
  { my $cmd = "delete from ident where id = $ident_id;";
    $sql->exec($cmd);

    return 1;
  }
  return 0;
}
#===================================================================== VALIDATE_IDENT
#=====================================================================
sub validate_ident
{ my ($cfg,$id) = @_;
  
  my $sql = $cfg->connect();

  my $cmd = "update ident set datevalidated = now(), validatedby_id = $cfg->{'user_id'}, status = 'valido' where id = $id";
  $sql->exec($cmd);
}
#===================================================================== INVALIDATE_IDENT
#=====================================================================
sub invalidate_ident
{ my ($cfg,$id) = @_;
  
  my $sql = $cfg->connect();

  my $cmd = "update ident set datevalidated = now(), validatedby_id = $cfg->{'user_id'}, status = 'invalido' where id = $id";
  $sql->exec($cmd);
}
#===================================================================== GET_RECORD_OWNER
#=====================================================================
sub get_record_owner
{ my ($cfg,$record_id) = @_;

  my $sql = $cfg->connect();

  my %p = $sql->query("select user_id from record where id = $record_id");

  return $p{0}{'user_id'}
}
#===================================================================== GET_RECORD
#=====================================================================
sub get_record # ( record_id )
{ my ($cfg,$record_id,$single_ident) = @_;

  my $sql = $cfg->connect();

  my %p = $sql->query("select * from record where id = $record_id");
  
  my $data = {};
  foreach ($sql->fieldName()) { $data->{$_} = $p{0}{$_} }

# images

  $data->{'photo'} = [];

  my $f_user_id = $cfg->format_user_id($data->{'user_id'});

  my ($interaction,$strength) = $cfg->interaction();

  my %q = $sql->query("select * from image where record_id = $record_id order by sequence");

  my $str = $strength->{$p{0}{'interaction'}} == -1 ? 100	:
            $strength->{$p{0}{'interaction'}} ==  1 ? 0	: 25;

  $data->{'relation_strength'} = $str;

  foreach my $i (0..$sql->nRecords-1)
  { 
    $data->{'photo'}[$i] = 
	{	
		id		=> $q{$i}{'id'},
		user_id		=> $q{$i}{'user_id'},
		record_id	=> $q{$i}{'record_id'},
		code		=> $q{$i}{'code'},
		sequence	=> $q{$i}{'sequence'},
		image_of	=> $q{$i}{'image_of'},
		original	=> "$q{$i}{'code'}.$q{$i}{'format'}",
		original_url	=> "$cfg->{'user_url'}/$f_user_id/$q{$i}{'code'}.$q{$i}{'format'}",

		thumb		=> "$q{$i}{'code'}_thumb.$q{$i}{'format'}",
		thumb_url	=> "$cfg->{'user_url'}/$f_user_id/$q{$i}{'code'}_thumb.$q{$i}{'format'}",

		large		=> "$q{$i}{'code'}_large.$q{$i}{'format'}",
		large_url	=> "$cfg->{'user_url'}/$f_user_id/$q{$i}{'code'}_large.$q{$i}{'format'}",
		metric		=> { strength => $str }
	};


  }

# idents

  $data->{'ident'} = [];
  my $cmd = '';

  if ((($cfg->{'user_level'} >= 3) || ($data->{'user_id'} == $cfg->{'user_id'})) && !$single_ident) 
  { $cmd = "select * from ident where record_id = $record_id order by dateidentified desc nulls last, datevalidated desc nulls last"; }
  else
  { $cmd = "select * from ident_view where record_id = $record_id order by status desc, datevalidated desc nulls last, dateidentified desc nulls last"; }

  %p = $sql->query($cmd);

  foreach my $i (0..$sql->nRecords-1)
  { my $ident = {};
    foreach ($sql->fieldName()) { $ident->{$_} = $p{$i}{$_} }
    push @{$data->{'ident'}},$ident;
  }

# checking if the record can be deleted
# it can always be deleted by an admin.
# it can also be deleted by the owner if there is no valid identifications made by other specialists
#					neither any validation made by other specialists

  $cmd = <<EOM;
select	(exists(select 1 from ident where record_id = $record_id and status != 'invalido' and identifiedby_id != $data->{'user_id'} limit 1) or
	 exists(select 1 from ident where record_id = $record_id and status != 'invalido' and validatedby_id != $data->{'user_id'} limit 1)
	) as existe
EOM
  %p = $sql->query($cmd);
  $data->{'can_be_deleted'} = !$p{0}{'existe'};

# ------------------------

  return $data; 
}
#===================================================================== GET_IDENT
#=====================================================================
sub get_ident # ( ident_id )
{ my ($cfg,$id) = @_;
   my $sql = $cfg->connect();
  my %p = $sql->query("select * from ident where id = $id");
  my $data = {};
  foreach ($sql->fieldName()) { $data->{$_} = $p{0}{$_} }
  return $data;
}
#===================================================================== FORMAT_RECORD
#=====================================================================
sub format_record
{ my ($cfg,$data) = @_;

  my $dic = $cfg->dic();

  my $collector = $cfg->get_user_info({ user_id => $data->{'user_id'} });

  my $st = "<span class='record'>";
  $st .= "<span class='tag'>$dic->{'tag_location'}: </span>";
  $st .= "$data->{'locality'}, "	if $data->{'locality'};
  $st .= "$data->{'municipality'}, "	if $data->{'municipality'};
  $st .= "$data->{'stateprovince'}, "	if $data->{'stateprovince'};
  $st .= "$data->{'country'} "		if $data->{'country'};
  $st =~ s/,\s*$//g;

  $st .= "<span class='tag'>$dic->{'tag_coords'}: </span> [";
  $st .= sprintf("%2.6f",$data->{'decimallongitude'});
  $st .= ",";
  $st .= sprintf("%2.6f",$data->{'decimallatitude'});
  $st .= "]";

  $st .= "<br/><span class='tag'>$dic->{'tag_observer'}: </span> ";
  $st .= "$collector->{'name'} "	if $collector->{'name'};

  if ($data->{'eventdate'} =~ /(\d{2}).(\d{2}).(\d{4})/)
  { my $fdate = $cfg->format_date( { day => $1, month => $2, year => $3 });

    if ($data->{'eventtime'} =~ /(\d\d)(\d\d)/)
    { $fdate .= " $1h - $2h" }

    $st .= "<span class='tag'>$dic->{'date_only:ucfirst'}: </span> $fdate";
  }

  if ($data->{'record_date'} =~ /(\d{4}).(\d{2}).(\d{2})/)
  { my $fdate = $cfg->format_date( { day => $3, month => $2, year => $1 });

    $st .= "<br/><span class='tag'>$dic->{'date_sent:ucfirst'}: </span> $fdate";
  }

  if ($data->{'eventremarks'})
  { $st .= "<br/><span class='tag'>$dic->{'tag_eventremarks'}: </span> $data->{'eventremarks'}";
  }

  $st .= "</span>";
  return $st;
}
#===================================================================== FORMAT_IDENT
#=====================================================================
sub acceptedName
{ my ($cfg,$ident) = @_;

  my $sql = $cfg->connect_dic();
  my $cmd = '';

  if ($ident->{'kingdom'} eq 'animalia')
  { $cmd = "select id from moure where plain_name = public.ascii('$ident->{'scientificname'}')";
    $sql->query($cmd);
    if ($sql->nRecords) { return 'moure' }

    $cmd = "select id from sp2000_animalia where plain_name = public.ascii('$ident->{'scientificname'}')";
    $sql->query($cmd);
    if ($sql->nRecords) { return 'sp2000' }

    return '';
  }
  elsif ($ident->{'kingdom'} eq 'plantae')
  { $cmd = "select id from flora2020 where plain_name = public.ascii('$ident->{'scientificname'}')";
    $sql->query($cmd);
    if ($sql->nRecords) { return 'flora2020' }

    $cmd = "select id from sp2000_plantae where plain_name = public.ascii('$ident->{'scientificname'}')";
    $sql->query($cmd);
    if ($sql->nRecords) { return 'sp2000' }

    return '';
  }

  return ''; 
} 
#===================================================================== FORMAT_IDENT
#=====================================================================
sub format_ident
{ my ($cfg,$ident,$work_mode) = @_;

  my $dic = $cfg->dic();

  my $st = "<span class='ident'>";
  $st .= "<span class='hi'>";
  $st .= "$ident->{'kingdom'}"		if $ident->{'kingdom'};
  $st .= " &#xbb; $ident->{'phylum'}"	if $ident->{'phylum'};
  $st .= " &#xbb; $ident->{'class'}"	if $ident->{'class'};
  $st .= " &#xbb; $ident->{'ordem'}"	if $ident->{'ordem'};
  $st .= " &#xbb; $ident->{'family'}"	if $ident->{'family'};
  $st .= "</span>";

  my $status_class = $cfg->acceptedName($ident) ? ' bold' : '';

  $st .= "<br/><span class='sp$status_class'>$ident->{'scientificname'}</span>"		if $ident->{'scientificname'};
  $st .= " <span class='au'>$ident->{'scientificnameauthorship'}</span>"	if $ident->{'scientificnameauthorship'};

  $st .= "<br/><span class='cn'>$ident->{'vernacularname'}</span>"		if $ident->{'vernacularname'};

  my $u = $cfg->get_user_info({ user_id => $ident->{'identifiedby_id'} });

  my $fdate = $ident->{'dateidentified'};
  if ($ident->{'dateidentified'} =~ /(\d{4}).(\d{2}).(\d{2})/)
  { $fdate = $cfg->format_date( { day => $3, month => $2, year => $1 }) }

  $st .= "<br/><span class='tag'>det. </span>".$u->{'name'}." ($fdate)";

  if ($work_mode && ($cfg->{'user_level'} > 1 || $ident->{'user_id'} == $cfg->{'user_id'}))
  { $st .= "<br/><span class='tag'>obs. </span>$ident->{'identificationremarks'}<br/>" if $ident->{'identificationremarks'};
  } 

  $st .= "</span>";
  return $st;
}

#===================================================================== COUNTS
# retrieves the whole table 
#=====================================================================
sub counts
{ my ($cfg) = @_;

  return $cfg->{'counts'} if $cfg->{'counts'};

  my $sql = $cfg->connect();

  my %p = $sql->query("select * from counts");

  my $counts = {};

  foreach my $i (0..$sql->nRecords-1)
  { my $key = $p{$i}{'key'};
       $key .= ":$p{$i}{'kingdom'}"	if $p{$i}{'kingdom'};
       $key .= ":$p{$i}{'taxgrp'}"	if $p{$i}{'taxgrp'};
    $counts->{$p{$i}{'user_id'}}{$key} = $p{$i}{'num'};
  }

  $cfg->{'counts'} = $counts;

  return $counts;
}
#===================================================================== CLEAN
#=====================================================================
sub clean
{ my $st = shift;
  $st =~ s/^\s+|\s+$//g; $st =~ s/\s+/ /g;
  $st =~ s/'/\\'/g;
  $st =~ s/"/\\"/g;
  return $st;
}
#===================================================================== GET_TABLE_FIELDS
#=====================================================================
sub get_table_fields
{ my ($cfg,$table_name) = @_;
  my $sql = $cfg->connect();
  my $field = {};

  my $cmd = <<EOM;
SELECT	column_name,data_type
FROM	information_schema.columns
WHERE	table_catalog = '$cfg->{'db_name'}' and table_name = '$table_name';
EOM
  my %p = $sql->query($cmd);
  foreach (0..$sql->nRecords-1)
  { $field->{$p{$_}{'column_name'}} = lc $p{$_}{'data_type'} }

  return $field;
}
#===================================================================== GET_AVAILABLE_UCS
#=====================================================================
sub get_available_ucs
{ my ($cfg) = @_;
  
  my $sql = $cfg->connect();
  my %p  = $sql->query("select distinct gid,nome from map_ucsfi,record where ST_contains(map_ucsfi.geom,record.point)");

  my $ucs = {};
  foreach (0..$sql->nRecords-1)
  { $ucs->{$p{$_}{'gid'}} = $p{$_}{'nome'}; }
  return $ucs;
}

#===================================================================== GET_AVAILABLE_PRJ
#=====================================================================
sub get_available_prj
{ my ($cfg) = @_;
  
  my $sql = $cfg->connect();
  my %p  = $sql->query("select distinct gid,nome from map_projects,record where ST_contains(map_projects.geom,record.point)");

  my $ucs = {};
  foreach (0..$sql->nRecords-1)
  { $ucs->{$p{$_}{'gid'}} = $p{$_}{'nome'}; }
  return $ucs;
}

#===================================================================== GET_AVAILABLE_UFS
#=====================================================================
sub get_available_ufs
{ my ($cfg) = @_;

  my $sql = $cfg->connect();

  my $ufs = {};

  my %p  = $sql->query("select distinct gid,nome_estado from map_ufs,record where ST_contains(map_ufs.geom,record.point)");

  foreach (0..$sql->nRecords-1)
  { $ufs->{$p{$_}{'gid'}} = $p{$_}{'nome_estado'} }

  return $ufs;
}
#===================================================================== GET_CENTROID
#=====================================================================
sub get_centroid
{ my ($cfg,$table,$gid) = @_;

  return { lat => 0, lng => 0 } if !$gid;

  my $sql = $cfg->connect();

  my %p = $sql->query("select ST_AsText(ST_Centroid(geom)) as coords from $table where gid = $gid");

  if ($p{0}{'coords'} =~ /(-?\d+.\d+) (-?\d+.\d+)/) { return { lat => $2, lng => $1 } }

  return { lat => 0, lng => 0 };

#  { lat: -12.8732, lng: -41.3751 }
}
#===================================================================== GET_MIN_EVENT_YEAR
sub get_min_event_year
{ my $cfg = shift;
   my $sql = $cfg->connect();
  my %p = $sql->query("select min(substring(eventdate,7,4)) from record where eventdate ~ '\\d\\d/\\d\\d/\\d\\d\\d\\d';");
  return $p{0}{'min'};
}
#===================================================================== GET_MAX_EVENT_YEAR
sub get_max_event_year
{ my $cfg = shift;
   my $sql = $cfg->connect();
  my %p = $sql->query("select max(substring(eventdate,7,4)) from record where eventdate ~ '\\d\\d/\\d\\d/\\d\\d\\d\\d';");
  return $p{0}{'max'};
}
#=====================================================================
#===================================================================== GET_RANDOM_THUMBS
#=====================================================================
sub get_random_thumbs
{ my($cfg,$n,$user_id,$image_of) = @_;

  my $data = [];
  $n = 1 if !$n;

  my $sql = $cfg->connect();

  my $cmd = "select count(1) from image";
  my $where  = '';
     $where .= " and user_id = $user_id" if $user_id;
     $where .= " and image_of = '$image_of'" if $image_of;
  $where =~ s/ and//;
    
  $cmd .= " where $where" if $where;

  my %q = $sql->query($cmd);
  my $max = $q{0}{'count'}+0;

  return [] if !$max;

  $n = $max if $max < $n;

  my %done = ();

  my $i = 0;
  while ($i < $n)
  { my $r = int(rand($max));

    $cmd  = "select * from image";
    $cmd .= " where $where" if $where;
    $cmd .= " offset $r limit 1";

    my %q = $sql->query($cmd);

    next if $done{$q{0}{'code'}};
    $done{$q{0}{'code'}} = 1;

    my $f_user_id = $cfg->format_user_id($q{0}{'user_id'});

    $data->[$i] = 
	{	id		=> $q{0}{'id'},
	 	code		=> $q{0}{'code'},
		user_id		=> $q{0}{'user_id'},
		record_id	=> $q{0}{'record_id'},
		sequence	=> $q{0}{'sequence'},
		image_of	=> $q{0}{'image_of'},
		original	=> "$q{0}{'code'}.$q{0}{'format'}",
		original_url	=> "$cfg->{'user_url'}/$f_user_id/$q{0}{'code'}.$q{0}{'format'}",

		thumb		=> "$q{0}{'code'}_thumb.$q{0}{'format'}",
		thumb_url	=> "$cfg->{'user_url'}/$f_user_id/$q{0}{'code'}_thumb.$q{0}{'format'}",

		large		=> "$q{0}{'code'}_large.$q{0}{'format'}",
		large_url	=> "$cfg->{'user_url'}/$f_user_id/$q{0}{'code'}_large.$q{0}{'format'}"
	};
    $i++;
  } 

  return $data;
}

#===================================================================== NEXT_SVG_COLOR
sub next_svg_color
{ my ($cfg) = @_;
  my $k;
  do { $k = chr(int(rand(4)+65)) } until ($k ne $cfg->{'svg_last_color'}) && ($k ne $cfg->{'svg_prev_color'});
  $cfg->{'svg_prev_color'} = $cfg->{'svg_last_color'};
  $cfg->{'svg_last_color'} = $k;
  return "--svg-$k";
}

#===================================================================== BUILD_SVG_CAPTION
sub user_svg
{ my ($cfg,$user_id) = @_;
  my $counts = $cfg->counts();

  my $temp = {
		1 => {	form => 'polygon', data => 'points="1,16, 26,1, 52,16, 51,46, 26,59, 1,44"',
			stroke => 'var('.$cfg->next_svg_color().')', image_data => 'x="0" y="0" width="55" height="61"'
		     },

                2 => {	form => 'polygon', data => 'points="38,28, 79,4, 122,28, 122,77, 80,101, 38,77"',
			stroke => 'var('.$cfg->next_svg_color().')', image_data => 'x="35" y="2" width="90" height="100"'
		     },

		3 => {	form => 'polygon', data => 'points="35,127, 80,50, 169,50, 215,128, 169,206, 79,206"',
			stroke => 'var('.$cfg->next_svg_color().')', image_data => 'x="20" y="48" width="187" height="161"'
		     },

		4 => {	form => 'polygon', data => 'points="116,94, 169,41, 240,61, 257,133, 202,185, 132,165"',
			stroke => 'var('.$cfg->next_svg_color().')', image_data => 'x="112" y="39" width="147" height="147"' 
		     },
		5 => {	form => 'circle', data => 'r="45" cy="177" cx="68"',
			stroke => 'var('.$cfg->next_svg_color().')', image_data => 'x="18" y="131" width="97" height="93"' },

		6 => {	form => 'polygon', data => 'points="142,153, 203,138, 247,184, 229,244, 168,259, 124,213"',
			stroke => 'var('.$cfg->next_svg_color().')', image_data => 'x="123" y="135" width="126" height="126"'
		     },

		7 => {	form => 'polygon', data => 'points="199,217, 241,193, 283,217, 283,266, 241,290, 199,266"',
			stroke => 'var('.$cfg->next_svg_color().')', image_data => 'x="197" y="190" width="88" height="101"'
		     },

		8 => {	form => 'polygon', data => 'points="269,226, 316,215, 350,251, 334,298, 288,308, 255,272"',
			stroke => 'var('.$cfg->next_svg_color().')', image_data => 'x="252" y="211" width="98" height="96"'
		     }
	    };
  my $nFig = scalar keys %$temp;
  my $num_rec = $counts->{$user_id}{'num_rec'};
  my $num_imgs = $num_rec ? int($num_rec/($nFig/2))+1 : 0;
     $num_imgs = $nFig if $num_imgs > $nFig;

  my $idents_by = $counts->{$user_id}{'idents_by:animalia'}+$counts->{$user_id}{'idents_by:plantae'};
  my $num_fig   = $idents_by ? int($idents_by/($nFig/2))+$num_imgs : 0;
     $num_fig   = $nFig if $num_fig > $nFig;

  my $svg = <<EOM;
<svg width="350" height="310" xmlns="http://www.w3.org/2000/svg">
<g>
EOM
  my %done = ();
  foreach my $k (sort { $a <=> $b } keys %$temp)
  { if ($k > $num_imgs)
    { if ($k > $num_fig)
      { $svg .= <<EOM;
<$temp->{$k}{'form'} $temp->{$k}{'data'} stroke-width="2" stroke="$temp->{$k}{'stroke'}" fill="none"/>
EOM
      }
      else
      { $svg .= <<EOM;
<$temp->{$k}{'form'} $temp->{$k}{'data'} stroke-width="2" stroke="$temp->{$k}{'stroke'}" fill="$temp->{$k}{'stroke'}"/>
EOM
      }
    }
    else
    { my $img = [];
      do { $img = $cfg->get_random_thumbs(1,$user_id,($temp->{$k}{'form'} eq 'circle' ? 'planta' : 'interacao')) } until !$done{$img->[0]{'thumb'}};
      $done{$img->[0]{'thumb'}} = 1;

      $svg .= <<EOM;
<defs>
    <clipPath id='svg_$k'>
<$temp->{$k}{'form'} $temp->{$k}{'data'} fill="none"/>
    </clipPath>
</defs>
<image $temp->{$k}{'image_data'} clip-path="url(#svg_$k)" xlink:href="$img->[0]{'thumb_url'}"/>
EOM
    }
  }

  $svg .= <<EOM;
</g>
</svg>
EOM

  return $svg;
}

#===================================================================== BUILD_SVG_CAPTION

sub build_svg_caption # ( { record_id => id, kingdom => 'animalia|plantae', image_id => img_id } )
{ my ($cfg,$par) = @_;

  return '' if !$par->{'record_id'} || !$par->{'kingdom'};

  my $sql = $cfg->connect();
  my $dic = $cfg->dic();

  my $cmd = <<EOM;
select  i.*,u.name as user_name,r.country,r.stateprovince,r.municipality,r.locality,r.eventdate
from    ident_view i
        left join record r on (i.record_id = r.id)
        left join users u on (r.user_id = u.id)
where   i.record_id = $par->{'record_id'} and i.kingdom = '$par->{'kingdom'}'
order by i.status desc, i.datevalidated desc nulls last, i.dateidentified desc nulls last;
EOM

  my %p = $sql->query($cmd);

  if (!$sql->nRecords)	# no identification available, so get the record and user data only
  { $cmd = <<EOM;
select  u.name as user_name,r.country,r.stateprovince,r.municipality,r.locality,r.eventdate
from    record r
        left join users u on (r.user_id = u.id)
where   r.id = $par->{'record_id'}
EOM

    %p = $sql->query($cmd);
  }
  return '' if !$sql->nRecords;

  my $caption = "<table class='w100 noBorder'><tr><td>";
     $caption .= "<b>$p{0}{'vernacularname'}</b><br/>" if $p{0}{'vernacularname'};
     $caption .= "<span class='sp'>$p{0}{'scientificname'}</span><br/>" if $p{0}{'scientificname'};

     my $d = $p{0}{'eventdate'} =~ /(\d+).(\d+).(\d+)/ ? "$1-$2-$3" : '';
     my $l = "$d, $p{0}{'locality'}, $p{0}{'municipality'}, $p{0}{'stateprovince'}, $p{0}{'country'}";
     $l =~ s/^, //g;
     $l =~ s/(, )+/, /g;

     $caption .= "<span class='tag'>$dic->{'tag_observed_on'}</span> $l<br/>" if $l;

     $caption .= "<span class='tag'>$dic->{'tag_fotografed_by'}</span> $p{0}{'user_name'}<br/>" if $p{0}{'user_name'};
     $caption .= "</td>";
 
     $caption .= "<td class='direita'><a href='/denuncia?record_id=$par->{'record_id'}&image_id=$par->{'image_id'}' class='alert'>$dic->{'denunciar'}</a></td>";
     $caption .= "</tr></table>";

  return $caption;
}

#===================================================================== BUILD_SVG_CIRC
# returns an svg code with the original image clipped by a circle
# the svg code is embedded in a highslide call to enlarge the image
# if large_url is not present, the svg is not embeded in a link
#=====================================================================
sub build_svg_circ # ( { record_id => id, large_url => 'http://...', thumb_url => 'http://...', radius => 60, image_id => 'id'
{ my ($cfg,$par) = @_;
  $cfg->{'nSVG'}++;

  my $r = $par->{'radius'};
  my $d = $r*2;

  my $image_id = $par->{'image_id'} ? " id='$par->{'image_id'}' preserveAspectRatio='none'" : '';

  my $svg = <<EOM;
<svg width='$d' height='$d' xmlns='http://www.w3.org/2000/svg' xmlns:svg='http://www.w3.org/2000/svg'>
	<defs><clipPath id="Circ$cfg->{'nSVG'}"><circle cx="$r" cy="$r" r="$r" fill="transparent"/></clipPath></defs>
<image x='0' y='0' width='$d' height='$d' clip-path='url(#Circ$cfg->{'nSVG'})' xlink:href='$par->{'thumb_url'}'$image_id/>
</svg>
EOM

  my $caption = $cfg->build_svg_caption({ record_id => $par->{'record_id'}, kingdom => 'plantae', image_id => $par->{'image_id'} });

  my $slideGroup = $par->{'slideGroup'} || $par->{'record_id'};

  $svg = "<a href='$par->{'large_url'}' class='highslide' onclick='return hs.expand(this, { slideshowGroup: $slideGroup })'>$svg</a>".
	 "<div class='highslide-caption'><small>$caption</small></div>" if $par->{'large_url'};
  $svg =~ s/>\s+</></g;
  return $svg;
}
#===================================================================== BUILD_SVG_HEX
# returns an svg code with the original image clipped by an hexagon
# the svg code is embedded in a highslide call to enlarge the image
# if large_url is not present, the svg is not embeded in a link
#=====================================================================
sub build_svg_hex # ( { record_id => id, large_url => 'http://...', thumb_url => 'http://...', radius => 60, mode => 'flatTop*|pointyTop', image_id => 'id'
{ my ($cfg,$par) = @_;

#  my $pol = '60,0 112,30 112,90 60,120 8,90 8,30';
#  my $pol = '30,8 90,8 120,60 90,112 30,112 0,60';

  $cfg->{'nSVG'}++;

  my $R = $par->{'radius'};

  my @polX = ( 0.5*$R, 1.5*$R, 2*$R, 1.5*$R, 0.5*$R, 0);

  my $r = $R * sqrt(3) * 0.5;

  my @polY = ( $R-$r, $R-$r, $R, $R+$r, $R+$r, $R);

  my $pol = '';
  foreach (0..$#polX) { $pol .= $par->{'mode'} =~ /pointy/i ? "$polY[$_],$polX[$_] " : "$polX[$_],$polY[$_] " }
  $pol =~ s/\s+$//g;

  my $d = $R*2;

  my $image_id = $par->{'image_id'} ? " id='$par->{'image_id'}' preserveAspectRatio='none'" : '';

  my $svg = <<EOM;
<svg width='$d' height='$d' xmlns='http://www.w3.org/2000/svg' xmlns:svg='http://www.w3.org/2000/svg'>
<defs><clipPath id="Hex$cfg->{'nSVG'}"><polygon points="$pol" fill="transparent"/></clipPath></defs>
<image x='0' y='0' width='$d' height='$d' clip-path='url(#Hex$cfg->{'nSVG'})'
	xlink:href='$par->{'thumb_url'}'$image_id/>
</svg>
EOM

  my $caption = $cfg->build_svg_caption({ record_id => $par->{'record_id'}, kingdom => 'animalia', image_id => $par->{'image_id'} });

  my $slideGroup = $par->{'slideGroup'} || $par->{'record_id'};

  $svg = "<a href='$par->{'large_url'}' class='highslide' onclick='return hs.expand(this, { slideshowGroup: $slideGroup })'>$svg</a>".
	 "<div class='highslide-caption'><small>$caption</small></div>" if $par->{'large_url'};
  $svg =~ s/>\s+</></g;
  return $svg;
}
#===================================================================== BUILD_SVG
# returns a hash with all images in the %$photo hash clipped in circles
# or hexagons depending on what they represent
#=====================================================================
sub build_svg
{ my ($cfg,$photo) = @_;

  my $SVG = { planta => [], interacao => [] };

  foreach my $i (0..$#$photo)
  { if ($photo->[$i]{'image_of'} eq 'interacao') #HEXAGONO
    { push @{$SVG->{'interacao'}},
	$cfg->build_svg_hex( {	thumb_url => $photo->[$i]{'thumb_url'},
				large_url => $cfg->{'user_level'} > 0 ? $photo->[$i]{'original_url'} : $photo->[$i]{'large_url'},
				record_id => $photo->[$i]{'record_id'},
				image_id  => $photo->[$i]{'id'},
				radius    => 60,
				mode      => 'flat'
			     } );
    }
   else	#CIRCULO
   { push @{$SVG->{'planta'}},
	$cfg->build_svg_circ( {	thumb_url => $photo->[$i]{'thumb_url'},
				large_url => $cfg->{'user_level'} > 0 ? $photo->[$i]{'original_url'} : $photo->[$i]{'large_url'},
				record_id => $photo->[$i]{'record_id'},
				image_id  => $photo->[$i]{'id'},
				radius    => 56
			      } );
   }
  }

  return $SVG;
}

#==========================================================================================
sub  verify_appcode
{ my ($cfg,$appcode) = @_;
  my $sql = $cfg->connect();

  my %p = $sql->query("select user_id from device where appcode = '$appcode'");
  return 0 if $sql->error() || $sql->nRecords() != 1;

  $sql->exec("update users set last_seen = now() where id = $p{0}{'user_id'};");
  return $p{0}{'user_id'};
}
#===================================================================== DIV_TOP_BANNER
#=====================================================================
sub div_top_banner
{ my ($cfg,$par) = @_;
  my $dic = $cfg->dic();
  my $html = ''; my @cell = ();
  my ($lang,$lang_string) = $cfg->{'user_lang'} eq 'pt' ? ('en',$dic->{'en'}) : ('pt',$dic->{'pt'});
  my $visibility = $cfg->{'mobile'} ? ' style="display:none;"' : '';

# definindo as classes dos itens

  my %class = ();
  foreach ('about', 'users', 'welcome', 'record', 'search', 'register', 'login') { $class{$_} = " class='mainMenuOff'" }
  $class{$par->{'page'}} = " class='mainMenuOn'";

  my %sub_class = ();
  foreach('about', 'howto', 'credits', 'indicators', 'faq', 'form', 'help', 'glossary') { $sub_class{$_} = " class='subMenuOff'" }
  $sub_class{$par->{'sub_page'}} = " class='subMenuOn'";

# linha 1, coluna 1

  $cell[0][0] = $par->{'page'} eq 'home' ? '&#160;' :
			"<a href='/'><img src='/imgs/marca_$cfg->{'palette_id'}.png' align='left' height='30px' hspace='10px'/></a>";

# linha 1, coluna 2

  $cell[0][1] = <<EOM;
	<table cellspacing='1' cellpadding='1' border='0'>
		<tr>
			<td><a href='/about'$class{'about'}>$dic->{'about'}</a></td>
			<td class='mainMenuSep'>&#160;&#x25c6;&#160;</td>
			<td><a href='/users'$class{'users'}>$dic->{'guardians:lc'}</a></td>
		</tr>
	</table>
EOM

# linha 1, coluna 3
 my $user =  $cfg->current_session_id() ? $cfg->get_user_info() : {};

  $cell[0][2] = $cfg->current_session_id() ? <<EOM
	<table cellspacing='1' cellpadding='1' border='0'>
		<tr>
			<td><a href='/welcome'><i $class{'welcome'} style='font-weight: normal'>$user->{'name'}</i></a></td>
			<td class='mainMenuSep'>&#160;&#x25c6;&#160;</td>
			<td><a href='/record'$class{'record'}>$dic->{'new_record'}</a></td>
		</tr>
	</table>
EOM
	: '&#160;';
 
# linha 1, coluna 4

  my $pending = '';
  $cell[0][3] = $cfg->current_session_id() ? <<EOM
	<table cellspacing='1' cellpadding='1' border='0'>
		<tr>
			<!-- td><a href='/search?action=search&usr_id=$cfg->{'user_id'}'$class{'myrecords'}>$dic->{'my_records'}</a></td>
			<td class='mainMenuSep'>&#160;&#x25c6;&#160;</td -->
			$pending
			<td><a href='/search' $class{'search'}>$dic->{'Search:lc'}</a></td>
			<td width='10px'>&#160;</td>
	       </tr>
	</table>
EOM
:
<<EOM;
	<table cellspacing='1' cellpadding='1' border='0'>
		<tr>
			<td><a href='/search' $class{'search'}>$dic->{'Search:lc'}</a></td>
			<td width='10px'>&#160;
</td>
	       </tr>
	</table>
EOM


  $cell[1][0] = $par->{'page'} eq 'home' ?
			"<table><tr><td><a href=\"javascript:switchLang('$lang')\">$lang_string</a></td></tr></table>" : 
			'&#160;';
# linha 2, coluna 1

  $cell[1][1] = $par->{'page'} =~ /about/ ? <<EOM
<table cellspacing='1' cellpadding='1' border='0'>
        <tr>
                <td align='right'><a href='/about'$sub_class{'about'}>$dic->{'project'}</a></td>
                <td class='subMenuSep'>&#160;&#x25cf;&#160;</td>
                <td align='right'><a href='/howto'$sub_class{'howto'}>$dic->{'howto'}</a></td>
                <td class='subMenuSep'>&#160;&#x25cf;&#160;</td>
                <td align='right'><a href='/credits'$sub_class{'credits'}>$dic->{'credits:lc'}</a></td>
                <td class='subMenuSep'>&#160;&#x25cf;&#160;</td>
                <td align='right'><a href='/indicators'$sub_class{'indicators'}>$dic->{'Indicators:lc'}</a></td>
                <td class='subMenuSep'>&#160;&#x25cf;&#160;</td>
                <td align='right'><a href='/faq'$sub_class{'faq'}>$dic->{'FAQ:lc'}</a></td>
        </tr>
        </table>
EOM
	: '&#160;';

# linha 2, coluna 2

  $cell[1][2] = $par->{'page'} eq 'record' && $cfg->current_session_id() ? <<EOM
	<table cellspacing='1' cellpadding='1' border='0'>
	<tr>
		<td align='right'><a href="javascript:showDiv('Main')"$sub_class{'form'} id='subMenuItemMain'>$dic->{'form'}</a></td>
		<td class='subMenuSep'>&#160;&#x25cf;&#160;</td>
		<td align='right'><a href="javascript:showDiv('Help')"$sub_class{'help'} id='subMenuItemHelp'>$dic->{'help'}</a></td>
		<td class='subMenuSep'>&#160;&#x25cf;&#160;</td>
		<td align='right'><a href="javascript:showDiv('Glossary')"$sub_class{'glossary'} id='subMenuItemGlossary'>$dic->{'glossary'}</a></td>
	</tr>
        </table>
EOM
	: '&#160;';

# linha 2, coluna 3

  if ($cfg->current_session_id())
  { $cell[1][3] = <<EOM;
	<table cellspacing='1' cellpadding='1' border='0'>
		<tr>
			<td align='right'><a href='/register'$class{'register'}>$dic->{'account'}</a></td>
			<td class='subMenuSep'>&#160;&#x25cf;&#160;</td>
			<td align='right'><a href='/logoff'>$dic->{'logoff'}</a></td>
			<td width='10px'>&#160;</td>
    		</tr>
	</table>
EOM
  }
  else
  { $cell[1][3] = <<EOM;
	<table cellspacing='1' cellpadding='1' border='0'>
		<tr>
			<td align='right'><a href='/login'$class{'login'}>$dic->{'login'}</a>&#160;</td>
			<td width='10px'>&#160;</td>
    		</tr>
	</table>
EOM
  }

# done
	
  return <<EOM;
<div id='divTopBanner'$visibility>
<table class='w100' cellspacing='0' cellpadding='0' border='0'>
<tr class='mainMenuBg'>
    <td width='100px'>$cell[0][0]</td>
    <td width='30%' align='left'>$cell[0][1]</td>
    <td width='30%' align='center'>$cell[0][2]</td>
    <td width='30%' align='right'>$cell[0][3]</td>
</tr>
<tr class='subMenuBg'>
    <td width='100px' align='left'>$cell[1][0]</td>
    <td width='30%' align='left'>$cell[1][1]</td>
    <td width='30%' align='center'>$cell[1][2]</td>
    <td width='30%' align='right'>$cell[1][3]</td>
</tr>
</table>
</div>
EOM
}

# ==================================================================================
sub isValidDate #(day,mon,year)
{ my ($cfg,$day,$month,$year) = @_;
  my $ok = 0; 
  if (($day >= 1 && $day <= 31) && ($month >= 1 && $month <= 12) && ($year >= 1900 && $year <= 2100))
  { # bissexto
       if ( $day == 29  && ((($year % 400) == 0) || (($year % 4) == 0 && ($year % 100) != 0))) { $ok = 1 }
    elsif ( $day <= 28  && $month == 2) { $ok = 1 }
    elsif (($day <= 30) && ($month == 4 || $month == 6 || $month == 9 || $month == 11)) { $ok = 1  }
    elsif (($day <= 31) && ($month == 1 || $month == 3 || $month == 5 || $month == 7 || $month == 8 || $month == 10 || $month == 12)) { $ok = 1  }
  }
  return $ok;
}
# ==================================================================================
sub maxDayOf #(mon,year)
{ my ($cfg,$month,$year) = @_;
  foreach my $i (31,30,29,28) { return $i if $cfg->isValidDate($i,$month,$year) }
}

# ==================================================================================
sub get_page
{ my ($cfg,$par) = @_;

  my $page = $par->{'page'};
  if (!$page)
  { my @p =  split('/',$0); $page = $p[$#p] }

  $page = "$cfg->{'lib_dir'}/pages/$page.$cfg->{'user_lang'}";

  return '' if ! -r $page;

  open(IN,"<:encoding(latin1)",$page);
  read(IN,my $text,(-s $page));
  close(IN);

  foreach my $key (keys %$par)
  { $text =~ s/\%$key\%/$par->{$key}/ig }
  
  return $text;
}
# ==================================================================================
sub unaccent
{ my ($cfg,$str) = @_;
  $str =~ tr/áéíóúâêîôûãõàèìòùäëïöüçýÿyñ/aeiouaeiouaoaeiouaeiouciiin/;
  return $str;
}
# ==================================================================================
sub rgba
{ my ($self,$color,$alpha) = @_;

  if ($color =~ /([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i)
  { if ($alpha)
    { $color = 'rgba('.hex($1).','.hex($2).','.hex($3).",$alpha)" }
    else
    { $color = 'rgb('.hex($1).','.hex($2).','.hex($3).")" }
  }
  return $color;
}
# ==================================================================================

1;

