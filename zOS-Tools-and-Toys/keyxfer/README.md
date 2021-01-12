# keyxfer

A Key Transfer Tool

## Introduction

The key transfer tool (KEYXFER) is a REXX exec that runs on MVS. KEYXFER facilitates the transfer of PKDS or CKDS key tokens between systems that use the Integrated Cryptographic Services Facility (ICSF).

The KEYXFER tool assumes the following:

1. ICSF is running on the systems involved in the key transfer
2. ICSF has an active Key Data Set (CKDS/PKDS)

For a PKA key token transfer the tool retrieves the token from the active PKDS and writes it to a data set (file).  For a symmetric key token transfer the tool retrieves the token from the active CKDS and writes it to a data set (file).

The data set can then be transmitted to any number of systems.  On each system the tool can be used to read the key token from the transmitted file and store it into the active PKDS or CKDS.  The tokens are referenced by label.

The format of the command is illustrated below:

## Syntax

     KEYXFER   OPER, LABEL, DSN,  OPTION

     OPER      = READ_PKDS reads from the transmitted data set
                 WRITE_PKDS writes to the transmitted data set
                 READ_CKDS reads from the transmitted data set
                 WRITE_CKDS writes to the transmitted data set
     LABEL     = label of PKDS or CKDS record to be retreived/stored
     DSN       = name of data set holding the token
     OPTION    = OVERWRITE a label in the PKDS or CKDS.
                 If OVERWRITE is specified in the option
                 field then an existing label will
                 be overwritten with the token from the
                 transmitted data set.

 DATA SET:      A PS or PDS data set can be used.
                An LRECL=80 is recommended, but not required
                The information stored in the KEYXFER data set
                consists of the following:
                  Date
                  KDS label
                  Length of token
                  Token

## Notes

External key tokens can be received on any ICSF system.  If the key token is an internal key token (see ICSF Application Programmers Guide) then it is encrypted under the ICSF master key of the system.  Transferring the key token requires that the receiving systems use the same ICSF master key.

If ICSF services are RACF protected (CSFSERV) then access will be required by the user for the CSNDKRC, CSNDKRR, and CSNDKRW services for PKDS transfers or CSNBKRC, CSNBKRR and CSNBKRW for CKDS transfers.

## Samples

* Write the key token stored in the active PKDS under the label PKDS.KEY.LABEL to the data set  TEMP.MEM

    KEYXFER WRITE_PKDS, PKDS.KEY.LABEL, TEMP.MEM

* Read the key token contained in the data set TEMP.MEM and write the token to the active PKDS under the label PKDS.KEY.LABEL. (If the label already exists in the PKDS the operation will fail.)

    KEYXFER READ_PKDS,  PKDS.KEY.LABEL, TEMP.MEM

* Read the key token contained in the data set TEMP.MEM and write the token to the active PKDS under the label PKDS.KEY.LABEL (If the label already exists in the PKDS the token for that label will be overwritten.)

    KEYXFER READ_PKDS, PKDS.KEY.LABEL, TEMP.MEM, OVERWRITE

* Read the key token contained in the data set TEMP.MEM and write the token to the active PKDS.  Since no PLABEL was specified the label Contained in the file is used as the label for the token on the new system.

    KEYXFER READ_PKDS, , TEMP.MEM

* Write the key token stored in the active CKDS under the label CKDS.KEY.LABEL to the data set TEMP.MEM

    KEYXFER WRITE_CKDS, CPKDS.KEY.LABEL, TEMP.MEM
