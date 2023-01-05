# ISPF-Exporter
This project aims to create tooling to work with automation policies managed by IBM Z System Automation. Automation policies, or *policies* in short, are kept in a set of ISPF-tables that are stored in a partionioned data set (PDS). Unlike other popular data formats used today, like XML or JSON, ISPF-tables cannot be used in their raw format. The tables only reside on z/OS and they can only be processed using ISPF-services. 

So, a tool is needed that makes it easy for developers and admins to access and read the ISPF-data and to enable processing of the data on any platform of choice. Hence, one task addressed by this project is to export a policy into a modern JSON data format. The REXX-script `ispf2j.rex` takes care of this task.

Once a single table is exported, another task addressed by this project is to repeat this process for all other tables in the PDS in a similar way. Since all tables reside in a partionened data set on z/OS the individual JSON-files should also be kept together. On the distributed side, an archive format (e.g zip) or a directory can be used. The REXX-script `exppdb.rex` exports all ISPF-tables into a set of individual JSON-files (using `ispf2j.rex`) that are stored in a directory in a UNIX System Services file system.

The information in JSON can help SA developers to better understand the table data structure and the use of individual columns. It can help service specialists to detect possible corruptions inside the policy that have been caused by defective code. It can be even used as an assist for customers to gain a quick insight into most recent changes compared to a previous snapshot before activating a new configuration created from the new policy.

## JSON-format
The exported data is structured in JSON-file with the following schema for the meta data:
```
{
    "dsn": string,
    "table": string,
    "num_rows": number,
    "keys": string-array,
    "names": string-array,
    "data": object-array
}
```
The actual ISPF-table data is dynamic and uses the *keys* and *names* as denoted by the corresponding meta data attributes as attributes.

## Using the REXX-scripts
Copy the REXX-scripts in folder `./rexx-src` to your TSO and store them in a data set in the SYSPROC or SYSEXEC concatenation. You can use any file transfer utility such as FTP for this. 

### Export a single table
To export a single ISPF-table, use the REXX-script `ispf2j`. The syntax is as follows:
```
ispf2j pds-name table-name directory-name '(' options
```

The three positional parameters have the following meaning:
- pds-name: The name of a PDS(E) data set containing ISPF-tables. The data set can be fully qualified enclosed in single quotes or not fully qualified.  
- table-name: The name of a member in the data set denoted by the previous parameter.
- directory-name: The name of an existing UNIX System Services directory where the JSON-files are stored.

The following options are supported (marginally right now):
- LOGLVL=<u>ERROR</u>|INFO

**Examples**

Use the following command to export a single table, for instance `AOFTADF`, into directory `/u/ibmuser/ispftemp`:
```
ispf2j 'hlq.ispf.pdb' aoftadf /u/ibmuser/ispftemp
```

If errors occur, the reason is shown in form of a TSO/ISPF message or in form of a message issued by the tool itself. For example, the following message shows a situation where the target directory doesn't exist. 
```
12:48:45.217146 - [ERROR] Output file >u/bhol/ispftemp/AOFTADF.json< not opened, error codes 81 594003D
```
The first error code is the hexadecimal return code (errno). The second part is the hexadecimal reason code (errnojrs) of which the last 4 digits are of most interest. Above message indicates errno ENOENT (No such file, directory, or IPC member exists.) and errnojr JRDirNotFound.

### Export a complete data set
To export all ISPF-tables in a library, use the REXX-script `exppdb`. The syntax is as follows:
```
exppdb pds-name directory-name '(' options
```

The two positional parameters have the following meaning:
- pds-name: The name of a PDS(E) data set containing ISPF-tables. The data set can be fully qualified enclosed in single quotes or not fully qualified.
- directory-name: The name of a UNIX System Services directory where the JSON-files are stored. If this directory doesn't exist, it will be created with read and execute permission for everyone and write access for the owner of the file (0755).

Currently, `options` are not used.

**Examples**

Use the following command to export the complete policy database into directory `ispftemp` which, if it doesn't exist, will be created in the owner's home directory, e.g. `/u/ibmuser/`:
```
exppdb ispf.pdb ispftemp
```


# Useful references
For information regarding ISPF-service usage, refer to the following publication:

- _z/OS 2.5 ISPF Services Guide_ 

For information about the specific meaning of error codes, refer to the publication below.

- _z/OS 2.5 UNIX System Services Messages and Codes_  