IBM z/OS V2.2 Migration Workflow
================================

**Introducing another advancement in z/OS migration assistance!**

The z/OS V2R2 Migration book is available as two z/OS Management Facility (z/OSMF) z/OS Migration Workflows. Using the appropriate workflow, you can perform a z/OS V2R2 migration as an interactive, step-by-step process. Depending on your z/OS V2R2 migration path, you select the files that you need and download them to your system to create the workflow.

The workflow XML content is identical to the z/OS Migration book (GA32-0889); the book and the workflows contain the same information. In z/OS V2R2, however, the z/OS V2R2 Migration Workflow further adds the ability to invoke IBM Health Checker for z/OS health checks directly from the applicable steps, and also provides the option for you to send feedback on your migration experience to IBM. When the z/OS Migration book is updated in the future, so too will the corresponding Migration Workflow files be updated to match. When in doubt, you can always check the level of the workflow to determine the corresponding level of the book.

If you would like to see a short demo on using the z/OS V2R1 migration workflow, visit the site  IBM z/OSMF V2.1 Migration Workflow Demo on YouTube.

The z/OS V2R2 Migration Workflow takes advantage of the new z/OSMF Workflow enhancements. Before using this workflow, install APAR PI32163 (PTF UI90022); otherwise, validation errors will occur (message IZUWF0133E) during the workflow creation process. To verify that the APAR is installed, click About in the upper-right corner of the z/OSMF Welcome page.

Current z/OS V2R2 Migration Workflow level: 03 (February 24, 2016), which corresponds to the z/OS V2R2 Migration book (GA32-0889-07). You can easily see which book level your workflow corresponds to by selecting the highest level Step 1 through Step 3 in the workflow. On the General tab in the description of those major tasks, see the following statement: This z/OSMF Workflow was derived from the Migration from z/OS V2R1 and z/OS V1R13 to z/OS V2R2, GA32-0889-07. On the "Migration: Introduction" General tab, see the Summary of Changes, which lists the changes between this workflow and the prior levels of the workflow.

**Migration Workflow Tips**

To be consistent with the book, the workflows include some migration actions shown as "None" for components that do not have any migration action. "None" still counts as a workflow sub-task to “complete,” even though there is no migration action to perform. To complete the sub-task, mark the migration action sub-tasks with an "Override-complete" to have them marked as complete.
The URL links to the documentation in the workflow cannot go to an anchor in the web page. The URLs take you to the web page, not specifically to the content, which might be further down in the page. You might have to scroll down the web page to find the information that you need.

Some migration actions have associated health checks. For those steps, the health check is invoked to determine whether the migration action is applicable for your system. Read the instructions carefully on the Perform tab before running the health check for important information about each check.

For the individual migration actions and for the entire migration effort, you can optionally provide your feedback to IBM. Just follow the instructions that are shown in the workflow. You do not need to provide feedback to complete each step of the workflow.

Currently, you cannot copy an existing workflow into a new or existing workflow. Take this limitation into consideration if you want to upgrade a workflow to a higher level when one is provided. Therefore, you should use the latest level of the workflow for your z/OS V2R2 migration. If subsequent levels of the workflow are released after you start, you can refer to those levels of the z/OS V2R2 Migration book and see (from the Summary of Changes) the migration actions that are not represented in your existing workflow.
 
 If you are migrating from z/OS V2R1 to V2R2, transfer the following three files as binary using File Transfer Protocol (FTP), and store them in the same z/OS UNIX directory:
* zosV2R1_to_V2R2_migration_workflow03.xml  - download this file by clicking on RAW, not the DOWNLOAD button, or you will have create problems in the z/OSMF Workflow.
* migration_feedback_gather_zos_v2r1.txt
* HC_rexx.txt 
 
If you are migrating from z/OS V1R13 to V2R2, transfer the following three files as binary using File Transfer Protocol (FTP), and store them in the same z/OS UNIX directory:
* zosV1R13_to_V2R2_migration_workflow03.xml
* migration_feedback_gather_zos_v1r13.txt 
* HC_rexx.txt 

We welcome any contributions or feedback on anything you find. Keep in mind, there are no warranties for any of the files or contributions that you find here. It is expected that you review what you are using in your environment. This tool is not supported by the IBM Service organization, but rather by the tool owner on a best-can-do basis. Please report any problems, suggestions, or comments to zosmig@us.ibm.com.
