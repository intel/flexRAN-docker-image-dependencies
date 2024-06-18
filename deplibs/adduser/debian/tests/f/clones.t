#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=701110


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;


END {
    remove_tree('/home/foo1');
    remove_tree('/var/mail/foo1');
    remove_tree('/home/foo2');
    remove_tree('/var/mail/foo2');
}

assert_user_does_not_exist('foo1');
assert_command_success('/usr/sbin/adduser', '-q', '--system', 'foo1');

assert_user_does_not_exist('foo2');
assert_command_success('/usr/sbin/useradd', '-r',
    '-g', scalar getgrnam('nogroup'),
    '-o', '-u', scalar getpwnam('foo1'), '-s', '/usr/sbin/nologin', 'foo2');

assert_command_success('/usr/sbin/adduser', '-q', 'foo1', 'adm');
assert_command_success('/usr/sbin/adduser', '-q', 'foo2', 'adm');

assert_group_membership_exists('foo1', 'adm');
assert_group_membership_exists('foo2', 'adm');

assert_command_success('/usr/sbin/deluser', '-q', 'foo2', 'adm');

assert_group_membership_exists('foo1', 'adm');
assert_group_membership_does_not_exist('foo2', 'adm');
