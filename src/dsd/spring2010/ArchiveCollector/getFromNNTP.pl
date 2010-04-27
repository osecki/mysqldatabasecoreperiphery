#!/usr/bin/perl -W

# built and tested on tux system  (linux x86_64 , perl 5.10)
# connects news group host and gets header information for a 
# given new group.

#issues currently takes to long to grab messages. if we are grabbing 
#100,000 messages then this might be too slow

use strict;
use Net::NNTP; 
use Getopt::Std;

#initialize global variables
my $newshost = "lists.mysql.com";          # hard coded news host
my $nntp = Net::NNTP->new($newshost);      # open connection to news host
my $grphashref=0;                          # reference to hash table of news groups
my $printonly=0;                           # global flag to print num. of messages 

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

#given a reference to an array containing 
#header information then insert into db table
### do db work here
sub insertMessage {
    my ($headerref) = @_;
    print(@$headerref);
}

#given a hash table reference, 
# loop through all news groups and gets the message
# the messages include the header and body
# currently runs in (num groups * num messages)
# NNTP module doesnt appear to have a "bulk" message get
# so i'm grabbing each individual message 
# not sure how much load this puts on the news host but it doesn't 
# seem the most efficient way to get all the messages
sub getArchiveMessages {
    my ($href) = @_;
    foreach my $curgroup (keys %$href) {
       my $msglistref = $nntp->listgroup($curgroup);
       # returns undefined if news group doesn't exist
       my $numrecs=0;
       if (defined($msglistref)) {
          #get the actual data
          foreach(@$msglistref) {
             my $headerinfo = $nntp->head($_);
             insertMessage($headerinfo);
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
   # process messages
   getArchiveMessages($grphashref);
}

#cleanup and disconnect
$nntp->quit;
