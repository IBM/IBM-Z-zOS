# Sample code of z/OSMF RESTful APIs

This repository contains sample code of z/OS Management Facility (z/OSMF) RESTful APIs that can be used to communicate with z/OS to work with z/OS Jobs, files and Data sets.

> There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

## Java client example
This example contains 2 java files:
* RestConnection.java  
  Utils for preparing connections with z/OSMF server.
* RestFileClient.java
  Sample code of invoking z/OS data set and file REST interface.

## Html example
This example contains 1 html file:
* rest-jobs.html  
  Sample javascript code of invoking z/OS jobs REST interface. To run this html, you can either optn it by Internet Explorer, or deploy it to a server, such as Liberty.
### Directly run html from browser
> If you want to directly run the html, please use Internet Explorer  

This example will send a **Cross-Site Request** to the default z/OSMF server by using javascript. And most browsers, such as Chrome, Firefox will block this Cross-Site Request due to their more strict CSRF/CORS settings compared with Internet Explorer.  
### Depoly html to a server
> If you want to use other browsers to run this html, you need to depoly it to a server

After depoly `rest-jobs.html` to a server, you also need to add the origin of your website to z/OSMF CSRF white list. For details, please reference [Establish security for cross-site z/OSMF REST requests](https://www.ibm.com/support/knowledgecenter/en/SSLTBW_2.3.0/com.ibm.zos.v2r3.e0zm100/IZU_V2R3_CSRF-Header.htm)

## Python example
This example contains 1 Python file:
* create_dataset_members.py
  Sample Python code that uses the z/OS data set REST interface to create three data set members.
