#! /usr/bin/perl -Idebian/tests/lib

# check usergroups functionality

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

my $quiet="--quiet";

# create custom user groups
my $cusergroup="myusers";
assert_command_success('/usr/sbin/addgroup', '--system', $cusergroup);
my @group_info = getgrnam($cusergroup);
my $cusergid = $group_info[2];
my %confhash;

my $dusergroup="manusers";
assert_command_success('/usr/sbin/addgroup', '--system', $dusergroup);
@group_info = getgrnam($dusergroup);
my $dusergid = $group_info[2];

my @extragroups=('extra1', 'extra2', 'extra3');
foreach ( @extragroups ) {
    assert_command_success('/usr/sbin/addgroup', '--system', $_);
}

# USERS_GROUP and USERS_GID both set => failure
my $test_name="test1";
%confhash=();
$confhash{"USERS_GROUP"}='users';
$confhash{"USERS_GID"}='100';
apply_config_hash(\%confhash);
assert_command_failure_silent('/usr/sbin/adduser', $quiet, 
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);

my $homedir;

my $usergroup="users";
my $usergid="100";
my $useruid=40000;
my $sysuuid=400;

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# this test also creates and checks a home directory
$test_name="test2";
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
my $test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# this test also creates and checks a home directory
# with explicit --uid
$test_name="test2-a";
$useruid++;
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--home', "$homedir",
  '--uid', "$useruid",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with explicit --ingroup
# this test also creates and checks a home directory
$test_name="test2a";
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_exists($test_name, $usergroup);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $dusergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with explicit --ingroup
# this test also creates and checks a home directory
# with explicit --uid
$test_name="test2a-a";
$useruid++;
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_exists($test_name, $usergroup);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $dusergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with explicit --gid
# this test also creates and checks a home directory
$test_name="test2b";
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_exists($test_name, $usergroup);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $dusergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with explicit --gid
# this test also creates and checks a home directory
# with explicit --uid
$test_name="test2b-a";
$useruid++;
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--uid', "$useruid",
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_exists($test_name, $usergroup);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $dusergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with (disabled) EXTRA_GROUPS
$test_name="test2c";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
$confhash{"EXTRA_GROUPS"}=join(' ', @extragroups);
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
foreach ( @extragroups ) {
    assert_supplementary_group_membership_does_not_exist($test_name, $_);
}
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with (disabled) EXTRA_GROUPS
# with explicit --uid
$test_name="test2c-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
$confhash{"EXTRA_GROUPS"}=join(' ', @extragroups);
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
foreach ( @extragroups ) {
    assert_supplementary_group_membership_does_not_exist($test_name, $_);
}
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with EXTRA_GROUPS enabled by --add-extra-groups
$test_name="test2d";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
$confhash{"EXTRA_GROUPS"}=join(' ', @extragroups);
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--add-extra-groups',
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
foreach ( @extragroups ) {
    assert_supplementary_group_membership_exists($test_name, $_);
}
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with EXTRA_GROUPS enabled by --add-extra-groups
# with explicit --uid
$test_name="test2d-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
$confhash{"EXTRA_GROUPS"}=join(' ', @extragroups);
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--add-extra-groups',
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
foreach ( @extragroups ) {
    assert_supplementary_group_membership_exists($test_name, $_);
}
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with EXTRA_GROUPS enabled by legacy underscored --add_extra_groups
$test_name="test2e";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
$confhash{"EXTRA_GROUPS"}=join(' ', @extragroups);
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--add_extra_groups',
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
foreach ( @extragroups ) {
    assert_supplementary_group_membership_exists($test_name, $_);
}
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with EXTRA_GROUPS enabled by legacy underscored --add_extra_groups
# with explicit --uid
$test_name="test2e-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
$confhash{"EXTRA_GROUPS"}=join(' ', @extragroups);
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--add_extra_groups',
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
foreach ( @extragroups ) {
    assert_supplementary_group_membership_exists($test_name, $_);
}
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with EXTRA_GROUPS enabled by configuration ADD_EXTRA_GROUPS=1
$test_name="test2f";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
$confhash{"EXTRA_GROUPS"}=join(' ', @extragroups);
$confhash{"ADD_EXTRA_GROUPS"}='1';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
foreach ( @extragroups ) {
    assert_supplementary_group_membership_exists($test_name, $_);
}
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=""
# with EXTRA_GROUPS enabled by configuration ADD_EXTRA_GROUPS=1
# with explicit --uid
$test_name="test2f-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
$confhash{"EXTRA_GROUPS"}=join(' ', @extragroups);
$confhash{"ADD_EXTRA_GROUPS"}='1';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $usergroup);
foreach ( @extragroups ) {
    assert_supplementary_group_membership_exists($test_name, $_);
}
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="$cusergroup" USERS_GID=""
$test_name="test3";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --uid
$test_name="test3-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --ingroup
$test_name="test3a";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --ingroup
# with explicit --uid
$test_name="test3a-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --gid
$test_name="test3b";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --gid
# with explicit --uid
$test_name="test3b-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID="$cusergid"
$test_name="test4";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --uid
$test_name="test4-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=yes USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --ingroup
$test_name="test4a";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --ingroup
# with explicit --uid
$test_name="test4a-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --gid
$test_name="test4b";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --gid
# with explicit --uid
$test_name="test4b-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=-1
# this test also creates and checks a home directory
$test_name="test5";
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=-1;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $test_name);
 
