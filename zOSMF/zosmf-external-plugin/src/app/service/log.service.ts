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
