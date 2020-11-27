IBM z/OS V2.4 Upgrade Workflow
===============================

Introducing the next advancement in z/OS upgrade assistance! The z/OS V2R4 Upgrade Workflow is available as two z/OS Management Facility (z/OSMF) upgrade workflows. Depending on whether you are migrating from z/OS V2.3 or z/OS V2.2, you select the files that apply to your migration path and download them to your system to create the workflow.

Using a z/OSMF workflow, you can perform a z/OS V2.4 upgrade as an interactive, step-by-step process. The workflow XML content follows the format of the previous z/OS Migration book (GA32-0889) and contain the same information. The z/OS V2R4 Upgrade Workflow goes even further by using the latest functions in z/OSMF to provide a smoother migration experience, as follows:

- Adds the ability to skip steps for features of z/OS that you are not using (with discovery)
- Allows you to skip upgrade actions that are "empty," meaning that there is nothing to do for that specific category (with a discovery choice)
- Allow you to skip hardware server upgrade actions for prior levels of hardware server which you are past (with a discovery choice)
- Invokes IBM Health Checker for z/OS health checks directly from the applicable steps
- Provides the option for you to send feedback on your upgrade experience to IBM.

Along with the change of format---a workflow instead of a book---is a change in terminology: *upgrade* instead of *migrate*. In our industry, the process of replacing software with a newer level is most often referred to as *upgrading the software*. In contrast, the phrase *migrating the software* can be taken to mean moving software from one server to another. When you perform the actions that are described in the workflow, you are upgrading z/OS to a newer level of function than the prior release. Thus, *upgrade* is the appropriate term for what these workflows do.

Before you can use the z/OS Upgrade Workflow, ensure that z/OSMF is running on your system and you have access to the workflow. As of z/OS V2.4, IBM no longer provides a z/OS Migration publication. Although z/OSMF is the strongly encouraged method to consume the z/OS V2.4 upgrade materials, IBM provides an exported file of the contents of both the V2.3 and the V2.2 in HTML format for your reference.  

---
## What's new

**New version:** z/OS V2R4 Upgrade Workflow, Version 2.3 (October 29 2020)
This workflow replaces the previous version, Version 2.2, from August 13 2020.

The following upgrade actions are new:
- Prepare for the removal of the internal battery feature
- Prepare for the removal of support for TLS 1.0 and TLS 1.1 for SE, HMC, and OSC
- BCP: The ASCB and WEB are backed in 64-bit real storage by default
- DFSMS: Change DFSMSrmm Web Services to use the HTTPS protocol
- ISPF: Accommodate the ISPF Gateway access change from HTTP to HTTPS
- z/OSMF: Ensure that workflow users are authorized to read workflow files
- z/OSMF: Use the Diagnostic Assistant to collect diagnostic data about z/OSMF
- z/OSMF: Remove STGADMIN SAF authorization requirements for Software Management

The following upgrade actions are changed:
- Verify that virtual storage limits are set properly
- BCP: Accommodate the new DSLIMITNUM default
- CIM: Accommodate the default change from HTTP to HTTPS
- DFSMSrmm: Remove the CIM provider registration and its associated files
- IP Services: Plan to upgrade the FTP server to AT-TLS security
- RMF: Configure AT-TLS to enable secure communication with the RMF distributed data server
- Security Server: Check for duplicate class names

Other changes:
- Terminology, maintenance, and editorial corrections.


**Previous version:** z/OS V2R4 Upgrade Workflow, Version 2.2 (August 13 2020)
This workflow replaces the previous version, Version 2.1, from July 31 2020.

The following upgrade actions are new:
- IP Services: Plan to upgrade the DCAS server to AT-TLS security
- IP Services: Plan to upgrade the FTP server to AT-TLS security
- IP Services: Plan to upgrade the TN3270E server to AT-TLS security
- OpenSSH: Accommodate a new level of OpenSSH
- z/OSMF: Remove references to z/OSMF mobile notification service

The following upgrade actions are changed:
- BCP: XCF/XES FUNCTIONS XTCSIZE is enabled by default
- ICSF: Plan for the removal of sequential data sets from the CSFPARM DD statement
- PKI Services: Ensure that users have CA root certificate for PKI and web pages use HTTPS
- SNA services: Migrate from VTAM Common Management Information Protocol

Other changes:
- Terminology, maintenance, and editorial corrections.


**Previous version:** z/OS V2R4 Upgrade Workflow, Version 2.1 (July 31 2020)
This workflow replaces the previous version, Version 2.0, from September 2019.

The following upgrade actions are new:
- "BCP: Plan for removal of support for the IEWTPORTS transport utility"
- "Security Server: Plan for removal of support for RACF database sharing with z/VM"

Other changes:
- Throughout this workflow, links were corrected or removed to ensure consistent linking.
- Terminology, maintenance, and editorial corrections.


### Changes in earlier versions of this workflow</h2>

