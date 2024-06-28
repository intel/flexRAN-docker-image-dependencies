#! /usr/bin/perl -Idebian/tests/lib

use diagnostics;
use strict;
use warnings;

use Fcntl qw(:flock SEEK_END);

use AdduserTestsCommon;

my $lockfile;

ok(open($lockfile, '>>', '/run/adduser'), 'open lockfile');
ok(flock($lockfile, LOCK_EX), 'lock established');
assert_path_exists('/run/adduser', 'lockfile exists');
assert_command_failure_silent('/usr/bin/adduser', '--system', 'foo');
assert_command_failure_silent('/usr/bin/addgroup', '--system', 'bar');
assert_command_failure_silent('/usr/bin/adduser', 'foo', 'bar');
assert_command_failure_silent('/usr/bin/adduser', '--system', 'foo');
assert_command_failure_silent('/usr/bin/deluser', '--system', 'foo');
ok(flock($lockfile, LOCK_UN), 'lock released');

assert_command_success('rm', '-f', '/run/adduser');
assert_command_success('mkdir', '/run/adduser');
assert_command_failure_silent('/usr/bin/adduser', '--system', 'foo');
assert_command_success('rmdir', '/run/adduser');

close($lockfile);
