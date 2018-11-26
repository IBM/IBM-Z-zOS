import { NgModule } from '@angular/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatStepperModule } from '@angular/material/stepper';
import { MatDividerModule } from '@angular/material/divider';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatInputModule } from '@angular/material/input';
import { MatListModule } from '@angular/material/list';


@NgModule({
  imports: [
    MatFormFieldModule,
    MatSelectModule,
    MatButtonModule,
    MatStepperModule,
    MatDividerModule,
    MatProgressBarModule,
    MatInputModule,
    MatListModule
  ],
  exports: [
    MatFormFieldModule,
    MatSelectModule,
    MatButtonModule,
    MatStepperModule,
    MatDividerModule,
    MatProgressBarModule,
    MatInputModule,
    MatListModule
  ]
})

/**
 * A separate NgModule that imports all of the Angular Material components
 */
export class MymatModule { }
