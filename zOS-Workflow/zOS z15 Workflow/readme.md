IBM z/OS z15 Workflow
=====================

## Helping you prepare for the IBM z15 server

Did you know that you can use a z/OSMF workflow to prepare your z/OS system for upgrading to the IBM z15&trade; server?
The IBM z/OS z15 Workflow contains the upgrade steps for the z15, including considerations, restrictions, and actions to
take before and after you order your server, along with a checklist of items that will be discontinued on future servers.

The z/OS V2R4 Upgrade Workflow step *"Upgrade to an IBM z15 server"* contains the same valuable information.
If you only want to see the z15 hardware upgrade actions in its own workflow, this is the one to use.
Otherwise, use the z/OS V2R4 Upgrade Workflow to see both the hardware and z/OS software upgrade actions in a combined workflow.

You can optionally provide feedback to IBM for any of the steps in the workflow.


## What's new

**New version:** IBM z/OS z15 Workflow, Version 2.1 (October 29 2020)
This workflow replaces the previous version, Version 2.0, from April 10 2020.

The following upgrade actions are new:
- Prepare for the removal of the internal battery feature
- Prepare for the removal of support for TLS 1.0 and TLS 1.1 for SE, HMC, and OSC

Other changes:
- Terminology, maintenance, and editorial corrections.


**Previous version:** IBM z/OS z15 Workflow, Version 2.0 (April 10 2020)

The IBM z/OS z15 Workflow is updated with new information for the IBM z15 Model T02, the latest addition to the IBM Z
server family. With the addition of the Model T02, the IBM z15 family of mainframes includes the following hardware models:

     * Model T01 (machine type 8561), with five feature codes to represent the processor capacity. The feature codes
       are Max34, Max71, Max108, Max145, and Max190 with (respectively) 34, 71, 108, 145, and 190. This system is
       configurable as a one-to-four 19-inch frame system.

     * Model T02 (machine type 8562), with five CPC size features (one or two drawers). The system is configurable
       as a 19-inch frame system.  

In the workflow, references to "z15" pertain to all models of the IBM z15, including the z15 T02, unless otherwise noted.


## Important information

Transfer these two files as binary files by using File Transfer Protocol (FTP). Store them together in the same z/OS UNIX directory.

    * z15_zOS_Upgrade_Workflow.xml
    * HC_rexx.txt


## GitHub file transfer tips

To avoid common errors, use this suggested technique to transfer the Workflow files to your system:
Click "View raw" to load the entire XML file into a web browser, then right-click for "Save as..."
to store the file.

Do not skip the "View raw" step; otherwise, you will save the web page (the HTML), instead of the XML file.
If you save the file and the file type is HTML, you did not use the raw view. Using the right mouse button
for "Save as..." from the "View raw" file should allow you to save the contents in the correct format.

Do not "Select All" and "Copy" from the raw file to save the XML file; it will not save correctly.

Be sure to save the workflow XML files in XML (.xml) format. The workflow also includes a text (.txt) file,
which should remain in .txt format.

## Exported workflow link

For a link to the z15 exported workflow, visit the z/OS V2R4 Knowledge Center and open the
[z/OS Upgrade Workflow](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.4.0/com.ibm.zos.v2r4.e0zm100/abstract.htm "z/OS Upgrade Workflow") topic.

Scroll down to the bottom of the abstract page to find the links for exported workflows.  
The exported format is suitable for browsing, printing, and searching.


**Comments welcome**

We welcome any contributions or feedback on anything you find. Keep in mind, there are no warranties for any of the files or contributions that you find here. This is a z/OS community that is sharing with others and it is expected that you review what you are using in your environment. This tool is not supported by the IBM Service organization, but rather by the tool owner on a best-can-do basis.

Report any problems, suggestions, or comments to zosmig@us.ibm.com.
