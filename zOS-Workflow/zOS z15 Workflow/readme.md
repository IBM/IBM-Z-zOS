IBM z/OS z15 Workflow
=====================

**Helping you to prepare for the IBM z15 server!**

Did you know that you can use a z/OSMF workflow to prepare your z/OS system for upgrading to the IBM z15&trade; server?  
This workflow contains interactive steps for upgrade considerations, restrictions, and actions to take before you order your server, 
along with a checklist of items that will be discontinued on future servers. 

The z/OS V2R4 Upgrade Workflow step *"Upgrade to an IBM z15 server."* will contain the same valuable information.  If you only want to see the z15 hardware upgrade upgrade actions in its own workflow, this is the one to use.  Otherwise, use the z/OS V2R4
Upgrade Workflow to see both the hardware and z/OS software upgrade actions in a combined workflow.

You can provide feedback to IBM for any of the steps in the workflow, if you wish.

**Exported worfklow link**

You can find a link to z15 exported workflow on z/OS V2.4 Knowledge Center [AT THE BOTTOM OF THIS WEB PAGE](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.4.0/com.ibm.zos.v2r4.e0zm100/abstract.htm).  The exported format is suitable for browsing, printing, and searching.

**What's new**

The IBM z/OS z15 Workflow is updated with new information for the IBM z15 (type 8561). The z15 is the newest addition to the 
IBM Z server family.

In the workflow, references to "z15" pertain to all models of the IBM z15, unless otherwise noted.

**Important information**

Transfer the appropriate two files as binary using File Transfer Protocol (FTP), and store them in the same z/OS UNIX directory:

    * z15_zOS_Upgrade_Workflow.xml
    * HC_rexx.txt

**Common Problem**
Most people that have problems creating the Upgrade Workflow have this as the cause! Github Transfer Tips! Because this Workflow contains large XML files, you must click on "View raw" to load the entire xml file into the browser, and then right mouse click for "Save as..." to store the file. Do not skip the "View raw" step or you will be saving the web page (that is, the HTML) which is unacceptable input to z/OSMF Workflow. If you are saving the file and the file type is HTML, this indicates you did not use the raw view. Using the right mouse button for "Save as..." from the "View raw" file should give you the proper contents of the file saved. Ensure you are saving the large workflow XML files, as XML. (There are two other files which are .txt, and should remain as .txt.) Do not use "Select All", then "Copy" from the raw file to save the xml file as the file will not save correctly.

We welcome any contributions or feedback on anything you find. Keep in mind, there are no warranties for any of the files or contributions that you find here. This is a z/OS community that is sharing with others and it is expected that you review what you are using in your environment. This tool is not supported by the IBM Service organization, but rather by the tool owner on a best-can-do basis.

Please report any problems, suggestions, or comments to zosmig@us.ibm.com.
