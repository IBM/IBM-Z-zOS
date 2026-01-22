IBM SMF resources for the z/OS platform
=================================================

This repository contains SMF resources that might be useful to the z/OS community. Here you might find items of interest about new functions in z/OS. 

We welcome your feedback on anything you see here. 

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

Though the materials provided herein are not supported by the IBM Service organization, your comments are welcomed by the developers, who reserve the right to revise or remove the materials at any time. To report a problem, or provide suggestions or comments, contact zosmig@us.ibm.com, or open a GitHub issue.

## Build

1. Install [Apache Maven](https://maven.apache.org/) and make sure `mvn` is on your `PATH`
2. Clone this repository:
   ```
   git clone https://github.com/IBM/IBM-Z-zOS
   ```
3. Change directory to this folder:
   ```
   cd IBM-Z-zOS/SMF-Tools
   ```
4. Compile and package:
   ```
   mvn clean install
   ```
5. Use the executable JAR at `SMF_JAR/target/smftools.jar` on a z/OS system:
   ```
   java -jar smftools.jar ...
   ```
