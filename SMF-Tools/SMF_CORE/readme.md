## README 
```
** Beginning of Copyright and License **

Copyright 2024 IBM Corp.                                           
                                                                    
Licensed under the Apache License, Version 2.0 (the "License");    
you may not use this file except in compliance with the License.   
You may obtain a copy of the License at                            
                                                                    
http://www.apache.org/licenses/LICENSE-2.0                         
                                                                   
Unless required by applicable law or agreed to in writing, software 
distributed under the License is distributed on an "AS IS" BASIS,  
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  
See the License for the specific language governing permissions and  
limitations under the License.                    

** End of Copyright and License **        
```

## Overview

This is a Java program intended to read and process z/OS
SMF records.  This project forms the core and defines the
interfaces used as well as some core SMF records and plugins.
Other projects may implement product-specific records
and plugins to help produce reports, etc.  

## Adding Support for SMF Record Types (and subtypes)

To support a specific record type and subtype you must define 
a class in the com.ibm.smf.format.types package called 
`SMFTypeAAASubTypeBBB` where 'AAA' is the record type and 'BBB'
is the subtype.  Only use the number of digits you need, so
for example, the WebSphere SMF 120-9 record is supported by
`SMFType120SubType9.java`.

Your class should extend the `SMFRecord` class.  You should provide
a constructor which takes an `SMFRecord` object as a parameter.  The
base class will have already read from the stream (`SMFRecord.m_stream`) a
byte of flags, a byte of record-type, a four-byte time stamp,
a one-byte century indicator, a one-byte year, and two bytes
of date, plus the four byte SID value.  If the subtype-valid flag
is set, four more bytes of subsystem id and a two-byte subtype
value will be read.  All these are available as attributes of the
base `SMFRecord` type.

You can then continue to read from the stream whatever makes
up the record type being supported.

Implementers typically also override the `dump( )` method.  It is
usually only called if no plugin is provided and
`-DPRINT_DETAILS=true` is set. The base `SMFRecord` implementation
just prints the header, but specific record type implementations
may choose to print out a long-form formatted version of the record.
This can be helpful if you are just looking at one single record and
want to verify you are parsing it properly.

## Writing Plugins

Plugins get control at key points in the processing for each
record found, as well as before and after all processing.

Plugins should implement the `SMFFilter` interface.  

The `initialize` method will get passed any parameters provided
with the filter name (see invocation syntax later on).  By convention
this is just the path and file name where plugin output should go.
You can get that properly initialized by just calling

`smf_printstream = DefaultFilter.commonInitialize(parms)`

The returned SmfPrintStream can be used to direct output to
the output file specified in the parms.  The initialize method
should return `true` if everything went well and it is ok
to continue.

The `preParse` method is a chance for the plugin to skip over
records it isn't interested in.  You can examine the record type
and subtype and return true or false depending on whether you 
want to bother with this record or not.  This can speed things
up by not bothering to parse records that aren't relevant to
whatever the purpose is for this plugin.

Usually there is nothing to do in the `parse` method as all
the parsing is handled by the record implementations.  Just
let the default filter handle it like this:

`return DefaultFilter.commonParse(record)`

The `processRecord` method is where most of the action is.  At
this point, if a class was found to parse it, the record is fully
parsed and available.  You'll need to start by casting the parameter
`SmfRecord` into whatever type implements the record you are interested in.

You can now examine things in the record and accumulate summary data
or log information about the record, possibly in the output printstream.
Pretty much you can do whatever you want at this point.

When we've run out of records to read and process, the `processingComplete` 
method will get control to wrap things up.  You may have nothing to do 
here if you've been writing results as you went, but if you're been accumulating
summary information then all the output from the plugin might come from 
this method.  

One instance of the plugin is created for the entire run, so you can use
object attributes to hold summary data etc. along the way.  

## Core plugins

- **Type98CPU** - Create a CSV from type 98.1 records with the timestamp,
  average percent CP, zAAP, and zIIP used, and largest CPU-consuming address
  space names for CP, zAAP, and zIIP.

## Invoking from the shell

Assuming the .jar files for the core SMF processor plus any needed
.jar files for parsing of required SMF records plus any plugins are already
on the classpath, you can invoke the SMF processing from the shell like this:

`java com.ibm.smf.format.SMF "INFILE(USER.SMFDATA)"`

where your SMF data is in a z/OS dataset called USER.SMFDATA.  This is
SMF data dumped via the IFASMFDP utility.

Without a plugin specified:

