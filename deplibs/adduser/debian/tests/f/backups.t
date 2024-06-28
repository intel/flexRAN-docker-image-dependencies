#! /usr/bin/perl -Idebian/tests/lib


use diagnostics;
use strict;
use warnings;

use AdduserTestsCommon;

END {
    remove_tree('/var/mail/foo');
}

test_suffix('gz', 'gzip');
test_suffix('bz2', 'bzip2');
test_suffix('lzo', 'lzop');
test_suffix('xz', 'xz');
test_suffix('zst', 'zstd');

sub test_suffix {
    my ($suffix, $program) = @_;
    my ($archive, $file_list);

    assert_user_does_not_exist('foo');
    assert_command_success('/usr/sbin/adduser', '--quiet', '--system', '--home', '/home/foo', 'foo');
    assert_user_exists('foo');

    open (FH, '>', '/home/foo/test.txt');
    print FH 'created by adduser/backups.t';
    close (FH);

    assert_command_success_silent('/usr/sbin/deluser', '--quiet', '--remove-home', '--backup-to', '/tmp', '--backup-suffix', $suffix, 'foo');
    assert_user_does_not_exist('foo');

    $archive = '/tmp/foo.tar.'.((&which($program, 1)) ? $suffix : 'gz');
    assert_path_exists($archive);
    assert_path_has_ownership($archive, 'root:root');
    assert_path_has_mode($archive, "0600");

    $file_list = `tar tf $archive 2>/dev/null`;
    ok($? == 0, "archive $archive ($suffix) listing successful");
    ok($file_list =~ qr{home/foo/test.txt}, 'archive contents are correct');
    
    unlink($archive);
}
