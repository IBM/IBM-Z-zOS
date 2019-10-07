import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AppRouteService {
  routeUrl:string = '/externalgateway/system';
  remoteSys:string = 'mySys';
  resourcePath:string = '/profile';
  parmContent:string = '{"target":"' + this.remoteSys + 
                       '","resourcePath":"'+ this.resourcePath +'","wrapped":"N"}';
  url:string = this.routeUrl + "?content=" + this.parmContent;
  constructor(private http:HttpClient) {}

  retrieveData():Observable<any> {
    // GET host:port/zosmf/externalgateway/system?content={"target":"mySys","resourcePath":"/profile","wrapped":"N"}
    return this.http.get(this.url);
  }

  updateData(prefix, owner):Observable<any> {
    // PUT host:port/zosmf/externalgateway/system
    // {
    //   "target": "mySys",
    //   "resourcePath": "/profile",
    //   "content": {
    //     "prefix": "<prefix>",
    //     "owner": "<owner>"
    //   }
    // }
    let content = new Object();
    content["owner"] = owner;
    content["prefix"] = prefix;
    let body = new Object();
    body["target"] = this.remoteSys;
    body["resourcePath"] = this.resourcePath;
    body["content"] = content;
    return this.http.put(this.routeUrl, JSON.stringify(body));
  }
}
