#!/usr/bin/env perl
use Modern::Perl;
use English qw( -no_match_vars );
use autodie;

use Test::More;

use Git;
use File::Path qw( remove_tree );

# start with a non-existing directory and create two
# consecutive LDIF backups on the new GIT repo

my $BASE = '.';
my $backup_dir = "/tmp/ldap-git-backup/backup-$PID";

ok( (not -e $backup_dir), 'backup directory should not exist at first' );

# ----- first backup -----
ok(
    system(
        "$BASE/ldap-git-backup",
        "--ldif-cmd=cat $BASE/t/testdata/data_A1.ldif",
        "--backup-dir=$backup_dir",
    ) == 0,
    'first backup should run'
);
ok( (-d $backup_dir), 'backup directory should have been created' );
ok( (-d "$backup_dir/.git"), 'backup directory should be a GIT repository now');

check_directory_list($backup_dir, qw(
    .
    ..
    .git
    20120604153004Z-3816ac9.ldif
    20120604153004Z-9941228.ldif
));

my $repo = Git->repository( Directory => $backup_dir );
my @revs = $repo->command('rev-list', '--all');
is( @revs, 1, 'should have one GIT revision' );

# ----- second backup -----
ok(
    system(
        "$BASE/ldap-git-backup",
        "--ldif-cmd=cat $BASE/t/testdata/data_A2.ldif",
        "--backup-dir=$backup_dir",
    ) == 0,
    'second backup should run'
);
check_directory_list($backup_dir, qw(
    .
    ..
    .git
    20120604153004Z-3816ac9.ldif
    20120604153004Z-9941228.ldif
    20120604161324Z-7ebb002.ldif
    20120604161334Z-e2a09bd.ldif
));
@revs = $repo->command('rev-list', '--all');
is( @revs, 2, 'should have two GIT revisions' );

# clean up test data
remove_tree($backup_dir);
done_testing();

exit 0;

sub check_directory_list {
    my ($dir, @filelist) = @_;

    opendir(my $dir_handle, $dir);
    my @file_list_actual = sort readdir($dir_handle);
    closedir($dir_handle);
    my @file_list_reference = sort @filelist;
    is_deeply( \@file_list_actual, \@file_list_reference, 'check file list for completeness' );

    return;
}