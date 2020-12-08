#!/usr/lpp/perl/bin/perl

# zFS Large Directory Perl Script
#
# This script checks for large directories within zFS File Systems
#
# Status Messages are printed to stdout if the -v option is specified
# Exception Messages (eg, failing a check) are printed to stdout
# Error messages are printed to stderr

use strict;
use warnings;

use File::stat;
use Getopt::Std;

sub largeDir($%);

# Program Exit Code
my $rc = 0;

# Option Flags
my %opts;
getopts('vh?', \%opts);

if ($opts{'h'} || $opts{'?'}) {
	print STDERR "Usage: $0 [-v] [directory [...]]\n";
	exit($rc);
}

print "Reading Filesystem Table\n" if $opts{'v'};
my %df = dfHash();

print "Checking for large directories\n" if $opts{'v'};
if (@ARGV < 1) {
	# Search from the root
	foreach my $dir (sort(keys(%df))) {
		if (largeDir($dir, %df)) {
			$rc = 1;
		}
	}
}
else {
	# Loop through the arguments
	foreach my $dir (@ARGV) {
		if (largeDir($dir, %df)) {
			$rc = 1;
		}
	}
}

# Completion message
print "Finished checking for large directories\n" if $opts{'v'};

# Get Out
exit($rc);

## Sub Routines ##

# Call df to determine our file system layout
# %df{/mnt} = { fstype => xxx, fsname => yyy }
sub dfHash {
	my %df;

	# Call df verbosely...
	open(DFOUT, "df -Pkv |") or die("Can't run df!");

	# Ignore our status line
	my $status = <DFOUT>;

	FILESYSTEM: while(my $filesystem = <DFOUT>) {
		# 1st Line: Filesystem Blocks Used Available Capacity Mount
		$filesystem  =~ /^(\S+)\s+\d+\s+\d+\s+\d+\s+\d+\%\s+(\S+)\s*$/;
		my $name     = $1;
		my $mnt      = $2;

		# 2nd Line per filesystem has the fstype, etc
		my $extended = <DFOUT>;
		$extended    =~ /^(\w+),/;
		my $type     = lc($1);

		# Add new df entry
		$df{$mnt} = { "fstype" => $type, "fsname" => $name };

		# Subsequent number of lines varies...
		while ($extended = <DFOUT>) {
			if ($extended eq "\n") {
				next FILESYSTEM;
			}
			elsif (!$extended) {
				last FILESYSTEM;
			}
		}
	}

	close(DFOUT);

	return %df;
}

# Search for large directories on the specified filesystem
sub largeDir($%) {
	my ($root, %df) = @_;
	my $rc = 0;

	# Our given directory isn't the root of a filesystem
	if (!defined($df{$root})) {
		my @dfout = `df -Pk '$root'`;
		if ($?) {
			die("df failed on $root!");
		}

		# Filesystem Blocks Used Available Capacity Mount
		$dfout[1]  =~ /^\S+\s+\d+\s+\d+\s+\d+\s+\d+\%\s+(\S+)\s*$/;

		if ($df{$1}{'fstype'} ne "zfs") {
			return $rc;
		}
		print "Testing $root on fs $1 | $df{$1}{'fsname'}\n" if $opts{'v'};
	}
	else {
		if ($df{$root}{'fstype'} ne "zfs") {
			return $rc;
		}
		print "Testing filesystem $root | $df{$root}{'fsname'}\n" if $opts{'v'};
	}

	# Call find - Directory on current fs with size >= 1024K
	open(FINDOUT, "find '$root' -type d -xdev -size +1048575c |")
		or die("Can't run find!");

	while(my $dir = <FINDOUT>) {
		# Strip trailing newlines
		chomp($dir);

		# Stat our directory
		my $statbuff = stat($dir);
		if (!defined($statbuff)) {
			warn("stat() failed on $dir: $!");
			return 1;
		}

		# 1MB -> 3MB
		if (($statbuff->size >= 0x100000) && ($statbuff->size < 0x300000)) {
			print("Minor Exception: Large Directory: $dir\n");
			$rc = 1;
		}
		# 3MB and up
		elsif (($statbuff->size >= 0x300000)) {
			print("Major Exception: Really Large Directory: $dir\n");
			$rc = 1;
		}
	}

	close(FINDOUT);

	return $rc;
}
