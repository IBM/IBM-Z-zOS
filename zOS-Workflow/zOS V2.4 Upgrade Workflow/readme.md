IBM z/OS V2.4 Migration Workflow
===============================

Introducing another advancement in z/OS upgrade  assistance!  (Be aware "upgrade" is the new term for "migration", as of z/OS V2.4.)

The z/OS V2R4 Upgrade Workflow is available as two z/OS Management Facility (z/OSMF) upgrade workflows. Depending on whether you are migrating from z/OS V2.3 or z/OS V2.2, you select the files that apply to your migration path and download them to your system to create the workflow. 

Using a z/OSMF workflow, you can perform a z/OS V2R4 upgrade as an interactive, step-by-step process. The workflow XML content follows exactly the format of the prior z/OS Migration book (GA32-0889) --- the workflows contain the same type of information. The z/OS V2R4 Upgrade Workflow goes even further by using the latest functions in z/OSMF to provide a smoother migration experience, as follows: 
<ul>
   <li>Adds the ability to skip steps for features of z/OS that you aren't using (with discovery)</li>
   <li>Allows you to skip upgrade actions which are "empty", meaning that there is nothing to do for that specific category (with a discovery choice).
   <li>Allow you to skip hardware server upgrade actions for prior levels of hardware server which you are past (with a discovery choice).
   <li>Invokes IBM Health Checker for z/OS health checks directly from the applicable steps</li>
   <li>Provides the option for you to send feedback on your upgrade experience to IBM.</li>
   </ul>
 
In order to use the z/OSMF Upgrade Workflow, you will need z/OSMF up and running, and Workflow access.  The "z/OS Migration" book is not
available for z/OS V2.4.  Although z/OSMF is the strongly encouraged method to consume the z/OS V2.4 upgrade materials, we have provided
an exported file of the contents of both the V2.3 and the V2.2 in HTML format.  

**Exported workflows link**

You can find links to those exported formats on z/OS V2.4 Knowledge Center [AT THE BOTTOM OF THIS WEB PAGE](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.4.0/com.ibm.zos.v2r4.e0zm100/abstract.htm).  The exported format is suitable for browsing, printing, and searching.

**Want to see a demo?**

If you would like to see a short demo on using the z/OS V2R1 migration workflow, visit the site IBM z/OSMF V2.1 Migration Workflow Demo on [YouTube](https://www.youtube.com/watch?v=ejQRSYaxz9M).

**Feedback is welcome**

The z/OS V2R4 Upgrade Workflow takes advantage of the newer z/OSMF Workflow enhancement for Feedback. Before using this workflow,  minimally install these PTFs:

* For z/OSMF V2.1:  PTF UI42016  (APAR PI69103)
* For z/OSMF V2.2:  PTF UI40923  (APAR PI66845)

Otherwise, validation errors will occur (message IZUWF0133E) during the workflow creation process. To see your z/OSMF Workflow level, click About in the upper-right corner of the z/OSMF Welcome page. 

Upgrade Workflow Tips
-----------------------

* You can skip the "empty" tasks, within the first Discovery step!  To be consistent with the former z/OS Migration book, the z/OS V2.4 upgrade workflows include some empty upgrade actions shown as "None" for components that do not have any migration action. "None" still counts as a workflow sub-task to “complete,” even though there is no upgrade action to perform. If you do not choose to skip the empty tasks during the Disovery step, to complete the sub-task, mark the upgrade action sub-tasks with an "Override-complete" to have them marked as complete. 

* The URL links to the documentation in the workflow cannot go to an anchor in the web page. The URLs take you to the web page, not specifically to the content, which might be further down in the page. You might have to scroll down the web page to find the information that you need. 

* Some upgrade actions have associated health checks. For those steps, the health check is invoked to determine whether the upgrade action is applicable for your system. Read the instructions carefully on the Perform tab before running the health check for important information about each check. 

* For the individual upgrade actions and for the entire release upgrade effort, you can optionally provide your feedback to IBM. Just follow the instructions that are shown in the workflow. You do not need to provide feedback to complete each step of the workflow, but IBM does welcome any feedback.

* _Most people that have problems creating the Upgrade Workflow have this as the cause!_  *Github Transfer Tips!*  Because this Workflow contains large XML files, you must click on "View raw" to load the entire xml file into the browser, and then right mouse click for "Save as..." to store the file.  Do not skip the "View raw" step or you will be saving the web page (that is, the HTML) which is unacceptable input to z/OSMF Workflow.  If you are saving the file and the file type is HTML, this indicates you did not use the raw view.  Using the right mouse button for "Save as..." from the "View raw" file should give you the proper contents of the file saved.  Ensure you are saving the large workflow XML files, as XML.  (There are two other files which are .txt, and should remain as .txt.) Do not use "Select All", then "Copy" from the raw file to save the xml file as the file will not save correctly. 

If you are upgrading from z/OS V2R3 to V2R4, transfer the appropriate three files as binary using File Transfer Protocol (FTP),
and store them in the same z/OS UNIX directory:

    * zOS Upgrade from V2.3 to V2.4-Level2.1.xml - download this file by clicking on "View Raw", not the DOWNLOAD button, or you will have create problems in the z/OSMF Workflow.
    * HC_rexx.txt
    * discovery.txt    

If you are migrating from z/OS V2R2 to V2R4, transfer the appropriate three files as binary using File Transfer Protocol (FTP),
and store them in the same z/OS UNIX directory:

    * zOS Upgrade from V2.2 to V2.4-Level2.1.xml - download this file by clicking on "View Raw" not the DOWNLOAD button, or you will have create problems in the z/OSMF Workflow.
    * HC_rexx.txt
    * discovery.txt

We welcome any contributions or feedback on anything you find. Keep in mind, there are no warranties for any of the files or contributions that you find here. This is a z/OS community that is sharing with others and it is expected that you review what you are using in your environment. This tool is not supported by the IBM Service organization, but rather by the tool owner on a best-can-do basis.

Please report any problems, suggestions, or comments to zosmig@us.ibm.com .
