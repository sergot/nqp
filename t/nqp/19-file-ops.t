#! nqp

# Test nqp::op file operations.

plan(54);

ok( nqp::stat('CREDITS', nqp::const::STAT_EXISTS) == 1, 'nqp::stat exists');
ok( nqp::stat('AARDVARKS', nqp::const::STAT_EXISTS) == 0, 'nqp::stat not exists');

ok( nqp::stat('t', nqp::const::STAT_ISDIR) == 1, 'nqp::stat is directory');
ok( nqp::stat('CREDITS', nqp::const::STAT_ISDIR) == 0, 'nqp::stat not directory');

ok( nqp::stat('CREDITS', nqp::const::STAT_ISREG) == 1, 'nqp::stat is regular file');
ok( nqp::stat('t', nqp::const::STAT_ISREG) == 0, 'nqp::stat not regular file');

my $credits := nqp::open('CREDITS', 'r');
ok( $credits, 'nqp::open for read');
ok( nqp::tellfh($credits) == 0, 'nqp::tellfh start of file');
my $line := nqp::readlinefh($credits);
ok( nqp::chars($line) == 5 || nqp::chars($line) == 6, 'nqp::readlinefh line to read'); # =pod\r?\n
ok( nqp::tellfh($credits) == 5 || nqp::tellfh($credits) == 6, 'nqp::tellfh line two');
my $rest := nqp::readallfh($credits);
ok( nqp::chars($rest) > 100, 'nqp::readallfh lines to read');
ok( nqp::tellfh($credits) == nqp::chars($line) + nqp::chars($rest), 'nqp::tellfh end of file');

ok( nqp::chars(nqp::readlinefh($credits)) == 0, 'nqp::readlinefh end of file');
ok( nqp::chars(nqp::readlinefh($credits)) == 0, 'nqp::readlinefh end of file repeat');
ok( nqp::chars(nqp::readallfh($credits)) == 0, 'nqp::readallfh end of file');
ok( nqp::chars(nqp::readlinefh($credits)) == 0, 'nqp::readlinefh end of file repeat');
ok( nqp::defined(nqp::closefh($credits)), 'nqp::closefh');

ok( nqp::defined(nqp::getstdin()), 'nqp::getstdin');
ok( nqp::defined(nqp::getstdout()), 'nqp::getstdout');
ok( nqp::defined(nqp::getstderr()), 'nqp::getstderr');

## open, printfh, readallfh, closefh
my $test-file := 'test-nqp-19';
nqp::unlink($test-file) if nqp::stat($test-file, 0); # XXX let mvm die on nonexistent file

my $fh := nqp::open($test-file, 'w');
ok($fh, 'we can open a nonexisting file for writing');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'w');
ok($fh, 'we can open an existing file for writing');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
ok(nqp::readallfh($fh) eq '', 'test file is empty');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'wa');
ok(nqp::printfh($fh, "awesome") == 7, 'appended a string to that file');
ok(nqp::printfh($fh, " thing!\n") == 8, 'appended a string to that file... again');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
ok(nqp::readallfh($fh) eq "awesome thing!\n", 'test file contains the strings');
ok(nqp::tellfh($fh) == 15, 'tellfh gives correct position');
nqp::closefh($fh);

my $size := nqp::stat($test-file, nqp::const::STAT_FILESIZE);
$fh := nqp::open($test-file, 'r');
nqp::seekfh($fh, 0, 2);
ok(nqp::tellfh($fh) == $size, 'seekfh to end gives correct position');
nqp::seekfh($fh, 8, 0);
ok(nqp::tellfh($fh) == 8, 'seekfh relative to start gives correct position');
ok(nqp::readallfh($fh) eq "thing!\n", 'seekfh relative to start gives correct content');
nqp::seekfh($fh, -7, 2);
ok(nqp::tellfh($fh) == 8, 'seekfh relative to end gives correct position');
ok(nqp::readallfh($fh) eq "thing!\n", 'seekfh relative to end gives correct content');
nqp::seekfh($fh, -8, 1);
ok(nqp::tellfh($fh) == 7, 'seekfh relative to current pos gives correct position');
ok(nqp::readallfh($fh) eq " thing!\n", 'seekfh relative to current pos gives correct content');
my $ok := 1;
try { nqp::seekfh($fh, -5, 0); $ok := 0; 1 }
ok($ok, 'seekfh before start of file fails');
$ok := 1;
try { nqp::seekfh($fh, 0, 3); $ok := 0; 1 }
ok($ok, 'seekfh with invalid whence fails');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'w');
nqp::closefh($fh);
$fh := nqp::open($test-file, 'r');
ok(nqp::readallfh($fh) eq '', 'opening for writing truncates the file');
nqp::closefh($fh);

