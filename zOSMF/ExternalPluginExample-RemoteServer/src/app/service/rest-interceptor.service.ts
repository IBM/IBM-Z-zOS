import { Injectable } from '@angular/core';
import { HttpHeaders, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class RestInterceptorService {
  private baseUrl;
  private headers: HttpHeaders;
  constructor() {
    let location = window.location.href;

    if (location.indexOf('localhost') > 0) {
      this.baseUrl = 'https://pev076.pok.ibm.com/zosmf';
      this.headers = new HttpHeaders({
        'Authorization': 'Basic aWJtdXNlcjpzeXMx',
        'X-CSRF-ZOSMF-HEADER': 'zosmf'
      });
    } else {
      this.baseUrl = '/zosmf';
    }
  }

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // copy requester's header
    if (req.headers != null && req.headers.keys() != null) {
      let keys = req.headers.keys();
      let key, value;
      for (let i in keys) {
        key = keys[i];
        value = req.headers.get(key);
        this.headers.set(key, value);
      }
    }

    const cloneReq = req.clone({
      url: `${this.baseUrl}${req.url}`,
      headers: this.headers
    })
    return next.handle(cloneReq);
  }
}


