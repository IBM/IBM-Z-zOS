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
import { TsoService } from '../service/tso.service';

/**
 * A simple class, which will be instantiated in VarViererComponent's onInit, then the instance
 * will be passed into window. z/OSMF desktop will invoke cleanupBeforeDestroy() method when user
 * clicking 'X' of plugin window. 
 */
export class ZosmfTools {
    constructor(private _tsoService: TsoService) { }

    /**
     * cleanup method which will be called by z/OSMF desktop when user clicking 'X' of plugin.
     */
    cleanupBeforeDestroy() {
        // do your clean up work here, in this example, call TsoService to delete the address space
        this._tsoService.deleteTSO().subscribe( data => {
            console.log("TSO AS cleaned!");
        });
    }
}