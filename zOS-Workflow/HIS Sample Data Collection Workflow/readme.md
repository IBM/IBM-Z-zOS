HIS Sample Data Collection Workflow
===================================

IBM Z Systems provide the CPU Measurement Facility (MF), which can be used to capture performance related Counter and Sample based information. 
On z/OS, CPU MF sample data is collected using Hardware Instrumentation Services (HIS), allowing the user to sample instruction addresses with 
very low overhead, providing the information necessary to determine what executable code is consuming the most CPU resources.

This workflow provides the steps to collect CPU MF sample data for problem determination. It also provides some automation
steps to check z/OS configuration related to HIS sample data collection, package the collected data, and upload it to IBM FTP server.

This workflow minimally requires z/OSMF and z/OS V2R1 and is tested on z13 and z14. 

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.
