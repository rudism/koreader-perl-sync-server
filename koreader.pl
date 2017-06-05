#!/usr/bin/perl

use DBI;
use CGI;
use JSON;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;

my $username = 'my-user-name';
my $password = '286755fad04869ca523320acce0dc6a4'; # md5sum
my $dbfile = '/path/to/koreader.db';

# Schema:
# CREATE TABLE progress (
#   timestamp datetime,
#   document text,
#   device_id text,
#   device text,
#   progress text,
#   percentage numeric
# );

my $q = CGI->new;

my $status = 200;
my $content = {};

my $rawpath = $ENV{'REQUEST_URI'};
my $path;
if($rawpath =~ /^\/koreader.pl(\/.*)$/) {
  $path = $1;
}

if($path eq '/users/create'){

  # registration not supported, single-user only
  $status = 402;
  $content = {code => 2002, message => 'Username is already registered.'};

} else {
  if(auth_user()){
    if($path eq '/users/auth'){

      # called when logging in
      $content = {authorized => 'OK'};

    } elsif($path eq '/syncs/progress'){

      # saving a book's progress
      my $timestamp = time;
      my $putdata = from_json($q->param('PUTDATA'));

      my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '');
      $dbh->do('INSERT INTO progress VALUES (?, ?, ?, ?, ?, ?)', undef,
        $timestamp,
        $putdata->{'document'},
        $putdata->{'device_id'},
        $putdata->{'device'},
        $putdata->{'progress'},
        $putdata->{'percentage'});
      $dbh->disconnect();

      $content = {timestamp => $timestamp, document => $putdata->{'document'}};

    } elsif($path =~ /^\/syncs\/progress\/(.*)$/){

      # retrieving a book's progress
      my $docid = $1;
      my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '');
      my @progress = $dbh->selectrow_array('SELECT timestamp, document, device_id, device, progress, percentage FROM progress WHERE document=? ORDER BY timestamp DESC LIMIT 1', undef, $docid);
      $dbh->disconnect();

      if($#progress == 5){
        $content = {
          timestamp => $progress[0],
          document => $progress[1],
          device_id => $progress[2],
          device => $progress[3],
          progress => $progress[4],
          percentage => $progress[5]
        };
      };

    } else {

      $status = 404;
      $content = { message => 'File not found.' };

    }
  } else {

    # login and password did not match
    $status = 401;
    $content = {code => 2001, message => 'Unauthorized'};

  }
}

print $q->header({
  type => 'application/json',
  status => $status
});

print to_json($content, {pretty => 1});

sub auth_user {
  my $xuser = $ENV{'HTTP_X_AUTH_USER'};
  my $xkey = $ENV{'HTTP_X_AUTH_KEY'};
  if($xuser eq $username && $xkey eq $password){
    return 1;
  }
  return 0;
}
