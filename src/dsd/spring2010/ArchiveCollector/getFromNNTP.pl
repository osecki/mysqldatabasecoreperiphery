#!/usr/bin/perl

# built and tested on tux system  (linux x86_64 , perl 5.10)
# connects news group host and gets header information for a 
# given new group.

#issues currently takes to long to grab messages. if we are grabbing 
#100,000 messages then this might be too slow
#20,000 messages takes 23 minutes
#this code is a bit bloated since I think the most efficient way to
#code this would be to create db functions directly and strip the code
#out of this perl script. 
# not a ton of error checking since we needed the data loaded
# to do:
# clean up code bloat around db functions
# process message text

# sample sql statements for my own reference
 ## INSERT INTO public.persons (fname,lname) VALUES('foo','bar');
 ## INSERT INTO public.aliases (person,name)  VALUES(1,'foo@bar'); 
 ## INSERT INTO public.threads (subject) VALUES('test message');
 ## INSERT INTO public.mails (thread,tstamp,sender,reply,message) VALUES(1,'Sun, 1 Oct 2000',1,4,'test body'); 
 ## DELETE from public.mails;
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

# db function
# given alias
# check public.aliases if it exists
# return id key
# otherwise -1
sub dbReadAliasesID {
    my ($alias) = @_;
    my $retval = -1;

    my $statement = "select id from public.aliases where name = ?";
    my $sth = $dbh->prepare($statement);
    $sth->execute($alias);
    $retval = $sth->fetchrow_array();
    # will returned undefined if alias doesn't exist
    if (! defined($retval) or $retval <= 0) {
       $retval = -1;
    }

    return($retval);
}

# db function
# given alias
# check public.aliases for person id
# return person id key
# otherwise -1
sub dbReadAliasesPersonIDbyName {
    my ($alias) = @_;
    my $retval = -1;

    # get alias id
    my $aliasid = dbReadAliasesID($alias);
    if ($aliasid > 0) {
       my $statement = "select person from public.aliases where id = ?";
       my $sth = $dbh->prepare($statement);
       $sth->execute($aliasid);
       $retval = $sth->fetchrow_array();

       # will returned undefined if alias doesn't exist
       if (! defined($retval) or $retval <= 0) {
          $retval = -1;
       }
    }

    return($retval);
}

# db function
# given first and lastname
# check public.persons if it exists
# return id key
# otherwise -1 
sub dbReadPersonsID {
    my ($fname,$lname) = @_;
    my $retval = -1;

    # since we are kind of guessing what the users name is
    # try both variations in case their alias was written different ways
    my $statement1 = "select id from public.persons where fname = ? and lname = ?";
    my $statement2 = "select id from public.persons where lname = ? and fname = ?";
    my $sth = $dbh->prepare($statement1);
    $sth->execute($fname,$lname);
    $retval = $sth->fetchrow_array();

    # try a different variation of the fname and lname
    if (! defined($retval) or $retval le 0) {
       $sth = $dbh->prepare($statement2);
       $sth->execute($fname,$lname);
       $retval = $sth->fetchrow_array();
       # the names were not found and the variable will
       # be undefined
       if (! defined($retval) or $retval <= 0) {
          $retval = -1;
       }
    }

    return($retval);
}

# db function
# given subject string
# check public.threads if it exists
# return id key
# otherwise -1 
sub dbReadThreadsID {
    my ($subject) = @_;
    my $retval = -1;

    my $statement = "select id from public.threads where subject = ?";
    my $sth = $dbh->prepare($statement);
    $sth->execute($subject);
    $retval = $sth->fetchrow_array();

    # will returned undefined if alias doesn't exist
    if (! defined($retval) or $retval le 0) {
       $retval = -1;
    }

    return($retval);
}

# db function
# given thread id 
# check public.threads if it exists
# return subject text 
# otherwise "" 
sub dbReadThreadsSubject {
    my ($threadid) = @_;
    my $retval = "";

    my $statement = "select subject from public.threads where id = ?";
    my $sth = $dbh->prepare($statement);
    $sth->execute($threadid);
    $retval = $sth->fetchrow_array();

    # will returned undefined if alias doesn't exist
    if (! defined($retval)) {
       $retval = "";
    }

    return($retval);
}

#given alias id
#return person id
sub dbReadAliasesPersonIDbyID {
    my ($aliasid) = @_;
    my $retval = -1;

    my $statement = "select person from public.aliases where id = ?";
    my $sth = $dbh->prepare($statement);
    $sth->execute($aliasid);
    $retval = $sth->fetchrow_array();

    # will returned undefined if alias doesn't exist
    if (! defined($retval)) {
       $retval = -1;
    }

    return($retval);
}

