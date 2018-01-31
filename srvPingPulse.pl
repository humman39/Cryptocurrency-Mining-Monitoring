#!/usr/bin/perl

use warnings;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;
use Time::localtime;

########################### Edit your config ###############################
# List of servers separated by comma. Server IP/name should be in double-quote
my @srvToMon = ("192.168.0.10"); 

# Inerval between ping in seconds
my $sleepTime = 180; 

# Email to be used to send from, and password (I recommend to set separate email for this)
my $fromEmail = "myEmailFrom\@gmail.com";
my $pass = "xxxxxxxxxx"; chomp($pass);

# Email to receive emails about failures
my $toEmail = "myEmailTo\@gmail.com";

# Email message in body
my $emailMsg = "Start Panicing!";

#############################################################################

my $currentTime = timestamp();
my $listOfSrv = join(", ", @srvToMon);
my $rc = "";

print "\n$currentTime - Starting Monitoring for $listOfSrv with sleep interval: $sleepTime seconds";

while ("having fun") {

   foreach $srv (@srvToMon) {
      my $currentTime = timestamp();
      print "\n$currentTime - Sending ping to $srv";
      my @pingResult = `PING.EXE -n 1 $srv`;

      foreach my $line (@pingResult) { chomp($line);
         if ($line =~ m/Request\stimed\sout./) {
            print "\n$currentTime - FAIL: ping to $srv TIMED OUT";
            print "\n$currentTime - Sending email with error: $line";
            sendEmailAlert($srv, $line); 
         }
         elsif ($line =~ m/Reply\sfrom/) {
            my ($reply, $stats) = split /:/, $line;
        
            if ($stats =~ m/unreachable/) {
               print "\n$currentTime - FAIL: $srv is UNREACHABLE";
               print "\n$currentTime - Sending email with error: $stats";
               sendEmailAlert($srv, $stats); 
            }
            else {
               $rc = $line;
            }
         } 
      } 
      print "\n$currentTime - $rc";
   }
   print "\n$currentTime - Sleeping for $sleepTime seconds ...\n";
   select()->flush();
   sleep($sleepTime);
}

sub sendEmailAlert { 
   my $srv = $_[0]; chomp($srv);
   my $errL = $_[1]; chomp($errL);

   my $email = Email::Simple->create(
       header => [
          From    => "$fromEmail",
          To      => "$toEmail",
          Subject => "ALERT: $srv is DOWN - $errL",
       ],
       body => "$emailMsg",
   );

   my $sender = Email::Send->new(
      {   mailer      => 'Gmail',
          mailer_args => [
            username => "$fromEmail",
            password => "$pass",
          ]
      }
   );

   eval { $sender->send($email) };
   die "Error sending email: $@" if $@;
}

sub timestamp {
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $t->year + 1900, $t->mon + 1, $t->mday, $t->hour, $t->min, $t->sec);
}
