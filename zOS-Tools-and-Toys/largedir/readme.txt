                   Readme zFS Large Directory Utility

zFS Large Directory Utility

Contents

1.0 Objectives and capabilities
2.0 Documentation
3.0 Trademarks

1.0 Objectives and capabilities

The largedir.pl utility identifies zFS directories that might
potentially cause a performance issue by searching for zFS directories
that are 1 MB or larger. A performance issue is particularly noticeable
when a zFS directory is 3 MB or larger.

Note: The size of a directory is independent of the size of the contents
      of that directory.

This utility supports the following options: 

largedir.pl [-v] [directory [...]]

When you specify a directory, the utility searches that directory and
any directory below it within the same file system. If you do not
specify a directory, the utility automatically searches every available
zFS directory on your system.

When you specify the -v option, the utility provides verbose output.
Without this the -v option, the utility displays only directories that
meet the above criteria. Failures always display on standard error.

For example, if you have three file systems mounted at: /zfs1,
/zfs1/foo/hfs, and /zfs1/foo/bar/zfs2

You run: largedir.pl /zfs1/foo

The utility searches foo and bar, but not hfs or zfs2.

Example of output when largedir.pl is successful: 

sandbox $ ./largedir.pl .
	Minor Exception: Large Directory: ./tmp
	sandbox $ echo RC=$?
	RC=1
	sandbox $ rm -r tmp
	sandbox $ ./largedir.pl .
	sandbox $ echo RC=$?
	RC=0

Notes: 
1. Transfer largedir.pl as text to a z/OS machine.
2. Set largedir.pl to run as executable (chmod +x largedir.pl).
3. Install Perl for z/OS. (Perl for z/OS is an unpriced feature of the
   IBM Ported Tools for z/OS.)

2.0 Documentation

For more information, see Chapter 4, "Minimum and maximum file system
sizes" in z/OS V1R11 zFS Administration Guide, SC24-5989-10.

3.0 Trademarks

Trademark or registered trademark of International Business Machines
Corporation in the United States, other countries, or both.

