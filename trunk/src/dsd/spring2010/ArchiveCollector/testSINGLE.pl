#!/usr/bin/perl

# used for testing or viewing one message
# help if you want look at the format of a message

use strict;
use warnings;
use Net::NNTP;
use Getopt::Std;
use DBI;

# constants used for header TAGs
use constant GROUPTAG => 'Newsgroups:';
use constant DATETAG => 'Date:';
use constant SUBJECTTAG => 'Subject:';
use constant FROMTAG => 'From:';
use constant REFERENCESTAG => 'References:';
use constant MESSAGEIDTAG => 'Message-ID:';
use constant NULLSTR => '0NULL0';

my $newshost = "lists.mysql.com";          # hard coded news host
my $nntp = Net::NNTP->new($newshost);      # open connection to news host
#  hardcode these two variables to test a single message
my $thegroup = "mysql.internals";
my $msgnum = "37878";

#given string
#returns true if the line is a tagged line
#a tagged line is if the first word has :
sub isTAG {
    my ($word) = @_;
    my $retval=0;

    # check if : is last character 
    my $lastchar = substr($word,length($word)-1);
    if ($lastchar eq ":") {
       $retval=1;
    }
    return($retval);
}

#give date string with format
# Mon, 25 Sep 2000 16:50:10 +0200 (CDT)
# return string without timezone
sub cleanDateField {
    my ($rawline) = @_;
    my $retval = "";
    my $junk;

    # check if there is a TZ
    # check if day of the week is included
    if ($rawline =~ m/\(/) {
       ($rawline, $junk) = split(/\(/,$rawline);
    }
 
    # check if day of the week is included
    if ($rawline =~ m/,/) {
       ($junk, $rawline) = split(/,/,$rawline);
       $rawline = removeSPACE($rawline);
    }

    my @dateinfo = split(/ /,$rawline);

    if (@dateinfo > 5) {
       $retval = "$dateinfo[1] $dateinfo[2] $dateinfo[3] $dateinfo[4]";
    } else {
       $retval = "$dateinfo[0] $dateinfo[1] $dateinfo[2] $dateinfo[3]";
    }

    return($retval);
}

#given string
#returns tag string if it is valid
#otherwise, return empty string;
#a tagged line is if the first word has :
sub getTAG {
    my ($line) = @_;
    my ($firstword) = split(/ /,$line);
    my $retval="";

    #check if valid tag and set the tag
    if (isTAG($firstword)) {
       $retval=$firstword;
    }
    return($retval);
}

#given string
#remove tag if it exists
#return tagless line 
sub removeTAG {
    my ($line) = @_;
    my $retval=$line;

    # grab firstword and save the remainder
    # use firstword to check for tag
    my ($firstword,$therest) = split(/ /,$line,2);
    if (isTAG($firstword)) {
       $retval=$therest;
    }
    return($retval);
}

# given string
# remove random characters that are used for delimiters
# in TO/FROM fields
sub removeCHARS {
    my ($rawline) = @_;

    # cleanout delimiter characters
    $rawline =~ s/<//g;
    $rawline =~ s/>//g;
    $rawline =~ s/,/ /g;
    $rawline =~ s/"//g;
    $rawline =~ s/'//g;
    $rawline =~ s/=//g;
    $rawline =~ s/\(//g;
    $rawline =~ s/\)//g;
    $rawline =~ s/\\//g;
    $rawline =~ s/	//g;
    #trim leading and trailing spaces
    $rawline =~ s/^\s+//;
    $rawline =~ s/\s+$//;

    return($rawline);
}

# given string
# trim leading and trailing spaces
sub removeSPACE {
   my ($rawline) = @_;
   $rawline =~ s/^\s+//;
   $rawline =~ s/\s+$//;

   return($rawline);
}

# given subject text clean out space and other characters
# returns clean line
sub cleanSubjectField {
    my ($rawline) = @_;

    $rawline =~ s/\?//g;
    $rawline =~ s/\:/ /g;
    $rawline =~ s/\!/ /g;
    $rawline =~ s/\Ç//g;
    $rawline =~ s/\¿//g;
    $rawline =~ s/\Á//g;
    $rawline =~ s/\¦//g;
    $rawline =~ s/\Í//g;
    $rawline =~ s/\Æ//g;
    $rawline =~ s/\¼//g;
    $rawline =~ s/\ö//g;
    $rawline =~ s/\ß//g;
    $rawline =~ s/\Ë//g;
    $rawline =~ s/\Ù//g;
    $rawline =~ s/\¡//g;
    $rawline =~ s/\¢//g;
    $rawline =~ s/\Î//g;
    $rawline =~ s/\È//g;
    $rawline =~ s/\¶//g;
    $rawline =~ s/\¡//g;
    $rawline =~ s/\¢//g;
    $rawline =~ s/\¹//g;
    $rawline =~ s/\ú//g;
    $rawline =~ s/\Ä//g;
    $rawline =~ s/\Ú//g;
    $rawline =~ s/\î//g;
    $rawline =~ s/\º//g;
    $rawline =~ s/\Ã//g;
    $rawline =~ s/\Ä//g;
    $rawline =~ s/\·//g;
    $rawline =~ s/\þ//g;
    $rawline =~ s/\ñ//g;
    $rawline =~ s/\µ//g;
    $rawline =~ s/\"//g;
    $rawline =~ s/\¨//g;
    $rawline =~ s/\'//g;
    #trim leading and trailing spaces
    $rawline = removeSPACE($rawline);

    return($rawline);
}

# given a hash table
# builds a string of the keys seperated by space
sub hashTOstring {
    my ($href) = @_;
    my $strval = "";
    foreach(%$href) {
       if ($strval ne "") {
          $strval = $strval . " " . $_;
       } else {
          $strval = $_;
       }
    }
    return($strval);
}

$nntp->group($thegroup);
my $theheader = $nntp->head($msgnum);

# returns a record with the email address and an attempt
# at the persons name. it's really just guessing but still might be
# helpful
sub cleanFROM {
    my ($rawline) = @_;
    $rawline = removeTAG($rawline);
    $rawline = removeCHARS($rawline);
    my @allwords = split(/ /,$rawline);
    # record that contains FROM information 
    # initialize to empty strings
    my $fromrec = {
       ADDR => "",
       FNAME => "",
       LNAME => "",
    };
    foreach(@allwords) {
       # clean out any additional spaces
       my $cleanword = removeCHARS($_);
       # check if its more than an initial
       # and more than @
       if (length($cleanword) > 1) {
          # check if its a mail address
          if ($cleanword =~ m/\@/) {
             $fromrec->{ADDR} = $cleanword;
          } else {
             # its as good as guess as any.
             # just grab the best string available
             # and use it for a name
             if ($fromrec->{FNAME} eq "") {
                $fromrec->{FNAME} = $cleanword;
             } elsif ($fromrec->{LNAME} eq "") {
                $fromrec->{LNAME} = $cleanword;
             }
          }
       }
    }

    return($fromrec);
}

# given raw news group string
# return clean group line
sub cleanGROUP {
    my ($rawline) = @_;
    my $retval = "";
    $retval = removeTAG($rawline);

    return($retval);
}

# given raw subject string
# return clean subject line
sub cleanSUBJECT {
    my ($rawline) = @_;
    my $retval = "";
    $retval = removeTAG($rawline);

    return($retval);
}

# given raw message id string
# return clean message id string
sub cleanMESSAGEID {
    my ($rawline) = @_;
    my $retval = "";
    $retval = removeTAG($rawline);
    $retval = cleanID($retval);

    return($retval);
}

# given message id format, remove characters
# return plain message ide
sub cleanID {
    my ($rawline) = @_;
    my $retval = "";
    $rawline =~ s/\<//g;
    $rawline =~ s/\>//g;
    $retval = removeSPACE($rawline);
}

# given raw references string
# return clean references string
sub cleanREFERENCES {
    my ($rawline) = @_;
    my $retval = "";
    $retval = removeTAG($rawline);
    $retval = cleanID($retval);

    return($retval);
}

# given list of references
# gets last reference in the list
# return reference
sub cleanREPLYTO {
    my ($rawline) = @_;
    my $retval = "";
    my @listofref = split(/ /,$rawline);
    my $numofref = @listofref;
    $retval = $listofref[$numofref-1];
    
    return($retval);
}

#give date string with format
# Mon, 25 Sep 2000 16:50:10 +0200 (CDT)
# return string without timezone
sub cleanDATE {
    my ($rawline) = @_;
    my $retval = "";
    my $junk;

    # get rid of tag
    $rawline = removeTAG($rawline);

    # get rid of spaces
    $rawline = removeSPACE($rawline);

    # check if there is a TZ
    # check if day of the week is included
    if ($rawline =~ m/\(/) {
       ($rawline, $junk) = split(/\(/,$rawline);
    }

    # check if day of the week is included
    if ($rawline =~ m/,/) {
       ($junk, $rawline) = split(/,/,$rawline);
       $rawline = removeSPACE($rawline);
    }

    my @dateinfo = split(/ /,$rawline);

    if (@dateinfo > 5) {
       $retval = "$dateinfo[1] $dateinfo[2] $dateinfo[3] $dateinfo[4]";
    } else {
       $retval = "$dateinfo[0] $dateinfo[1] $dateinfo[2] $dateinfo[3]";
    }

    return($retval);
}

# given string that exists in a record field
# and another string to be added
# return updated string
sub updateRECORD {
    my ($recstr,$newstr) = @_;

    if ($newstr ne "") {
       if ( $recstr eq NULLSTR) {
          $recstr = $newstr;
       } else {
          $recstr = $recstr . " " . $newstr;
       }
    }

    return($recstr);
}

if ($#ARGV >= 0) {
   print(@$theheader);
} else {

    # record that contains message information 
    # initialize to empty strings
    my $msgrec = {
       MSGNUM => $msgnum,
       GROUP => NULLSTR,
       DATE => NULLSTR,
       SUBJECT => NULLSTR,
       FROM => NULLSTR,
       FNAME => NULLSTR,
       LNAME => NULLSTR,
       MESSAGEID => NULLSTR,
       REFERENCES => NULLSTR,
       REPLYTO => NULLSTR,
       BODY => NULLSTR,
    };

   my $curtag="";
   foreach(@$theheader) {
      chomp($_);
      my $tmptag=getTAG($_);
      #set current tag value
      if ($tmptag ne "") {
         $curtag=$tmptag;
      }

       #fill record based on valid tag
       #a tag is the first word of the message 
       #with : at the end
       #using if statements. might be faster to use hash
       #for some performance speed up. lets see
       if ($curtag eq GROUPTAG) {
          my $cleangroup = cleanGROUP($_);
          $msgrec->{GROUP} = updateRECORD($msgrec->{GROUP},$cleangroup);
       }
       if ($curtag eq DATETAG) {
          my $cleandate = cleanDATE($_);
          $msgrec->{DATE} = updateRECORD($msgrec->{DATE},$cleandate);
       }
       if ($curtag eq SUBJECTTAG) {
          my $cleansubline = cleanSUBJECT($_);
          $msgrec->{SUBJECT} = updateRECORD($msgrec->{SUBJECT},$cleansubline);
       }
       if ($curtag eq FROMTAG) {
          my $fromrec = cleanFROM($_);
          $msgrec->{FROM} = updateRECORD($msgrec->{FROM},$fromrec->{ADDR});
          $msgrec->{FNAME} = updateRECORD($msgrec->{FNAME},$fromrec->{FNAME});
          $msgrec->{LNAME} = updateRECORD($msgrec->{LNAME},$fromrec->{LNAME});
       }
       if ($curtag eq MESSAGEIDTAG) {
           my $cleanmsgidline = cleanMESSAGEID($_);
           $msgrec->{MESSAGEID} = updateRECORD($msgrec->{MESSAGEID},$cleanmsgidline);
       }
       if ($curtag eq REFERENCESTAG) {
           my $cleanrefsline = cleanREFERENCES($_);
           $msgrec->{REFERENCES} = updateRECORD($msgrec->{REFERENCES},$cleanrefsline);
           #continuously update reply to with last entry in the line
           #this will give us the actual parent
           $msgrec->{REPLYTO} = cleanREPLYTO($msgrec->{REFERENCES});
       }
   }

   print("MSGNUM     - $msgrec->{MSGNUM}\n");
   print("GROUP      - $msgrec->{GROUP}\n");
   print("DATE       - $msgrec->{DATE}\n");
   print("FROM       - $msgrec->{FROM}\n");
   print("REPLYTO    - $msgrec->{REPLYTO}\n");
   print("FNAME      - $msgrec->{FNAME}\n");
   print("LNAME      - $msgrec->{LNAME}\n");
   print("REFERENCES - $msgrec->{REFERENCES}\n");
   print("MESSAGEID  - $msgrec->{MESSAGEID}\n");
   print("SUBJECT    - $msgrec->{SUBJECT}\n");

}
$nntp->quit;