# USERGROUPS=yes USERS_GROUP="" USERS_GID=-1
# this test also creates and checks a home directory
# with explicit --uid
$test_name="test5-a";
$useruid++;
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=-1;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--home', "$homedir",
  '--uid', "$useruid",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_exists($test_name);
$test_uid=getpwnam($test_name);
assert_group_has_gid($test_name, $test_uid);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $test_name);
 
# USERGROUPS=yes USERS_GROUP="" USERS_GID=-1
# with explicit --ingroup
# this test also creates and checks a home directory
$test_name="test5a";
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=-1;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $dusergroup);
 
# USERGROUPS=yes USERS_GROUP="" USERS_GID=-1
# with explicit --ingroup
# this test also creates and checks a home directory
# with explicit --uid
$test_name="test5a-a";
$useruid++;
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=-1;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--home', "$homedir",
  '--uid', "$useruid",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $dusergroup);
 
# USERGROUPS=yes USERS_GROUP="" USERS_GID=-1
# with explicit --gid
$test_name="test5b";
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=-1;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=yes USERS_GROUP="" USERS_GID=-1
# with explicit --gid
# with explicit --uid
$test_name="test5b-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='yes';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=-1;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="$cusergroup" USERS_GID=""
# this test also creates and checks a home directory
$test_name="test6";
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet,
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $cusergroup);

# USERGROUPS=no USERS_GROUP="$cusergroup" USERS_GID=""
# this test also creates and checks a home directory
# with explicit --uid
$test_name="test6-a";
$useruid++;
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet,
  '--home', "$homedir",
  '--uid', "$useruid",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $cusergroup);

# USERGROUPS=no USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --ingroup
$test_name="test6a";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --ingroup
# with explicit --uid
$test_name="test6a-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --gid
$test_name="test6b";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="$cusergroup" USERS_GID=""
# with explicit --gid
# with explicit --uid
$test_name="test6b-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}=$cusergroup;
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID="$cusergid"
$test_name="test7";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=no USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --uid
$test_name="test7-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);

# USERGROUPS=no USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --ingroup
$test_name="test7a";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --ingroup
# with explicit --uid
$test_name="test7a-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --gid
$test_name="test7b";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID="$cusergid"
# with explicit --gid
# with explicit --uid
$test_name="test7b-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=$cusergid;
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID=""
# this test also creates and checks a home directory
$test_name="test8";
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet,
  '--home', "$homedir",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID=""
# this test also creates and checks a home directory
# with explicit --uid
$test_name="test8-a";
$useruid++;
$homedir="/home/$test_name";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet,
  '--home', "$homedir",
  '--uid', "$useruid",
  '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_path_is_a_directory($homedir);
