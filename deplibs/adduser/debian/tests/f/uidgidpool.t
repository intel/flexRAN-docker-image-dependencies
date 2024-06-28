#! /usr/bin/perl -Idebian/tests/lib

# check uidgidpool functionality

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $quiet="--quiet";

# single pool file
my $uidpoolfile="/etc/adduser-uidpool.conf";
my $gidpoolfile="/etc/adduser-gidpool.conf";
my $poolbasedir="/etc/adduser-pool.d";
my $uidpooldir="$poolbasedir/uid";
my $gidpooldir="$poolbasedir/gid";
my %confhash;

my $auid=40123;
my $agid=40234;
my $ashell="/bin/dash";
my $acomment="alternate comment";

my @uidlist = (
   {
    'name' => 'pooluid101',
    'id' => 23101,
    'comment' => 'pooluid101 pool account',
    'home' => '/home/pool101',
    'ahome' => '/home/alt101',
    'shell' => '/bin/bash',
   },{
    'name' => 'pooluid202',
    'id' => 23202,
    'comment' => 'pooluid202 pool account',
    'home' => '/home/pool202',
    'ahome' => '/home/alt202',
    'shell' => '/bin/sh',
   }
);

my @gidlist = (
    {
     name => 'poolgid101',
     id => 32101,
    },{
     name => 'poolgid202',
     id => 32202,
    }
);

# test creating user/group without uidpool set

foreach my $group( @gidlist ) {
    assert_command_success('/usr/sbin/addgroup', $quiet,
      '--comment', '""', '--disabled-password', $group->{name});
    assert_group_exists($group->{name});
    assert_gid_does_not_exist($group->{id});
}

