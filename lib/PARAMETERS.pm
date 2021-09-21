# modificado para permitir varias imagens. 
package PARAMETERS;
use strict;
use Encode;

#==================================================================
sub new
{ my $class = ref($_[0])||$_[0]; shift;
  my $encode = shift;

  my $self = {	_method_ => '',
		data	 => {},
		filename => {},
		content	 => {},
		stdin	 => ''
	     };

  if ($ENV{'REQUEST_METHOD'} eq 'POST')
  { return bless $self, $class if !$ENV{'CONTENT_LENGTH'};

    $self->{'_method_'} = 'post';

    read(STDIN,my $buf,$ENV{'CONTENT_LENGTH'});
#open(OUT,'>>/system/guardioes/tmp/PARAMETERS.debug');
#print OUT $buf;
#close OUT;

    if ($encode)
    { my $buf1 = Encode::decode('utf-8',$buf,Encode::FB_HTMLCREF);
      $buf = $buf1 if $buf1;
      $buf = $encode =~ /latin1|iso\-8859\-1/i ?
             Encode::encode('latin1',$buf,Encode::FB_HTMLCREF) :
             $encode =~ /ascii|decimal/i ?
             Encode::encode('ascii',$buf,Encode::FB_HTMLCREF) :
             $encode =~ /utf/i ? 
             Encode::encode('utf8',$buf,Encode::FB_HTMLCREF) :
             $buf;
    }

# post + outro content-type  
    if ($ENV{'CONTENT_TYPE'} !~ /multipart\/form-data/)
    { foreach (split('&',$buf))
      { my ($a,@b) = split('=',$_);
        if (@b)
        { push @{$self->{'data'}->{$a}},join('=',@b);
        }
      }

      foreach my $key (keys %{$self->{'data'}})
      { foreach my $i (0..$#{$self->{'data'}->{$key}})
        { $self->{'data'}->{$key}[$i] =~ s/\+/ /g;
          while ($self->{'data'}->{$key}[$i] =~ /%(..)/)
          { if ($1 == 25)
            { $self->{'data'}->{$key}[$i] =~ s/%$1/_PERCENT_CHAR_/g }
            else
            { $a = hex($1);
              $a = sprintf("%c",$a);
              $self->{'data'}->{$key}[$i] =~ s/%$1/$a/g;
            }
          }
          $self->{'data'}->{$key}[$i] =~ s/_PERCENT_CHAR_/%/g;
        }
      }
    }
# post + content-type = multipart/form-data
    else
    { my ($separator,$a,$sep,@in,$i,$name,$filename,@parts,$start,$k,@tags) = ();
#open(DBG,'>html/tmp/content_type'); print DBG "$ENV{'CONTENT_TYPE'}\n$buf"; close(DBG);
  
      $separator = (split(';',$ENV{'CONTENT_TYPE'}))[1];
      ($a,$separator) = split('=',$separator);
  
      $sep = '--'.$separator."--\cM\n";
      $buf =~ s/$sep//;
  
      $separator = '--'.$separator."\cM\n";
      @in = split($separator,$buf);
  
      for ($i=0;$i<=$#in;$i++)
      { $name = $filename = '';
        @parts = split("\cM\n",$in[$i]);
  
        $start = 2;
        for ($k=0;$k<=$#parts;$k++)
        {  if (!$parts[$k]) { $start = $k + 1; last } }
 
        @tags = split(';',$parts[0]);
        for ($k=0;$k<=$#tags;$k++)
        { if ($tags[$k] =~ /filename/) 
          { ($a,$filename) = split('=',$tags[$k]);
             $filename =~ s/"//g;
          }
          elsif ($tags[$k] =~ /name/) 
          { ($a,$name) = split('=',$tags[$k]); $name =~ s/"//g }
        }
  
        $in[$i] = join("\cM\n",@parts[$start..$#parts]);
  
        if ($name)
        { my $k = $#{$self->{'data'}->{$name}}+1;
          $self->{'data'}->{$name}[$k] = $in[$i];
          if ($filename) 
          { $self->{'filename'}->{$name}[$k] = $filename; 
            $self->{'content'}->{$name}[$k] = $parts[1];
            $self->{'content'}->{$name}[$k] =~ s/Content-Type: //;
  
            $self->{'filename'}->{$name}[$k] =~ s/\+/ /g;
            while ($self->{'filename'}->{$name}[$k] =~ /%(..)/)
            { if ($1 == 25)
              { $self->{'filename'}->{$name}[$k] =~ s/%$1/_PERCENT_CHAR_/g }
              else
              { $a = hex($1);
                $a = sprintf("%c",$a);
                $self->{'filename'}->{$name}[$k] =~ s/%$1/$a/g;
              }
            }
            $self->{'filename'}->{$name}[$k] =~ s/_PERCENT_CHAR_/%/g;
          }
        }
      }
    }
  }
#-------- prg?name=Jose&age=32
  elsif ($ENV{'QUERY_STRING'} && ($ENV{'REQUEST_METHOD'} eq 'GET'))
  { $self->{'_method_'} = 'get';
    foreach my $e (split('&',$ENV{'QUERY_STRING'}))
    { my ($a,$b) = split('=',$e);
      while ($b =~ /\%(..)/)
      { my $c = chr(hex($1)); $b =~ s/\%$1/$c/g }
      push @{$self->{'data'}->{$a}},$b;
    }
  }
#-------- prg?Jose+32
  elsif (@ARGV)
  { foreach (0..$#ARGV-1) { push @{$self->{'data'}->{$_}},$ARGV[$_] }
  }

  bless $self, $class;
}

#------------------------------------------------------------
sub data
{ my ($self, $key, $k) = @_;
  return defined $k ? $self->{'data'}->{$key}[$k] : $self->{'data'}->{$key}[0];
}
#------------------------------------------------------------
sub keys
{ my ($self) = @_;
  return sort keys %{$self->{'data'}};
}

#------------------------------------------------------------
sub content
{ my ($self, $key,$k) = @_;
  return defined $k ? $self->{'content'}->{$key}[$k] : $self->{'content'}->{$key}[0];
}

#------------------------------------------------------------
sub filename
{ my ($self, $key,$k) = @_;
  return defined $k ? $self->{'filename'}->{$key}[$k] : $self->{'filename'}->{$key}[0];
}
#------------------------------------------------------------
sub method
{ my ($self) = @_;
  return $self->{'_method_'};
}


1;
