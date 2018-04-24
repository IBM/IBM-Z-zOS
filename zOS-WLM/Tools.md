WLM Work Queue Viewing Tools (WLMQUE)
=====================================
WLMQUE, the WLM Work Queue Viewer is a small ISPF based tool that may assist you in displaying the application environments that are currently being used on your z/OS system. This can be helpful for using WebSphere Application Servers when you specify minimum and maximum limits for the number of server address spaces that should be started. You can view the number of started and active server address spaces, and the service classes being used as work queues for the application environments with the help of the REXX command list. The tool can be used for any kind of application environment from WebSphere, DB2 or user specified types and applications.
 
WLMOPT, the WLM OPT parameter viewer assists you in displaying the current OPT settings of your z/OS system. The tool is stabilized on the level of z/OS 1.10. That means no OPT parameters which have been introduced after z/OS 1.10 can be displayed with it. Instead you can use the RMF Monitor II Report "OPT Settings" which is a new selection under "Library Lists". All future OPT parameters will only be made available through the new RMF report.
 
To install the tools download

ftp://public.dhe.ibm.com/eserver/zseries/zos/wlm/wlmque.zip

to your workstation. Note that both tools are contained in this file as well as the CEXEC library that will be created on z/OS. Unzip the file and follow the installation instructions in Readme.txt.
