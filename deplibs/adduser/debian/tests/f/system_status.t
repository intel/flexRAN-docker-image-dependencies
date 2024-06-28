#! /usr/bin/perl -Idebian/tests/lib

# Ref: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=559423


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;


assert_group_does_not_exist('foo');

assert_command_success('/usr/sbin/addgroup', '--quiet', '--system', 'foo');
assert_group_exists('foo');
assert_command_success('/usr/sbin/addgroup', '--quiet', '--system', 'foo');

assert_command_success('/usr/sbin/delgroup', '--quiet', '--system', 'foo');
assert_group_does_not_exist('foo');
assert_command_success('/usr/sbin/delgroup', '--quiet', '--system', 'foo');
