import { Injectable } from '@angular/core';
import { HttpEvent, HttpHandler, HttpRequest, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class RestInterceptorService {

  private baseUrl;
  private headers: HttpHeaders;

  constructor() { 
    let location = window.location.href;

    // add additional header to help local env visit remote server
    if (location.indexOf("4300") > 0) {
      this.baseUrl = 'https://pev076.pok.ibm.com/zosmf';
      this.headers = new HttpHeaders({
        'Content-Type': 'application/json',
        'Authorization': 'Basic aWJtdXNlcjpzeXMx',
        'Access-Control-Allow-Origin': this.baseUrl,
        'X-CSRF-ZOSMF-HEADER': 'zosmf',
        'Accept':'application/json'
      })
    } else { // no additional header need, if run in same server
      this.baseUrl = '/zosmf';
      this.headers = new HttpHeaders({
        'Content-Type': 'application/json'
      })
    }
  }

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // copy requser's header
    if (req.headers != null && req.headers.keys() != null) {
      let keys = req.headers.keys();
      let key, value;
      for (let i in keys) {
        key = keys[i];
        value = req.headers.get(key);
        this.headers.set(key, value);
      }
    }
    // add prefix '/zosmf' to the url 
    const cloneReq = req.clone({
      url: `${this.baseUrl}${req.url}`,
      headers: this.headers
    });
    
    return next.handle(cloneReq);
  }
}
