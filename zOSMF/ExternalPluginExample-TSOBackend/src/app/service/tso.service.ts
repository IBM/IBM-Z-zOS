/* ** Beginning of Copyright and License **                                */
/*                                                                         */
/* Copyright 2018 IBM Corp.                                                */
/*                                                                         */
/* Licensed under the Apache License, Version 2.0 (the "License");         */
/* you may not use this file except in compliance with the License.        */
/* You may obtain a copy of the License at                                 */
/*                                                                         */
/* http://www.apache.org/licenses/LICENSE-2.0                              */
/*                                                                         */
/* Unless required by applicable law or agreed to in writing, software     */
/* distributed under the License is distributed on an "AS IS" BASIS,       */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.*/
/* See the License for the specific language governing permissions and     */
/* limitations under the License.                                          */
/*                                                                         */
/* ** End of Copyright and License **                                      */
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http'
import { Observable } from 'rxjs';

/**
 * A service will be injected into VarViewerComponent to supply ability to communicate with
 * z/OSMF TSO/E address space service, basically it represents one TSO/E address space at one time
 */
@Injectable({
  providedIn: 'root'
})
export class TsoService {

  // url for creating, deleting TSO/E address space
  tsoUrl = "/tsoApp/tso"; 
  
  // url for starting long-run REXX, putting message to REXX, reading messages from REXX
  appUrl = "/tsoApp/app"; 

  // params used when creating TSO/E address space
  param = {
    proc: "IZUFPROC",
    acct: "IZUACCT",
    chset: 697,
    cpage: 1047,
    rows: 204,
    cols: 160,
    rsize: 50000
  }

  servletKey; // a servlet key represents the TSO/E address space
  queueId;    // queue id which needs to be passed to REXX 
  
  // hard coded application name represents the long-run REXX
  appKey = "extapp"; 
  
  // since our REXX is not resident in any lib in PROC, so we need to specify the whole name of the PDS
  // which containg the rexx
  rexxLib = "ZOSMF.EXTERNAL.REXX"; 
  rexx = "VAREXX";


  constructor(private httpClient: HttpClient) { }

  setServletKey(key: String) {
    this.servletKey = key;
  }

  setQueueId(id: String) {
    this.queueId = id;
  }

  /**
   * Send a POST request to start a TSO/E address space. See example:
   * 
   * POST /zosmf/tsoApp/tso?proc=IZUFPROC&acct=IZUACCT&chset=697&cpage=1047&rows=204&cols=160&rsize=50000
   * 
   * 200 OK
   * {
   *   "servletKey": "IBMUSER-71-aabcaaaf",
   *   "ver": "1.0.0",
   *   "tsoData": [...],
   *   "queueId": "16064",
   *   "timeout": false
   * }
   * 
   * 'servletKey' and 'queueId' needs to be stored for further use, this will be done by caller, in this
   * example, VarViewerComponent.startTSO() will do this.
   * @param proc 
   */
  startTSO(proc): Observable<any> {
    if (proc) this.param.proc = proc;
    let url = this.tsoUrl + "?proc=" + this.param.proc + "&acct=" + this.param.acct + "&chset=" + this.param.chset
      + "&cpage=" + this.param.cpage + "&rows=" + this.param.rows + "&cols=" + this.param.cols + "&rsize=" +
      this.param.rsize;
    return this.httpClient.post(url, {});
  }

  /**
   * Send a PUT request to a started TSO/E address space to start a long-run REXX, this will be only invoked after
   * the first time start application failed.
   * 
   * PUT /zosmf/tsoApp/tso/IBMUSER-71-aabcaaaf
   * {"TSO RESPONSE": {"VERSION": "0100", "DATA": "..."}}
   * 
   * 200 OK
   * {
   *   "servletKey": "IBMUSER-71-aabcaaaf",
   *   "ver": "1.0.0",
   *   "tsoData": [...],
   *   "queueId": "16064",
   *   "timeout": false
   * }
   * @param rexx 
   */
  putTSO(rexx): Observable<any> {
    if (rexx) this.rexx = rexx;
    let url = this.tsoUrl + "/" + this.servletKey;
    let cmd = "EXEC '" + this.rexxLib + "("+ this.rexx +")' '4 32772 " + this.queueId + "'";
    let body = {
      "TSO RESPONSE": {
        "VERSION": "0100",
        "DATA": cmd
      }
    }
    return this.httpClient.put(url, JSON.stringify(body));
  }

  /**
   * Send a POST request to start an application in a started TSO/E address space. 
   * This method must be called after startTSO(proc). See example:
   * 
   * POST /zosmf/tsoApp/app/IBMUSER-71-aabcaaaf/extapp
   * {"startcmd": "EXEC 'ZOSMF.EXTERNAL.REXX(VAREXX)' '&1 &2 16064'"}
   * 
   * 200 OK
   * {
   *   "servletKey": "IBMUSER-71-aabcaaaf",
   *   "ver": "1.0.0",
   *   "tsoData": [...],
   *   "queueId": "16064",
   *   "timeout": false
   * }
   */
  startApp(rexx): Observable<any> {
    if (rexx) this.rexx = rexx;
    let url = this.appUrl + "/" + this.servletKey + "/" + this.appKey;
    let startcmd = "EXEC '" + this.rexxLib + "("+ this.rexx +")' '&1 &2 " + this.queueId + "'";
    return this.httpClient.post(url, { "startcmd": startcmd });
  }

  /**
   * Send a PUT request to the started application in the TSO/E address space. See example:
   * 
   * PUT /zosmf/tsoApp/app/IBMUSER-71-aabcaaaf/extapp
   * SYSNAME
   * 
   * 200 OK
   * {
   *   "servletKey": "IBMUSER-71-aabcaaaf",
   *   "ver": "1.0.0",
   *   "tsoData": [...],
   *   "queueId": "16064",
   *   "timeout": false
   * }
   * 
   * @param mvsvar payload which will be sent to backedn long-run REXX
   */
  putApp(mvsvar: String): Observable<any> {
    let url = this.appUrl + "/" + this.servletKey + "/" + this.appKey;
    return this.httpClient.put(url, mvsvar);
  }

  /**
   * Send a GET to read data which is written by backend REXX. Here is an example:
   * 
   * GET /zosmf/tsoApp/app/IBMUSER-71-aabcaaaf/extapp
   * 
   * 200 OK
   * {
   *   "servletKey": "IBMUSER-71-aabcaaaf",
   *   "ver": "1.0.0",
   *   "appData": SY1,
   *   "queueId": "16064",
   *   "timeout": false
   * }
   * 
   * Noticed that, the response is not a real JSON, binary data is contained after "appData", 
   * in this example, the data is ASCII encoded. 
   */
  readApp(): Observable<any> {
    let url = this.appUrl + "/" + this.servletKey + "/" + this.appKey;
    // add '{responseType: "text"}' to parse the response to String instead of object
    return this.httpClient.get(url,{responseType: 'text'});
  }

  /**
   * Send a DELETE request to delete the TSO/E address space
   */
  deleteTSO(): Observable<any> {
    if (this.servletKey) {
      let url = this.tsoUrl + "/" + this.servletKey;
      return  this.httpClient.delete(url);
    }
  }
}
