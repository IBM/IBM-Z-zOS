import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { VarViewerComponent } from './var-viewer.component';

describe('VarViewerComponent', () => {
  let component: VarViewerComponent;
  let fixture: ComponentFixture<VarViewerComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ VarViewerComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(VarViewerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
