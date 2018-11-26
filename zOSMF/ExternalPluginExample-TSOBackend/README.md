# ZosmfExternalPlugin

In this exercise, you will learn how to create and deploy your own z/OSMF external plug-in. Included is a sample plug-in (an application), which contains a user interface that is based on the popular Angular framework. The plug-in uses several z/OSMF Representational State Transfer (REST) APIs to perform operations on a z/OS host system.  

## Introduction of sample plug-in

This sample plug-in consists of 3 parts:
* Front-end code  
  The front-end code of this sample plug-in is based on [Angular](https://angular.io/). It is comprised of widgets from [Angular Material](https://material.angular.io/). This README file assumes you have basic knowledge of Angular. 
  The major front-end code of this sample plug-in is component VarViewerComponent.
* A REXX program  
  which runs as the back-end program in z/OS side for this sample plug-in.
* A properties file  
  which is used to describe meta data of the sample plug-in.

Below is the detailed source code structure:
* **/src/app/var-viewer/**            
  This directory contains the component `VarViewerComponent`. This component is used for displaying data, handling user interaction, and calling services for communicating with z/OSMF.  
* **/src/app/service/tso.service.ts**  
  This program uses REST APIs to work with a subordinate TSO/E address space. Specifically, the `TsoService` program creates a TSO/E address space, starts an application in the TSO/E address space, and retrieves messages from the application. It will be injected into VarViewerComponent as an instance at the beginning.
* **/src/app/service/persist.service.ts**  
   This program uses z/OSMF REST APIs to exchange persistent data with the z/OSMF server. 
* **/src/app/service/log.service.ts**  
  This program writes messages to the z/OSMF server log files. 
* **/src/app/tool/zosmfTools.ts**  
  This program overrides the `cleanupBeforeDestroy` method that is normally used by the z/OSMF desktop whenever a user closes the plug-in window.  
* **/dist/zosmf-external-plugin/**        
  This directory contains the binary code for the plug-in UI. It is uploaded to the z/OS UNIX System Services environment when you deploy the plug-in.
* **/rexx/VAREXX**                      
  This REXX program uses looping to continually read input from the message queue. It calls the `MVSVAR` program to retrieve a system variable and write the value back to the message queue. This program is uploaded to z/OS when you deploy the plug-in.
* **/myextapp.properties**       
  This properties file contains settings for the external plug-in, such as the plug-in name and the file path of the binary code. z/OSMF uses these settings to configure the plug-in when you deploy it.        

This sample plug-in (in particular, front-end code) also invokes some services provided by z/OSMF:
* REST TSO/E address space services  
This REST service is used by the sample plug-in to allow front-end code communicate with back end TSO application which is the REXX program in this sample.  
* REST Data persistence services  
This REST service is used by the sample plug-in to read/write persistent data from/in z/OS side.
* Javascript log service  
This service is used by the sample plug-in to write UI log into z/OSMF IZUG*.log file. 
* Javascript clean-up mechanism  
This service is used by the sample plug-in to register clean-up work.

For details about how to invoke z/OSMF REST services from front-end code, refer to source code `/src/app/service/tso.service.ts` and `/src/app/service/persist.service.ts` in this example.  
Note that z/OSMF includes [other useful REST services](https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.3.0/com.ibm.zos.v2r3.izua700/IZUHPINFO_RESTServices.htm), such as the
z/OS jobs REST services and the z/OS data set and file REST services.  
For details about how to invoke z/OSMF Javascript services from front-end code, refer to the programs `/src/app/service/log.service.ts` and `/src/app/tool/zosmfTools.ts` in this example.  
[z/OSMF core JavaScript APIs](https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.3.0/com.ibm.zos.v2r3.izua700/izuprog_CoreAPIs.htm) lists the available javascript APIs.

## Deploy the external plug-in into z/OSMF
### 1. Verify the parameters for starting the TSO/E address space
The sample plug-in uses the following parameters to start a TSO/E address space. Ensure that these settings are suitable for your environment. 
If necessary, you can modify the parameters at _line 20_ in `src/app/service/tso.service.ts`. Alternatively, the parameter `proc` can also be specified in the UI by the plug-in user. 
```javascript
param = {
  proc: "IZUFPROC", // this parameter can also be specified from the UI
  acct: "IZUACCT",
  chset: 697,
  cpage: 1047,
  rows: 204,
  cols: 160,
  rsize: 50000
}
```

### 2. Upload the REXX file to z/OS
Upload `rexx/VAREXX` to z/OS. The name of the PDS that contains the REXX program is hard-coded at _line 39_ of `src/app/service/tso.service.ts`. If you upload the REXX program to another location, you must change the source code, too. Also, if you want to rename the REXX program, you must change _line 40_ of `TsoService`.
```javascript
rexxLib = "ZOSMF.EXTERNAL.REXX"; 
rexx = "VAREXX";
```
Remember to **catalog** the PDS.

### 3. Build the UI and upload it to z/OS
This example uploads the UI binary files to the directory `/dist/zosmf-external-plugin/`. However, if you changed the source code, you might need to build the binary files again. To do so, use the following command. The binary files will reside in the another directory `/dist/ExternalPluginExample-TSOBackend/`.
```shell
ng build --base-href='./'
```
In this example, you must upload the binary files from the source code directory `/dist/zosmf-external-plugin/` or `/dist/ExternalPluginExample-TSOBackend`(if you re-build the project) to the z/OS directory `/usr/lpp/myextapp/dist/`.

### 4. Prepare the properties file
Upload the properties file `/myextapp.properties` to the directory `/usr/lpp/myextapp/`. Included in this file are the following properties: 
```shell
# below properties are for the plug-in
izu.externalapp.local.context.root=myextapp
izu.externalapp.code.root=zosmf-external-plugin
pluginId=MYEXTAPP
# below properties are for the UI task
taskId1=APPTSO
taskSAFResourceName1=ZOSMF.IBM_MYEXTAPP.APPTSO.VARVIEWER
taskNavigationURL1=index.html
```
For more information about the available plug-in properties, see [Adding your applications to z/OSMF](https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.3.0/com.ibm.zos.v2r3.izua700/izuprog_ImportPlugin.htm)

### 5. Authorize users to the task
On a system with RACF as the security manager, you can authorize users by entering the following RACF commands. Note that the RDEFINE command creates a SAF profile with the format `<safPrefix>.<taskSAFResourceName>`. `<safPrefix>` is configured in z/OSMF; by default it is `IZUDFLT`. `<taskSAFResourceName>` is configured in the `myextapp.properties` file in last step of this procedure.
```
RDEFINE ZMFAPLA IZUDFLT.ZOSMF.IBM_MYEXTAPP.APPTSO.VARVIEWER UACC(NONE)
PERMIT IZUDFLT.ZOSMF.IBM_MYEXTAPP.APPTSO.VARVIEWER CLASS(ZMFAPLA) ID(IZUADMIN) ACCESS(CONTROL)
PERMIT IZUDFLT.ZOSMF.IBM_MYEXTAPP.APPTSO.VARVIEWER CLASS(ZMFAPLA) ID(IZUUSER) ACCESS(READ)
SETROPTS RACLIST(ZMFAPLA) REFRESH
```
### 6. Import the plug-in into z/OSMF
Complete your work by importing the plug-in into z/OSMF. 

Do the following:
1. Log into z/OSMF
2. Access the z/OSMF Import Manager task. If you selected the z/OSMF classic view, click the `Import Manager` task in the `z/OSMF Administration` category. Otherwise, if you selected the z/OSMF desktop view, click the `Import Manager` icon on the desktop.
3. In the `Import Manager` task, select the `Import` tab and specify the full file path and name of the property file that you created:  `/usr/lpp/myextapp/myextapp.properties`. 
4. Click `Import`. A message is displayed to indicate whether the plug-in was added.

### Try the plug-in
Find your plug-in in z/OSMF. In the z/OSMF classic view, expand the `Configuration` category and select `VarViewer`. In the z/OSMF desktop view, select the icon `VarViewer` on the desktop.  

Note that the z/OSMF category can be changed in the `myextapp.properties` file. To select a different category, see the link in **Step 4**.


For questions or comments about this external plug-in, contact: caoy@cn.ibm.com, whwuhbj@cn.ibm.com