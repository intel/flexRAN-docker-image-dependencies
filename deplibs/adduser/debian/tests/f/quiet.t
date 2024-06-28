#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=558260


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;


END {
    remove_tree('/var/mail/foo');
}

assert_user_does_not_exist('foo');
assert_group_does_not_exist('foo');

assert_command_success('/usr/sbin/adduser', '--quiet', '--disabled-login', '--comment="x"', '--no-create-home', 'foo');

assert_user_exists('foo');
assert_group_exists('foo');
assert_path_does_not_exist('/home/foo');

assert_group_membership_exists('foo', 'foo');
assert_primary_group_membership_exists('foo', 'foo');

assert_group_membership_does_not_exist('foo', 'adm');

my $command = '/usr/sbin/adduser --quiet foo adm 2>&1';
my $output = `$command`;

is($? >> 8, 0, "command success: $command");
is($output, '', 'option "--quiet" silences output when adding user to group');

assert_group_membership_exists('foo', 'adm');

assert_primary_group_membership_exists('foo', 'foo');
assert_supplementary_group_membership_exists('foo', 'adm');