# given fname, lname, 
# insert into db
# returns the id returned
sub dbInsertPerson {
    my ($fname,$lname) = @_;
    my $retval = -1;

    # check that atleast one of them isn't empty
    if ($fname ne "" or $lname ne "") {
       my $statement = "INSERT INTO public.persons (fname,lname) VALUES(?,?)";
       my $sth = $dbh->prepare($statement);
       $sth->execute($fname,$lname);
       $dbh->commit;

       $retval = dbReadPersonsID($fname,$lname);  
       # will returned undefined if alias doesn't exist
       if (! defined($retval)) {
          $retval = -1;
       }
    }

    return($retval); 
}

# given alias, personid
# insert into db
# returns the id returned
sub dbInsertAlias {
    my ($alias,$personid) = @_;
    my $retval = -1;

    my $statement = "INSERT INTO public.aliases (person,name) VALUES(?,?)";
    my $sth = $dbh->prepare($statement);
    $sth->execute($personid,$alias);
    $dbh->commit;

    # check if the insert was successful
    $retval = dbReadAliasesID($alias); 

    return($retval); 
}

# given alias id and new person id 
# set person reference to new id
sub dbUpdateAliasPerson {
    my ($aliasid,$newpersonid) = @_;
    my $statement = "UPDATE public.aliases SET person = ? WHERE id = ?";

    my $sth = $dbh->prepare($statement);
    $sth->execute($newpersonid,$aliasid);
    $dbh->commit;
}

# given subject text
# insert into db
# return thread id
sub dbInsertThread {
    my ($subject) = @_;

    my $retval = dbReadThreadsID($subject);
    if ($retval < 0) {
       my $statement = "INSERT INTO public.threads (subject) VALUES(?)";
       my $sth = $dbh->prepare($statement);
       $sth->execute($subject);
       $dbh->commit;

       $retval = dbReadThreadsID($subject); 
       # will returned undefined if alias doesn't exist
       if (! defined($retval)) {
          $retval = -1;
       }
    } 
    return($retval);
}

# given fname, lname, from/sender address
# try to resolve address with fname/lname
# or if fname/lname exist, attempt to update alias key
# returns the alias id
sub dbInsertSender {
    my ($fname,$lname,$alias) = @_;
    my $retval = -1;

    # grab person and alias id
    my $personid = dbReadPersonsID($fname,$lname);
    my $aliasid = dbReadAliasesID($alias);

    if ($personid < 0 and $aliasid < 0) {
       # niether alias or person exist  
       $personid = dbInsertPerson($fname,$lname); 
       $retval = dbInsertAlias($alias,$personid);
    } elsif ($personid > 0 and $aliasid < 0) {
       # person exists alias doesnt
       $retval = dbInsertAlias($alias,$personid);
    } elsif ($personid < 0 and $aliasid > 0) {
       # person doesnt exist alias exists 
       # if existing alias person id is empty, fill it 
       # with new person information. otherwise, just keep 
       # existing person reference
       $retval = $aliasid;
       $personid = dbReadAliasesPersonIDbyID($aliasid);
       if ($personid < 0) {
          $personid = dbInsertPerson($fname,$lname); 
          dbUpdateAliasPerson($aliasid,$personid);
       }
    } elsif ($personid > 0 and $aliasid > 0) {
       # person exists and alias exists       
       # verify that personid is set to a valid id
       $retval = $aliasid;
       my $tmppersonid = dbReadAliasesPersonIDbyID($aliasid); 
       if ($tmppersonid < 0) {
          dbUpdateAliasPerson($aliasid,$personid);
       }
    }

    return($retval);
}

# given to/reply address
# insert db into public.aliases
# returns id
sub dbInsertReply {
    my ($alias) = @_;
    my $retval = -1;

    if ($alias ne "") {
       $retval = dbReadAliasesID($alias);
       if ($retval < 0) {
          # alias doesn't exist and we dont have
          # any name information so initialize with -1
          $retval = dbInsertAlias($alias,"-1");
       }
    }
    return($retval);
}

