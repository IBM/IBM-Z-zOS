import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { JobSearcherComponent } from './job-searcher.component';

describe('JobSearcherComponent', () => {
  let component: JobSearcherComponent;
  let fixture: ComponentFixture<JobSearcherComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ JobSearcherComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(JobSearcherComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