foreach my $user( @uidlist ) {
    assert_command_success('/usr/sbin/adduser', $quiet,
      '--comment', '""', '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_uid_does_not_exist($user->{id});
}

sub cleanup {
    foreach my $user( @uidlist ) {
        system("/usr/sbin/deluser $quiet --remove-home $user->{name} 2>/dev/null");
        assert_user_does_not_exist($user->{name});
    }
    foreach my $group( @gidlist ) {
        system("/usr/sbin/delgroup $quiet $group->{name} 2>/dev/null");
        assert_group_does_not_exist($group->{name});
    }
}
cleanup();

# create test pool files
my $fh;
open ($fh, ">>", $uidpoolfile) or die "Failed to open file $uidpoolfile for writing";
foreach my $idset( @uidlist ) {
    print $fh $idset->{name}. ":". $idset->{id}. ":". $idset->{comment}. ":". $idset->{home}. ":". $idset->{shell}. "\n"
}

open ($fh, ">>", $gidpoolfile) or die "Failed to open file $gidpoolfile for writing";
foreach my $idset( @gidlist ) {
    print $fh $idset->{name}. ":". $idset->{id}. "\n"
}

# configure adduser to use uidpool
%confhash=();
$confhash{"UID_POOL"}="$uidpoolfile";
$confhash{"GID_POOL"}="$gidpoolfile";
apply_config_hash(\%confhash);

# test creating user/group with uidpool set

foreach my $group( @gidlist ) {
    assert_command_success('/usr/sbin/addgroup', $quiet,
      $group->{name});
    assert_group_exists($group->{name});
    assert_group_has_gid($group->{name}, $group->{id});
    cleanup();

    assert_command_success('/usr/sbin/addgroup', $quiet,
      '--gid', $agid, $group->{name});
    assert_group_exists($group->{name});
    assert_group_has_gid($group->{name}, $agid);
    cleanup();
}

foreach my $user( @uidlist ) {
    assert_command_success('/usr/sbin/adduser', $quiet,
      '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $user->{id});
    assert_user_has_comment($user->{name}, $user->{comment});
    assert_user_has_home_directory($user->{name}, $user->{home});
    assert_user_has_login_shell($user->{name}, $user->{shell});
    cleanup();

    assert_command_success('/usr/sbin/adduser', $quiet,
      '--uid', $auid, '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $auid);
    assert_user_has_comment($user->{name}, $user->{comment});
    assert_user_has_home_directory($user->{name}, $user->{home});
    assert_user_has_login_shell($user->{name}, $user->{shell});
    cleanup();

    assert_command_success('/usr/sbin/adduser', $quiet,
      '--comment', $acomment, '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $user->{id});
    assert_user_has_comment($user->{name}, $acomment);
    assert_user_has_home_directory($user->{name}, $user->{home});
    assert_user_has_login_shell($user->{name}, $user->{shell});
    cleanup();

    assert_command_success('/usr/sbin/adduser', $quiet,
      '--home', $user->{ahome}, '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $user->{id});
    assert_user_has_comment($user->{name}, $user->{comment});
    assert_user_has_home_directory($user->{name}, $user->{ahome});
    assert_user_has_login_shell($user->{name}, $user->{shell});
    cleanup();

    assert_command_success('/usr/sbin/adduser', $quiet,
      '--shell', $ashell, '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $user->{id});
    assert_user_has_comment($user->{name}, $user->{comment});
    assert_user_has_home_directory($user->{name}, $user->{home});
    assert_user_has_login_shell($user->{name}, $ashell);
    cleanup();
}

# remove test pool files
assert_command_success('rm', '-f', $uidpoolfile, $gidpoolfile);

# create and fill test pool directories
assert_command_success('mkdir', '-p', $uidpooldir, $gidpooldir);
my $counter=1;
foreach my $idset( @uidlist ) {
    my $fn = $uidpooldir. "/uidpool". $counter. ".conf";
    open (my $fh, ">>", $fn) or die "Failed to open file $fn for writing";
    print $fh $idset->{name}. ":". $idset->{id}. ":". $idset->{comment}. ":". $idset->{home}. ":". $idset->{shell}. "\n";
    $counter++;
}

foreach my $idset( @gidlist ) {
    my $fn = $gidpooldir. "/gidpool". $counter. ".conf";
    open (my $fh, ">>", $fn) or die "Failed to open file $fn for writing";
    print $fh $idset->{name}. ":". $idset->{id}. "\n";
    $counter++;
}

# configure adduser to use uidpool
%confhash=();
$confhash{"UID_POOL"}="$uidpooldir";
$confhash{"GID_POOL"}="$gidpooldir";
apply_config_hash(\%confhash);

# test creating user/group with uidpool set

foreach my $group( @gidlist ) {
    assert_command_success('/usr/sbin/addgroup', $quiet,
      $group->{name});
    assert_group_exists($group->{name});
    assert_group_has_gid($group->{name}, $group->{id});
    cleanup();

    assert_command_success('/usr/sbin/addgroup', $quiet,
      '--gid', $agid, $group->{name});
    assert_group_exists($group->{name});
    assert_group_has_gid($group->{name}, $agid);
    cleanup();
}

foreach my $user( @uidlist ) {
    assert_command_success('/usr/sbin/adduser', $quiet,
      '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $user->{id});
    assert_user_has_comment($user->{name}, $user->{comment});
    assert_user_has_home_directory($user->{name}, $user->{home});
    assert_user_has_login_shell($user->{name}, $user->{shell});
    cleanup();

    assert_command_success('/usr/sbin/adduser', $quiet,
      '--uid', $auid, '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $auid);
    assert_user_has_comment($user->{name}, $user->{comment});
    assert_user_has_home_directory($user->{name}, $user->{home});
    assert_user_has_login_shell($user->{name}, $user->{shell});
    cleanup();

    assert_command_success('/usr/sbin/adduser', $quiet,
      '--comment', $acomment, '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $user->{id});
    assert_user_has_comment($user->{name}, $acomment);
    assert_user_has_home_directory($user->{name}, $user->{home});
    assert_user_has_login_shell($user->{name}, $user->{shell});
    cleanup();

    assert_command_success('/usr/sbin/adduser', $quiet,
      '--home', $user->{ahome}, '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $user->{id});
    assert_user_has_comment($user->{name}, $user->{comment});
    assert_user_has_home_directory($user->{name}, $user->{ahome});
    assert_user_has_login_shell($user->{name}, $user->{shell});
    cleanup();

    assert_command_success('/usr/sbin/adduser', $quiet,
      '--shell', $ashell, '--disabled-password', $user->{name});
    assert_user_exists($user->{name});
    assert_user_has_uid($user->{name}, $user->{id});
    assert_user_has_comment($user->{name}, $user->{comment});
    assert_user_has_home_directory($user->{name}, $user->{home});
    assert_user_has_login_shell($user->{name}, $ashell);
    cleanup();
}

# remove test pool directories
assert_command_success('rm', '-rf', $uidpooldir, $gidpooldir, $poolbasedir);

# vim: tabstop=4 shiftwidth=4 expandtab
