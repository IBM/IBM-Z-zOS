IBM z/OS V2.3 Migration Workflow
===============================

Introducing another advancement in z/OS migration assistance!

The z/OS V2R3 Migration book is available as two z/OS Management Facility (z/OSMF) migration workflows. Depending on whether you are migrating from z/OS V2.2 or z/OS V2.1, you select the files that apply to your migration path and download them to your system to create the workflow. 

Using a z/OSMF workflow, you can perform a z/OS V2R3 migration as an interactive, step-by-step process. The workflow XML content is identical to the z/OS Migration book (GA32-0889) --- the book and the workflows contain the same information. The z/OS V2R3 Migration Workflow goes even further by using the latest functions in z/OSMF to provide a smoother migration experience, as follows: 
<ul>
   <li>Adds the ability to skip steps for features of z/OS that you aren't using (with discovery)</li>
   <li>Invokes IBM Health Checker for z/OS health checks directly from the applicable steps</li>
   <li>Provides the option for you to send feedback on your migration experience to IBM.</li>
   </ul>
   
Whenever the z/OS Migration book is updated, the corresponding migration workflow is updated to match. 
When in doubt, you can always check the level of the workflow to determine the corresponding level of the book. 

**What's new**

The z/OS V2.3 Migration Workflow is updated to include the new migration actions that were added in the April 2018 edition of the z/OS Migration book, including changes for the new IBM z14&trade; ZR1 mainframe. To indicate this change:
<ul>
   <li>In the workflow XML file, the workflow version tag is updated to Version 2.1.</li>
   <li>In the z/OS Migration book, the edition notice states <i>Last updated: April 10, 2018</i>.</li>
</ul>

**Already started with an earlier version?**

To upgrade an existing workflow to a new level of the workflow definition, use the action **Create New Based on Existing**, which is provided in the z/OSMF Workflows UI. When you upgrade a workflow, you create a new instance of the workflow, while you retain your data from the existing workflow. This action can help you avoid rework. As one of the upgrade actions, be sure to select **Assign all steps to owner user ID** if you want all of the steps to be assigned to you on completion of the upgrade action. For details, see the online help for the Workflows task in z/OSMF.  

**Want to see a demo?**

If you would like to see a short demo on using the z/OS V2R1 migration workflow, visit the site IBM z/OSMF V2.1 Migration Workflow Demo on [here](
https://mediacenter.ibm.com/media/IBM+zOSMF+V2.1+Migration+Workflow+Demo/1_s1bdgpil).

**Feedback is welcome**

The z/OS V2R3 Migration Workflow takes advantage of the newer z/OSMF Workflow enhancement for Feedback. Before using this workflow,  minimally install these PTFs:

* For z/OSMF V2.1:  PTF UI42016  (APAR PI69103)
* For z/OSMF V2.2:  PTF UI40923  (APAR PI66845)

Otherwise, validation errors will occur (message IZUWF0133E) during the workflow creation process. To see your z/OSMF Workflow level, click About in the upper-right corner of the z/OSMF Welcome page. 

Migration Workflow Tips
-----------------------

To be consistent with the z/OS Migration book, the workflows include some migration actions shown as "None" for components that do not have any migration action. "None" still counts as a workflow sub-task to “complete,” even though there is no migration action to perform. To complete the sub-task, mark the migration action sub-tasks with an "Override-complete" to have them marked as complete. The URL links to the documentation in the workflow cannot go to an anchor in the web page. The URLs take you to the web page, not specifically to the content, which might be further down in the page. You might have to scroll down the web page to find the information that you need. 

Some migration actions have associated health checks. For those steps, the health check is invoked to determine whether the migration action is applicable for your system. Read the instructions carefully on the Perform tab before running the health check for important information about each check. 

For the individual migration actions and for the entire migration effort, you can optionally provide your feedback to IBM. Just follow the instructions that are shown in the workflow. You do not need to provide feedback to complete each step of the workflow. 

*Github Transfer Tips!*  Because this Workflow contains large XML files, you must click on "View raw" to load the entire xml file into the browser, and then right mouse click for "Save as..." to store the file.  Do not skip the "View raw" step or you will be saving the web page (that is, the HTML) which is unacceptable input to z/OSMF Workflow.  If you are saving the file and the file type is HTML, this indicates you did not use the raw view.  Using the right mouse button for "Save as..." from the "View raw" file should give you the proper contents of the file saved.  Do not use "Select All", then "Copy" from the raw file to save the xml file as the file will not save correctly. 

If you are migrating from z/OS V2R2 to V2R3, transfer the appropriate three files as binary using File Transfer Protocol (FTP),
and store them in the same z/OS UNIX directory:

    * zOS Migration from V2.2 to V2.3-Level2.0.xml - download this file by clicking on "View Raw", not the DOWNLOAD button, or you will have create problems in the z/OSMF Workflow.
    * HC_rexx.txt
    * discovery.txt    

If you are migrating from z/OS V2R1 to V2R3, transfer the appropriate three files as binary using File Transfer Protocol (FTP),
and store them in the same z/OS UNIX directory:

    * zOS Migration from V2.1 to V2.3-Level2.0.xml - download this file by clicking on "View Raw" not the DOWNLOAD button, or you will have create problems in the z/OSMF Workflow.
    * HC_rexx.txt
    * discovery.txt

We welcome any contributions or feedback on anything you find. Keep in mind, there are no warranties for any of the files or contributions that you find here. This is a z/OS community that is sharing with others and it is expected that you review what you are using in your environment. This tool is not supported by the IBM Service organization, but rather by the tool owner on a best-can-do basis.

Please report any problems, suggestions, or comments to zosmig@us.ibm.com.
