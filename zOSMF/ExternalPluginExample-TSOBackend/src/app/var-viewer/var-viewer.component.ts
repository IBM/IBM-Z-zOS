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
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

import { ZosmfTools } from '../tool/zosmfTools';
import { TsoService } from '../service/tso.service';
import { LogService } from '../service/log.service';
import { PersistService } from '../service/persist.service';

@Component({
  selector: 'app-var-viewer',
  templateUrl: './var-viewer.component.html',
  styleUrls: ['./var-viewer.component.css']
})

/**
 * Component uses TsoService, LogService, PersistService to communicate with z/OSMF.
 * From this component, users could start a long-run REXX in a TSO/E address space and retrieve
 * system variable via the long-run REXX.
 */
export class VarViewerComponent implements OnInit {

  /**
   * variables control which part should be displayed based on the progress of user action
   */
  progress = {
    introduct: {
      show: true,
    },
    createTSO: {
      show: false,
      try: false,
      done: false,
      bad: false
    },
    startApp: {
      show: false,
      try: false,
      done: false,
      bad: false,
      second: false
    },
    getVar: {
      show: false,
      try: false,
      done: false,
      ready: false
    },
    cleanup: {
      show: false,
      try: false,
      done: false
    }
  }

  /**
   * properties for persist used
   */
  proc = "IZUFPROC";
  rexx = "VAREXX";
  mvsvar = "SYSNAME";
  path = "persist";
  preProc: string;
  preRexx: string;
  preMvsvar: string;

  /**
   * save current retrieval's result
   */
  result: string;

  /**
   * default var values for selected
   */
  MVSVARS = [
    // "SYSAPPCLU",
    "SYSDFP",
    "SYSMVS",
    "SYSNAME",
    "SYSOPSYS",
    "SYSSECLAB",
    "SYSSMFID",
    "SYSSMS",
    "SYSCLONE",
    "SYSPLEX",
    "SYMDEF"
  ];

  /**
   * inject services to component.
   * @param _tsoService responsible for creating TSO/E address space, starting application, etc
   * @param _logService logs your messages to server, by default, in IZUGX.log files 
   * @param _persistService persist json data to server end, in .zdf files
   */
  constructor(
    private _tsoService: TsoService,
    private _logService: LogService,
    private _persistService: PersistService) { }

  ngOnInit() {
    // pass a ZosmfTools instance to window, it will be used by z/OSMF desktop when doing cleanup.
    window["zosmfTools"] = new ZosmfTools(this._tsoService);
    // get proc, rexx, var from server via PersistService
    this._persistService.getJson(this.path).subscribe(data => {
      // parse data
      let param = data["value"];
      this._logService.logInfo("init", "persist value: " + JSON.stringify(param));
      // if properties persisted before, then use it
      if (param["proc"]) this.preProc = param["proc"];
      if (param["rexx"]) this.preRexx = param["rexx"];
      if (param["mvsvar"]) this.preMvsvar = param["mvsvar"];
      this.proc = this.preProc;
      this.rexx = this.preRexx;
      this.mvsvar = this.preMvsvar;
    });
  }

  /**
   * Make UI jump to next View after user click start or next button
   */
  next() {
    if (this.progress.introduct.show) {
      this.progress.introduct.show = false;
      this.progress.createTSO.show = true;
    } else if (this.progress.getVar.show) {
      this.progress.getVar.show = false;
      this.progress.cleanup.show = true;
    } else if (this.progress.cleanup.show) {
      this.progress.cleanup.show = false;
      this.progress.introduct.show = true;
      this.progress.createTSO.try = false;
      this.progress.createTSO.done = false;
      this.progress.startApp.try = false;
      this.progress.startApp.done = false;
      this.progress.startApp.second = false;
      this.progress.getVar.try = false;
      this.progress.getVar.done = false;
      this.progress.cleanup.try = false;
      this.progress.cleanup.done = false;
    }
  }

  /**
   * Clear error notification once input get focused
   */
  clearBad() {
    if (this.progress.createTSO.bad) this.progress.createTSO.bad = false;
    if (this.progress.startApp.bad) this.progress.startApp.bad = false;
  }

  /**
   * Start a TSO/E address space with proc which specified by user.
   */
  startTSO() {
    let mname = "startTSO";
    this._logService.logEnter(mname);

    // set progress bar status
    this.progress.createTSO.try = true;

    // (async () => {
    //   await this.delay(5000);
    //   this.progress.createTSO.done = true;
    //   (async () => {
    //     await this.delay(3000);
    //     this.progress.createTSO.show = false;
    //     this.progress.startApp.show = true;
    //   })();
    // })();

    // start a TSO/E address space via TsoService
    this._tsoService.startTSO(this.proc).subscribe(data => {
      // parse response of z/OSMF TSO REST API
      let key = data["servletKey"];
      let qid = data["queueID"];
      this._logService.logInfo(mname, "key: " + key + ", qid: " + qid);

      if (data["msgData"]) { // error happened, suppose this is because the wrong PROC user input
        this.progress.createTSO.bad = true;
        this.progress.createTSO.try = false;
      } else { // suppose TSO/E address space is successfully created
        // set servletKey and queueId to service for next use
        this._tsoService.setServletKey(key);
        this._tsoService.setQueueId(qid);

        // change progress bar status
        this.progress.createTSO.done = true;
        (async () => {
          await this.delay(5000);
          this.progress.createTSO.show = false;
          this.progress.startApp.show = true;
        })();

        // persist proc if user specified one is different with old one
        if (this.proc != this.preProc) {
          let json = { "proc": this.proc };
          this._persistService.putJson(this.path, json).subscribe(data => {

            // update previous proc to current one for next time's comparation
            this.preProc = this.proc;
          });
        }
      }
    });
    this._logService.logExit(mname);
  }

