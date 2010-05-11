#!/usr/bin/perl

# used for testing or viewing one message
# help if you want look at the format of a message

use strict;
use warnings;
use Net::NNTP;
use Getopt::Std;
use DBI;

my $newshost = "lists.mysql.com";          # hard coded news host
my $nntp = Net::NNTP->new($newshost);      # open connection to news host
#  hardcode these two variables to test a single message
my $thegroup = "mysql.users-conference";
my $msgnum = "7";

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
    $rawline =~ s/	//g;
    #trim leading and trailing spaces
    $rawline =~ s/^\s+//;
    $rawline =~ s/\s+$//;

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

# given TO field. clean out all unnecessary junk
# returns only email aliases
sub cleanTOField {
    my ($rawline) = @_;
    my %tmpaddressholder = ();

    $rawline = removeCHARS($rawline);
    my @allwords = split(/ /,$rawline);
    foreach(@allwords) {
       # clean out any additional spaces
       my $cleanaddr = removeCHARS($_);
       # check if its a mail address
       if ($cleanaddr =~ m/\@/) {
          if (not exists $tmpaddressholder{$cleanaddr}) {
             $tmpaddressholder{$cleanaddr} = "";
          }
       }
    }
    my $cleanline= hashTOstring(\%tmpaddressholder);
    return($cleanline);
}

$nntp->group($thegroup);
my $theheader = $nntp->head($msgnum);

if ($#ARGV >= 0) {
   print(@$theheader);
} else {
   my $curtag="";
   foreach(@$theheader) {
      chomp($_);
      my $tmptag=getTAG($_);
      #set current tag value
      if ($tmptag ne "") {
         $curtag=$tmptag;
      }
     if ($curtag eq "To:") {
        my $cleanTOline = cleanTOField(removeTAG($_));
        print("$cleanTOline\n");
     }
     if ($curtag eq "From:") {
        my $cleanFROMline = removeCHARS(removeTAG($_));
        print("$cleanFROMline\n");
     }
   }
}
$nntp->quit;
