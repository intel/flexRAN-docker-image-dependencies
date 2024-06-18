#! /usr/bin/perl -Idebian/tests/lib

# N.B. This test script is intended to serve as living documentation of the
# default behavior one can expect when creating a new system user. It should
# match the behavior as specified in the adduser(8) man page and vice versa.


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;


END {
    remove_tree('/home/foo');
    remove_tree('/var/mail/foo');
}

my $uid;

# Ref: https://www.debian.org/doc/debian-policy/ch-opersys.html#uid-and-gid-classes
for (100..999) {
    next if defined(getpwuid($_));

    $uid = $_;
    last;
}

assert_user_does_not_exist('foo');
assert_path_does_not_exist('/nonexistent');

assert_command_success('/usr/sbin/adduser', '--quiet',
	'--system',
       	'foo');
assert_user_exists('foo');

assert_user_has_uid('foo', $uid);

assert_group_does_not_exist('foo');
assert_primary_group_membership_exists('foo', 'nogroup');

assert_user_has_home_directory('foo', '/nonexistent');
assert_path_does_not_exist('/nonexistent');

assert_user_has_login_shell('foo', '/usr/sbin/nologin');

assert_user_has_disabled_password('foo');

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1004710
assert_path_does_not_exist('/var/mail/foo');

while (defined(getpwuid($uid))) {
    $uid++;
}
assert_user_does_not_exist('foo2');
assert_path_does_not_exist('/nonexistent');

assert_command_success('/usr/sbin/adduser', '--quiet',
	'--system',
	'--shell', '/bin/sh',
	'foo2');
assert_user_exists('foo2');

assert_user_has_uid('foo2', $uid);

assert_group_does_not_exist('foo2');
assert_primary_group_membership_exists('foo2', 'nogroup');

assert_user_has_home_directory('foo2', '/nonexistent');
assert_path_does_not_exist('/nonexistent');

assert_user_has_login_shell('foo2', '/bin/sh');

assert_user_has_disabled_password('foo2');

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1004710
assert_path_does_not_exist('/var/mail/foo2');
