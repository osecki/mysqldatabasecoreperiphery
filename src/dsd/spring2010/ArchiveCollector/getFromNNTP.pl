#!/usr/bin/perl

# built and tested on tux system  (linux x86_64 , perl 5.10)
# connects news group host and gets header information for a 
# given new group.

#issues currently takes to long to grab messages. if we are grabbing 
#100,000 messages then this might be too slow
#20,000 messages takes 23 minutes

use strict;
use warnings;
use lib qw(../../../../lib);               # include local references
use Net::NNTP; 
use Getopt::Std;
use DBI;


# constants used for header TAGs
use constant GROUPSTR => 'Newsgroups:';
use constant DATESTR => 'Date:';
use constant TOSTR => 'To:';
use constant SUBJECTSTR => 'Subject:';
use constant FROMSTR => 'From:';
use constant CCSTR => 'Cc:';

#initialize global variables
my $newshost = "lists.mysql.com";          # hard coded news host
my $nntp = Net::NNTP->new($newshost);      # open connection to news host
my $grphashref=0;                          # reference to hash table of news groups
my $printonly=0;                           # global flag to print num. of messages 
my $dbh;                                   # postgresql db handler 
my $dbhost="wander";                       # db hostname
my $dbport="5432";                         # db port
my $dbname="CS680ateam";                   # db name
my $dbuser="sms28";                        # db user name
my $dbpasswd="";               # db password


# print script usage
sub Usage {
    print("\n");
    print("getFromNNTP.pl [-a | -f <newsgroup file> | -l <newsgroups> ] | [-p]\n");
    print("\n");
    print("	connects to NNTP server lists.mysql.com \n");
    print("	grabs messages from given news groups. \n");
    print("	requires at least one argument a|f|l \n");
    print("	-a\n");
    print("		grabs all available news groups\n");
    print("	-f <newsgroup file>\n");
    print("		file containing list of news groups with one on each line\n");
    print("	-l <newsgroups>\n");
    print("		list of news groups seperated by spaces within quotes\n");
    print("	-p\n");
    print("		print the number of messages for each news group\n");
    print("\n");
    print("	note:\n");
    print("	precedence of arguments (l, f, a)  if one or more are given\n");
    exit(0);
}

#given group key and reference to hash table
#add to hash table
sub addToGrpTable {
    my ($thegroup,$href) = @_;
    #temp array filler to mimic hash table from
    #NNTP "list"
    my @tmparray=(0,0);
    if (not exists $href->{$thegroup}) {
       $href->{$thegroup} = \@tmparray;
    }
}

#given file of news groups with a group on each line.
#returns : hash table reference with group as keys
#returns empty hash if there are issues with the file
sub processGroupFile {
    my ($thefile) = @_;
    my %grouplist = ();

    #process file
    if (-e $thefile) {
       open(GROUPNAMES, $thefile);
       while(my $line = <GROUPNAMES>) {
            #get rid of newline
            chomp($line);
            #only get non-blank line
            if (length($line) > 0) {
               #only get one word from the line
               my ($groupname) = split(' ',$line);
               addToGrpTable($groupname,\%grouplist);
            }
       }
       close(GROUPNAMES);
    }
    return(\%grouplist);
}

#given a list of news groups seperated by spaces.
#returns : hash table reference with group as keys
sub processGroupArgList {
    my ($groupstr) = @_;
    my @rawgrouplist = split(/ /,$groupstr);
    my %grouplist = ();
    foreach(@rawgrouplist) {
       addToGrpTable($_,\%grouplist);
    }
    return(\%grouplist);
}

#given a hash table reference, 
#print the group name and number of messages
#to stdout
sub doPrint {
    my ($href) = @_;

    foreach my $curgroup (keys %$href) {
       my $msglistref = $nntp->listgroup($curgroup);
       # returns undefined if news group doesn't exist
       my $numrecs=0;
       if (defined($msglistref)) {
          $numrecs=@$msglistref;
       }
       print("$curgroup : $numrecs\n"); 
    }
}


# given a perl record of header information and
# an array reference with body text
# insert into db table
### do db work here
sub insertRecordToDB {
    my ($msgrec,$bodyref) = @_;
    print("MSGNUM  - $msgrec->{MSGNUM}\n");
    print("GROUP   - $msgrec->{GROUP}\n");
    print("DATE    - $msgrec->{DATE}\n");
    print("TO      - $msgrec->{TO}\n");
    print("FROM    - $msgrec->{FROM}\n");
    print("FNAME   - $msgrec->{FNAME}\n");
    print("LNAME   - $msgrec->{LNAME}\n");
    print("SUBJECT - $msgrec->{SUBJECT}\n");
    ##my $sth = $dbh->prepare("INSERT INTO public.persons (fname,lname) VALUES(?,?)");
    ##$sth->execute("Sam","Stahlback");
    ##$dbh->commit;
    ##$sth = $dbh->prepare("SELECT * FROM public.persons");
    ##$sth->execute();
    ##while ( my @row = $sth->fetchrow_array()) {
    ##  print("@row\n");
    ##}
}

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
       my $cleanword = removeCHARS($_);
       # check if its a mail address
       if ($cleanword =~ m/\@/) {
          #try to avoid aliases that are just @
          if (length($cleanword) > 1) {
             if (not exists $tmpaddressholder{$cleanword}) {
                $tmpaddressholder{$cleanword} = "";
             }
          }
       }
    }
    my $cleanline= hashTOstring(\%tmpaddressholder);
    return($cleanline);
}

