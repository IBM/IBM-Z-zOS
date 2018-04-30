WLM Work Queue Viewing Tools (WLMQUE)
=====================================
WLMQUE, the WLM Work Queue Viewer is a small ISPF based tool that may assist you in displaying the application environments that are currently being used on your z/OS system. This can be helpful for using WebSphere Application Servers when you specify minimum and maximum limits for the number of server address spaces that should be started. You can view the number of started and active server address spaces, and the service classes being used as work queues for the application environments with the help of the REXX command list. The tool can be used for any kind of application environment from WebSphere, DB2 or user specified types and applications.
 
WLMOPT, the WLM OPT parameter viewer assists you in displaying the current OPT settings of your z/OS system. The tool is stabilized on the level of z/OS 1.10. That means no OPT parameters which have been introduced after z/OS 1.10 can be displayed with it. Instead you can use the RMF Monitor II Report "OPT Settings" which is a new selection under "Library Lists". All future OPT parameters will only be made available through the new RMF report.
 
To install the tools download [wlmqueue.zip](https://ibm.biz/BdZgnS) to your workstation. Note that both tools are contained in this file as well as the CEXEC library that will be created on z/OS. Unzip the file and follow the installation instructions in Readme.txt.

LPAR Design Tool
================
The LPAR Design tool assists you in planning the LPAR layout of your Central Processor Complexes. The tool allows you to specify all partitions, the number of logical processors and their weights. If you run your system in Hiperdispatch mode it also assist you in displaying the number of high, medium and low processors as a result of your definition. This will help you to easily identify definition errors. In addition offload processors like zIIPs and zAAPs are also supported. You can upload or download the results from / to a zPCR study. To install the tool, download the [LPAR Design Tool](https://ibm.biz/BdZgee) and unzip it to your workstation. The package consists of the tool (a Microsoft Excel spreadsheet) and the associated user's guide in the PDF format.
 
WLM Topology Report
===================
The topology report displays the logical processor topology for systems running in Hiperdispatch mode. The Excel report on your workstation uses an input file (comma separated value) which must be first created on a z/OS system from SMF 99 subtype 14 records. The tool supports all System z environments from z10 to z13 for partitions running in Hiperdispatch mode. It displays the association of logical processors to books, chips, drawers, and nodes, the polarization of the processors (high, medium, low), the processor type (regular CP, zIIP, or zAAP), and the association to WLM nodes. The tool can be used to understand the processor placement and how it changes when topology changes occur.
 
In order to run the tool it is required to install the exe file from this webpage and afterwards two z/OS datasets on your local z/OS system. The install file creates two entries: "TopoReport.lnk" and "Topo Report Help.lnk" in the Windows program folder "IBM RMF Performance Management". Please select the "Topo Report Help" link and follow the instructions in topic "Processing SMF 99 data" to install and execute the z/OS datasets and programs. The other topics in the help file describe the usage of the Excel spreadsheet to display the information on your workstation.
 
Requirements:
* A z10 or newer System z environment with partitions running in Hiperdispatch mode
* Collecting SMF 99 subtype 14 records
* Excel Version 2013. The spreadsheet should also work on Excel 2007 and 2010


Download: [SetupTopologyReport.V1201.exe](https://ibm.biz/BdZgeb)
 
SMF113 Reporting Tool
=====================
SMF 113 records provide insight into the usage of hardware cache structures of your partitions. This reporting tool provides a set of REXX programs which assist you in printing SMF 113 subtype 2 records and they also provide a a basic summary of the Cache activity in form of a CSV report. For collecting SMF 113 data (CPU Measurement Facility or Hardware Instrumentation Counters) please refer to  CPU MF Overview and WSC Experiences
 
In order to run the tool it is required to install the exe file from this webpage and afterwards three z/OS datasets on your local z/OS system. The install file creates two entries: "HISandCSVReport.lnk" and "HIS and CSV Reporting Help.lnk" in the Windows program folder "IBM RMF Performance Management". Please select the "HIS and CSV Reporting Help" link and follow the instructions in topic "Installing Host files" to install and "Process SMF 113 data" execute the z/OS datasets and programs. The other topics in the help file describe the usage of the Excel spreadsheet to display the information on your workstation.
 
Requirements:
* Collecting SMF 113 subtype 2 records on a z10 or newer z system.
* Excel Version 2013. The spreadsheet should also work on Excel 2007, 2010, and 2016

Download: [SetupGenReport.exe](https://ibm.biz/BdZgeh)
