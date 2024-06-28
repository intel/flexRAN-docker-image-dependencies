#! /usr/bin/perl -Idebian/tests/lib

use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;


END {
    remove_tree('/home/foo');
    remove_tree('/var/mail/foo');
}

my $uid;

# --- disabled-login
assert_user_does_not_exist('disabledlogin');

assert_command_success('/usr/sbin/adduser', '--quiet',
        '--disabled-login',
        '--comment', '""',
        'disabledlogin');
assert_user_exists('disabledlogin');

assert_user_has_login_shell('disabledlogin', '/usr/sbin/nologin');
assert_user_has_disabled_password('disabledlogin');

# --- disabled-login with explicit shell

assert_user_does_not_exist('disabledlogins');

assert_command_success('/usr/sbin/adduser', '--quiet',
        '--disabled-login',
        '--comment', '""',
        '--shell', '/bin/sh',
        'disabledlogins');
assert_user_exists('disabledlogins');

assert_user_has_login_shell('disabledlogins', '/bin/sh');
assert_user_has_disabled_password('disabledlogins');

# --- disabled-password
assert_user_does_not_exist('disabledpassword');

assert_command_success('/usr/sbin/adduser', '--quiet',
        '--disabled-password',
        '--comment', '""',
        'disabledpassword');
assert_user_exists('disabledpassword');

assert_user_has_login_shell('disabledpassword', '/bin/bash');
assert_user_has_disabled_password('disabledpassword');

# --- disabled-password with explicit shell

assert_user_does_not_exist('disabledpasswords');

assert_command_success('/usr/sbin/adduser', '--quiet',
        '--disabled-password',
        '--comment', '""',
        '--shell', '/bin/bash',
        'disabledpasswords');
assert_user_exists('disabledpasswords');

assert_user_has_login_shell('disabledpasswords', '/bin/bash');
assert_user_has_disabled_password('disabledpasswords');

