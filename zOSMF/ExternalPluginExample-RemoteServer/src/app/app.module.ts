import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { FormsModule } from '@angular/forms';

import { MymatModule } from '../mat/mymat.module';
import { AppComponent } from './app.component';
import { JobSearcherComponent } from './job-searcher/job-searcher.component'; 
import { RestInterceptorService } from './service/rest-interceptor.service';

@NgModule({
  declarations: [
    AppComponent,
    JobSearcherComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    HttpClientModule,
    FormsModule,
    MymatModule
  ],
  providers: [{
    provide: HTTP_INTERCEPTORS,
    useClass: RestInterceptorService,
    multi: true
  }],
  bootstrap: [AppComponent]
})
export class AppModule { }