## setencoding
$fh := nqp::open($test-file, 'w');
nqp::setencoding($fh, 'utf8');
ok(nqp::printfh($fh, "ä") == 2, 'umlauts are printed as two bytes');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
nqp::setencoding($fh, 'utf8'); # XXX let ascii be the default
my $str := nqp::readallfh($fh);
ok(nqp::chars($str) == 1, 'utf8 means one char for an umlaut');
ok($str eq "ä", 'utf8 reads the umlaut correct');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
nqp::setencoding($fh, 'iso-8859-1');
ok(nqp::chars(nqp::readallfh($fh)) == 2, 'switching to ansi results in 2 chars for an umlaut');
nqp::closefh($fh);

## chdir
if nqp::getcomp('nqp').backend.name eq 'jvm' {
    ok(1, "$_ # Skipped: chdir is not possible on jvm") for (33, 34, 35);
}
else {
    nqp::chdir('t');
    $fh := nqp::open('../' ~ $test-file, 'r');
    nqp::setencoding($fh, 'utf8');
    ok(nqp::chars(nqp::readallfh($fh)) == 1, 'we can chdir into a subdir');
    nqp::closefh($fh);

    nqp::chdir('..');
    $fh := nqp::open($test-file, 'r');
    nqp::setencoding($fh, 'utf8');
    ok(nqp::chars(nqp::readallfh($fh)) == 1, 'we can chdir back to the parent dir');
    nqp::closefh($fh);

    ## mkdir
    nqp::mkdir($test-file ~ '-dir', 0o777);
    nqp::chdir($test-file ~ '-dir');
    $fh := nqp::open('../' ~ $test-file, 'r');
    nqp::setencoding($fh, 'utf8');
    ok(nqp::chars(nqp::readallfh($fh)) == 1, 'we can create a new directory');
    nqp::closefh($fh);
    nqp::chdir('..');

    nqp::rmdir($test-file ~ '-dir');
    nqp::unlink($test-file);
}

if nqp::getcomp('nqp').backend.name eq 'parrot' {
    ok(1, "ok $_ # Skipped: readlinefh is broken on parrot") for (36, 37, 38, 39, 40);
}
elsif nqp::getcomp('nqp').backend.name eq 'moar' {
    ok(1, "ok $_ # Skipped: readlinefh won't match \\r on Moar") for (36, 37, 38, 39, 40);
}
else {
    $fh := nqp::open('t/nqp/19-readline.txt', 'r');
    ok(nqp::readlinefh($fh) eq "line1\r",   'reading a line till CR');
    ok(nqp::readlinefh($fh) eq "line2\r\n", 'reading a line till CRLF');
    ok(nqp::readlinefh($fh) eq "line3\n",   'reading a line till LF');
    ok(nqp::readlinefh($fh) eq "\n",          'reading an empty line');
    ok(nqp::readlinefh($fh) eq "line4",     'reading a line till EOF');
    nqp::closefh($fh);
}

# link
nqp::unlink($test-file ~ '-linked') if nqp::stat($test-file ~ '-linked', nqp::const::STAT_EXISTS);
$fh := nqp::open($test-file, 'w');
nqp::printfh($fh, 'Hello');
nqp::closefh($fh);
nqp::link($test-file, $test-file ~ '-linked');
ok(nqp::stat($test-file ~ '-linked', nqp::const::STAT_EXISTS), 'the hard link should exist');
ok(nqp::stat($test-file, nqp::const::STAT_PLATFORM_DEV) == nqp::stat($test-file ~ '-linked', nqp::const::STAT_PLATFORM_DEV), "a hard link should share the original's device number");
ok(nqp::stat($test-file, nqp::const::STAT_PLATFORM_INODE) == nqp::stat($test-file ~ '-linked', nqp::const::STAT_PLATFORM_INODE), "a hard link should share the original's inode number");
nqp::unlink($test-file);
nqp::unlink($test-file ~ '-linked');

# symlink

my $tmp_file := "tmp";
my $env := nqp::getenvhash();
$env<NQP_SHELL_TEST_ENV_VAR> := "123foo";
nqp::shell("echo %NQP_SHELL_TEST_ENV_VAR% > $tmp_file",nqp::cwd(),$env);
my $output := slurp($tmp_file);
my $is-windows := $output ne "%NQP_SHELL_TEST_ENV_VAR%\n";

if $is-windows {
    ok(1, "ok $_ # Skipped: symlink not tested on Windows") for (44, 45);
}
else {
    nqp::unlink($test-file ~ '-symlink') if nqp::stat($test-file ~ '-symlink', nqp::const::STAT_EXISTS);
    $fh := nqp::open($test-file, 'w');
    nqp::printfh($fh, 'Hello');
    nqp::closefh($fh);
    nqp::symlink($test-file, $test-file ~ '-symlink');
    ok(nqp::stat($test-file ~ '-symlink', nqp::const::STAT_EXISTS), 'the symbolic link should exist');
    if nqp::getcomp('nqp').backend.name eq 'parrot' {
        ok(1, 'ok 45 # Skipped: stat + STAT_ISLNK is broken on parrot');
    }
    else {
        ok(nqp::stat($test-file ~ '-symlink', nqp::const::STAT_ISLNK), 'the symbolic link should actually *be* a symbolic link');
    }
    nqp::unlink($test-file);
    nqp::unlink($test-file ~ '-symlink');
}