# given FROM field. clean out all unnecessary junk
# returns a record with the email address and an attempt
# at the persons name. it's really just guessing but still might be
# helpful
sub cleanFROMField {
    my ($rawline) = @_;
    my $cleanline = removeCHARS($rawline);
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

#given a reference to an array containing message information
#create perl record of information
#returns reference to record 
#note: duplicate functionality to MessageToHash. test perf differences
#so far, MessageToRecord is the winner
sub MessageToRecord {
    my ($msgref,$msgnum) = @_;

    # record that contains message information 
    # initialize to empty strings
    my $msgrec = {
       MSGNUM => $msgnum,
       GROUP => "",
       DATE => "",
       TO => "",
       SUBJECT => "",
       FROM => "",
       FNAME => "",
       LNAME => "",
       BODY => "",
    };

    # parse the message information
    my $curtag="";
    foreach(@$msgref) {
       #get rid of newline
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
       if ($curtag eq GROUPSTR) { 
          $msgrec->{GROUP} = $msgrec->{GROUP} . " " . removeTAG($_); 
       }
       if ($curtag eq DATESTR) { 
          $msgrec->{DATE} = $msgrec->{DATE} . " " . removeTAG($_); 
       }
       if ($curtag eq TOSTR or $curtag eq CCSTR) { 
          my $cleanTOline = cleanTOField(removeTAG($_));
          $msgrec->{TO} = $msgrec->{TO} . " " . $cleanTOline; 
       }
       if ($curtag eq SUBJECTSTR) { 
          $msgrec->{SUBJECT} = $msgrec->{SUBJECT} . " " . removeTAG($_); 
       } 
       if ($curtag eq FROMSTR) { 
          my $fromrec = cleanFROMField(removeTAG($_));
          $msgrec->{FROM} = $msgrec->{FROM} . " " . $fromrec->{ADDR};
          $msgrec->{FNAME} = $fromrec->{FNAME};
          $msgrec->{LNAME} = $fromrec->{LNAME};
       }
    }
    return($msgrec);
}

# given a hash table reference, 
# loop through all news groups and gets the message
# the messages include the header and body
# currently runs in (num groups * num messages)
# NNTP module doesnt appear to have a "bulk" message get
# so i'm grabbing each individual message 
# not sure how much load this puts on the news host but it doesn't 
# seem the most efficient way to get all the messages
sub processArchiveMessages {
    my ($href) = @_;
    # loop through each group and get the header information
    foreach my $curgroup (keys %$href) {
       my $msglistref = $nntp->listgroup($curgroup);
       # returns undefined if news group doesn't exist
       if (defined($msglistref)) {
          #get the actual data
          foreach(@$msglistref) {
             my $bodyinfo = $nntp->body($_);
             insertRecordToDB(MessageToRecord($nntp->head($_),$_),$bodyinfo);
          }
       }
    }
}

# process arguments
our($opt_a,$opt_f,$opt_l,$opt_p);
getopts('af:l:p');
   # get newsgroup information
   # returns a hash reference where the key is the news group
   # and the value is an array with:
   # id of first message and last message 
   # first index is last message
   # second index is first message
if ($opt_a) { $grphashref = $nntp->list(); } 
   #create hash table from news group file
if ($opt_f) { $grphashref=processGroupFile($opt_f); } 
   #create hash table from list of news groups 
if ($opt_l) { $grphashref=processGroupArgList($opt_l); } 
   #set print only option
if ($opt_p) { $printonly=1; } 
Usage() unless ($opt_a || $opt_f || $opt_l);

# main 
if ($printonly) {
   # just print the group and number of messages
   doPrint($grphashref);
} else {
   # setup db connection
   ##$dbh = DBI->connect("DBI:PgPP:dbname=$dbname;host=$dbhost;port=$dbport",$dbuser,$dbpasswd);

   # process messages
   processArchiveMessages($grphashref);

   # close out db connection if it exists
   if (defined($dbh)) {
      $dbh->disconnect;
   }
}

#cleanup and disconnect
$nntp->quit;