# given thread id, date string, from/sender id, to/reply id
# return mail id
sub dbReadMail {
    my ($threadid,$datestr,$senderid,$replyid) = @_;
    my $retval = -1;

    my $statement = "SELECT id from public.mails where thread = ? and tstamp = ? and sender = ? and reply = ?";
    my $sth = $dbh->prepare($statement);
    $sth->execute($threadid,$datestr,$senderid,$replyid);
    $retval = $sth->fetchrow_array();

    # will returned undefined if alias doesn't exist
    if (! defined($retval)) {
       $retval = -1;
    }

    return($retval);
}
 
# given thread id, date string, from/sender id, to/reply id
# insert db into public.mails
# returns id
sub dbInsertMail {
    my ($threadid,$datestr,$senderid,$replyid) = @_;

    my $retval = dbReadMail($threadid,$datestr,$senderid,$replyid); 
    if ($retval < 0) {
       my $statement = "INSERT INTO public.mails (thread,tstamp,sender,reply) VALUES(?,?,?,?)";
       my $sth = $dbh->prepare($statement);
       $sth->execute($threadid,$datestr,$senderid,$replyid);
       $dbh->commit;

       $retval = dbReadMail($threadid,$datestr,$senderid,$replyid); 
       # will returned undefined if alias doesn't exist
       if (! defined($retval)) {
          $retval = -1;
       }
      
    }
    return($retval);
}

# given a perl record of header information and
# an array reference with body text
# insert into db table
sub dbInsertRecord {
    my ($msgrec,$bodyref) = @_;
    ###print("MSGNUM  - $msgrec->{MSGNUM}\n");
    ###print("GROUP   - $msgrec->{GROUP}\n");
    ###print("DATE    - $msgrec->{DATE}\n");
    ###print("TO      - $msgrec->{TO}\n");
    ###print("FROM    - $msgrec->{FROM}\n");
    ###print("FNAME   - $msgrec->{FNAME}\n");
    ###print("LNAME   - $msgrec->{LNAME}\n");
    ###print("SUBJECT - $msgrec->{SUBJECT}\n");
    my $fname = removeSpace($msgrec->{FNAME});
    my $lname = removeSpace($msgrec->{LNAME});
    my $sender = removeSpace($msgrec->{FROM});
    my $tstamp = removeSpace($msgrec->{DATE});
    my $subject = removeSpace($msgrec->{SUBJECT});

    my $senderid = dbInsertSender($fname,$lname,$sender);
    my $threadid = dbInsertThread($subject);
    my @fulltolist = split(/ /,$msgrec->{TO});
    # to list can have many aliases in the list so we need to loop through them
    # i'm creating a record for each unique mail
    my $replyid = -1;
    my $mailid = -1;
    foreach(@fulltolist) {
       my $toaddr = removeSpace($_);
       if ($toaddr ne "") {
          $replyid = dbInsertReply($toaddr);
          $mailid = dbInsertMail($threadid,$tstamp,$senderid,$replyid);
       }
    }
}

#given no arguments
#sets up dummy record in public.persons with -1 id
sub InitializeDB {
    my $retval = -1;

    my $statement = "select id from public.persons where id = ?";
    my $sth = $dbh->prepare($statement);
    $sth->execute("-1");
    $retval = $sth->fetchrow_array();

    # will return not defined if id not found
    if (! defined($retval)) {
       $statement = "INSERT INTO public.persons (id,fname,lname) VALUES(?,?,?)";
       $sth = $dbh->prepare($statement);
       $sth->execute("-1","dummyname","dummyname");
       $dbh->commit;
    }
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
# trim leading and trailing spaces
sub removeSpace {
   my ($rawline) = @_;
   $rawline =~ s/^\s+//;
   $rawline =~ s/\s+$//;

   return($rawline); 
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
    $rawline = removeSpace($rawline);

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

#give date string with format
# Mon, 25 Sep 2000 16:50:10 +0200 (CDT)
# return string without timezone
sub cleanDateField {
    my ($rawline) = @_;
    my ($cleandate) = split('\(',$rawline);

    return($cleandate);
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
          my $cleandate = cleanDateField(removeTAG($_));
          $msgrec->{DATE} = $cleandate; 
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
             dbInsertRecord(MessageToRecord($nntp->head($_),$_),$bodyinfo);
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
   $dbh = DBI->connect("DBI:PgPP:dbname=$dbname;host=$dbhost;port=$dbport",$dbuser,$dbpasswd);
   InitializeDB();

   # process messages
   processArchiveMessages($grphashref);

   # close out db connection if it exists
   if (defined($dbh)) {
      $dbh->disconnect;
   }
}

#cleanup and disconnect
$nntp->quit;
