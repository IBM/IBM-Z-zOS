This directory contains sample code for ACIF, the Advanced Function
Printing Conversion and Indexing Function. It illustrates methods
for coding each of the ACIF exits (Input, Output, Index, and Resource),
and also shows a method of using the ACIF index file to index and
retrieve documents from archive files.

The programs documented here are examples intended to illustrate
the use of MO:DCA indexing. They are not intended as complete working
applications. For more information, please read the comments in the
example code.

AFPINDEX and AFPXTRCT are sample COBOL programs that show how
ACIF produced index and output files can be used.  These extract
programs allow a user to select a group(s) from the output based on the
index values.  A hierarchical index format is assumed. A separate index
file for the selected output is NOT currently produced, but could be
done in APFXTRCT.

How the samples work.
AFPINDEX loads an ACIF index file into a predefined VSAM KSDS.  The
VSAM KSDS is used to allow keyed and partial key searches.  The output
file that corresponds to the index file is repro'd into a VSAM RRDS.  An
RRDS was used to allow skip-sequential reads in COBOL.  AFPXTRCT reads a
control file that contains the key(s) or partial key(s) of the records
to extract.  The format of the control file is INDEX1 followed by INDEX2
followed by INDEX3, ...  Each field must be the same length as defined
in the original ACIF run, values should be padded with blanks (x'40') or
binary zeroes.

The selected group(s) are output to a new QSAM file, ddname AFPXTRCT.
The new files contains the original BDT, as such the cross-reference FQN
triplets will be incorrect - but this should cause no problem, since
these fields are currently for reference only. If your archive process
uses them, you must change AFPXTRCT to put in the correct values.

Using the sample programs.
First compile and link AFPINDEX and AFPXTRCT.  Modify AFPINDEX JCL
to use your libraries, ACIF index file, and VSAM KSDS.  Run AFPINDEX
to create the index VSAM file.  Modify AFPXTRCT to use your libraries,
VSAM files, and change the control card (AFPCNTRL) to contain a value(s)
found in you index files.  Run AFPXTRCT to create a document containing
only the selected groups.