* If `-DPRINT_DETAILS=true` is not set (the default), then statistics on record
  types are printed per system; for example:
  ```
  SMF Data for system ABCD covering Mon Dec 11 12:30:00 GMT 2023 to Mon Dec 11 14:29:59 GMT 2023
   Record Type      Records  %Total   Avg Length   Min Length   Max Length
            98        1,440    0.03    28,533.69       27,292       30,204
           120    4,801,374   99.97     1,680.77        1,236        6,116
         Total    4,802,814  100.00     1,688.82        1,236       30,204
  ```
* If `-DPRINT_DETAILS=true` is set, the `dump` method is called on each record as
  it is processed. This will print each record header and raw record which
  is useful for developing plugins.

If you want to use a plugin, you'll need to know the package and class name.
For example, if you want to use my.plugin you would invoke SMF processing like this:

`java com.ibm.smf.format.SMF "INFILE(USER.SMFDATA)" "PLUGIN(my.plugin,/u/my/smf.out)"`

If the plugin uses the parameter string following the name of the plugin as an
output file (usually the case by convention, but not always), then any output
from the plugin will go to /u/my/smf.out based on that invocation.

You can just redirect the output of the command (which goes to STDOUT by default) but
that will include the 'starting' and 'finished' messages that the SMF processor
logs as it starts and finishes.  That might cause you a problem if you are producing
a .csv file or some other format that won't expect these extra lines.

## Invoking from JCL

There is a different interface which allows you to more easily invoke the browser from JCL. You
can do this by exploiting the JZOS launcher. Here’s some sample JCL that could be used:

```
//SMF1 EXEC PROC=JVMPRC86,
// JAVACLS='com.ibm.smf.format.JclSmf'
//*
//* Change to the dataset containing the SMF data
//SMFDATA DD DISP=SHR,DSN=FOLLIS.WSC.SMF.DATA
//*
//* Sets up where .jar files are etc.
//STDENV DD DISP=SHR,DSN=FOLLIS.SMF.JCL(SMFENV)
//*
//* Options to the SMF utility
//SMFENV DD DISP=SHR,DSN=FOLLIS.SMF.JCL(RPS)
```

The SMFDATA DD points to the dataset where the SMF data to be processed resides.
The STDENV DD points to a script which sets up variables required to run the browser. This
includes things like LIBPATH and CLASSPATH. Here’s a sample:

```
#This is a shell script which configures env-vars for the launcher
#Export where the browser and plugin jars live
CLASSPATH=/u/follis/SMF_CORE.jar
CLASSPATH="$CLASSPATH":/u/follis/smf/SMF_WAS.jar
CLASSPATH="$CLASSPATH":/u/follis/smf/SMF_WAS_PLUGINS.jar
export CLASSPATH="$CLASSPATH"

#Export wherever Java lives
export JAVA_HOME=/usr/lpp/java/J8.0_64

# Configure JVM options - Uncomment if you need to change heap size
#IJO="-Xms1024m -Xmx1024m"

#export IBM_JAVA_OPTIONS="$IJO

# Other required exports
export PATH=/bin:"${JAVA_HOME}"/bin
LIBPATH=/lib:/usr/lib:$"${JAVA_HOME}"/bin
LIBPATH="$LIBPATH":"${JAVA_HOME}"/lib/s390
LIBPATH="$LIBPATH":"${JAVA_HOME}"/lib/s390/j9vm
LIBPATH="$LIBPATH":"${JAVA_HOME}"/bin/classic
export LIBPATH="$LIBPATH":
```

Note that if you have other properties you want to specify, you can add those to the IJO environment
variable to be set as IBM_JAVA_OPTIONS. Just specify -Dname=value like you would on the
command line to the JVM.

The SMFENV DD points to input name/value properties to be used by the browser. Recognized
properties include:

**plugin** – specifies the plugin to be used. If the package is com.ibm.smf.was.plugins then you
can leave it out (i.e. just specify RequestsPerServer) and that package will be assumed.
This is to preserve a shortcut from the original implementation.

**output** – the zFS file to use for output

The following keywords are also recognized for consistency with the original WebSphere 
specific implementation

**matchServer** – for 120-9 records, only records from the named server will be processed

**matchSystem** – for 120-9 records, only records from the named z/OS image will be processed

**excludeInternal** – set to true, some reports will ignore 120-9 records for internal requests

**RespRatioMin** - specifies a minimum WLM response ratio in the 120-9 or 120-11 records

Here’s a sample:
```
# Specify the plugin to use
plugin=RequestsPerServer
# Specify where the output goes
# Usually a zFS file (/ecurep/...)
# or a fully qualified datset name for ReWrite
output=/u/follis/jclSMF.txt
# Uncomment (and change the value as appropriate) to filter
matchServer=XDSR01B
```

## Building from the source

A copy of the compiled processor is provided in github as SMF_CORE.jar.  If you want
to build it yourself, you will need the ibmjzos.jar which can be found in z/OS Java
in the lib/ext directory.

