[TOC]
# ExternalPluginExample-RemoteServer
In this example, you will see how to create and deploy your own z/OSMF external plug-in, furthermore, it also shows how the plug-in communicates with a remote server.

## Introduction
This sample plug-in consists of 4 parts:
* Front-end program  
  which is based on [Angular](https://angular.io/). This README file assumes you have basic knowledge of Angular. Component `JobSearcherComponent` is the major part of the front-end code.
* A properties file
  which is used to describe meta data of the sample plug-in. It will be used when importing the sample plug-in into z/OSMF.
* A server 
  Actually, this is a sample server space which you can directly deploy it to a `WebSphere Liberty` server.
* certificate file 
  which is used by the sample server, and it also needs to be imported into z/OSMF keyring to support HTTPS connection between z/OSMF and the sample server.

###  Files
|Files or Directory|Purpose|
|------------------|-------|
|./src/app/job-searcher/                  |This directory contains Angular component `JobSearcherComponent`. This component is used for displaying data of jobs, handling user interaction and calling services for communicating with z/OSMF|
|./src/app/service/job.service.ts         |This Angular service uses z/OSMF jobs REST interface to get information about jobs running on z/OS. It will be injected into JobSearcherComponent as an instance at the beginning|
|./src/app/service/app-route.service.ts   |This Angular service uses z/OSMF Application server routing service to communicate with the sample remote server via z/OSMF|
|./dist/ExternalPluginExample-RemoteServer|This directory contains the binary code for the sample plug-in. It needs to be uploaded to the z/OS UNIX environment when you deploy the plug-in|
|./myplugin.properties                    |This properties file contains settings for the external plug-in, such as the plug-in name and the file path of the binary code. z/OSMF uses these settings to configure the plug-in|
|./mypluginServer/                        |This directory is a server space containing binary web application files and server configurations. It can be directly deployed into a Websphere Liberty server|
|./myserver.cer                           |This self-signed certificate file is used for the sample server to support HTTPS|

## Deploy the sample external plug-in into z/OSMF
1. upload binary UI files to z/OS UNIX environment
    * create a directory on z/OS to put the sample plug-in related files. In this example, let's say the directory is `/usr/lpp/zosmfPlugin`.
    * upload binary UI files under directory `./dist/ExternalPluginExample-RemoteServer/` to a sub-directory under `/usr/lpp/zosmfPlugin/`. In this example, let's say the directory is `content`. So the files should be uploaded to `/usr/lpp/zosmfPlugin/content/`.
2. prepare myplugin.properties file
    go through `./myplugin.properties` file. Then upload the file to `/usr/lpp/zosmfPlugin/`.
    ```
    importType=plugin

    izu.externalapp.file.version=1.0.0
    izu.externalapp.local.context.root=myplugin
    
    # the relative path of code firectory
    izu.externalapp.code.root=content

    pluginId=MYPLUGIN
    pluginDefaultName=MyPlugin
    pluginDescription=myPlugin
    aboutPanelPath=/usr/lpp/zosmfPlugin/content/about.txt

    taskId1=MYTASK
    taskVersion1=1.0
    taskCategoryId1=13
    taskDispName1=MyTask
    taskDispDesc1=list jobs and store to remote server

    # the RACF profile suffix of class ZMFAPLA
    taskSAFResourceName1=ZOSMF.MYPLUGIN.MYTASK
    taskNavigationURL1=index.html
    taskBundleUrl1=/usr/lpp/zosmfPlugin/content/nls/
    taskBundleFileName1=bundle.js
    taskMinZOS1=04.25.00
    taskMinZOSMF1=04.25.00
    ```
3. authorize users to the task(the sample plug-in)
    creates a SAF profile with the format `<safPrefix>.<taskSAFResourceName>`. `<safPrefix>` is configured in z/OSMF; by default it is IZUDFLT. `<taskSAFResourceName>` is set in the `myplugin.properties` file.
    ```
    RDEFINE ZMFAPLA IZUDFLT.ZOSMF.MYPLUGIN.MYTASK UACC(NONE)
    PERMIT IZUDFLT.ZOSMF.MYPLUGIN.MYTASK CLASS(ZMFAPLA) ID(IZUADMIN) ACCESS(CONTROL)
    PERMIT IZUDFLT.ZOSMF.MYPLUGIN.MYTASK CLASS(ZMFAPLA) ID(IZUUSER) ACCESS(READ)
    SETROPTS RACLIST(ZMFAPLA) REFRESH
    ```
4. import the plug-in into z/OSMF
    * Log into z/OSMF with a user who is connected to `IZUADMIN` group
    * Access the z/OSMF Import Manager task. If you selected the z/OSMF classic view, click the `Import Manager` task in the `z/OSMF Administration` category. Otherwise, if you selected the z/OSMF desktop view, click the `Import Manager` icon on the desktop.
    * In the `Import Manager` task, select the `Import` tab and specify the full file path and name of the properties file: `/usr/lpp/zosmfPlugin/myplugin.properties`
    * Click `Import`. A message is displayed to indicate whether the plug-in was added.
5. Open the plug-in  
    Find your plug-in in z/OSMF. In the z/OSMF classic view, expand the `Jobs and Resources` category and select `MyTask`. In the z/OSMF desktop view, select the icon `MyTask` on the desktop.  
    Note that the z/OSMF category can be changed in the `myplugin.properties` file. To select a different category, change the value of `taskCategoryId1` property.

### A glance of MyTask UI
There are 2 functions MyTask UI supplied.
1. Invoking z/OSMF jobs REST interface to retrieve the data of jobs running on z/OS based on parameters `Prefix` and `Owned By` which could be specified by users. After opening MyTask UI, a GET request is sent with default parameters to retrieve the jobs owned by current users.
2. Invoking z/OSMF application routing service to send/retrieve JSON data to/from the remote sample server. By clicking the menu item `save to remote server` or `retrieve from remote server`, the value of parameters `Prefix` and `Owned By` will be sent/retrieved.
    > NOTE: Since the sample server is still not deployed, so the save/retrieve to/from remote server function is not available for now. And also since the UI code is deployed into z/OSMF, so it can not directly communicate with the sample server because the browser will block cross-site request. z/OSMF application routing service is needed to bypass the problem.

### Use the z/OSMF core JavaScript APIs
[The z/OSMF core JavaScript APIs](https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.3.0/com.ibm.zos.v2r3.izua700/izuprog_CoreAPIs.htm) are supplied as modules by AMD way because it's developed by DOJO. But this external plugin example is developed based on Angular which is not compatible. So we need to manually change the built index.html file to let it load dojo resource firstly, then the zosmfExternalTools module could be loaded by DOJO. You can reference `./index.html.template` for how to load `zosmfExternalTools`, and reference `./src/app/app.component.ts` for how to use `zosmfExternalTools`.  
And when you try to use the zosmfExternalTools in Angular, you need to declare it first to tell the compiler that it's already defined like below: 
```javascript 
declare var zosmfExternalTools: any;
```

## Deploy sample server and configure z/OSMF
> Websphere Liberty Server is required to follow this README to deploy the sample server. If you want to use other servers, you can directly use the standard web application archive file `./mypluginServer/MypluginService.war`. Another requirement is that your local machine should have a hostname assigned and it can be pinged from z/OS environment.
To deploy the sample server into a Websphere Liberty Server:
1. copy directory `./mypluginServer` to your local Liberty servers directory `$LIBERTY_HOME/usr/servers`. `$LIBERTY_HOME` is the installation directory of your Liberty.
2. run below command to start the sample server  
    `$LIBERTY_HOME/bin/server start mypluginServer` or
    `$LIBERTY_HOME/bin/server.bat start mypluginServer`
3. after the server started, you can open a browser to visit https://localhost:9080/MypluginService/profile or https://host:9080/MypluginService/profile to verify. 

### Interface of sample remote server
One RESTful interface would be supplied by the server to retrieve/save JSON data, below are examples:
#### retrieve json data.
* request:
    ```
    GET https://host:9080/MypluginService/profile
    ```
* response:  
    ```
    Status 200 OK
    {
        "prefix": NULL,
        "owner": NULL
    }
    ```
#### save json data to server
* request:
    ```
    PUT https://host:9080/MypluginService/profile
    {
        "prefix": "IZU",
        "owner": "IBMUSER"
    }
    ```
* response:
    ```
    Status 200 OK
    ```
### z/OSMF application routing service
As mentioned before, the sample plug-in needs to communicate with the sample server via [Application server routing services](https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.3.0/com.ibm.zos.v2r3.izua700/izuprog_API_AppServerRoutingServices.htm) because the cross site requests would be blocked. You can reference `./src/app/service/app-route.service.ts` for details of how to use. Below are examples of application server routing services.
> NOTE: z/OSMF application server routing service is still not available because lack of some configuration which we will complete later. 
#### Retrieve data from an application server
* request:
    ```
    GET https://host:9443/zosmf/externalgateway/system?content={"target":"mySys","resourcePath":"/profile","wrapped":"N"}
    ```
* response:
    ```
    Status 200 OK
    {
        "prefix": "I*",
        "owner": "IZUSVR"
    }
    ```
#### Update data for an application server
* request:
    ```
    PUT https://host:9443/zosmf/externalgateway/system
    {
        "target": "mySys",
        "resourcePath": "/profile",
        "content": {
            "prefix": "I*",
            "owner": "IZUSVR"
        }
    }
    ```
* response:
    ```
    Status 200 OK
    {...}
    ```
#### paramter meaning
* `target`  
    Nickname assigned to the system entry in the z/OSMF Systems task
* `resourcePath`
    Path to the service that will process the request.
* `wrapped`
    Whether wrap the result of the target application server in a JSON object. `N` in current example

### Associate the sample plug-in with the sample remote server
1. create System Entry in `Systems` task.
    * open `Systems` task under `z/OSMF Settings` category.
    * click `Actions` and choose `Add` -> `System...`, click `Next`.
    * **since mySys is hardcoded in the front-end code**, so you need to Enter `mySys` as `System name` and `System nickname`, then enter whatever you want as `Sysplex name`, click `Next`.
    * this step is a little tricky. Although z/OSMF is not running on your own remote system, we need to choose the option `z/OSMF is running on the system` to specify a URL. enter the URL of the sample remote server, for example, `https://host:9443/MypluginService/`, click `Next`.
    * click `Next`.
    * click `Next`.
    * click `Finish`.
2. associate the imported plugin to the System Entry you defined.
    * open `Import Manager` task under `z/OSMF Administration` category.
    * click `Imported Plug-ins` tab of the task.
    * click `Actions` and choose `Associate Server` button.
    * choose the System Entry `mySys` you just defined, and associate it with `MyTask` task you just imported.
> NOTE: After associate the sample plug-in with the sample remote server. z/OSMF application server routing service could find the URL of the remote system, but z/OSMF still can not set up HTTPS connection to the remote system because the certificate of remote server can't be trusted.

### Import Certificate Auth to z/OSMF Keyring
1. export the Certificate Auth of sample remote server from browser, or you can directly find it here: `./myserver.cer`. It's in `DER` format.
2. import the Certificate Auth to z/OSMF Keyring:
   * ftp the certificate to a z/OS UNIX directory, let's say the directory is `/tmp/cert/`, and copy it to data set  
    `cp -B /tmp/cert/myserver.cer "//'MYPLUGIN.SERVER.CERT'"`      
   * add certificate to RACF  
    `RACDCERT CERTAUTH ADD ('MYPLUGIN.SERVER.CERT') WITHLABEL('mypluginCA') TRUST`
   * connect the cert to the keyring  
    `RACDCERT ID(IZUSVR) CONNECT (CERTAUTH LABEL('mypluginCA') RING(IZUKeyring.IZUDFLT))`

### Try the plug-in
Now, after all these configurations, the imported task should be able to run. You can retrieve data of jobs from z/OS and save the parameters to the sample remote server.

For questions or comments about this example external plug-in, contact: caoy@cn.ibm.com.

