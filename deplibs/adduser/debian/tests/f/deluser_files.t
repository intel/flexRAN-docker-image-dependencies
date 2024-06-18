#! /usr/bin/perl -Idebian/tests/lib


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;


END {
    # remove_tree('/home/foo');
    # remove_tree('/var/mail/foo');
    system('umount', '/home/foo-extra/mnt');
    remove_tree('/home/foo-extra');
    remove_tree('/tmp/foo-extra');
    unlink('/tmp/foo.tar.gz'); 
    unlink('/tmp/foo.txt');
}

assert_user_does_not_exist('foo');
assert_command_success('/usr/sbin/adduser', '--quiet', '--system', 
    '--home', '/home/foo', 'foo');
assert_user_exists('foo');

my ($login, $pass, $uid, $gid) = getpwnam('foo');
mkdir ('/home/foo-extra', 0777);
mkdir ('/home/foo-extra/mnt', 0777);
mkdir ('/home/foo-extra/dir', 0777);
mkdir ('/tmp/foo-extra', 0777);
for ('/home/foo-extra/extra.txt', '/tmp/foo-extra/extra2.txt', '/tmp/foo.txt') {
    open (XTRA, '>', $_) || die ('could not open file!');
    print XTRA "extra file";
    close (XTRA) || die ('could not close file!');
}
system ('mkfifo', '/home/foo-extra/pipe');
chown ($uid, $gid, 
    '/home/foo-extra', 
    '/home/foo-extra/extra.txt',
    '/tmp/foo-extra/extra2.txt',
    '/home/foo-extra/mnt',
    '/home/foo-extra/dir',
    '/tmp/foo.txt',
    '/home/foo-extra/pipe');
assert_command_success('mount','-o','bind','/tmp/foo-extra','/home/foo-extra/mnt');

assert_command_success('/usr/sbin/deluser', '--quiet', '--system',
    '--backup-suffix', 'gz',
    '--remove-all-files', '--backup-to', '/tmp', 'foo');
assert_user_does_not_exist('foo');
assert_path_does_not_exist('/home/foo');
assert_path_does_not_exist('/home/foo-extra/extra.txt');
assert_path_does_not_exist('/home/foo-extra/pipe');
#FIXME
#assert_path_does_not_exist('/tmp/foo-extra/extra2.txt');
assert_path_exists('/tmp/foo.txt');
assert_path_exists('/home/foo-extra/mnt');
assert_path_does_not_exist('/home/foo-extra/dir');

# check backup archive
assert_path_exists('/tmp/foo.tar.gz');
my $tar_files = `tar tf /tmp/foo.tar.gz`;
is($? >> 8, 0, 'successfully listed backup files');
like($tar_files, qr{home/foo-extra/extra.txt}, 'archive contains expected file: extra.txt');

assert_command_success('/usr/sbin/adduser', '--quiet', '--system', 
    '--home', '/home/foo', 'foo');
assert_user_exists('foo');
assert_command_failure_silent('/usr/sbin/deluser', '--quiet', '--system',
    '--remove-all-files', '--backup-to', '/nonexistent', 'foo');
assert_command_success('/usr/sbin/deluser', '--quiet', '--system',
    '--remove-all-files', '--backup-to', '/tmp', 'foo');
