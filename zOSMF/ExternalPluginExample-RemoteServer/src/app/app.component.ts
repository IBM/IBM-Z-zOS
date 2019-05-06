import { Component } from '@angular/core';

declare var zosmfExternalTools: any;

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})

export class AppComponent {
  title = 'ExternalPluginExample-RemoteServer';

  constructor(){
    zosmfExternalTools.cleanupBeforeDestroy = function(obj){
      // doing cleanup work
      console.log("Cleanup work done!");
      zosmfExternalTools.cleanupBeforeDestroyComplete(obj);
    }
  }
}
