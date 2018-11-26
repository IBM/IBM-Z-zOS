import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { MymatModule } from '../mat/mymat.module';

import { AppComponent } from './app.component';
import { VarViewerComponent } from './var-viewer/var-viewer.component';
import { RestInterceptorService } from './service/rest-interceptor.service';

@NgModule({
  declarations: [
    AppComponent,
    VarViewerComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    FormsModule,
    ReactiveFormsModule,
    HttpClientModule,
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
