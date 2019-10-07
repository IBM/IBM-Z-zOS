import { NgModule } from '@angular/core';
import { MatMenuModule } from '@angular/material/menu'; 

@NgModule({
    imports: [
        MatMenuModule
    ],
    exports: [
        MatMenuModule
    ]
})
export class MymatModule { }