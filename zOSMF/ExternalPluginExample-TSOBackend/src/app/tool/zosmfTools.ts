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