  /**
   * Start a long-run REXX with user specified rexx name
   */
  startApp() {
    let mname = "startApp";
    this._logService.logEnter(mname);

    // set progress bar status
    this.progress.startApp.try = true;

    // (async () => {
    //   await this.delay(5000);
    //   this.progress.startApp.done = true;
    //   (async () => {
    //     await this.delay(3000);
    //     this.progress.startApp.show = false;
    //     this.progress.getVar.show = true;
    //   })();
    // })();


    // start an app via TsoService
    if (!this.progress.startApp.second) { // first time try to start REXX
      this._tsoService.startApp(this.rexx).subscribe(data => {
        this._logService.logInfo("startApp", "res of start app:\n" + JSON.stringify(data));
        if (!this.checkREXXStatusFromRes(data)) this.checkREXXStatus();
      });
    } else { // normal start progress failed, need to start REXX again
      this._tsoService.putTSO(this.rexx).subscribe(data => {
        this._logService.logInfo("startApp", "res of put TSO:\n" + JSON.stringify(data));
        if (!this.checkREXXStatusFromRes(data)) this.checkREXXStatus();
      })
    }

    this._logService.logExit(mname);
  }

  /**
   * Check the response of POST start App or PUT TSO cmd to determin if REXX is successfully started,
   * if it's still no result at the point, then return false.
   * @param res 
   */
  checkREXXStatusFromRes(res): boolean {
    let tsoData = res["tsoData"];
    let str = JSON.stringify(tsoData);

    if (str.indexOf("IKJ565") >= 0) { // member not exist
      this.progress.startApp.bad = true;
      this.progress.startApp.try = false;
      this.progress.startApp.second = true;
      return true;
    } else if (str.indexOf("processing has started") >= 0) { // REXX is started
      // change progress bar status
      this.progress.startApp.done = true;

      // below is only for debug
      (async () => {
        await this.delay(5000);
        this.progress.startApp.show = false;
        this.progress.getVar.show = true;
      })();

      // persist rexx if user specified one is different with old one
      if (this.rexx != this.preRexx) {
        let json = { "rexx": this.rexx };
        this._persistService.putJson(this.path, json).subscribe(data => {

          // update previous rexx name for next time use
          this.preRexx = this.rexx;
        });
      }
      return true;
    } else { // can't determine whether REXX is started or failed
      return false;
    }
  }

  /**
   * recusive method to read TSO messages to determine whether REXX is started.
   */
  checkREXXStatus() {
    this._tsoService.readApp().subscribe(data => {
      let jsonData = JSON.parse(data);
      if (jsonData["timeout"]) { // timeout occurred, suppose REXX is failed to start
        this.progress.startApp.bad = true;
        this.progress.startApp.try = false;
        this.progress.startApp.second = true;
      } else {
        let tsoData = jsonData["tsoData"];
        let res = JSON.stringify(tsoData);
        if (this.checkREXXStatusFromRes(jsonData)) {
          return;
        } else this.checkREXXStatus();
      }
    });
  }

  /**
   * Pass the mvsvar to backend long-run rexx and retrievel the value of mvsvar
   */
  getVar() {

    // clear result status and set progress bar status
    this.result = null;
    this.progress.getVar.try = true;
    this.progress.getVar.done = false;

    // (async () => {
    //   await this.delay(5000);
    //   this.progress.getVar.done = true;
    //   this.progress.getVar.try = false;
    //   if (!this.progress.getVar.ready) this.progress.getVar.ready = true;
    //   this.result = "test";
    // })();

    // put mvsvar name which users want to retrieve, to backend long-run rexx
    this._tsoService.putApp(this.mvsvar).subscribe(putRes => {
      // after backend rexx receive the mvsvar, call rReadApp() to read the result
      this.rReadApp();

      // persist mvsvar name if user specified one is different
      if (this.mvsvar != this.preMvsvar) {
        let json = { "mvsvar": this.mvsvar };
        this._persistService.putJson(this.path, json).subscribe(data => {
          this.preMvsvar = this.mvsvar;
        });
      }
    });
  }

  /**
   * recusive method to read data writen by backend REXX via TsoService
   */
  rReadApp() {
    if (this._tsoService.servletKey) {
      this._tsoService.readApp().subscribe(readRes => {
        // since response of reading app is not a real json, we need to parse it as string.
        let start = readRes.indexOf("appData");
        if (start >= 0) { // "appData" contains in response
          // get the string behind '"appData":'
          let rawValue = readRes.substring(start + 9);
          // cut the data off until the first ','
          let len = rawValue.indexOf(',');
          this._logService.logInfo("readApp", "res: " + readRes + "\nstart: " + start + ", len: " + len);
          this.result = rawValue.substring(0, len);
          this.progress.getVar.done = true;
          this.progress.getVar.try = false;
          this.progress.getVar.ready = true;
        } else this.rReadApp(); // if no "appData" contains in response, then recusivly call itself
      })
    } else {
      this.progress.getVar.try = false;
      this._logService.logInfo("readApp", "tso as is not exist");
    }
  }

  /**
   * delete a TSO/E address space via TsoService
   */
  deleteAS() {
    this.progress.cleanup.try = true;

    // (async () => {
    //   await this.delay(5000);
    //   this.progress.cleanup.done = true;
    // })();

    this._tsoService.deleteTSO().subscribe(data => {
      this._tsoService.servletKey = null;
      this._tsoService.queueId = null;
      this.progress.cleanup.done = true;
    });
  }

  /**
   * debug used
   * @param ms 
   */
  delay(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

}
