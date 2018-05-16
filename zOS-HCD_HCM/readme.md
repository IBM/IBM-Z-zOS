## z/OS Hardware Configuration (HCD and HCM)

### Hardware Configuration Definition (HCD)

Hardware Configuration Definition (HCD) provides an interactive interface that allows you to define the hardware configuration for both a processor's channel subsystem and the operating system running on the processor. The configuration you define with HCD may consist of multiple processors with multiple channel subsystems, each containing multiple partitions. HCD stores the entire configuration data in a central repository, the input/output definition file (IODF). The IODF as single source for all hardware and software definitions for a multi-processor system eliminates the need to maintain several independent MVSCP or IOCP data sets. That means that you enter the information only once using an interactive dialog. 

The official HCD documentation can be found [here](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.3.0/com.ibm.zos.v2r3.cbd/cbd.htm)

This repository contains HCD resources that might be useful to the z/OS community. Here you will find items of interest about new functions in z/OS HCD.

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

Though the materials provided herein are not supported by the IBM Service organization, your comments are welcomed by the developers, who reserve the right to revise or remove the materials at any time. To report a problem, or provide suggestions or comments, contact ibmhcd@de.ibm.com.


### Hardware Configuration Manager (HCM)

The z/OS and z/VM Hardware Configuration Manager (HCM) is a PC based client/server interface to HCD that combines the logical and physical aspects of hardware configuration management. In addition to the logical connections, you can also manage the physical aspects of a configuration. For example, you can effectively manage the flexibility offered by the FICON infrastructure (cabinet, cabling). All updates to your configuration are done via HCM’s intuitive graphical user interface and, most important, due to the client/server relationship with HCD, all changes of the logical I/O configuration are written into the IODF and fully validated and checked for accuracy and completeness by HCD, thus avoiding unplanned system outages due to incorrect definitions. For z/OS only, HCM also allows you to display operational data such as system status information and operate on the switch via an interface to the I/O Operations function of System Automation on the host. 

The official HCM documentation can be found [here](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.3.0/com.ibm.zos.v2r3.e0za100/e0za10044.htm)

This repository contains HCM resources that might be useful to the z/OS community. Here you will find items of interest about new functions in z/OS HCM.

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

Though the materials provided herein are not supported by the IBM Service organization, your comments are welcomed by the developers, who reserve the right to revise or remove the materials at any time. To report a problem, or provide suggestions or comments, contact ibmhcm4z@cn.ibm.com.
