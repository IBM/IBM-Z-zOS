# JES Status Monitoring on SDF

This guide is an add-on to the document [OperatingDoneByExceptions](../OperatingDoneByExceptions.pdf) and describes how to configure your environment to use the sample SDF panel and tree for JES monitoring.

## Sample members

The following sample files are contained in this data set:

* JMHJSMON - REXX-routine to collect JES-data
* JMHPSPL - REXX-routine to purge a job's output
* JMHTALL - DSIPARM-member, SDF-tree replacing INGTALL
* JMHPJES - DSIPARM-member, SDF-panel for JES status

## Copy instructions

Copy the following members into a data set within your NetView DSICLD-library
concatenation:

* JMHJSMON
* JMHPSPL

Copy the following members into a data set within your NetView DSIPARM-library
concatenation:

* JMHTALL
* JMHPJES


## Configuration

The following sections describe the steps necessary to update SDF
on a single system.

### SDF-tree

The following description assumes that your SDF-environment uses the
sample member `AOFTREE` provided by IBM System Automation for z/OS.

  1. Edit member AOFTREE in your NetView DSIPARM-library

  2. Change INGTALL to JMHTALL

  3. Save and exit

  4. Enter the following command on the NetView console to dynamically
     update the SDF-tree:

     ```
     SDFTREE AOFTREE,DISK
     ```

Alternatively, you can also customize the member containing your
system-specific SDF-tree.  In this case, ensure that the following
subtree is defined within that member:

```
  2 JES
    3 JESPOOL
      5 JSPLRANK
      5 JSPOOL
    3 JESELEM
      5 JSJNUM
      5 JSJQE
      5 JSJOE
      5 JSBERT
```

After you have modified your tree, use the command `SDFTREE` on the
NetView console to dynamically update your tree.


## SDF-panel

The following description assumes that your SDF-environment uses the
sample member `AOFPNLS` provided by IBM System Automation for z/OS.

  1. Edit member AOFPNLS in your NetView DSIPARM-library

  2. Add the following line to member AOFPNLS

     ```
     %INCLUDE(JMHPJES)     DYNAMIC
     ```

  3. Save and exit

  In order to invoke the JES status panel from your system overview
  status panel, for example, `INGPMAIN`, enter a status field
  definition similar to the one below to that panel:

  4. Edit, for example, member INGPMAIN in your NetView DSIPARM-library

  5. Add the following lines to the member

     ```
     SF(&SDFROOT..JES,18,55,69,N,,&SDFROOT.JES)
     ST(>JES Status)
     ```

     Note, that the line number (18), the start column (55) and the
     end column (69) are only examples.  You need to adopt these
     coordinates to match the actual location of the status field on
     your status panel.

     The example above furthermore assumes, that your status panel is
     dynamic.  This is the case for System Automation's INGPMAIN.

  6. Save and exit

  7. Enter the following command on the NetView console to dynamically
     update all panels in memory:

     ```
     SDFPANEL AOFPNLS,DISK
     ```

##  Setting up the JES status monitor

The REXX-sample script `JMHJSMON` is intended to periodically collect
JES status information.  Enter the following CHRON timer command to
schedule its execution once every 5 minutes, at the top of the minute.

```
     CHRON AT=XX.XX EVERY=(INTERVAL=(00.05)) ID=JESTMR
       ROUTE=PPT COMMAND=JMHJSMON
```

To stop data collection, purge the timer using the following command:

```
     PURGE TIMER=JESTMR OP=PPT
```

If you want to manage JMHJSMON like any other APL, create a NONMVS
resource in your automation policy and define the CHRON command as
a startup command (see Note 1).  Similarly, use the PURGE command to purge this
timer as a shutdown command.

Another possibility is to setup the CHRON-timer in System Automation's initialization exit `AOFEXINT` which is called once initialization has completed.

Note 1: Unfortunately, it is not possible today to define such a CHRON timer
within the automation policy using entry type TMR.


## Congratulations

Now that you have completed all configuration steps above, have a look
at the JES status.  You can enter SDF and navigate to status overview
of the local system and from there zoom into the JES status.

```
     SDF
```

Please, let us know how you like this example and whether it helps you
to get a deeper understanding about SDF and how to exploit it for even
more than what comes with IBM System Automation for z/OS out of the box.

If you have any comments or suggestions to improve the example or the
product's use of SDF, please let us know.  See also below.

## Disclaimer

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

Though the materials provided herein are not supported by the IBM Service organization, your comments are welcomed by the developers, who reserve the right to revise or remove the materials at any time. To report a problem, or provide feedback, contact holtz@de.ibm.com.
