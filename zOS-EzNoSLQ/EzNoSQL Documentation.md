*![image](https://media.github.ibm.com/user/329101/files/daed8580-0754-11ed-9c97-4a51e5444f52)

# Table of Contents
Introduction and Concepts:
* [Introduction to EzNoSQL](#Introduction-to-EzNoSQL)
* [JSON Documents](#JSON-Documents)
* [Primary Keys](#Primary-keys)
* [Secondary Indexes](#Secondary-Indexes)
* [Active Secondary Indexes](#Creating-and-Activating-Secondary-Indexes)
* [Non-Unique Secondary Indexes](#Unique-and-Non-Unique-Secondary-Indexes)
* [Multi Level Keys](#Multi-Level-Keys)
* [Document Retrieval](#Document-Retrieval)
* [Recoverable Databases](#Recoverable-Databases)

System Requirements:
* [System Requirements](#System-Requirements)
* [Hardware/Software Requirements](#Hardware-and-Software-Requirements)
* [Storage Administration Requirements](#Storage-Administration-Requirements)
* [Application Requirements](#Application-Requirements)

Performance Considerations:
* [In-Memory Caching](#In-Memory-Caching)

Getting Started:
* [Getting Started with EzNoSQL](#Getting-Started)
* [Executables and Side Decks](#C-Executables-and-Side-Decks)
* [Java and JNI Library](#Java-JAR-and-JNI-library)
* [Sample Application Program](#Sample-Application-Program)
* [Compile and Link Procedure](#Compile-and-Link-Procedure)

Application Programming Interfaces (APIs):
* [Application Programming Tiers](#Application-Programming-Tiers)

Data Management APIs:
* [znsq_create()](#znsq_create)
* [znsq_create_index()](#znsq_create_index)
* [znsq_destroy()](#znsq_destroy)
* [znsq_add_index()](#znsq_add_index)
* [znsq_drop_index()](#znsq_drop_index)
* [znsq_report_stats()](#znsq_report_stats)

Connection Management APIs:
* [znsq_open()](#znsq_open)
* [znsq_close()](#znsq_close)

Document Retrieval APIs:
* [znsq_read()](#znsq_read)
* [znsq_position()](#znsq_position)
* [znsq_next_result()](#znsq_next_result)
* [znsq_close_result()](#znsq_close_result)

Document Management APIs:
* [znsq_write()](#znsq_write)
* [znsq_delete()](#znsq_delete)
* [znsq_delete_result()](#znsq_delete_result)
* [znsq_update()](#znsq_update)
* [znsq_update_result()](#znsq_update_result)
* [znsq_commit()](#znsq_commit)
* [znsq_set_autocommit()](#znsq_set_autocommit)
* [znsq_abort()](#znsq_abort)

Diagnostic Management APIs:
* [znsq_last_result()](#znsq_last_result)

Return and Reason Codes:
* [Return Code 0](#Return-Code-0)
* [Return Code 4](#Return-Code-4)
* [Return Code 8](#Return-Code-8)
* [Return Code 12](#Return-Code-12)
* [Return Code 16](#Return-Code-16)
* [Return Code 36](#Return-Code-36)

# Introduction to EzNoSQL

EzNoSQL for z/OS provides a comprehensive set of C and Java-based Application Programming Interfaces (APIs), which enable applications to store JSON (UTF-8) documents while utilizing the full data-sharing capabilities of IBM's Parallel Sysplex technology and System Z Operating System (z/OS). The JSON data can be accessed as either non-recoverable, or with recoverable (transactional) consistency across the sysplex. The APIs also allow for the creation of secondary indexes, which provide for faster queries to specific key fields within the JSON data.

IBM's Parallel Sysplex Coupling Facility (CF) technology enables separate processors to share a single instance of a database (collection of documents) without the need for data sharding, replicating the updates, or programming for eventual consistency. Additionally, the sysplex allows for horizontal scalability by adding additional processors (or z/OS instances) as required. Implementing EzNoSQL on z/OS will inherit many of the desired functions provided by z/OS such as in-memory caching, system-managed storage, data encryption, and compression. EzNoSQL databases can be shared with other exploiters of VSAM databases defined as DATABASE(JSON) Refer to the following link for more information on native access to DATABASE(JSON) databases: [z/OS DFSMS Using Data Sets (Chapter 14)](https://www-40.ibm.com/servers/resourcelink/svc00100.nsf/pages/zOSV2R4sc236855?OpenDocument).

# EzNoSQL Sysplex Design

![image](https://media.github.ibm.com/user/329101/files/68680500-eb19-11ec-9082-bb908596e988)


## JSON Documents

EzNoSQL is a document-oriented data store which accepts UTF-8 JSON documents (analogous to records or rows in other databases). JSON documents must meet the standard as described by [JavaScript Object Notation (JSON)](https://www.json.org/json-en.html). JSON documents consist of an unordered set of `key:value` elements enclosed in brackets, and can be up to two gigabytes in size. The document may contain arrays and other embedded documents:
```json
{
  "Customer_id": "4084",
  "Address": {
    "Street": "1 Main Street",
    "City": "New York",
    "State": "NY"
  },
  "Accounts": ["Checking", "Savings"]
}
```

## Primary Keys

An EzNoSQL database can be defined with a user supplied primary key, where the chosen key must be contained in each the document and paired with a unique value.

The primary key name must be less than 256 characters; however, the key value size is unrestricted. In the above example, the `"Customer_id"` key name may be a good choice for a unique primary key. In this case, `"4084"` becomes the primary key value used to retrieve the document. The primary key value cannot be part of an array; however, it can be an embedded document less than sixteen megabytes in size.  Primary key values cannot be changed (replaced) once inserted, only 
deleted and re-inserted.

If a unique key name is not available, the database can be defined without a key name. EzNoSQL will generate a unique `key:value` and insert the additional element at the beginning of the document. The additional element will use a reserved key name of `"znsq_id"` and will be paired with a 122 byte unique character value:
```json
{
  "znsq_id": "F3F9F3F1C1F0F140404040404040404040404040F0F0F0F0F0F0F0F0F0F0F0F7F2F3C...",
  "Address": {
    "Street": "1 Main Street",
    "City": "New York",
    "State": "NY"
  },
  "Accounts": ["Checking", "Savings"]
}
```
Note that the use of autogenerated keys will incur additional CPU overhead when compared to providing a primary key for document inserts.

The inserted documents can then be retrieved directly via the primary key name and value (e.g. `"Customer_id":"4084"` or `"znsq_id":"F3F9F3F1C1F0F140404040404040404040404040F0F0F0F0F0F0F0F0F0F0F0F7F2F3C"`).  Alternatively, all the documents in the database can be retrieved in a consecutive fashion, beginning either with the first or the last document without providing a key name value. Retrieving documents in this manner will not return documents in order of the key values.


## Secondary Indexes

Documents may also be retrieved or updated through the use of secondary indexes. Secondary indexes contain alternate keys which can be used to retrieve the documents in the database. By creating alternate keys, the application can have more than one option for locating specific documents, or can find groups of like documents more directly than scanning the entire database.  Alternate keys be changed (replaced) after the initial insert.

When creating a secondary index, the application developer assigns the alternate key name which contains the value to be used as the alternate key. Although the alternate key names must be less than 256 characters, the combined key name and paired value is not restricted by length. Secondary indexes must also be created while the database is fully disconnected (closed); however, the activation or deactivation can occur dynamically while the database is connected (open) and in-use. Consideration should be given when creating secondary indexes, as each additional active index will incur additional overhead when updating the database.

Assume an EzNoSQL database is created with a primary key name of `"Customer_id"` and a secondary index with an alternate key name of `"Address"`. It contains the following JSON document:
```json
{
  "Customer_id": "4084",
  "Address": {
    "Street": "1 Main Street",
    "City": "New York",
    "State": "NY"
  },
  "Accounts": ["Checking", "Savings"]
}
```

The document can be retrieved either through the primary index using a key name of `"Customer_id"` and a value of `"4084"`, or via the secondary index using a key name of `"Address"` and a value of `{"Street":"1 Main Street","City":"New York","State":"NY"}`. When replacing documents, all active secondary indexes will be updated to reflect the latest `key:value` changes in the new version of the document.

When secondary index key names are paired with an array, alternate keys will be generated for all the values in the array. For example, an alternate key name of `"Accounts"` would allow the above document to be retrieved using a value of `"Checking"` or `"Savings"`. For a primary key name, only the first value in the array will be used as the primary key.


### Creating and Activating Secondary Indexes

A Secondary Index can be created only while the database is disconnected. However, it can be activated and built at any point in time after the successful creation of the index. Note that the time it takes to build an index is relative to the size of the database. All active indexes are updated whenever new documents are inserted, erased, or updated via the primary key or any other (active) alternate key. If a secondary index is no longer required, it can be switched to inactive (quiesced) across the sysplex.  Activating secondary indexes will require obtaining several large (2 GB) temporary buffers. Ensure that any memory restrictions allow for the necessary buffers.

Once a secondary index is switched to inactive, it will no longer be updated and may become out-of-sync with the documents in the database. While a secondary index is inactive, any requests to access documents via the same index will also fail. Switching the index to inactive will remove the additional overhead of maintaining that index. Inactive indexes can be re-activated and rebuilt by adding the index.


### Unique and Non-Unique Secondary Indexes

Secondary indexes can be defined as either unique or non-unique.  For unique indexes, each key-value must be unique or a duplicate key error is returned. Note that the primary index is always unique. For non-unique secondary indexes, a duplicate value can be used to retrieve all documents containing the same value. In this scenario, EzNoSQL will indicate when more than one document exists for a given alternate key-value.


## Multi-Level Keys

Both the primary and secondary indexes can have a single level key name, or can have a multiple level key name (referred to as a multi-key). The individual levels are connected by the reverse solidus character `\`.  For example, an alternate key name of `"Address\Street"` would allow the following document to be retrieved using a value of `"1 Main Street"`.
```json
{
  "Customer_id": "4084",
  "Address": {
    "Street": "1 Main Street",
    "City": "New York",
    "State": "NY"
  },
  "Accounts": ["Checking", "Savings"]
}
```

Multi-key names can also span into embedded documents or an array of embedded documents. For example, creating a secondary index with a key name of `"Employee\Name"` will allow the following document to be retrieved by either a value of `"John Smith"` or `"Fred Jones"`:
```json
{
  "_id:": "0001",
  "Employee": [{
    "Name": "John Smith"
  },
    {
      "Name": "Fred Jones"
    }
  ]
}
```

## Document Retrieval

Documents can be directly read, updated, or deleted by specifying the desired key name and value. Additionally, documents can be retrieved in an ordered fashion through the use of secondary indexes. For example, the application can position into the secondary index to a specific key-value, or for any value greater than or equal to the desired key range. The documents can then be retrieved in a sequential ascending or descending order, and optionally updated or deleted following the retrieval. When using sequential access to update or delete, the document will not be visible on disk and to other sharers until 1) the end of the buffer is reached, 2) a close result is issued, or 3) a successful close of the database. When a close result is issued, positioning is ended and a new request must be issued to re-establish position within the secondary index. EzNoSQL will indicate via a return code when a duplicate key-value is returned by a non-unique secondary index.

In order to iterate in an ordered fashion over the primary key, and optionally update/delete the document(s), the application may perform a direct read with the update option for the primary key. Then optionally update result, delete result, or end the update by closing the result. Attempting to position with a generic (greater than or equal to) search may result in unpredictable results when used in conjunction with a primary index.

While the combined alternate key-value pair is not length restricted, the alternate key itself will be automatically truncated after the first 251 bytes. Note that truncated keys may be inadvertently recognized as a non-unique key when there exists other keys containing the same initial 251 bytes. Moreover, sequentially reading truncated keys may also return the documents out of order and require further sorting by the application. EzNoSQL will return a reason code alerting the application if a truncated key is detected.

When using alternate keys, documents may be retrieved by specifying either an exact match or generic search (via a full or partial key-value). If the key value is a String, then the partial key-value should contain an ending escaped quote character. For example, `"\"John S\""`.


## Recoverable Databases

The recoverability of a database determines the duration of the locking and the transactional (atomic) capabilities when accessing documents in and across an EzNoSQL database. EzNoSQL will always obtain a document-level exclusive lock for any type of write, update, or delete request, but an optional shared lock may be obtained for reads:

* Non-recoverable databases are created using the default log option parameter of `NONE`. When the database is created with the default log option, the document-level locks are held only for the duration of the update or read request. This means for any type of update (insert, replace, delete), a document-level lock is obtained exclusively and protects the document from multiple (simultaneous) updates. Read requests use a default option with no read integrity (`NRI`).  With `NRI`, the latest version of the document is returned at the time of the read request. Optionally shared locks may be obtained to provide a consistent read which will better protect a reader from viewing the document in the middle of an update. These shared locks may be obtained for the duration of the read request via specifying consistent read (`CR`) or for the entire duration of the transaction via consistent read extended (`CRE`). Obtaining shared locks may incur overhead and should be used only when required.

* Recoverable databases are created using the log option `UNDO` or `ALL`.  The `UNDO` option logs the before image of the document for backing out of a failed transaction. The `ALL` option logs both the before and after image to a forward recovery log for recovering a damaged data set. Using the `ALL` log options parameter adds forward recovery logging for the database and requires a forward recovery log to be assigned to the database. When the database is created with either `UNDO` or `ALL` option, the document-level locks (exclusive or CRE shared locks) are held for the duration of the transaction and only released after a successful commit or abort request. A transaction is started and assigned a unit of work (UOW) ID when the first update is made to any EzNoSQL database under the current task. The transaction can then be explicitly committed or backed out (aborted) by the application via the EzNoSQL APIs. Following a commit or abort, the next update request will start a new transaction ID.

For recoverable databases, the autocommit option will generate a commit after every update. The autocommit option is enabled by default and the application can enable/disable autocommit at any time the task is actively connected. Note that frequent commits can cause additional overhead when updating the database, while infrequent commits can cause record lock contention with other sharers of the database.

If the task ends normally without a commit for the last transaction, an implicit commit will be issued by EzNoSQL. If the task ends abnormally without a commit following the last transaction, an implicit back out (abort) will be issued by EzNoSQL. Transactions which fail to abort will be shunted and the locks owned by the transaction will be retained until the issue preventing the abort is resolved.


# System Requirements

## Hardware and Software Requirements

EzNoSQL executes in an IBM Parallel Sysplex configuration. Refer to [z/OS MVS Setting Up a Sysplex](https://www.ibm.com/docs/en/zos/2.5.0?topic=mvs-zos-setting-up-sysplex) for more information on configuring a Parallel Sysplex. The minimum hardware/software configuration for EzNoSQL requires:
1. At least one logical partition (LPAR) running IBM's Version 2.4 z/OS or above in plex mode with APAR OA62553 (C API), and OA64018/OA64811 (Java API).
2. At least one internal or external Coupling Facility (CF) attached to the LPAR(s) (see [PR/SM Planning Guide](https://www.ibm.com/support/pages/sites/default/files/inline-files/SB10-7175-01a.pdf)). EzNoSQL is provided with z/OS and does not require any additional software licences.

## Storage Administration Requirements

1. Enable the SMSVSAM address space on each LPAR which will access the EzNoSQL databases. If recoverable EzNoSQL databases will be accessed, the DFSMS Transaction VSAM (TVS) manager must be enabled and configured including the availability of forward recovery log streams, if required by the application. Refer to [Administering VSAM record-level sharing](https://www.ibm.com/docs/en/zos/2.5.0?topic=administration-administering-vsam-record-level-sharing), or [VSAM Demystified](https://www.redbooks.ibm.com/abstracts/sg246105.html_-) (Chapters 5 and 6).
2. Configure one or more SMS storage classes (STORCLAS) containing a CACHESET (see [Defining storage classes for VSAM RLS](https://www.ibm.com/docs/en/zos/2.5.0?topic=sharing-defining-storage-classes-vsam-rls#dscrls)). The CACHESET identifies the name of one or more CF cache structures for use by the EzNoSQL databases (see [Defining VSAM RLS attributes in data classes](https://www.ibm.com/docs/en/zos/2.5.0?topic=sharing-defining-vsam-rls-attributes-in-data-classes)).
3. If SMS guaranteed space (GS) storage classes are implemented, the associated storage group (STORGRP) must contain 59 candidate volumes.
4. Provide the name of the SMS STORCLAS name to the application architect for use in creating the databases, or it can be assigned dynamically by the system through the use of SMS Access Control System (ACS). Refer to [DFSMSdfp Storage Administration](https://www-40.ibm.com/servers/resourcelink/svc00100.nsf/pages/zOSV2R5SC236860/$file/idas200_v2r5.pdf) (Chapter 13).
5. Create or assign a database high-level-qualifier to the application developer for use in assigning database names for the EzNoSQL databases.
6. Optionally, create SMS data classes (DATACLAS) to enable additional system functions such as encryption, data compression, SMSVSAM 64-bit buffering, and control of space allocation amounts.  Provide the name of the DATACLAS to the application architect for use when defining the database, or it can be assigned dynamically by the system through the use of SMS Access Control System (ACS). Refer to [Defining Shareoptions and RLS attributes for data class](https://www.ibm.com/docs/en/zos/2.5.0?topic=attributes-defining-shareoptions-rls-data-class#dorlsadc).
7. Optionally, create SMS management classes (MGMTCLAS) to provide backup and data retention requirements for the EzNoSQL data. Provide the name of the MGMTCLAS to the application architect for use when defining the database, or it can be assigned dynamically by the system through the use of SMS Access Control System (ACS) (link).

## Application Requirements

Contact your system administrator for requirements when creating EzNoSQL databases:
1. High level qualifier(s) for database names.
2. `STORCLAS` name if not assigned by the system. A `STORCLAS` name is required either explicitly on the create API (znsq_create), or implicitly by the system. If a  name is not assigned by either method, the creation of the database will fail.
3. `DATACLAS` name if not assigned by the system for optional features (i.e. encryption, compression, storing data in the CF global cache) if required by the application.
4. `MGMTCLAS` name if not assigned by the system for application requirements related to data backup frequency and data retention.

Programs intending to use EzNoSQL must not execute in cross-memory (XM) mode, Functional Recovery Routine (FRR) mode, or non-primary Address Space Control (ASC) mode.

Programs intending to allow multiple concurrent reads/writes to the database while sharing a connection and single open must issue the connect and at least one read/write API to force the open from a parent task.  Subsequent concurrent read/write requests must be issued as children of the parent task which issued the open.  The close connection must be issued by the task that performed the open (i.e. parent task).  

Applications should consider a recovery design for handling a z/OS EzNoSQL server (SMSVSAM) recycle while databases are open.  Any subsequent API call to the database will receive and error indicating the server is unavailable or a new instance has initialized.  Databases should be closed and reopened when the server is available.  SMSVSAM will issue an ENF 45 upon initialization.  

# Performance Considerations

## In-Memory Caching

EzNoSQL databases are accessed via the Record Level Sharing (RLS) function on z/OS servers. RLS provides a 3-tier storage hierarchy which includes:
1. Local real memory buffering
2. Global Coupling Facility (CF) caching
3. Physical disk storage

When a JSON document is read from the database, the local buffer pool is initially searched for an existing (valid) buffer which contains the desired document. If the buffer is not found (or tested to be invalid), the CF cache is then searched and if found loaded into the local buffer pool. If the buffer is not found in the CF cache, a physical I/O is issued to disk, and the buffer is optionally loaded into the CF cache and local buffer pool. Once a buffer is loaded into the CF cache, other sharing LPARs can avoid a physical I/O by accessing the CF copy of the buffer.

When a JSON document is written to the database, the buffer potentially containing the document is first located as described by the read logic above. Once a buffer is located or created, the JSON document is inserted into the buffer, (optionally) written to the CF, then always written to disk. Updated/inserted documents are always written to disk, or a non-zero return code returns to the application indicating the write request did not complete. RLS serializes writes to the CF and to disk, and the buffer is cross-invalidated to any sharing LPARs.

Optionally, loading data into the CF cache may be bypassed and reduces overhead if global caching is not required (for example in a single LPAR configuration). The `RLSCFCACHE` option in the SMS `DATACLAS` controls which buffers are loaded into the CF on behalf of the database. When electing to cache data in the CF, separate cache structures can be assigned to different groups of databases. Separate cache structures can provide more consistent performance by providing isolation from other RLS data. Contact your z/OS Storage Administrator for caching requirements.

# Getting Started

The EzNoSQL C APIs can be called from application user programs running in either 31-bit or 64-bit mode. The Java APIs are 64-bit mode only running on the minimum supported version of Java 8. The user programs can link to the required executables and side decks directly from z/OS USS directories. This section explains the required files along with their location and descriptions. Additionally, a sample user program containing compile and link instructions is provided to help test the system configuration and to gain familiarity with a subset of the available APIs. The full suite of available APIs are detailed in the following sections.

## C Executables and Side Decks

The following table shows the names and locations of the EzNoSQL executables, side decks, and sample program:

| Member             | Location            | Description                |
|--------------------|---------------------|----------------------------|
| `libigwznsqd31.so` | `/usr/lib/`         | C API Library DLL (31-bit) |
| `libigwznsqd31.x`  | `/usr/lib/`         | Side Deck (31-bit)         |
| `libigwznsqd64.so` | `/usr/lib/`         | C API Library DLL (64-bit) |
| `libigwznsqd64.x`  | `/usr/lib/`         | Side Deck (64-bit)         |
| `igwvznsq.h`       | `/usr/include/zos/` | EzNoSQL C Header File      |
| `igwznsqsamp1.c`   | `/samples/`         | Sample C 31-bit program    |

## Java JAR and JNI library
| Member              | Location                     | Description          |
|---------------------|------------------------------|----------------------|
| `libigwznsqj.so`    | `/usr/lib/`                  | JNI Shared Library   |
| `igwznsq.jar`       | `/usr/include/java_classes/` | Java API JAR file    |
| `Igwznsqsamp1.java` | `/samples/`                  | Sample Java program  |

## Sample Application Program

Sample user program: /samples/igwznsqsamp1.c, is a 31-bit user program which does the following sequence of API calls:
1) Create a one megabyte JSON (non-recoverable) EzNoSQL database with a primary key of `"_id"`.
2) Create a one megabyte non-unique secondary index with a key of `"Author"`.
3) Connect (open) the database.
4) Insert three documents with identical key values for `"Author":"J. R. R. Tolkien"`.
5) Position to the top of the secondary index and read all three documents sequentially.
6) Disconnect (close) the data base.
7) Destroy the database.

## Compile and Link Procedure

To compile and link the sample program `/samples/igwznsqsamp1.c`:
```shell
xlc -c -qDLL -qcpluscmt -qLSEARCH="//'SYS1.SCUNHF'" igwznsqsamp1.c
xlc -o igwznsqsamp1 igwznsqsamp1.o -W l,DLL /usr/lib/libigwznsqd31.x
```

# Application Programming Tiers

The following section lists the EzNoSQL Application Programming Interfaces (APIs) available to the application architect. The APIs are classified in four tiers:
1. *Data Management* - APIs to create, destroy, disable, and report on the EzNoSQL databases and associated indexes.
2. *Connection Management* - APIs to establish a connection to the EzNoSQL database, or disconnect the connection when access is no longer required.
3. *Document Management* - APIs to write, delete, update, read, commit, and abort documents in the EzNoSQL databases.
4. *Document Retrieval* - APIs to position within the database and sequentially browse the documents via associated indexes.

![image](https://media.github.ibm.com/user/329101/files/c6a48580-fc8a-11ec-8cad-87c06a2ba221)


## Data Management

APIs in the Data Management section must run in task mode and non cross-memory mode.

### znsq_create

```C
int znsq_create(const char *dsname, const znsq_create_options *options);
```

#### Create EzNoSQL Database
Creates an EzNoSQL primary index database with the name specified in parameter `dsname` using the attributes that are specified by the `options` parameter. Note that EzNoSQL databases can also be created through other system APIs and are compatible and shareable with the EzNoSQL APIs.

#### Parameters
`dsname`: C-string containing the name of the database. The name consists of 1 to 44 EBCDIC characters divided by one or up to 22 segments. Each name segment (qualifier) is 1 to 8 characters, the first of which must be alphabetic (A to Z) or national (# @ $).  The remaining seven characters are either alphabetic, numeric (0 - 9), national, or a hyphen (-). Name segments are separated by a period (.).  If the name is less than 44 characters, the remaining characters should be EBCDIC blanks (x'40').
> Example: MY.JSON.DATA.

`options`: Pointer to an object of type `znsq_create_options`, where the database attributes are provided.

#### Return value
The return code of the function.

If the database was created, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes 2 and 3 of the return code.

#### struct znsq_create_options
`znsq_create_options;`

#### Member attributes
| member           | type     | description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| version          | `int`    | API version.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| znsq_format      | `format` | Database format. Specify `0` (default) for JSON. Currently, only JSON is supported.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| max_space        | `int`    | Maximum space of database in megabytes (required). Additional space will be added per document for system metadata and generated keys: <br> ```Keyed:....x'AC' bytes``` <br> ```Autogenerated Keyed:....x'132' bytes```</br> Refer to section Primary keyed vs Autogenerated keyed databases for information on this option.                                                                                                                                                                                                                                                                   |
| avg_doc_size     | `int`    | Average size of all documents in the database.  Providing an accurate size as close as possible may improve performance when reading/writing to the database.  A zero value will result in a default physical block size of 32768.                                                                                                                                                                                                                                                                                                                                                             |
| update_percent   | `int`    | Percentage of actual update requests compared to writes (inserts) and deletes. Used in conjunction with a non-zero avg_doc_size will further aid in read/write performance by optimizing the physical block size by EzNoSQL.                                                                                                                                                                                                                                                                                                                                                                   |
| znsq_log_options | `enum`   | Database recovery option: </br>`0` indicates the database is non-recoverable (`NONE`). This is the default option.</br>`2` indicates the database is recoverable (`UNDO`) and supports back out logging only.</br>`3` indicates the database is recoverable (`ALL`) and supports both back out and forward recovery logging.</br>Refer to section Non-Recoverable vs Recoverable Database for information on this option.</br>Note that IBM's forward recovery utility (CICSVR) currently does not support EzNoSQL databases, therefore using the `ALL` option may not be useful at this time. |
| primary_key      | `char`   | UTF-8 JSON C-string providing the primary key name for the database. The string must be <256 bytes including quotes, and end with one byte of x'00'.  The key name may consist of a multi level name.  Omitting the key name results in auto-generated keys. Refer to sections Multi Level Key names and Primary Keyed vs Autogenerated Keys for more information on these options.                                                                                                                                                                                                            |
| storclas         | `char`   | C-string in EBCDIC (maximum of 8 characters) for the required system storage class name (`STORCLAS`). </br>Refer to section System Administration Requirements for more information on this option.                                                                                                                                                                                                                                                                                                                                                                                            |
| mgmtclas         | `char`   | C-string in EBCDIC (maximum of 8 character) for the optional system management class name (`MGMTCLAS`).</br>Refer to section System Administration Requirements for more information on this option.                                                                                                                                                                                                                                                                                                                                                                                           |
| dataclas         | `char`   | C-string in EBCDIC (maximum of 8 characters) for the optional system data class name (`DATACLAS`).</br>Refer to the section System Administration Requirements for more information on this option.                                                                                                                                                                                                                                                                                                                                                                                            |
| logstreamId      | `char`   | C-string in EBCDIC (maximum of 26 characters) for the optional forwards recovery log stream.  Required when znsq_log_option = 3 (`ALL`) is specified.                                                                                                                                                                                                                                                                                                                                                                                                                                          |

Example of creating a keyed EzNoSQL database:
```c
      struct znsq_create_options create_options;
      char* dsname = "MY.JSON.DATA";                          // Database name, "MY" qualifer assigned by the system administrator
      char keyname[] = {0x22, 0x5f, 0x69, 0x64, 0x22, 0x00};  // "_id" in utf-8 225F696422
      char storclas[] = "MYSTORCL";                           // STORCLAS name assigned by the system administrator

      create_options.storclas = storclas;
      create_options.primary_key = keyname;

      return_code = znsq_create(dsname, &create_options);

      if (return_code != 0)
      {
        Ilog("Unexpected return code received from znsq_create()");
        Ilog("Return code from znsq_create(): X%x", znsq_err(return_code));
        variation_rc = 1;
        break;
      }
```

### znsq_create_index

```C
int znsq_create_index(const char *alternate_key, unsigned int flags, 
                      const znsq_create_index_options *options)
```

#### Create EzNoSQL Secondary Index
Creates a secondary index with the name specified in parameters `aix_name`, using a key name of `alternate_key`. The database to be associated with this index is specified in the `base_name` parameter. Together, the secondary index and database are associated by the `path_name` parameter. The `path_name` is used internally by EzNoSQL to identify the correct association of the secondary index to its base database. 

The secondary index is created in an inactive state, and must be activated via the `znsq_add_index()` API before attempting to access documents via the specified `alternate_key`. For EzNoSQL databases created as recoverable (`znsq_log_options=UNDO/ALL`), a commit will be issued for any active transaction following the build of the index. Note that EzNoSQL databases can also be created through other system APIs and are compatible and shareable with the EzNoSQL APIs.  

The creation of any secondary index must occur while the database is fully disconnected.

#### Parameters

`alternate_key`: C-string containing the name of the UTF-8 JSON C-string providing the secondary key name for the index. The string must be <256 bytes including quotes and end in one byte of x'00.  The key name may consist of a multi level name.  Refer to section [Multi Level Keys](#Multi-Level-Keys) for more information on this option.

`flags`:
+ _`1 (= (1 << 0))`_ indicates the creation of a unique index. Non-Unique indexes may contain alternate keys representing one or more documents, while unique indexes ensure only one document is represented by each key.  Attempting to insert duplicate documents with the same alternate key into a unique index will result in a duplicate document error. Refer to section entitled Unique vs Non-Unique Indexes for more information on this topic.

+ _`2 (=(1 << 1))`_ indicates descending sequential access when retrieving documents through this index. Refer to section Direct vs Sequential Document Retrieval for more information on this topic.

`options`: Pointer to an object of type `znsq_add_index_options`, where the database attributes are provided.

#### Return value
The return code of the function.

If the database was created, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes 2 and 3 of the return code.

#### struct znsq_create_index_options
`znsq_create_index_options;`

#### Member attributes
| member    | type   | description                                                                                                                                                                                                                                                                                                                                                                                                         |
|-----------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| version   | `int`  | API version.                                                                                                                                                                                                                                                                                                                                                                                                        |
| base_name | `char` | Primary index database name specified on the associated `znsq_create()`.                                                                                                                                                                                                                                                                                                                                            |
| aix_name  | `char` | C-string containing the name of the secondary index. The name consists of 1 to 44 EBCDIC characters divided by one or up to 22 segments. Each name segment (qualifier) is 1 to 8 characters, the first of which must be alphabetic (A to Z) or national (# @ $). The remaining seven characters are either alphabetic, numeric (0-9), national, or a hyphen (-). Name segments are separated by a period (.)        |
|           |        | Example: _MY.JSON.AIX1_                                                                                                                                                                                                                                                                                                                                                                                             |
| path_name | `char` | C-string containing the path name of the secondary index. The name consists of 1 to 44 EBCDIC characters divided by one or up to 22 segments. Each name segment (qualifier) is 1 to 8 characters, the first of which must be alphabetic (A to Z) or national (# @ $). The remaining seven characters are either alphabetic, numeric (0 - 9), national, or a hyphen (-). Name segments are separated by a period (.) |
|           |        | Example: _MY.JSON.PATH1_                                                                                                                                                                                                                                                                                                                                                                                    |
| max_space | `int`  | Maximum space of database in megabytes (required).                                                                                                                                                                                                                                                                                                                                                                  |


Example of creating a non-unique secondary index with descending access:
```C
      struct znsq_create_index_options create__index_options;
      unsigned int create_index_flags = 0;                         //  Initialize create index flags
      char* base_name = "MY.JSON.DATA";                            //  Database name for primary index created with znsq_create
      char* aix_name = "MY.JSON.AIX1 ";                            //  Database name for secondary index
      char* path_name = "MY.JSON.PATH1 ";                          //  Database name for path name to secondary index
      char altkey[] = {0x22, 0x44, 0x61, 0x74, 0x65, 0x22, 0x00};  //  Secondary key name of "Date" in utf-8  224461746522

      #define FLAG_UNIQUE          (1 << 0)                        //  Unique index
      #define FLAG_DESCENDING_KEYS (1 << 1)                        //  Descending retrieves

      create_index_flags = FLAG_UNIQUE + FLAG_DESCENDING_KEYS;     //  Set flags to unique and descending retrieves

      create_aix_options.base_name = base_name;                    //  Database name for primary index
      create_aix_options.aix_name = aix_name;                      //  Database name for secondary index
      create_aix_options.path_name = path_name;                    //  Path name to associate secondary to primary index

      return_code = znsq_create_index(altkey, create_index_flags, &znsq_create_index_options);

      if (return_code != 0)
      {
        Ilog("Unexpected return code received from znsq_create_index()");
        Ilog("Return code from znsq_create_index(): X%x", znsq_err(return_code));
        variation_rc = 1;
        break;
      }
```

### znsq_destroy
```C
int znsq_destroy(const char *dsname);
```

#### Destroy EzNoSQL Database
Destroys an EzNoSQL primary and/or secondary index databases previously created with the name specified in parameter `dsname`. A `znsq_close()` must be issued for all previous opens whether issued via EzNoSQL or other APIs sharing the database.
​
#### Parameters
`dsname`:
C-string containing the name of the previously created EzNoSQL database.

#### Return value
The return code of the function.

If the database was destroyed, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes 2 and 3 of the return code.

Example of destroying an EzNoSQL:
```C
      char* dsname = "MY.JSON.DATA";           // Database name, "MY" qualifer assigned by the system administrator

      return_code = znsq_destroy(dsname);

      if (return_code != 0)
      {
        Ilog("Unexpected return code received from znsq_destroy()");
        Ilog("Return code from znsq_create(): X%x", znsq_err(return_code));
        variation_rc = 1;
        break;
      }
```

### znsq_add_index
```C
int znsq_add_index(const znsq_add_index_options *options);
```

#### Add EzNoSQL Secondary Index
Builds and activates a previously inactive EzNoSQL secondary index for the name specified in parameter `aix_name` and for a base database specified in parameter `base_name`. Note that the length of time to complete the build phase is directly related to the size of the primary index. For databases created as recoverable (`znsq_log_options=UNDO/ALL`), a commit will be issued for any active transaction following the build of the index. Note that EzNoSQL databases can also be created through other system APIs and are compatible and shareable with the EzNoSQL APIs.

Adding an index requires a system reion size or OMVS memory limit greater than 245762M. 

#### Return value
The return code of the function.

If the database was created, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes 2 and 3 of the return code.

#### struct znsq_add_index_options
`znsq_add_index_options;`

#### Member attributes
| member    | type   | description                                                                                                                                                                                                                                                                                                                                                                                                    |
|-----------|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| version   | `int`  | API version.                                                                                                                                                                                                                                                                                                                                                                                                   |
| base_name | `char` | C-string containing the name of the primary index. The name consists of 1 to 44 EBCDIC characters divided by one or up to 22 segments. Each name segment (qualifier) is 1 to 8 characters, the first of which must be alphabetic (A to Z) or national (# @ $). The remaining seven characters are either alphabetic, numeric (0 - 9), national, or a hyphen (-). Name segments are separated by a period (.)   |
|           |        | Example: _MY.JSON.DATA_                                                                                                                                                                                                                                                                                                                                                                                        |
| aix_name  | `char` | C-string containing the name of the secondary index. The name consists of 1 to 44 EBCDIC characters divided by one or up to 22 segments. Each name segment (qualifier) is 1 to 8 characters, the first of which must be alphabetic (A to Z) or national (# @ $). The remaining seven characters are either alphabetic, numeric (0 - 9), national, or a hyphen (-). Name segments are separated by a period (.) |
|           |        | Example: _MY.JSON.AIX1_                                                                                                                                                                                                                                                                                                                                                                                        |

Example of creating a non-unique secondary index with descending access:
```C
      struct znsq_add_index_options add__index_options;
      char* base_name = "MY.JSON.DATA";                 // Database name for primary index created with znsq_create()
      char* aix_name = "MY.JSON.AIX1 ";                 //  Database name for secondary index

      add_index_options.base_name = base_name;

      return_code = znsq_add_index(aix_name, &znsq_add_index_options);

      if (return_code != 0)
      {
        Ilog("Unexpected return code received from znsq_add_index()");
        Ilog("Return code from znsq_add_index(): X%x", znsq_err(return_code));
        variation_rc = 1;
        break;
      }
```
### znsq_drop_index
```C
int znsq_drop_index(const znsq_drop_index_options *options);
```

#### Disable a Secondary Index
Disables (drops) an EzNoSQL secondary index across the sysplex.  When disabled, access is prevented for reads and writes until such a time as the index is re-enabled via the `znsq_add_index()` command.  Note that disabling an index will affect all sharers of the database including those accessed by EzNoSQL and other system APIs.

#### Parameters
`dsname`:
C-string containing the name of the previously added EzNoSQL index by the `znsq_add_index()` API.

#### Return value
The return code of the function.

If the index was dropped, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes 2 and 3 of the return code.

#### struct znsq_add_index_options
`znsq_drop_index_options;`

#### Member attributes
| member    | type   | description                                                                                                                                                                                                                                                                                                                                                                                             |
|-----------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| version   | `int`  | API version.                                                                                                                                                                                                                                                                                                                                                                                            |
| base_name | `char` | C-string containing the name of the database. The name consists of 1 to 44 EBCDIC characters divided by one or up to 22 segments. Each name segment (qualifier) is 1 to 8 characters, the first of which must be alphabetic (A to Z) or national (# @ $). The remaining seven characters are either alphabetic, numeric (0 - 9), national, or a hyphen (-). Name segments are separated by a period (.) |
|           |        | Example: _MY.JSON.AIX1_                                                                                                                                                                                                                                                                                                                                                                                 |


Example of dropping an EzNoSQL index:
```C
      char* dsname = "MY.JSON.AIX1";               // Secondary index name from znsq_add_index()
      char* base_name = "MY.JSON.DATA;             // Associated database name for the primary index

      drop_index_options.base_name = base_name;

      return_code = znsq_drop_index(dsname, &znsq_add_index_options);

      if (return_code != 0)
      {
        Ilog("Unexpected return code received from znsq_drop_index()");
        Ilog("Return code from znsq_create(): X%x", znsq_err(return_code));
        variation_rc = 1;
        break;
      }
```

### znsq_report_stats
```C
int znsq_report_stats(znsq_connection_t con, const char *buf, size_t buff_len);
```

#### Create EzNoSQL usage report

Use the `znsq_report_stats()` API to generate a JSON document containing the attributes and usage information for all the indexes associated with the data set, along with information related to the specific connection by the application. A connection to the data set via the `znsq_open()` API is required prior to calling this API.

#### Parameters:

`znsq_connection_t`:
The znsq_connection_t represents the connection token previously returned by the `znsq_open()` API.

`buf`:
The buf parameter is a required input parameter containing a pointer to a buffer which will contain the generated JSON report document.

`buff_len`:
The buff_len is a required input/output parameter pointing to the length of the buf area. The initial size of the buffer can be calculated as 453 bytes for the primary index, and 346 bytes for each secondary index added to the EzNoSQL database.  If the buffer is too small, a reason code of x'119 is returned along with the required size in this parameter.

Example call to `znsq_report_stats()`:
```C
      return_code = znsq_report_stats(connection, &buf_len, buf);

      if (return_code != 0)
      {
        Ilog("Unexpected return code received from znsq_report_stats()");
        Ilog("Return code from znsq_report_stats(): X%x", znsq_err(return_code));
        variation_rc = 1;
        break;
      }
```

Example format of the returned JSON report document:
```YAML
{
  "name": "MY.JSON.DATA",             // Name of the EzNoSQL primary index
  "version": 1,                       // Version number for JSON document format
  "documentFormat": "JSON",           // Document format is JSON
  "keyName": "_id",                   // Primary key name
  "logOptions": "UNDO",               // Recovery options of UNDO specified on create
  "readIntegrity": "NRI",             // Read integrity
  "readOnly": false,                  // Database opened for write access
  "writeForce": true,                 // Write force requested
  "autoCommit": false,                // Auto commit disabled option
  "descendingKeys": false,            // Sequential access ascending
  "timeout": 5,                       // Lock timeout of 5 seconds
  "avgDocumentSize": 1000,            // Average document size 
  "blockSize": 26624,                 // Physical I/O block size (bytes) selected by znsq_create()
  "avgElapseTime": 150,               // Average time (microseconds) per number of requests
  "avgCPUTime": 8,                    // Average TCB CPU time (microseconds) per number requests
  "statistics": {                     // Primary index statistics embedded document
    "numberBlocksAllocated": 1234,    // Database opened for write access for this connection
    "numberBlocksUsed": 124,          // Total number of blocks allocated to the primary index
    "numberExtents": 1,               // Total number of physical extents for the primary index
    "numberRecords": 2,               // Total number of documents in the primary index
    "numberDeletes": 5,               // Total number of documents deleted since index was created
    "numberInserts": 10,              // Total number of documents inserted since index was created
    "numberUpdates": 4,               // Total number of documents updated since index was created
    "numberRetrieves": 13             // Total number of documents retrieved since index was created
  },
  "numberIndices": 1,                 // Total number of secondary indexes
  "indices": [{                       // Secondary index attributes and statistics
    "name": "HL1.JSON.AIX",           // Name of the secondary index
    "keyname": "Firstname",           // Key name for the secondary index
    "pathname": "HL1.JSON.PATH",      // Path name for the secondary index
    "active": true,                   // Index is synchronized and available for R/W access
    "unique": true,                   // Index contains only unique keys
    "descendingKeys": false,          // Sequential access was set to ascending
    "blockSize": 26624,               // Physical I/O block size (bytes) selected by znsq_add_index()
    "statistics": {                   // Secondary index statistics embedded document 
      "numberBlocksAllocated": 1234,  // Total number of blocks allocated to the secondary index
      "numberBlocksUsed": 124,        // Total number of blocks in use for the secondary index
      "numberExtents": 1,             // Total number of physical extents for the secondary index
      "numberRecords": 2,             // Total number of documents in the secondary index
      "numberDeletes": 5,             // Total number of deleted documents since the index was added
      "numberInserts": 10,            // Total number of inserted documents since the index was added
      "numberUpdates": 4,             // Total number of updated documents since the index was added
      "numberRetrieves": 13           // Total number of retrieved documents since the index was added
    },
    "numberCompoundKeys": 1,          // Number of compound index keys for this secondary index
    "compoundKeys": [{                // Compound keys array (API support will be added at a future date)
      "A": true,                      // Ascending sort for compound key name
      "name": "City"                  // Compound key name
    },
      {}...
    ]
  }]
}
```

## Connection Management

APIs in the Connection Management section, must run in task mode and non cross-memory mode.

### znsq_open
```C
int znsq_open(znsq_connection_t *con, const char *dsname, unsigned int flags, 
              const struct znsq_open_options *options);
```

#### Establishes an open connection to an EzNoSQL database
Opens an EzNoSQL database by establishing a connection between the user's task and the database. Additionally, the `znsq_open()` API establishes the optional parameters to be used on behalf of this connection, such as read integrity, lock timeout, auto commit, read only, write force, and read access direction for the primary index:

Additional connections can be established as needed by the same user task, or other tasks executing across the sysplex. Additional connections allow for the use of different options, or to load balance the workload across different processors. A successful open returns a connection token which must be provided on other APIs for reading and writing to the database.

#### Parameters

`znsq_connection_t`:
C-constant which will contain the connection token after a successful open.

`dsname`:
C-string containing the name of the primary database name specified on a prior create or other system API.

`flags`:
+ _`1 (= (1 << 0))`_ indicates read only access is requested for this connection. Read level security access to the database will be checked, and all write requests will fail.

+ _`2 (=(1 << 1))`_  indicates write force is used when attempting to insert a document with a duplicate key name either for the primary or a unique secondary index. The document is replaced instead of receiving a duplicate document error.

+ _`3 (=(1 << 2))`_  indicates descending sequential access when retrieving documents through the primary index. Refer to section Direct vs Sequential Document Retrieval for more information on this topic.

`options`:
Pointer to an object of type `znsq_open_options`, where the open options are provided.

#### Return value
The return code of the function.

If the database was created, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes 2 and 3 of the return code.

#### struct znsq_open_options
`znsq_open_options;`

#### Member attributes
| member         | type      | description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|----------------|-----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| version        | `int`     | API version.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| znsq_integrity | `enum`    | The (read) integrity specifies whether shared locks will be obtained for retrieves and the duration the lock will be held. </br>Read integrity option:</br>`0` indicates no read integrity (NRI) (default).</br>`1` indicates consist read (CR).</br>`2` indicates consistent read extended (CRE).</br>Refer to section Non-Recoverable vs Recoverable Databases for information on this option.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| znsq_timeout   | `int16_t` | Timeout specifies how long a lock request will wait (in seconds) for the lock before terminating.</br>Lock wait time out in seconds.  Default 0.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| znsq_boolean   | `enum`    | The boolean auto commit option specifies if EzNoSQL will issue a commit after any type of update (write, update, erase), or a read integrity extended (CRE) request on behalf if the user. If this option is omitted, then commits will be performed by the system after each update or CRE read. Note that commits are required only for databases created with the log_options of undo or all, or for reads with the use of the CRE option. Committing after every update request can incur overhead compared to optimizing commits for larger groups of updates. Conversely, committing to infrequently can impact other sharers of the database from accessing the locked documents:</br>`0` indicates auto commit (default)</br>`1` indicates auto commit</br>`2` indicates no auto commit</br>Refer to section Non-Recoverable vs Recoverable Databases for information on this option. |

Example of opening an EzNoSQL database:
```C
      char* base_name = "MY.JSON.DATA";          //  Database name for primary index created with znsq_create()
      znsq_connection_t connection = 0;          //  Initialize returned connection token
      unsigned int open_flags = 0;               //  Initialize open flags
      znsq_open_options.znsq_timeout = 5;        //  Timeout lock waiters after 5 seconds
      znsq_open_options.znsq_boolean = 1;        //  Auto commit after ever update

      #define FLAG_READ_ONLY       (1 << 0)      //  Read only
      #define FLAG_FORCE_WRITE     (1 << 1)      //  Force writes
      #define FLAG_DESCENDING_KEYS (1 << 2)      //  Descending access to primary index

      open_flags = FLAG_FORCE_WRITE;             //  Set flags to write force on

      return_code = znsq_open(&connection, dsname, open_flags, &open_options);

      if (return_code != 0)
      {
        Ilog("Unexpected return code received from znsq_open()");
        Ilog("Return code from znsq_open(): X%x", znsq_err(return_code));
        variation_rc = 3;
        break;
     }
```

### znsq_close

Closes the connection to the EzNoSQL database previously established by a `znsq_open()`.

```C
int znsq_close(znsq_connection_t con);
```

#### Parameters

`znsq_connection_t`:
The znsq_connection_t represents the connection token previously returned by the `znsq_open()` API.

Example of closing an EzNoSQL database:
```C
      return_code = znsq_close(connection);               // Connection token returned by znsq_open

      if (return_code != 0)
      {
        Ilog("Unexpected return code received from znsq_close()");
        Ilog("Return code from znsq_close(): X%x", znsq_err(return_code));
        variation_rc = 6;
        break;
      }
```

## Document Retrieval

APIs in the Data Retrieval section provide direct and sequential retrievals/updates/deletes of EzNoSQL documents.

### znsq_read
```C
int znsq_read(znsq_connection_t con, const char *buf, size_t *buf_len, const char *key, 
              const char *key_value, unsigned int flags, znsq_read_options *options);
```

#### Direct Read Documents
Issues a direct read for a previously added document using the `key` name and `key_value` specified on the read request.  The key name must match the name on a previously issued `znsq_create()`, `znsq_create_index()`, or a generated `"znsq_id"` element. The value must match a previously added `key_value` paired with the specified key, otherwise a document not found error is returned.

The read request can opt to retrieve the document for update which will obtain an exclusive lock and return a result set token representing ownership of the lock.  The result set token must then be used to issue an update, delete, or end result for the document via `znsq_update_result()`, `znsq_delete_result()`, or `znsq_close_result()` APIs.  For non-recoverable databases, the lock will be released following the update, delete request, or close result.  For recoverable databases, the lock will be released by the `znsq_commit()` or `znsq_abort()` APIs.

#### Parameters

`znsq_connection_t`:
C-constant contains the connection token from a previous `znsq_open()`.

`buf`:
contains a buffer to receive the JSON document following a success read.

`buff_len`:
contains the length of the buffer to receive the document.  The buffer may be larger than the returned document; however, if the buffer is too small to contain the document, an x'51 error is returned to the caller along with the required buffer length. For successful reads, the actual length of the document is returned.  When reading documents containing an auto-generated key, allow for an extra 134 (86x) bytes.

`key`:
C-string containing the key name associated with either the primary or a secondary index and ending with one byte of x'00.

`key_value`:
value for the specific document to be retrieved.

`flags`
+ _`1 (= (1 << 0))`_ indicates read for update.  A read with the update option will obtain a document level lock exclusively and return a token in the `result_set`.

`options`:
Pointer to an object of type `znsq_read_options`, where the read options are provided.

#### Return value
The return code of the function.

If successful read, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes
2 and 3 of the return code.

#### struct znsq_read_options
`znsq_read_options;`

#### Member attributes
| member     | type                | description                                                                                                                         |
|------------|---------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| result_set | `znsq_result_set_t` | Returned when the update option is set in flags and to be used for subsequent `znsq_update_result()` or `znsq_erase_result()` APIs. |

Example of reading a document from an EzNoSQL database:
```C
     struct znsq_read_options read_options;
     unsigned int read_flags = 0;                                      // Initialize read flags
     char keyname[] = {0x22, 0x5f, 0x69, 0x64, 0x22, 0x00};            // "_id" in utf-8  225F696422
     char key_value[] = {0x22, 0x30, 0x31, 0x22, 0x00};                // "01" in utf-8 22303122
     char *read_buf = calloc(200, 1);                                  // Buffer for returned document
     size_t read_buf_len = strlen(read_buf);                           // Buffer length
     int32_t read_keyname_len = strlen(keyname);                       // Key name length
     int32_t read_keyname_val_len = strlen(key_value);                 // Key_value length
     char* read_buf_ptr = (char*) malloc(read_buf_len);                // Pointer to returned document
     char* keyname_ptr = (char*) malloc(read_keyname_len);             // Pointer to key name
     char* keyname_val_ptr = (char*) malloc(read_keyname_val_len);     // Pointer to value
     strncpy(keyname_ptr, keyname, read_keyname_val_len);              // Copy key name
     strncpy(keyname_val_ptr, key_value, read_keyname_val_len);        // Copy value

     #define FLAG_READ_UPDATE       (1 << 1)                           // Read for update
     read_flags = FLAG_READ_UPDATE;                                    // Set flag to read for no update

     return_code = znsq_read(
        connection,
        read_buf_ptr,
        &read_buf_len,
        read_keyname_ptr,
        read_keyname_val_ptr,
        read_flags,
        &read_options
      );

     if (return_code != 0)
     {
        Ilog("Error returned from znsq_read()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(read_buf_ptr);
        free(keyname_val_ptr);
        free(read_keyname_ptr);
        break;
     }
```

### znsq_position
```C
int znsq_position(znsq_connection_t con, znsq_result_set_t *result_set, const char *key, 
                  const char *key_value, enum znsq_search_method search_method, unsigned int flags);
```

#### Position to a key within the EzNoSQL database
Issues a request to locate a specific key value (or a key value greater than or equal to) the desired key range. When the key value length is zero, positioning will be to the first or last document in the database based on the search order parameter: a search order (specified with the `znsq_open()` API) of forward (default) will position to the first document, while backward will position to the last document. Following a successful position, a `result_set` token is returned which is then used as input for subsequent sequential retrieves or updates/deletes.  Positioning is therefore required prior to issuing the `znsq_next_result()`, `znsq_update_result()`, or the `znsq_delete_result()` APIs. Positioning should be terminated by using the `znsq_close_result()` API in order to release the `result_set`.

When using alternate keys with a search_method_option equal to one and searching in a forward (ascending) direcction, key values may be generic (partial key value).  Documents which match the generic key or are greater than will be returned for subsequent retrieves. When providing a generic key for a string it 
should still include ending double quotes which are not part of the actual key value and will not be used in the search for the generic key value.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`znsq_result_set_t`: int32_t token returned following the successful completion of the API and used for subsequent read, update, or delete result APIs.

`key`: C-string containing the key name associated with either the primary or a secondary index and ending with one byte of x'00.

`key_value`: C-string containing the value for the specific document to be retrieved. To position to the first document in the primary ir secondary index, pass an empty string as the key_value.

`znsq_search_method`:
+ _`0`_  indicates that the first (or last) document equal to specified `key_value` should be located for subsequent sequential retrieves/updates/deletes.
+ _`1`_  indicates that the first (or last) document greater than or equal to the specified `key_value` should be located for sequential retrieves/updates/deletes.

`flags`: Reserved for future use.

#### Return value
The return code of the function.

If successfully positioned, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes
2 and 3 of the return code.

Example of positioning to document from an EzNoSQL database:
```C
     char keyname[] = {0x22, 0x5f, 0x69, 0x64, 0x22, 0x00};                 //  "_id" in utf-8  225F696422
     char key_value[] = {0x22, 0x30, 0x31, 0x22, 0x00};                     //  "01"
     int32_t position_keyname_len = strlen(keyname);                        //  Key name length
     int32_t Position_keyname_val_len = strlen(key_value);                  //  Key value length
     char* position_keyname_ptr = (char*) malloc(read_keyname_val_len);     //  Pointer to key name
     char* Position_keyname_val_ptr = (char*) malloc(read_keyname_val_len); //  Pointer to value
     strncpy(position_keyname_ptr, keyname, position_keyname_val_len);      //  Copy key name
     strncpy(keyname_val_ptr, key_value, read_keyname_val_len);             //  Copy value

     #define VSAMDB_KEY_EQUAL (1 << 0)                                      //  Set position to the first document with the specified key_value

     return_code = znsq_position(
        connection,
        &rs,
        position_keyname_ptr,
        VSAMDB_KEY_EQUAL,
        NULL
       );

     if (return_code != 0)
     {
        Ilog("Error returned from znsq_position()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(keyname_val_ptr);
        free(read_keyname_ptr);
        break;
     }
```

### znsq_next_result
```C
int znsq_next_result(znsq_connection_t con, znsq_result_set_t *result_set, const char *buf, 
                     size_t *buf_len, unsigned int flags);
```

#### Sequential retrieval of documents by ascending/descending key value
Issues a sequential read for the next key value based on the search order specified in the `znsq_open()` API. Prior to reading sequentially, a `znsq_position()` must be issued to create the `result_set` token representing the starting key value.  The `result_set` token is used as input for each sequential read in order to receive the document in the user provided buffer. The `znsq_close_result()` API is used to end the positioning into the key range. Note that depending on the read integrity option specified in the `znsq_open()` API, shared locks maybe obtained for each retrieval, and for CRE held until a commit is issued.

The read request can opt to retrieve the documents for update which will obtain an exclusive lock. The result set token must then be used to issue an update, delete, or end result for the document via `znsq_update_result()`, `znsq_delete_result()`, or `znsq_close_result()` APIs.  For non-recoverable databases, the lock will be released following the update or delete request.  For recoverable databases, the lock will be released by the `znsq_commit()`, `znsq_abort()` APIs, or at the end of the task.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`znsq_result_set_t`: int32_t token returned from a previous successful `znsq_position()` or `znsq_next_result()`.

`buf`: contains a buffer to receive the JSON document following a successful read.

`buff_len`: contains the length of the buffer to receive the document.  If the buffer is too small to contain the document, an x'51 error is returned to the caller along with the required buffer length.

`flags`:
+ _`1 (= (1 << 0))`_ indicates read for update.  A read with the update option will obtain a document level lock exclusively and return a token in the `result_set`.

`options`: Pointer to an object of type `znsq_next_result_options`, where the next result options are provided.

#### Return value
The return code of the function.

If successful read, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err` can be used to mask the error reason in bytes
2 and 3 of the return code.

Example of reading documents sequentially from an EzNoSQL database:
```C
     unsigned int next_result_flags = 0;
     char *read_buf = calloc(200, 1);                               // Buffer for returned document
     size_t read_buf_len = strlen(read_buf);                        // Buffer length
     int32_t read_keyname_len = strlen(keyname);                    // Key name length
     int32_t read_keyname_val_len = strlen(key_value);              // Key_Value length
     char* read_buf_ptr = (char*) malloc(read_buf_len);             // Pointer to returned document

     #define FLAG_READ_UPDATE       (1 << 1)                        // Read for update
     next_result_flags = FLAG_READ_UPDATE;                          // Set flag to read forupdate

     return_code = znsq_next_result(
        connection,
        &rs,
        read_buf_ptr,
        &read_buf_len,
        next_result_flags
       );

     if (return_code != 0)
     {
        Ilog("Error returned from znsq_next_result()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(read_buf_ptr);
        break;
     }
```

### znsq_close_result
```C
int znsq_close_result(znsq_connection_t con, znsq_result_set_t result);
```

#### Close Result
Ends positioning into the EzNoSQL database previously established by the `znsq_position()` API.  The `result_set` (provided as input) is invalidated, and for non-recoverable databases, any document level locks will be released.  A new `znsq_position()` must be issued to restart sequential retrievals following the close result.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`znsq_result_set_t`: int32_t token returned from previous `znsq_position()`.

#### Return value
The return code of the function.

If successfully closed, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes
2 and 3 of the return code.

Example of ending positioning with `znsq_close_result()`:
```C
     return_code = znsq_next_result(connection, &rs);

     if (return_code != 0)
     {
        Ilog("Error returned from znsq_close_result()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        break;
     }
```

## Document Management

APIs in the Document Management section must run in non cross-memory mode.

### znsq_write
```C
int znsq_write(znsq_connection_t con, const char *buf, size_t buff_len, znsq_write_options *options);
```

#### Write new documents
Writes (inserts) new documents into the EzNoSQL database using the key name (optionally) specified. Whether the key name represents the primary or a secondary index, all indexes are updated to reflect the new values found in the document. For a keyed EzNoSQL database, the key name on write must match the key name specified on create. If the key value was previously added to the database, then a duplicate document error is returned, unless the write force option was specified on the `znsq_open()` API.

If the key name option is omitted, the database is assumed to be an auto-generated keyed database, and will generate a new `"key:value"` element for the document (refer to the section Primary keyed vs Auto-generated keyed databases for more information on this topic).  If the document contains an auto-generated key element from a prior write request, a duplicate document error will be returned unless the write force option was specified on the `znsq_open()` API.

If the auto-commit option is active for the connection, then a commit will be issued following a successful write.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`buf`: contains the JSON document followed by an ending delimiter of x'00.

`buff_len`: contains the length of the document.

`options`: pointer to an object of type `znsq_write_options, where the database attributes are provided.

#### Return value
The return code of the function.

If the document was created, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes 2 and 3 of the return code.

#### struct znsq_write_options
`znsq_write_options;`

#### Member attributes
| member         | type   | description                                                                                                                   |
|----------------|--------|-------------------------------------------------------------------------------------------------------------------------------|
| version        | `int`  | API version.                                                                                                                  |
| key_name       | `char` | C-string containing the key name used on the `znsq_create()` or `znsq_create_index()` including an ending delimiter of x'00'. |
| autokey_buffer | `char` | Minimum buffer of 122 bytes to receive the generated key for auto generated EzNoSQL databases.                                |
| autokey_length | `char` | Length of the returned auto generated key.                                                                                    |                                                                                

Example of writing a document to a keyed EzNoSQL database:
```C
      char keyname[] = {0x22, 0x5f, 0x69, 0x64, 0x22, 0x00};  // "_id" in utf-8  225F696422
      char key_value[] = {0x22, 0x30, 0x31, 0x22, 0x00};      // "01"
      
      char write_buf[13] = {                                  // Document containing an element with "_id" 
        0x7B, 0x22, 0x5f, 0x69, 0x64, 0x22, 0x3A, 0x22, 0x30, 0x31, 0x22, 0x7D, 0x00
      };

      size_t write_buf_len = strlen(write_buf);
      int32_t write_keyname_len = strlen(keyname);

      char* write_keyname_ptr = (char*) malloc(write_keyname_len);
      char* write_buf_ptr = (char*) malloc(write_buf_len);

      strncpy(write_keyname_ptr, keyname, write_keyname_len);
      strncpy(write_buf_ptr, write_buf, write_buf_len);

      return_code = znsq_write(
        connection,
        write_buf_ptr,
        write_buf_len,
        &write_options
      );

      if (return_code != 0)
      {
        Ilog("Error returned from znsq_write()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(write_keyname_ptr);
        free(write_buf_ptr);
        variation_rc = 3;
        break;
      }
```

### znsq_delete
```C
int znsq_delete(znsq_connection_t, const char *key, const char *key_value);
```

#### Delete Documents
Deletes (erases) existing documents from an EzNoSQL database using the provided primary or secondary key name and paired `key_value`. An exclusive document level lock will be obtained for the delete request. For non-recoverable datasets, the lock will be released immediately following the request, and for recoverable databases, the lock will be released by a `znsq_commit()`, `znsq_abort()`, or when the task ends. All secondary indexes will be updated to reflect any alternate key deletions when the document is deleted.

If the auto-commit option is active for the connection, then a commit will be issued following a successful delete.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`key`: C-string containing the key name associated with either the primary or a secondary index and ending with one byte of x'00.

`key_value`: value for the specific document to be retrieved.

#### Return value
The return code of the function.

If the document was deleted, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes 2 and 3 of the return code.

Example of deleting a document from an EzNoSQL database:
```C
      char keyname[] = {0x22, 0x5f, 0x69, 0x64, 0x22, 0x00};            // "_id" in utf-8 225F696422
      char key_value[] = {0x22, 0x30, 0x31, 0x22, 0x00};                // "01"
      int32_t delete_keyname_len = strlen(keyname);                     //  key name length
      int32_t delete_keyname_val_len = strlen(key_value);               //  key value length
      char* delete_keyname_ptr = (char*) malloc(delete_keyname_len);    //  Pointer to key name
      char* delete_keyval_ptr = (char*) malloc(read_keyname_val_len);   //  Pointer to key value
      strncpy(delete_keyname_ptr, keyname, delete_keyname_len);         //  Copy key name
      strncpy(keyname_val_ptr, key_value, read_keyname_val_len);        //  Copy value

      return_code = znsq_delete(
        connection,
        delete_keyname_ptr,
        delete_keyval_ptr,
      );

      if (return_code != 0)
      {
        Ilog("Error returned from znsq_delete()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(delete_keyname_ptr);
        free(delete_keyval_ptr);
        variation_rc = 3;
        break;
      }
```

### znsq_delete_result
```C
int znsq_delete_result(znsq_connection_t con, znsq_result_set_t result);
```

#### Delete Result
Deletes (erases) existing documents previously retrieved by a (direct) `znsq_read()` or a (sequential) `znsq_next_result()` with the update options specified. An exclusive document level lock is obtained by the read requests. For non-recoverable datasets, the lock will be released immediately following the delete result request, and for recoverable databases, the lock will be released by a `znsq_commit()`, `znsq_abort()`, or when the task ends.

If the auto-commit option is active for the connection, then a commit will be issued following a successful delete.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`znsq_result_set_t': int32_t token returned from a previous successful completion of a `znsq_read()` or `znsq_next_result()` with the update options specified.

#### Return value
The return code of the function.

If the document was deleted, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err` can be used to mask the error reason in bytes 2 and 3 of the return code.

Example of a delete result for a document from an EzNoSQL database:
```C
    return_code = znsq_delete_result(connection, &rs);

    if (return_code != 0)
    {
        Ilog("Error returned from znsq_delete_result()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(delete_keyname_ptr);
        free(delete_keyval_ptr);
        variation_rc = 3;
    }
```

### znsq_update
```C
int znsq_update(znsq_connection_t con, const char *newbuf,const char *key, const char *key_value);
```

#### Direct update documents
Issues a direct update for a previously added document using the requested `key` name and `key_value`, and providing the updated version of the document. The `key` must match the key name on a previously issued `znsq_create()`, `znsq_create_index()`, or a generated `"znsq_id"` element. The value must match a previously added value paired with the specified key name, otherwise a document not found error is returned.

An exclusive document level lock will be obtained for the update request.  For non-recoverable databases, the lock will be released immediately following the request, and for recoverable databases, the lock will be released by a `znsq_commit()`, `znsq_abort()`, or when the task ends.

If the auto-commit option is active for the connection, then a commit will be issued following a successful update.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`newbuf`: contains a copy of the updated document to replace the existing version of the document. All secondary indexes will be updated to reflect any alternate key changes found in the new version of the document.

`key`: C-string containing the key name associated with either the primary or a secondary index and ending with one byte of x'00.

`key_value`: value for the specific document to be retrieved.

#### Return value
The return code of the function.

If the document was updated, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes
2 and 3 of the return code.

Example of updating a document in an EzNoSQL database:
```C
      char keyname[] = {0x22, 0x5f, 0x69, 0x64, 0x22, 0x00};            // "_id" in utf-8  225F696422
      char key_value[] = {0x22, 0x30, 0x31, 0x22, 0x00};                // "01"
      char update_buf[13] = {                                           // Updated document (adds new element)
        0x7B, 0x22, 0x5f, 0x69, 0x64, 0x22, 0x3A, 0x22, 
        0x30, 0x31, 0x22, 0x2C, 0x22, 0x6e, 0x61, 0x6d, 
        0x65, 0x22, 0x3A, 0x22, 0x4a, 0x6f, 0x68, 0x6e,
        0x22, 0x7D, 0x00
      };
      
      int32_t update_keyname_len = strlen(keyname);                     // Key name length
      int32_t update_keyname_val_len = strlen(key_value);               // Key_value length
      size_t update_buf_len = strlen(write_buf);                        // New buffer length
      char* keyname_ptr = (char*) malloc(update_keyname_len);           // Pointer to keynane
      char* keyname_val_ptr = (char*) malloc(update_keyname_val_len);   // Pointer to value
      char* update_buf_ptr = (char*) malloc(update_buf_len);            // Pointer to new buffer
      strncpy(keyname_ptr, keyname, update_keyname_val_len);            // Copy key name
      strncpy(keyname_val_ptr, key_value, update_keyname_val_len);      // Copy value
      strncpy(update_buf_ptr, update_buf, update_buf_len);              // Copy new document

      return_code = znsq_update(
        connection,
	    update_buf_ptr,
        update_keyname_ptr,
        update_keyname_val_ptr
      );

      if (return_code != 0)
      {
        Ilog("Error returned from znsq_update()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(update_buf_ptr);
        free(update_keyname_val_ptr);
        free(update_keyname_ptr);
      }
```

### znsq_update_result
```C
int znsq_update_result(znsq_connection_t con, znsq_result_set_t result, const char *buf, size_t buf_len);
```

#### Update Documents after Reads for Update
Updates existing documents previously retrieved by a (direct) `znsq_read()` or a (sequential) `znsq_next_result()` with the update options specified. An exclusive document level lock is obtained by the read requests. For non-recoverable databases, the lock will be released immediately following the update result request, and for recoverable databases, the lock will be released by a `znsq_commit()`, `znsq_abort()`, or when the task ends.

If the auto-commit option is active for the connection, then a commit will be issued following a successful update.

The updated version of the document may not change the primary key value, however, secondary key values may be change resutlting in the addition of new 
alternate keys or the deletion of existing ones. 

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`znsq_result_set_t`: int32_t token returned by a previous `znsq_read()` with the update option or `znsq_next_result()`.

`buf`: contains a copy of the updated document to replace the existing version of the document. All secondary indexes will be updated to reflect any alternate key changes found in the new version of the document.

`buf_len`: length of buffer containing the updated document.

#### Return value
The return code of the function.

If the document was updated, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes
2 and 3 of the return code.

Example of updating a document in an EzNoSQL database:
```C
    char update_buf[13] = {                                 // Updated document (adds new element)
        0x7B, 0x22, 0x5f, 0x69, 0x64, 0x22, 
        0x3A, 0x22, 0x30, 0x31, 0x22, 0x2C, 
        0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 
        0x3A, 0x22, 0x4a, 0x6f, 0x68, 0x6e,
        0x22, 0x7D, 0x00
    };

    size_t update_buf_len = strlen(write_buf);              // New buffer length
    char* update_buf_ptr = (char*) malloc(update_buf_len);  // Pointer to new buffer
    strncpy(update_buf_ptr, update_buf, update_buf_len);    // Copy new document into buffer

    return_code = znsq_update_result(connection, &rs, update_buf_ptr, &update_buf_len);

    if (return_code != 0)
    {
        Ilog("Error returned from znsq_update()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(update_buf_ptr);
        break;
    }
```

### znsq_commit
```C
int znsq_commit(znsq_connection_t con);
```

#### Commit Updates
Issues a commit to end the current transaction and release document level locks. The next write, delete, or update request will start a new transaction.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

#### Return value
The return code of the function.

If successfully committed, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes
2 and 3 of the return code.

Example of committing transactions for an EzNoSQL database:
```C
     return_code = znsq_commit(connection);

     if (return_code != 0)
     {
        Ilog("Error returned from znsq_commit()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(read_buf_ptr);
        break;
     }
```

### znsq_set_autocommit
```C
int znsq_set_autocommit(znsq_connection_t con, const znsq_commit_options *options);
```

#### Enable/Disable Auto Commit
Updates the connection to the database to enable or disable the auto commit option.  When enabled, EzNoSQL will issue a commit after every update. Commits after every update request can incur overhead compared to optimizing commits for larger groups of updates. Conversely, committing too infrequently can impact other sharers of the database from accessing the locked documents.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

`options`: pointer to an object of type `znsq_commit_options`, where the set autocommit options are provided.

#### Return value
The return code of the function.

If successfully set, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes
2 and 3 of the return code.

#### struct znsq_commit_options
`znsq_commit_options;`

#### Member attributes
| member          | type   | description                                                                                                                            |
|-----------------|--------|----------------------------------------------------------------------------------------------------------------------------------------|
| version         | `int`  | API version.                                                                                                                           |
| znsq_autocommit | `enum` | Enable or disable auto commits:</br>0 indicates the auto commit option is disabled.</br>1 indicates the auto commit option is enabled. |

Example of enabling auto commit for an EzNoSQL database:
```C
     commit_options.znsq_autocommit = 1;             // Enables auto commit

     return_code = znsq_set_autocommit(connection, &commit_options);

     if (return_code != 0)
     {
        Ilog("Error returned from znsq_set_autocommit()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        break;
     }
```

### znsq_abort
```C
int znsq_abort(znsq_connection_t con);
```

#### Abort Updates
Issues an abort to end the current transaction, restore updated documents to their original versions prior to the start of the transaction, and release the document level locks. The next write, delete, or update request will start a new transaction.

#### Parameters

`znsq_connection_t`: C-constant contains the connection token from a previous `znsq_open()`.

#### Return value
The return code of the function.

If successfully aborted, the return code is 0.

If an error occurred, the return code contains the detailed error reason. The macro `znsq_err()` can be used to mask the error reason in bytes
2 and 3 of the return code.

Example of committing transactions for an EzNoSQL database:
```C
     return_code = znsq_abort(connection);

     if (return_code != 0)
     {
        Ilog("Error returned from znsq_abort()");
        Ilog("Return code received: X%x", znsq_err(return_code));
        free(read_buf_ptr);
        break;
     }
```

## Diagnostic Management

APIs in the Document Management section must run in non-cross memory mode.

### znsq_last_result

Use the `znsq_last_result()` API to obtain a text report containing additional diagnostic information following an API failure. The report is primarily intended for the system support staff. The information can be logged by the application and referred to for problem determination.

```C
int znsq_last_result(const char *buf, size_t buff_len);
```

#### Parameters
`buf`: the buf parameter is a required input parameter which will point to a buffer to receive the generated text report.

`buff_len`: the buff_len is a required input/output parameter pointing to the length of the buffer, and on return the length of the report.

Example call to `znsq_last_result()`:
```C
    size_t buffer_size = 32*1024;
    char *buffer = (char *) malloc(buffer_size);
    
    if (!buffer)
    {
        printf("FATAL ERROR - malloc()\n");
        return;
    }
    
    int err = znsq_last_result(&buffer_size, buffer);
    if (err)
    {
        printf("FATAL ERROR - znsq_last_result, rc=%08X\n", err);
        return;
    }

    printf("buffer addr %p, buffer size %d\n", buffer, buffer_size);
    
    char c;
    for (int z = 0; z <= buffer_size; z++)
    {
         c = buffer[z];
         printf("%c",c);
    }
    
    free(buffer);
```

#### Example Report 1
`znsq_last_result()` report following an RC=8 RSN=x'38 (security violation). The additional diagnostic message (ACBMSGAR) indicates a system IEC161I 040-0257 message was issued for an open error ACBERFLG = 98:
```shell
   znsq.last.result Report  2022.042 15:48:52
   API Name: znsq_write          RC: 00000008  RS: 82060038
   Diagnostic Data:
   ACBMSGAR: 40025798
```

#### Example Report 2
`znsq_last_result()` report following an RC=8 RSN=x'44 (duplicate document insert error). The additional diagnostic error (RPLFDWRD) indicates an RC=8 RSN=0801 RPLDUP error:
```shell
   znsq.last.result Report  2022.042 15:48:52
   API Name: znsq_write          RC: 00000008  RS: 82060044
   Diagnostic Data:
   RPLFDWRD: 01080008
```

#### Example Report 3
`znsq_last_result()` report following an RC=8 RSN=x'01 (database not found error). The additional diagnostic error (CATPROB) indicates a RC=8 RSN=42(x'2A) data set not
found error:
```shell
   znsq.last.result Report  2022.042 15:48:52
   API Name: znsq_report         RC: 00000008  RS: 82150001
   Diagnostic Data:
   CATPROB: C5C7002A
```

#### Example Report 4
`znsq_last_result()` report for a no space create failure. The additional diagnostic error is the system output from the IDCAMS utility to create the database:
```shell
   znsq.last.result Report  2022.042 15:48:52
   API Name: znsq_create          RC: 0000000C  RS: 82030004
   Diagnostic Data:
   IDCAMS  SYSTEM SERVICES                                           TIME: 15:48:51        03/03/22

   DEFINE CLUSTER                       
      (NAME(MY.JSON.DATA) 
      CYLINDERS(1000000 1)      
      RECORDSIZE(500000 500000) 
      SHAREOPTIONS(2 3)        
      STORCLAS(SXPXXS01)        
      DATACLAS(KSX00002)        
      LOG(NONE)                 
      SPANNED                   
      DATABASE(JSON)            
      KEYNAME(_id)             
      VOLUME (XP0201)           
      FREESPACE (50 5))         
      DATA(NAME(MY.JSON.DATA.D) 
      CONTROLINTERVALSIZE (32768)) 
      INDEX(NAME(MY.JSON.DATA.I)
      CONTROLINTERVALSIZE (32768))
      IGD01007I DATACLAS ACSRTN VRS 02/19/92-1 ENTERED
      IGD01007I DATACLAS ACS EXECUTOR TEST ROUTINE IS ENTERED
      IGD01007I DATACLAS DEFAULTING TO JCL OR TSO BATCH ALLOCATE
      IGD01008I THE STORCLX ACSRTN VRS 07/06/99-1 ENTERED FOR SYSTEM X
      IGD01008I STORCLAS ACS EXECUTOR TEST ROUTINE IS ENTERED
      IGD01008I STORCLAS DEFAULTED TO JCL OR TSO BATCH ALLOCATE
      IGD01009I MGMTCLAS ACSRTN VRS 07/28/88-1 ENTERED FOR SYSTEM X
      IGD01009I   MGMTCLAS BEING DEFAULTED VIA JCL
      IGD01010I STORGRP ACSRTN VRS 08/06/98-1 ENTERED FOR SYSPLEX
      IGD01010I STORGRP BEING SET VIA STORCLAS UNLESS MULTIPLE GRPS SET
      IGD01010I STORGRP BEING SET VIA STORCLAS UNLESS MULTIPLE GRPS SET
      IGD17226I THERE IS AN INSUFFICIENT NUMBER OF VOLUMES IN THE ELIGIBLE
      STORAGE GROUP(S) TO SATISFY THIS REQUEST FOR DATA SET
      HL1.JSONWS01.BASE.KSDS1
      IGD17290I THERE WERE 2 CANDIDATE STORAGE GROUPS OF WHICH THE FIRST 2
      WERE ELIGIBLE FOR VOLUME SELECTION.
      THE CANDIDATE STORAGE GROUPS WERE:SXP01 SXP02
      IGD17279I 1 VOLUMES WERE REJECTED BECAUSE THEY WERE NOT ONLINE
      IGD17279I 1 VOLUMES WERE REJECTED BECAUSE THE UCB WAS NOT AVAILABLE
      IGD17279I 2 VOLUMES WERE REJECTED BECAUSE OF INSUFF TOTAL SPACE
      IGD17219I UNABLE TO CONTINUE DEFINE OF DATA SET
      HL1.JSONWS01.BASE.KSDS1
      IDC3003I FUNCTION TERMINATED. CONDITION CODE IS 12

      IDC0002I IDCAMS PROCESSING COMPLETE. MAXIMUM CONDITION CODE WAS 12
```
# Return and Reason Codes

API reason codes (RS), consist of 4 bytes xx/yy/zzzz:

  	xx is subcomp (#rs.#cid) =x'82 (ARSC_ID_VRA),
  	 
	yy is VSAM RLS API (VRA) module id (#rs.#mid),
	 
	zzzz is reason code (#rs.#reason), as listed below.

## Return Code 0
____________________________________________________________________________________________________
Return Code 00(X'00)
Reason Code Meaning
____________________________________________________________________________________________________
**0052(X'34)** - While accessing a non-unique index sequentially (e.g. using the znsq_next_result()
API), one or more duplicate keys still exist in the index.

        The program may want to continue reading all the duplicate keys, or stop after a specific 
        key is found.
____________________________________________________________________________________________________
**0053(X'35)** - While accessing an index, a truncated key was returned to the program. Only the
first 251 bytes of the key was stored in the index when the key was inserted.

        The program may want to locate the full key in the returned document before using the key.
____________________________________________________________________________________________________
**0054(X'36)** - While accessing a non-unique index sequentially (e.g. using the znsq_next_result()
API), one or more duplicate keys still exist and a truncated key may have been returned. Only the
first 251 bytes of the key was stored in the index when the key was inserted.

        The program may want to locate the full key in the returned document before using the key.
____________________________________________________________________________________________________
## Return Code 4
____________________________________________________________________________________________________
Return Code 04(X'04)
Reason Code Meaning
____________________________________________________________________________________________________
**0027(X'1B)** - Undo log write failed. While accessing an EzNoSQL database, the undo log is not
available or the write request failed.

        Contact the z/OS Storage Administrator and provide additional documentation via the 
        znsq_last_result() report.
____________________________________________________________________________________________________

## Return Code 8
____________________________________________________________________________________________________
Return Code 08(X'08)
Reason Code Meaning
____________________________________________________________________________________________________
**0001(X'01)** - The database was not found in the catalog. The database name passed on the API was
not found and was required for the successful completion of this API.

        Verify the database was created successfully and has not been deleted prior to issuing this 
        API. In some cases, this reason code code indicate that an internal parmlist was overlaid.
        If necessary, provide the addtional documentation via znsq_last_result() report.
____________________________________________________________________________________________________
**0009(X'09)** - Database not found. A database was not found on the znsq_destroy() API.

        Ensure that the database to be destroyed was created.
____________________________________________________________________________________________________
**0010(X'0A)** - Error Buffer too small. Internal error indicating the error buffer is not large
enough to return additional error information. Minimum size returned in error buffer size.

        Reissue the request with the correct buffer size.
____________________________________________________________________________________________________
**00011(X'0B)** - Missing parenthesis during znsq_create() or znsq_add_index(). Probable internal
error when defining a base, alternate index, or path database (IDC3209I).

        Report the problem to the z/OS Storage Administrator; and if available, provide the output 
        from the znsq_last_result() report.
____________________________________________________________________________________________________
**0012(X'0C)** - Duplicate key name for unique index. znsq_add_index() encountered a document in
the database which would result in a duplicate alternate key and the alternate (secondary) index was
defined as unique.

        Define the secondary index as non-unique, or remove the duplicate key name from the document.
____________________________________________________________________________________________________
**0013(X'0D)** - Open failure while adding/enabling an alternate (secondary) index. Most likely a
znsq_add_index() was issued for a previously defined and active index which has not been disabled
via the znsq_drop_index() API.

        Issue a znsq_drop_index() prior to re-enabling the alternate index. Refer to the 
        znsq_last_result() report for more information on the actual open error.
____________________________________________________________________________________________________
**0014(X'0E)** - SYSDSN Resource unavailable. The znsq_create_index() API could not obtain the
SYSDSN database name. The most likely reason is the database is currently allocated (in use).
znsq_create_index() can only be issued against fully disconnected databases.

        If the database is currently connected, disconnect the database before issuing a 
        znsq_create_index().
____________________________________________________________________________________________________
**0016(X'10)** - Release of the SYSDSN Resource failed. The znsq_create_index() failed when
releasing the SYSDSN resource. This is most likely an internal logic error.

        Contact the z/OS Storage Administration for help in resolving this error.
____________________________________________________________________________________________________
**0017(X'11)** - Reserved.
____________________________________________________________________________________________________
**0018(X'12)** - Database not found. The znsq_open() or znsq_close() API did not find the
specified database.

        Ensure the database has been created prior to opening or closing the database.
____________________________________________________________________________________________________
**0019(X'13)** - Database component not found. The znsq_open() or znsq_close() API did not find
one of the components for the specified database. A partially created database has been detected.

        The database may need to be re-cataloged or recreated. Contact the z/OS storage administrator
        if help is required in repairing the database.
____________________________________________________________________________________________________
**0020(X'14)** - Path entry not found. The znsq_read() or znsq_write() APIs did not find the
required path entry from when the associated index was added.

        The index and path need to be destroyed and readded to correct the problem. Contact the z/OS 
        storage administrator if help is required in repairing the database.
____________________________________________________________________________________________________
**0021(X'15)** - Alternate key not found. The znsq_open(), znsq_close(), znsq_read(), or
znsq_write() APIs did not find the required alternate key.

        Ensure a znsq_add_index() was issued to build an index for the required alternate key.
____________________________________________________________________________________________________
**0028(X'1C)** - Forward recovery log write failed. While accessing an EzNoSQL database, the forward
recovery log was not available or the write request failed.

        Contact the z/OS Storage Administrator and provide additional documentation via the 
        znsq_last_result() report.
____________________________________________________________________________________________________
**0029(X'1D)** - CF cache structure failure. While accessing an EzNoSQL database, the Coupling
Facility (CF) cache failed during the open of the database.

        Contact the z/OS Storage Administrator and provide additional documentation via the 
        znsq_last_result() report.
____________________________________________________________________________________________________
**0030(X'1E)** - CF cache structure is unavailable. While accessing an EzNoSQL database, the Coupling
Facility (CF) cache structure associated with the database's storage class was unavailable during
the open of the database.

        Contact the z/OS Storage Administrator and provide additional documentation via the 
        znsq_last_result() report.
____________________________________________________________________________________________________
**0031(X'1F)** - CF cache set is unavailable. While accessing an EzNoSQL database, the Coupling
Facility (CF) cache set was not found in the database storage class during the open of the database.

        Contact the z/OS Storage Administrator and provide additional documentation via the 
        znsq_last_result() report.
____________________________________________________________________________________________________
**0051(X'33)** - The JSON primary key name field was not found in the catalog when accessing the
database. The database does not appear to be a valid NOSQL DATABASE.

        Verify database was created with the znsq_create API, or was defined with LOG and DATABASE 
        parameters when using IDCAMS DEFINE CLUSTER.
____________________________________________________________________________________________________
**0055(X'37)** - The database was not found in the catalog. The first access to the database will
attempt to open the database and open could not locate the database.

        Verify the database was successfully created prior to accessing the database.
____________________________________________________________________________________________________
**0056(X'38)** - User not authorized to access database. The first access to the database will 
attempt to open the data set for read and/or write. The user is not authorized for the requested 
access.

        Request access for the database if allowed.
____________________________________________________________________________________________________
**0057(X'39)** Open for input and the database is empty. The first access to the database will
attempt to open the database. An open for input fails if the database attempt is empty.

        Open the database for output to add at least one document prior to an open for read only.
____________________________________________________________________________________________________
**0058(X'3A)** - Reserved.
**0064(X'40)**
____________________________________________________________________________________________________
**0065(X'41)** - High used relative byte address (RBA) is higher than the high allocated RBA. The
first access to the database will attempt to open the database. The open discovered the high used
RBA is greater than the high allocated indicating the database is damaged.

        The database may need to be recovered. Contact the z/OS Storage Administrator for help 
        recovering the database.
____________________________________________________________________________________________________
**0066(X'42)** - Update failed during write force. A znsq_write() request was issued with the write
force open option specified. The write request was for a duplicate document, but the force write
(update) failed.

        Refer to the return code and reason code from the znsq_write API for information on why 
        the update failed.
____________________________________________________________________________________________________
**0067(X'43)** - While accessing the database sequentially (e.g. using the znsq_next_result() API) 
the end of the database was reached.

        The program may want to treat this error as expected. If the end of data was not expected, 
        the database may be damaged.

        If the end of data was not expected, the database may need to be recovered. Contact the z/OS
        Storage Administrator for help recovering the database.
____________________________________________________________________________________________________
**0068(X'44)** - A duplicate primary or alternate index key (for a non-unique index) was inserted. 
The insert request is failed.

        The program may want to treat this error as expected. If the program would like to update 
        the document regardless, use the write force option on the znsq_open() API.
____________________________________________________________________________________________________
**0069(X'45)** - No document found for the specified key. A read request for a primary or alternate 
key was not found in the database. The read request is failed.

        The program may want to treat this error as expected. If the error is not expected, the data
        set maybe damaged and may need to be recovered. Contact the z/OS Storage Administrator to 
        help recover the database.
____________________________________________________________________________________________________
**0070(X'46)** - Incompatible lock error. The same unit of recovery requested the same key in an 
incompatible state (e.g. two exclusive lock updates). The request is failed.

        The program may have a data access error trying to obtain the same document keys exclusively 
        in the same unit of recovery record. Correct the logic in the user program.
____________________________________________________________________________________________________
**0071(X'47)** - Deadlock time out occurred. Different units of recovery each are attempting to lock
two different document keys in reversed order. The deadlock is resolved by failing one of the requests.

        The program may expect this situation and can redrive the failed request. The program may want
        to improve the logic to avoid deadlocks which can impact performance.
____________________________________________________________________________________________________
**0072(X'48)** - A lock time out occurred. A read/write request timed out waiting for a document 
lock for the specified key. The timeout value specified at open was greater than zero and the 
request waited longer than the timeout value.

        The program may expect this situation and can take an action to release the held lock and 
        redrive the failed request. The timeout value may need to be increased to tolerate the 
        expected wait time.
____________________________________________________________________________________________________
**0073(X'49)** - Out of space. A write request attempt to extend the size of the database failed.

        The database may have reached its maximum size or there is not enough space on the available
        volumes.
____________________________________________________________________________________________________
**0074(X'4A)** - Reserved.
**0079(X'4F)**
____________________________________________________________________________________________________
**0080(X'50)** - Memory obtain error. A read or write request attempted to obtain memory for internal
control blocks and the request failed.

        The program's memory may be exhausted. If unexpected, report the problem to z/OS support for
        help diagnosing the problem.
____________________________________________________________________________________________________
**0081(X'51)** - Buffer too small. A read or write request did not provide an adequate buffer to 
hold the requested document or auto-generated key value. The required size is returned in the
buffer size field provided on the API.

        Obtain the correct buffer size and redrive the request. For write requests the buffer would 
        be the return buffer for autogenerated keys.
____________________________________________________________________________________________________
**0082(X'52)** - Request Parameter List (RPL) reuse error. Multiple requests to access the database 
are using the same RPL. This is an internal logic error in the system software.

        Report the problem to z/OS support.
____________________________________________________________________________________________________
**0083(X'53)** - Maximum number of concurrent requests exceeded the limit. For each znsq_open(), up 
to 1024 concurrent requests are allowed. Requests exceeding 1024 will be failed.

        Reduce the number of concurrent requests or issue another znsq_open() in the same program or
        other sharing instances.
____________________________________________________________________________________________________
**0084(X'54)** - Illegal key change. An update request for a document through an alternate index 
attempted to change the primary key. Primary keys cannot be changed once the document is inserted.

        Correct the document to ensure the primary key has not been changed.
____________________________________________________________________________________________________
**0085(X'55)** - No key name found. A write request provided a document that does not contain a key 
that matches the key name on the znsq_create(). Either the key name is not in the JSON document, or 
the JSON document itself is of an invalid structure.

        Ensure the document contains the required key name or is a valid JSON document.
____________________________________________________________________________________________________
**0086(X'56)** - Incomplete document found. A read request attempted to return a document that has an
incomplete length. The write request of the original document may have failed and was only partially
written to disk. This type of error may occur for non-recoverable (logOptions(NONE)) databases.
Recoverable databases (logOptions(UNDO)) would have backed out the damaged document after the unit
of recovery was backed out or retried.

        The damaged document may still be deleted from the data set. Use recoverable data sets to 
        avoid damaged data sets. The logOptions attribute is returned on the znsq_report_stats() API.
____________________________________________________________________________________________________
**0087(X'57)** - Request Parameter List (RPL) error. Invalid RPL options were specified by the 
system code. One example would be when attempting sequential writes/updates/deletes to the primary 
index set. Using sequential access (i.e., znsq_position()) for updates/deletes is only applicable to
secondary indexes.

        To update the primary index, use znsq_read for update followed by znsq_updated_result or
        znsq_delete_result(). If an error is still received, capture the znsq_last_result diagnostic
        information and report the problem to the z/OS support.
____________________________________________________________________________________________________
**0088(X'58)** - Invalid user environment. The user's program is executing in cross memory mode. 
API calls must not be issued in cross memory.

        Correct the environment the user program is executing in to non-cross memory.
____________________________________________________________________________________________________
**0089(X'59)** - Invalid index pointers. The database's index is corrupted. This is likely a system
software defect.

        For the primary index, the database may need to be redefined and reloaded to rebuild the 
        index. For alternate indexes, a znsq_drop_index() followed by a znsq_add_index() will 
        rebuild the index. Save a copy of the damaged database and report the problem to the z/OS 
        Storage Administrator.
____________________________________________________________________________________________________
**0090(X'5A)** - Access type not allowed. A write, update, or erase request was issued against a 
database opened for input (read) only.

        If write access is required, open the database for output if eligible.
____________________________________________________________________________________________________
**0091(X'5B)** - Retained lock failure. A request to obtain a document level lock has failed because
the lock is in a retained state from a previous transaction, which has either failed to back out
(transaction shunted), or has closed the database and not yet issued a commit or abort. The request
to obtain the lock is failed until such a time the owning transaction (URID) completes the transaction.

        Ensure all transactions are committed before closing the database to limit the window retain 
        locks may be encountered. It the transaction owning the lock has become shunted, contact the
        system storage administrator to list the shunted URIDs and either retry or if necessary 
        purge the URID(s).
____________________________________________________________________________________________________
**0092(X'5C)** - Reserved.
**0095(X'5F)**
____________________________________________________________________________________________________
**0096(X'60)** - Incomplete document found. A read request attempted to return a document that has an
incomplete document segment. The write request of the original document may have failed and was only
partially written to disk. This type of error may occur for non-recoverable (logOptions(NONE))
databases. Recoverable data sets (logOptions(UNDO)) would have backed out the damaged document after
the unit of recovery was backed out or retried.

        The damaged document may still be deleted from the data set. Use recoverable data sets to 
        avoid damaged data sets. The logOptions attribute is returned on the znsq_report_stats() API.
____________________________________________________________________________________________________
**0097(X'61)** - 0097(X'61') No base record. A read or write through an alternate index could not 
locate the document in the base database. This is likely an internal error or system failure that
cause the alternate index to be out of sync with the base database.

        Rebuilding the index can correct the problem by issuing a znsq_drop_index (or znsq_destroy
	_index, followed by a znsq_add_index).  Saving a copy of the primary and secondary indexes
        prior to rebuilding the index may help diagnose the inconsistencey.
____________________________________________________________________________________________________
**0098(X'62)** - Maximum duplicate index keys. The maximum number of non-primary (alternate) keys 
has been reached. The maximum number of duplicate keys support is 4 gigabytes.

        Consider choosing index keys for more unique values. The unique attribute is returned on the
        znsq_report_stats() API.
____________________________________________________________________________________________________
**0099(X'63)** - Attempt to write corrupted index entry. While inserting/updating documents, the 
system software detected an invalid index record is about to update the database's index. The bad 
record is not written the request which caused the bad entry is failed. A dump is produced. This is 
likely a system software defect.

        Report the problem to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0100(X'64)** - Potentially corrupted database. Write requests are failed due to a prior internal 
logic error which occurred during a critical system code path and may indicate the database was 
damaged and needs to be recovered.

        All opens on this system must close and re-open before write requests may resume. The 
        database shoule be examined for errors and may need the primary or alternate indexes rebuilt
        by reloading the base database and/or issuing a znsq_drop_index() or znsq_destroy() for the 
        alternate indexes, followed by a znsq_add_index().

        Save a copy of the potentially damaged database and report the problem to the z/OS Storage 
        Administrator.
____________________________________________________________________________________________________
**0101(X'65)** - User not authorized to alter the database. The znsq_add_index() and znsq_drop_index()
API alters the data set and update access is required.

        Obtain update access if allowed for this database.
____________________________________________________________________________________________________
**0102(X'66)** - Multiple add indexes in progress. More than one znsq_add_index() is executing for 
the same alternate index. The duplicate adds are failed.

        Restrict the number of concurrent znsq_add_index() requests for a given index.
____________________________________________________________________________________________________
**0103(X'67)** - Physical I/O failed. While writing a document to the database, a physical I/O error
occurred. The duplicate adds are failed. A system dump is produce for this error.

        Report the problem to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0104(X'68)** - Insert in backward mode. A znsq_write() request was issued while processing the 
data in backward. This is likely an internal logic error.

        Report the problem to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0105(X'69)** - New system instance after open. The system server's transactional instance has
restarted after open.

        Fully close and reopen the database on this system.
____________________________________________________________________________________________________
**0106(X'6A)** - A znsq_next_result() or znsq_close_result() API was issued without a proceeding 
znsq_position().

        Issue or reissue the znsq_position() prior to issuing the znsq_next_result().
____________________________________________________________________________________________________
**0107(X'6B)** - Reserved.
**0111(X'6F)**
____________________________________________________________________________________________________
**0112(X'70)** - The database is quiesced for backup. A request to insert/update/erase a document 
occurred while the data set is temporarily quiesced for backup.

        Retry the request after the backup completes, define the database using a DCName for a 
        DATACLAS with the Backup While Open (BWO) option in the DATACLAS.
____________________________________________________________________________________________________
**0113(X'71)** - The system's transactional server is disabling. An attempt to access a recoverable 
database (logOptions(UNDO/ALL) while the transaction server instance is disabling.
        
        Fully close and reopen the data set after the transaction server is available. The 
        logOptions attribute is returned on the znsq_report_stats() API.
____________________________________________________________________________________________________
**0114(X'72)** - Invalid user environment. The user's program is executing in an invalid environment.
Either the program is executing in cross memory mode, or issuing requests from a task that is not 
either the task that issued the open (via a read/write request), or a subtask of the task that did 
the open.

        Correct the environment in the user program that meets the requirements.
____________________________________________________________________________________________________
**0115(X'73)** - Document too large for logging. The database was defined as a recoverable database 
(logOptions(UNDO/ALL)) and a document larger than 62K (63488 bytes) was inserted/updated in the 
database. Documents must be less than 62K when using recoverable databases.

        Limit the size of the documents to 62K when using recoverable data sets. The logOptions 
        attribute is returned on the znsq_report_stats() API.
____________________________________________________________________________________________________
**0116(X'74)** - Update or delete issue without prior read for update.

        Issue or reissue the znsq_read() or znsq_next_result() with the update parameter prior to 
        issuing the znsq_update_result() or znsq_delete_result().
____________________________________________________________________________________________________
**0117(X'75)** - Index not active. A request was made to access an inactive index which was 
inactivated by the znsq_drop_index() API.

        Reactivate the desired index with the znsq_add_index() API. The active attribute is returned
        using the znsq_report_stats() API.
____________________________________________________________________________________________________
**0118(X'76)** - Reserved.
____________________________________________________________________________________________________
**0119(X'77)** - A system ABEND has occurred. The znsq API while reading/writing documents 
encountered an error which resulted in a system ABEND. A dump is produced for the error.

        Report the problem to z/OS support.
____________________________________________________________________________________________________
**0120(X'78)** - Locate of internal (BTREE) control blocks failed. The znsq API while accessing the 
database could not locate a BTREE control block anchored in the user's connect token. This error 
could represent a system or user error if the connection token is overlaid or is invalid.

        Verify that a valid connection token was passed on the znsq API. If valid the problem to z/OS support.
____________________________________________________________________________________________________
**0122(X'7A)** - Internal ACB control block pool could not be freed. The znsq API could not free the
storage for an internal (ACB) control block. This error would most likely be an internal system 
logic error. A system dump is produced for this error.

        Report the problem to z/OS support.
____________________________________________________________________________________________________
**0123(X'7B)** - Free of internal (BTREE) control block failed. The znsq API could not free the 
storage for a node in a system BTREE. This error would most likely be an internal system logic error.
A system dump is produced for this error.

        Report the problem to z/OS support.
____________________________________________________________________________________________________
**0124(X'7C)** - Reserved.
**0126(X'7E)**
____________________________________________________________________________________________________
**0144(X'90)** - Internal system logic error. While reading/writing to the database, an internal 
system logic error was detected. A dump may have been produced for this error.

        Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0146(X'92)** - I/O error flushing buffers. While closing the database, an I/O error occurred while
flushing in-memory buffers to disk. A dump may have been produced for this error.

        Report the issue to the z/OS Storage Administrator.

____________________________________________________________________________________________________
**0150(X'96)** - Secondary index not found. The znsq_add_index() API encountered an error while 
dynamically allocating a secondary index.

        Ensure the secondary index has been previously created with the znsq_create_index() or 
        equivalent native API. Issue the znsq_report_stats() API to list the available indexes.
____________________________________________________________________________________________________
**0151(X'97)** - Primary index not found. The znsq_add_index() API encountered an error while 
dynamically allocating the primary index.

        Ensure the secondary index has been previously created with the znsq_create_index() or 
        equivalent native API. Issue the znsq_report_stats() API to list the available indexes.
____________________________________________________________________________________________________
**0154(X'9A)** - Reserved.
**0159(X'9F)**
____________________________________________________________________________________________________
**0256(X'100)** - Invalid key name. The znsq_add_index() API detected that an invalid key name was 
provided to the API. The key name did not start with an opening double quote.

        Correct the program by passing a valid key name.
____________________________________________________________________________________________________
**0257(X'101)** - Invalid key name. The znsq_add_index() API detected that an invalid key name was 
provided to the API. The key name did not end with an opening double quote and/or did not match the 
key name length provided to the API.

        Correct the program by passing a valid key name and/or length.
____________________________________________________________________________________________________
**0261(X'105)** - Invalid key name. An invalid alternate key name was located in the catalog entry 
and exceeded 255 bytes including quotes.

        Correct the program to use an alternate key name <= 255 including quotes.
____________________________________________________________________________________________________
**0262(X'106)** - Invalid key name. An invalid primary key name was located in the catalog entry and
exceeded 255 bytes including quotes.

        Correct the program to use a primary key name <= 255 including quotes.
____________________________________________________________________________________________________
**0263(X'107)** - Open failed for alternate index. While accessing the database, the open for a 
previously added alternate index could not obtain a necessary control block (ACB/Key Btree). This 
error is likely related to a storage shortage in the program's memory.

        Attempt to reduce memory requirements in the program's memory. If unsuccessful, report the 
        issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0264(X'108)** - Database not found. The znsq_open() API could not locate the database.

        Ensure the database was created (znsq_create) prior to attempting to open the data set.
        If the database was created, report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0265(X'109)** - Database not eligible. The znsq_open() API could not locate the database information
required for eligibility for API access. This error is most likely related to a previously created 
database which did not use the znsq_create() API.

        The Record Level Sharing (RLS) cell in the catalog was not found. Destroy and create the API 
        using the znsq apis or create a database which is eligible for RLS access. If the database 
        was created validly and the error still occurs, report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0266(X'10A)** - Reserved.
**0271(X'10F)**
____________________________________________________________________________________________________
**0272(X'110)** - Invalid key name when accessing an EzNoSQL database. The key name passed as input 
does not match the database key name from the znsq_create() or any other key names provided on 
znsq_create_index() APIs.

        Verify that a znsq_create() or znsq_add_index() was issued to add the key name passed on the
        read/write APIs.
____________________________________________________________________________________________________
**0275(X'113)** - Commit failed. The znsq_commit() API detected a failure. The znsq_commit() API 
should only be used for databases defined as a recoverable database (logOptions(UNDO/ALL).

        Verify the database was created using the logOptions(UNDO/ALL). The znsq_report_stats() API 
        can be used to verify this option. If the database is defined correctly, contact the z/OS
        Storage Administrator.
____________________________________________________________________________________________________
**0276(X'114)** - Abort failed. The znsq_abort() API detected a failure. The znsq_abort() API should
only be used for databases defined as a recoverable database (logOptions(UNDO/ALL).

        Verify the data set was created using the logOptions(UNDO/ALL). The znsq_report_stats() API 
        can be used to verify this option. If the data set is defined correctly, contact the z/OS 
        Storage Administrator.
____________________________________________________________________________________________________
**0277(X'115)** - Database not found. The znsq_add_index() or the znsq_drop_index() could not locate
the base database provided to the API.

        Ensure a valid connection token for the correct data set name was provided to znsq_add_index() 
        and znsq_drop_index() APIs. The znsq_report_stats() API can be used to verify the correct base
        name for this connection token. If the name is correct, contact the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0279(X'117)** - Alternate index information not found. The znsq_report_stats() API could not locate
the alternate key information or one of the alternate index previously created with the znsq_add_index().

        Ensure a valid connection token for the correct data set name was provided to the 
        znsq_report_stats() API. If the name is correct, contact the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0280(X'118)** - Data set information not found. The znsq_report_report() API could not locate 
information for the base or one of the alternate index previously created with the znsq_add_index().

        Ensure a valid connection token for the correct data set name was provided to the 
        znsq_report_stats() API. If the name is correct, contact the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0281(X'119)** - Report buffer is too small. The size of the report buffer is too small to hold the 
complete znsq_report_stats() information. The required length is returned in the report length 
parameter on the znsq_report_stats() API.

        Obtain the required buffer size and reissue the znsq_report_stats() API.
____________________________________________________________________________________________________
**0282(X'11A)** - Reserved.
**0287(X'11F)**
____________________________________________________________________________________________________
**0288(X'120)** - The znsq_close() API detected a null connection token.

        Ensure a connection token was passed to the znsq_close() API.
____________________________________________________________________________________________________
**0289(X'121)** - An invalid connection token. The znsq_close() API detected an invalid connection token.

        Ensure a valid connection token was passed to the znsq_close() API.
____________________________________________________________________________________________________
**0291(X'123)** - Document is too large for logging. The database was defined as a recoverable 
database (logOptions(UNDO/ALL)) and a document larger than 62K (63488 bytes) was inserted/updated in
the database. Documents must be less than 62K when using recoverable databases.

        Limit the size of the documents to 62K when using recoverable data sets. The logOptions 
        attribute is returned on the znsq_report_stats() API.
____________________________________________________________________________________________________
**0296(X'128)** - CF cache set is not found. While accessing a EzNoSQL database, the Coupling 
Facility (CF) cache set was not found in the database's storage class during the open of the database.

        Contact the z/OS Storage Administrator and provide additional documentation via the
        znsq_last_result() report.
____________________________________________________________________________________________________
**0299(X'12B)** - Access to ICSF key label failed. The open for an EzNoSQL failed because the user 
does not have access to the ICSF encryption key label.

        Contact your z/OS Security Administrator to gain access to the key label, or provide the 
        correct key label in the database's SMS DATACLAS.
____________________________________________________________________________________________________
**0297(X'1298)** 
**4095(X'FFF)** - Reserved.
____________________________________________________________________________________________________

## Return Code 12
________________________________________________________________________________________________________________________________
Return Code 12(X'0C)
Reason Code Meaning
________________________________________________________________________________________________________________________________
**0002(X'02)** - Duplicate database name. The database name passed on the API was already defined.  This error likely occurs if two
znsq_create API calls are made without a znsq_destroy in between.

             Verify if the database should have been destroyed prior to this create and issue the znsq_destroy API for the data
             set.
________________________________________________________________________________________________________________________________
**0003(X'03)** - Invalid database name. The database name passed on the API has either invalid characters, qualifiers, or exceeds 44
characters.

             Correct the database name to meet z/OS restrictions.  Refer the Data Set names section in the z/OS: z/OS DFSMS Using
             Data Sets book for a description of valid data set names.
_________________________________________________________________________________________________________________________________
**0004(X'04)** - No candidate space or volumes available for the creation of the database. The system does not have enough candidate
volumes available for the znsq_create API. If a guaranteed space STORCLAS was either assigned explicitly on the API,
or via the z/OS storage management policy, then the storage group must have 59 volumes.

             Use a storage class which contains 59 candidate voluems, or assign the database to a non guaranteed storage class.
________________________________________________________________________________________________________________________________
**0005(X'05)** - No guaranteed storage space for the creation of the database. The system does not have enough guaranteed storage
space for the database's maximum space requirement on the znsq_create API.

             Either reduce the maximum space amount, or request more space from the z/OS system administrator.
________________________________________________________________________________________________________________________________
**0006(X'06)** - No storage space available for the creation of the database. The system does not have enough storage space for the
database's maximum space requirement on the znsq_create API.

             Either reduce the maximum space amount, or request more space from the z/OS system administrator.
________________________________________________________________________________________________________________________________
**0007(X'07)** - Parameter out of range. A parameter passed to  z/OS Access Method Services  on either the znsq_create,
znsq_add_index, znsq_drop_index, or znsq_destroy API is out of range.

             Verify the parameters on the above API.  Contact z/OS support for additional diagnostic help.
_________________________________________________________________________________________________________________________________
**0008(X'08)** - No log stream provided. A database parameters on the znsq_create API indicate that LOG_OPTIONS(ALL) is required, but
failed to provide the required LOGSTREAMID name for the forward recovery log stream.

             Provide the LOGSTREAMID parameter, or define the database as LOG_OPTIONS(NONE) or LOG_OPTIONS(UNDO) if forward
             recovery logging is not required.
_________________________________________________________________________________________________________________________________
**0016(X'10)** - Security check failed.  The user does not have the required authority to create or access the database.

             Obtain the required security prior to creating or accessing the database.
__________________________________________________________________________________________________________________________________
**0017(X'11)** - Encryption violation.  The znsq_create API has detected that the database requires encryption support however the
data is using a non-extended format DATACLAS database. Database level key labels are only supported for extended
format databases.

             If encryption support is required, provide an extended format DATACLAS on the create API. Contact the z/OS storage
             administrator for the desired DATACLAS.
__________________________________________________________________________________________________________________________________
**0026(X'1A)** - OPEN failed while building the index.  The znsq_add_index API could not open the base or alternate index while
attempting to build the index.

             Check for valid database names. Refer to the last result report for more specific details regarding the failure.
__________________________________________________________________________________________________________________________________
**0058(X'3A)** - No storage space available for the creation of the database. The system does not have enough storage space for the
database's maximum space requirement on the znsq_create or znsq_create_index APIs.

             Either reduce the maximum space amount, or request more space from the z/OS system administrator.
__________________________________________________________________________________________________________________________________
**0128(X'80)** - Internal control block (RPL) pool could not be obtained. The znsq APIs could not obtain storage for an internal (RPL)
control block. This error would most likely be related to a memory shortage.
A system dump is produced for this error.

             Possibly close databases to free up menory.  Report the problem to z/OS support if the memory shortage is unexpected.
___________________________________________________________________________________________________________________________________
**0129(X'81)** - Internal RPL control block pool could not be freed. The znsq APIs could not free the storage for an internal (RPL)
control block. This error would most likely be an internal system logic error. A system dump is produced for this
error.

             Report the problem to z/OS support.
___________________________________________________________________________________________________________________________________
**0130(X'82)** - Physical I/O failed. While reading the data component of the database, the physical I/O failed the read for data
component control interval containing the document.  A system dump is produce for this error.

             Report the problem to the z/OS Storage Administrator.
___________________________________________________________________________________________________________________________________
**0131(X'83)** - Physical I/O failed. While reading the index component of the database, the physical I/O failed the read the index
component control interval containing the key for the document.  A system dump is produce for this error.

             Report the problem to the z/OS Storage Administrator.
__________________________________________________________________________________________________________________________________
**0132(X'84)** - Physical I/O failed. While reading the index component of the database, the physical I/O failed the read the index
component's sequence set control intervals.  A system dump is produce for this error.

             Report the problem to the z/OS Storage Administrator.
__________________________________________________________________________________________________________________________________
**0133(X'85)** - Physical I/O failed. While writing to the data component of the database, the physical I/O failed the write for data
component control interval containing the document.  A system dump is produce for this error.

             Report the problem to the z/OS Storage Administrator.
__________________________________________________________________________________________________________________________________
**0134(X'86)** - Physical I/O failed. While writing to the index component of the database, the physical I/O failed the write for the
index component control interval containing the key for the document.  A system dump is produce for this error.

             Report the problem to the z/OS Storage Administrator.
__________________________________________________________________________________________________________________________________
**0135(X'87)** - Physical I/O failed. While writing to the index component of the database, the physical I/O failed the write request to the
index component's sequence set control intervals. A system dump is produce for this error.

             Report the problem to the z/OS Storage Administrator.
__________________________________________________________________________________________________________________________________
**0136(X'88)** - Cache unavailable.  The system's znsq server (SMSVSAM) cannot access the global cache structure for this database.
This error is likely a system configuration issue.

             Report the issue to the z/OS Storage Administrator.
__________________________________________________________________________________________________________________________________
**0137(X'89)** - Cache failure.  The global cache structure for this database failed.  This may be a temporary error.

             The program can try redriving the request. Report the issue to the z/OS Storage Administrator.
__________________________________________________________________________________________________________________________________________
**0282(X'11A)** - Create, add or drop function terminated. An error occurred while creating a database, secondary index, or enabling/disabling
the index.

             Contact the z/OS Storage and provide the output from the znsq_last_result error.	
__________________________________________________________________________________________________________________________________________
**0282(X'11B)** - Create, add or drop function terminated due to z/OS catalog error. An error occurred while creating a database, secondary
index, or enabling/disabling the index.

             Contact the z/OS Storage and provide the output from the znsq_last_result error.			     
__________________________________________________________________________________________________________________________________________
**0295(X'127)** - Storage or data class not found. The znsq_create API could not find a valid storage or data class name, either from the user
parameters on the znsq_create API or implicitly assigned by the server.  A valid storage or optional data class name must be
available to the creation of the database.

             Ensure a valid storage or optional data class name is provided to the znsq_create API, or contact the z/OS Storage 
	     Administrator to configure the system's storage management policy to assign a Record Level Sharing (RLS) storage class and 
	     optional data class for the database.  If necessary, provide the output from the znsq_last_result error.	     
____________________________________________________________________________________________________
**0297(X'129)** - Inconsistent parameters. The znsq_create() or znsq_create_index() failed with 
inconsistent parameters. This error is likely due to creating a database larger than 4 gigabytes and
not specifying an SMS DATACLAS containing the Extended Format and Extended Addressability options.

        If the error is due to a create for a database greater than 4 gigabytes, ensure a SMS 
        DATACLAS is assigned with the Extended Format and Extended Addressability options. If this 
        is not the reason for the inconsistent parameter error, contact the z/OS Storage Administrator
        and provide the output from the znsq_last_result() error.
____________________________________________________________________________________________________
**0298(X'12A)** - Catalog unavailable. The z/OS ICF catalog, associated with the high level qualifier
representing the EzNoSQL database name is not available.

        Report the error to the z/OS Storage Aministrator and provide the output from the 
        znsq_last_result() error.
____________________________________________________________________________________________________

## Return Code 16
____________________________________________________________________________________________________
Return Code 16(X'10)
Reason Code Meaning
____________________________________________________________________________________________________
**0121(X'79')**  The system's znsq server (SMSVSAM) is not available or is a new instance. The 
server has terminated or recycled since the database was open.

        Close the connection and reopen the database after the znsq server is available.
____________________________________________________________________________________________________
**0124(X'7C')**  The system's znsq transactional server (DFSMSTVS) is not available. DFSMSTVS either
did not fully initialize or has been quiesced. Accessing EzNoSQL databases as recoverable, requires 
the availability of DFSMSTVS.

        Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0125(X'7D')**  The system's transactional server (DFSMSTVS) is not installed. DFSMSTVS is not 
specified as enabled in the list of optional product features for z/OS. Accessing EzNoSQL databases 
as recoverable, requires the availability of DFSMSTVS.

        Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________

## Return Code 36
____________________________________________________________________________________________________
Return Code 36(X'24)
Reason Code Meaning
____________________________________________________________________________________________________
**0022(X'16)** - Dynamic Allocation of the database failed. The znsq_open() and znsq_add_index() APIs 
could not allocate the database or alternate index to the user's program.

        Ensure the database or index was successfully created prior to issuing znsq_open() or 
        znsq_add_index().
____________________________________________________________________________________________________
**0023(X'17)** - Connection token could not be obtained. The znsq_open() API could not obtain 
storage for a connection token. This error would most likely be related to a memory shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory 
        shortage is unexpected.
____________________________________________________________________________________________________
**0024(X'18)** - Internal control block could not be obtained. The znsq_open() API could not obtain 
storage for an internal control block. This error would most likely be related to a memory shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0025(X'19)** - Internal control block could not be obtained. The znsq_open() API could not obtain 
storage for an internal control block. This error would most likely be related to a memory shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0032(X'20)** - Internal control block could not be obtained. The znsq_open() or znsq_add_index() 
APIs could not obtain storage for an ACB control block. This error would most likely be related to a
memory shortage.

        Possibly close database to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0033(X'21)** - Internal control block could not be obtained. The znsq_open() or znsq_add_index() 
APIs could not obtain storage for an ACB/Key control block. This error would most likely be related 
to a memory shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0034(X'22)** - Internal control block could not be obtained. The znsq_open() API could not obtain 
storage for an internal control block. This error would most likely be related to a memory shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0035(X'23)** - Internal control block could not be obtained. The znsq API could not obtain storage
for an internal control block. This error would most likely be related to a memory shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0036(X'24)** - Internal error locating a database or its attributes. An internal error attempting 
to locate the database or its attributes failed.

        Report the problem to z/OS support.
____________________________________________________________________________________________________
**0037(X'25)** - Internal control block could not be obtained. The znsq API could not obtain storage
for an internal ACB or RPL control block. This error would most likely be related to a memory 
shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0038(X'26)** - Internal control block pool could not be obtained. The znsq API could not obtain 
storage for a set of internal control blocks. This error would most likely be related to a memory 
shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0039(X'27)** - Internal control block pool could not be obtained. The znsq API could not obtain 
storage for a set of internal control blocks. This error would most likely be related to a memory 
shortage.

        Possibly close databases to free up memory. Report the problem to z/OS support if the memory
        shortage is unexpected.
____________________________________________________________________________________________________
**0040(X'28)** - An internal logic error occurred. The znsq API encountered an internal logic error 
with IBM code.

        The internal logic likely produced a system dump. Report the problem to z/OS support.
____________________________________________________________________________________________________
**0049(X'31)** - An internal logic error occurred. The znsq API encountered an internal logic error 
while freeing storage.

        The internal logic likely produced a system dump. Report the problem to z/OS support.
____________________________________________________________________________________________________
**050(X'32)** - An internal logic error occurred. The znsq API encountered an internal logic error 
while dynamically allocating small internal temporary work files (2 tracks).

        Verify adequate disk space (volumes mounted STRG) is available to the program for allocating 
        the temporary files. If this does not resolve the problem, contact z/OS support.
____________________________________________________________________________________________________
**0145(X'91)** - Open failed for a secondary index. While reading/writing to the database, an open 
failed for a previously added secondary index.

        Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0147(X'93)** - An internal logic error occurred. The znsq_add_index() API encountered an internal 
logic error while dynamically allocating small temporary work files (2 tracks).

        Verify adequate disk space (volumes mounted STRG) is available to the program for allocating
        the temporary files. Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0148(X'94)** - An internal logic error occurred. The znsq_add_index() API encountered an internal 
logic error while dynamically allocating small temporary work files (2 tracks).

        Verify adequate disk space (volumes mounted STRG) is available to the program for allocating 
        the temporary files. Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0149(X'95)** - An internal logic error occurred. The znsq_add_index() API encountered an internal 
logic error while dynamically allocating small temporary work files (2 tracks).

        Verify adequate disk space (volumes mounted STRG) is available to the program for allocating
        the temporary files. Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0152(X'98)** - Memory shortage occurred. The znsq_add_index() API encountered an error obtaining 
24-bit storage for a DCB control block. This error is likely due to a memory shortage below the 
31-bit line.

        Reduce memory requirements for 24-bit storage. Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0153(X'99)** - An internal logic error occurred. The znsq_add_index() API encountered an error 
freeing 24-bit storage for a DCB control block.

        Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0258(X'102)** - An internal logic error occurred. The znsq_add_index() API encountered an internal
logic error while dynamically deallocating temporary work files.

        Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0259(X'103)** - An internal logic error occurred. The znsq_add_index() API encountered an internal
logic error while dynamically deallocating internal temporary work files.

        Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0260(X'104)** - An internal logic error occurred. The znsq_add_index() API encountered an internal
logic error while dynamically deallocating temporary work files.

        Report the issue to the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0273(X'111)-0274(x'112)** - Reserved.
____________________________________________________________________________________________________
**0277(X'115)** - Database not found. The znsq_add_index or the znsq_drop Index could not locate the
base database provided to the API.

        Ensure a valid connection token for the correct data set name was provided to the 
        znsq_add_index() API and znsq_drop_index() API. The znsq_report_stats() API can be used to
        verify the correct base name for this connection token. If the name is correct, contact the
        z/OS Storage Administrator.
____________________________________________________________________________________________________
**0278(X'116)** - Data set not found. The znsq_report_stats() API could not locate the base data set
provided to the API.

        Ensure a valid connection token for the correct data set name was provided to the 
        znsq_report_stats() API. If the name is correct, contact the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0279(X'117)** - Alternate index information not found. The znsq_report_stats() API could not
locate the alternate key information for one of the alternate index previously created with the 
znsq_add_index().

        Ensure a valid connection token for the correct data set name was provided to the 
        znsq_report_stats() API. If the name is correct contact the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0280(X'118)** - Data set information not found. The znsq_report_stats() API could not locate 
information for the base or one of the alternate index previously created with the znsq_add_index().

        Ensure a valid connection token for the correct data set name was provided to the 
        znsq_report_stats() API.
____________________________________________________________________________________________________
**0290(X'122)** - Database in use. The znsq_destroy() API detected the database is still open/allocated.

        Ensure the connection for this database is closed using the znsq_close() API before 
        attempting to destroy the database.
____________________________________________________________________________________________________
**0292(X'124)** - UTF8 conversion failed. The znsq_report_stats() API encountered an error converting 
data set information (such as the data set name) to UTF8. This is likely due to an invalid 
connection token or an internal error.

        Verify a valid connection token was passed to the znsq_report_stats() API. If valid, contact 
        the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0293(X'125)** - Data set information not found. The znsq_report_stats() API could not locate 
information for the base or one of the alternate index previously created with the znsq_add_index().

        Ensure a valid connection token for the correct data set name was provided to the 
        znsq_report_stats() API. If the name is correct, contact the z/OS Storage Administrator.
____________________________________________________________________________________________________
**0294(X'126)** - Data set information not found. The znsq_report_stats() API could not locate 
information for the base or one of the alternate index previously created with the znsq_add_index().

        Ensure a valid connection token for the correct data set name was provided to the 
        znsq_report_stats() API. If the name is correct, contact the z/OS Storage Administrator.
____________________________________________________________________________________________________
**32767(x'7FFF)** - Unknown error. An unknown error resulted in the termination of the API request.  
Likely an abend occurred during the request.

        Report the problem to the Storage Administrator along with any last result API diagnostic information.
