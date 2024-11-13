## About The Project

zmf_wxa4z is a sample plugin for z/OS Management Facility (z/OSMF). It allows you to easily enable chat interface of IBM watsonx Assistant for Z in z/OSMF.
This IBM watsonx Assistant for Z plugin provides an out-of-box LLM based chat interface in z/OSMF which enables a fingertip assistant for you to work with z/OS from z/OSMF. 

Here is a <a href="https://ibm.box.com/shared/static/kk2gl930r84zyzyf7kok105d4z6wfzid.mov">demo</a> about this plugin.

## Getting Started

### Prerequisites
* Install IBM watsonx Assistant for Z in your on-premises environment.
* z/OS V2R5 or above with z/OSMF enabled.
* For every end user who needs to access this plugin from z/OSMF, please ensure Cloud Pak for Data host that is used by IBM watsonx Assistant for Z can be accessed from your browser. This can be done by opening the URL of Cloud Pak for Data from your browser.

### Installation steps for this plugin
1. Choose a USS directory on z/OS as the installation location for zmf_wxa4z.
2. Download all directories and files from the current directory to your laptop, then transfer them to the installation directory on the z/OS system. Make sure to transfer the 'ui' directory in binary mode and the properties files in text mode.
3. Adjust the permissions of the uploaded directories and files to allow z/OSMF server to load this plugin. Here are the sample commands 
```
cd <the installation path you picked up in step 1>
chmod 644 wxa4z*.properties
chmod -R 755 ui
```
4. Users who need to access this plugin requries proper security permission. Here are the example RACF commands. If your setup uses an external security manager other than RACF, adjust these commands accordingly for your environment:
```
RDEFINE ZMFAPLA IZUDFLT.ZOSMF.IBM_WXA4Z.CHAT UACC(NONE)
PERMIT IZUDFLT.ZOSMF.IBM_WXA4Z.CHAT CLASS(ZMFAPLA) ID(<user id or group id>) ACCESS(READ)
SETROPTS RACLIST(ZMFAPLA) REFRESH
```
5. Open the z/OSMF UI and then open Import Manager plugin (If you don't see Import Manager plugin on z/OSMF Desktop, you can find this plugin from "App Center" icon on the bottom left).
6. Navigate to the Import tab within Import Manager plugin, specify the full path and filename of the property file wxa4z.properties, and proceed by clicking Import. The plugin should now be installed in your z/OSMF. You can find the icon named "watsonx Assistant for Z" on z/OSMF Desktop.

These steps guide you through the process of installing and configuring zmf_wxa4z on your z/OS system for integrating chat interface of IBM watsonx Assistant for Z in z/OSMF. Adjust commands and paths as needed based on your specific environment and security configuration. If you need to upgrade the plugin to a newer version later, simply replace the 'ui' directory with the latest version.

### Settings
To allow the plugin connects to watsonx Assistant for Z, follow these steps. This is typically a one-time setup unless you need to update these settings later.
1. Open your watsonx Assistant for Z instance on IBM Cloud Pak.
2. Navigate to the AI Assistant Builder and select the assistant you want to work with.
3. In the Preview Assistant view, click on 'Customize Web Chat' and open the "Embed" tab.
4. Copy the entire script containing all the necessary settings with a single click.
5. Open this plugin from z/OSMF Desktop, if you have never setup this plugin, a dialog will be popped up and ask for required settings. Now paste the copied script in step 4 in the settings panel and save it. The settings will be securely persisted by z/OSMF and apply for all z/OSMF users.

## Disclamer:
This is an experimental z/OSMF external plugin. It is not intended for production usage.
