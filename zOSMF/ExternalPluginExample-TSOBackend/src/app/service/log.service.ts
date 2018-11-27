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

/**
 * A service which will be injected into VarViewerComponent, and supply ability to log messages
 * to server. Normally, the messages will be stored in IZUGx.log
 */
@Injectable({
  providedIn: 'root'
})
export class LogService {

  logPrefix = "EXTERNAL--";

  constructor() { }

  logEnter(mname) {
    /**
     * parent will point to z/OSMF desktop window, and there is already a instance called "LOGGER"
     * which alreay initialized in z/OSMF desktop(Desktop.jsp), in this example, we'll use the
     * instance to finish the log work
     */
    if (parent['LOGGER']) {
      console.log("call logger");
      parent['LOGGER'].entering(this.logPrefix + mname);
    } else {
      console.log("entering--"+ mname );
    }
  }

  logExit(mname) {
    if (parent['LOGGER']) {
      console.log("call logger");
      parent['LOGGER'].exiting(this.logPrefix + mname);
    } else {
      console.log("exiting--"+ mname);
    }
  }

  logInfo(mname, log) {
    if (parent['LOGGER']) {
      console.log("call logger");
      parent['LOGGER'].info(this.logPrefix + mname + "--" + log);
    } else {
      console.log(mname +":"+ log);
    }
  }

  logFiner(mname, log) {
    if (parent['LOGGER']) {
      console.log("call logger");
      parent['LOGGER'].finer(this.logPrefix + mname + "--" + log);
    } else {
      console.log(mname +":"+ log);
    }
  }
}