The z/OS V2R4 Upgrade Workflow is updated with new information for the IBM z15 Model T02, the latest addition to the IBM Z
server family. With the addition of the Model T02, the IBM z15 family of mainframes includes the following hardware models:

* Model T01 (machine type 8561), with five feature codes to represent the processor capacity. The feature codes
are Max34, Max71, Max108, Max145, and Max190 with (respectively) 34, 71, 108, 145, and 190. This system is
configurable as a one-to-four 19-inch frame system.

* Model T02 (machine type 8562), with five CPC size features (one or two drawers). The system is configurable
as a 19-inch frame system.  

In the workflow, references to "z15" pertain to all models of the IBM z15, including the z15 T02, unless otherwise noted.


### Exported workflows link

You can find links to sample exported workflows in the z/OS V2.4 Knowledge Center [AT THE BOTTOM OF THIS WEB PAGE](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.4.0/com.ibm.zos.v2r4.e0zm100/abstract.htm).  The exported format is suitable for browsing, printing, and searching.

### Want to see a demo?

If you would like to see a short demo on using the z/OS V2R1 migration workflow, visit the site IBM z/OSMF V2.1 Migration Workflow Demo [here](https://mediacenter.ibm.com/media/IBM+zOSMF+V2.1+Migration+Workflow+Demo/1_s1bdgpil).

### Feedback is welcome

The z/OS V2R4 Upgrade Workflow takes advantage of the newer z/OSMF Workflow enhancement for Feedback. Before using this workflow,  minimally install these PTFs:

* For z/OSMF V2.1:  PTF UI42016  (APAR PI69103)
* For z/OSMF V2.2:  PTF UI40923  (APAR PI66845)

Otherwise, validation errors will occur (message IZUWF0133E) during the workflow creation process. To see your z/OSMF Workflow level, click About in the upper-right corner of the z/OSMF Welcome page.

Upgrade Workflow Tips
-----------------------

* You can skip the "empty" tasks, within the first Discovery step. To be consistent with the former z/OS Migration book, the z/OS V2.4 upgrade workflows include some empty upgrade actions shown as "None" for components that do not have any migration action. "None" still counts as a workflow sub-task to “complete,” even though there is no upgrade action to perform. If you do not choose to skip the empty tasks during the Disovery step, to complete the sub-task, mark the upgrade action sub-tasks with an "Override-complete" to have them marked as complete.

* The URL links to the documentation in the workflow cannot go to an anchor in the web page. The URLs take you to the web page, not specifically to the content, which might be further down in the page. You might have to scroll down the web page to find the information that you need.

* Some upgrade actions have associated health checks. For those steps, the health check is invoked to determine whether the upgrade action is applicable for your system. Read the instructions carefully on the Perform tab before running the health check for important information about each check.

* For the individual upgrade actions and for the entire release upgrade effort, you can optionally provide your feedback to IBM. Just follow the instructions that are shown in the workflow. You do not need to provide feedback to complete each step of the workflow, but IBM does welcome any feedback.

* _Most people that have problems creating the Upgrade Workflow have this as the cause!_  *Github Transfer Tips!*  Because this Workflow contains large XML files, you must click on "View raw" to load the entire xml file into the browser, and then right mouse click for "Save as..." to store the file.  Do not skip the "View raw" step or you will be saving the web page (that is, the HTML) which is unacceptable input to z/OSMF Workflow.  If you are saving the file and the file type is HTML, this indicates you did not use the raw view.  Using the right mouse button for "Save as..." from the "View raw" file should give you the proper contents of the file saved.  Ensure you are saving the large workflow XML files, as XML.  (There are two other files which are .txt, and should remain as .txt.) Do not use "Select All", then "Copy" from the raw file to save the xml file as the file will not save correctly.

If you are upgrading from z/OS V2R3 to V2R4, transfer the appropriate three files as binary using File Transfer Protocol (FTP),
and store them in the same z/OS UNIX directory:

    * zOS Upgrade from V2.3 to V2.4-Level2.2.xml - download this file by clicking on "View Raw", not the DOWNLOAD button, or you will have create problems in the z/OSMF Workflow.
    * HC_rexx.txt
    * discovery.txt    

If you are migrating from z/OS V2R2 to V2R4, transfer the appropriate three files as binary using File Transfer Protocol (FTP),
and store them in the same z/OS UNIX directory:

    * zOS Upgrade from V2.2 to V2.4-Level2.2.xml - download this file by clicking on "View Raw" not the DOWNLOAD button, or you will have create problems in the z/OSMF Workflow.
    * HC_rexx.txt
    * discovery.txt


**Comments welcome**

We welcome any contributions or feedback on anything you find. Keep in mind, there are no warranties for any of the files or contributions that you find here. This is a z/OS community that is sharing with others and it is expected that you review what you are using in your environment. This tool is not supported by the IBM Service organization, but rather by the tool owner on a best-can-do basis.

Report any problems, suggestions, or comments to zosmig@us.ibm.com.