assert_user_has_home_directory($test_name, $homedir);
assert_dir_group_owner($homedir, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID=""
# with explicit --ingroup
$test_name="test8a";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID=""
# with explicit --ingroup
# with explicit --uid
$test_name="test8a-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--ingroup', $dusergroup,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID=""
# with explicit --gid
$test_name="test8b";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID=""
# with explicit --gid
# with explicit --uid
$test_name="test8b-a";
$useruid++;
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}='';
apply_config_hash(\%confhash);
assert_command_success('/usr/sbin/adduser', $quiet, 
  '--gid', $dusergid,
  '--uid', "$useruid",
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);
assert_user_uid_exists($test_name,$useruid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $dusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $usergroup);

# USERGROUPS=no USERS_GROUP="" USERS_GID=-1
# expected failure: needs a primary group
$test_name="test9";
%confhash=();
$confhash{"USERGROUPS"}='no';
$confhash{"USERS_GROUP"}='';
$confhash{"USERS_GID"}=-1;
apply_config_hash(\%confhash);
assert_command_failure_silent('/usr/sbin/adduser', $quiet, 
  '--no-create-home', '--comment', '""', '--disabled-password', $test_name);

##+# TODO: write tests with loops

# remove configuration file
%confhash=();
apply_config_hash(\%confhash);

# system user, default, should be in nogroup
$test_name="systest1";
assert_command_success('/usr/sbin/adduser', $quiet, '--system', 
  '--no-create-home', $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, 'nogroup');
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);

# system user, default, should be in nogroup
# with explicit --uid
$test_name="systest1-a";
$sysuuid++;
assert_command_success('/usr/sbin/adduser', $quiet, '--system', 
  '--uid', "$sysuuid",
  '--no-create-home', $test_name);
assert_user_uid_exists($test_name,$sysuuid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, 'nogroup');
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);

# system user, with --gid
$test_name="systest2";
assert_command_success('/usr/sbin/adduser', $quiet, '--system', 
  '--no-create-home', '--gid', $cusergid, $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);

# system user, with --gid
# with explicit --uid
$test_name="systest2-a";
$sysuuid++;
assert_command_success('/usr/sbin/adduser', $quiet, '--system', 
  '--uid', "$sysuuid",
  '--no-create-home', '--gid', $cusergid, $test_name);
assert_user_uid_exists($test_name,$sysuuid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);

# system user, with --ingroup
$test_name="systest3";
assert_command_success('/usr/sbin/adduser', $quiet, '--system', 
  '--no-create-home', '--ingroup', $cusergroup, $test_name);
assert_user_exists($test_name);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);

# system user, with --ingroup
# with --uid
# with explicit --uid
$test_name="systest3-a";
$sysuuid++;
assert_command_success('/usr/sbin/adduser', $quiet, '--system', 
  '--uid', "$sysuuid",
  '--no-create-home', '--ingroup', $cusergroup, $test_name);
assert_user_uid_exists($test_name,$sysuuid);
assert_group_does_not_exist($test_name);
assert_primary_group_membership_exists($test_name, $cusergroup);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);

# system user, with --group
$test_name="systest4";
assert_command_success('/usr/sbin/adduser', $quiet, '--system', 
  '--no-create-home', '--group', $test_name);
assert_user_exists($test_name);
assert_group_exists($test_name);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);

# system user, with --group
# with --uid
# with explicit --uid
$test_name="systest4-a";
$sysuuid++;
assert_command_success('/usr/sbin/adduser', $quiet, '--system', 
  '--uid', "$sysuuid",
  '--no-create-home', '--group', $test_name);
assert_user_uid_exists($test_name,$sysuuid);
assert_group_exists($test_name);
assert_primary_group_membership_exists($test_name, $test_name);
assert_supplementary_group_membership_does_not_exist($test_name, $test_name);
assert_supplementary_group_membership_does_not_exist($test_name, $cusergroup);

# vim: tabstop=4 shiftwidth=4 expandtab
