#! /usr/bin/perl -Idebian/tests/lib

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

# enable ecryptfs kernel module
system('/sbin/modprobe', 'ecryptfs');

my $test_user="foocrypt";

assert_user_does_not_exist($test_user);

assert_command_success('/usr/sbin/adduser', '--encrypt-home', $test_user);

assert_user_exists($test_user);
assert_group_exists($test_user);
assert_group_membership_exists($test_user, $test_user);

# test for ecryptfs files stored in $HOME
assert_path_exists("/home/$test_user/.ecryptfs");
assert_path_exists("/home/$test_user/.Private");
# and not stored in $HOME
assert_path_exists("/home/.ecryptfs/$test_user");

assert_command_success('/usr/sbin/deluser', '--remove-home', $test_user);
assert_user_does_not_exist($test_user);
assert_path_does_not_exist("/home/$test_user");
assert_path_does_not_exist("/home/.ecryptfs/$test_user");
