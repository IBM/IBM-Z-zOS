import { TestBed, inject } from '@angular/core/testing';

import { JobService } from './job.service';

describe('JobService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [JobService]
    });
  });

  it('should be created', inject([JobService], (service: JobService) => {
    expect(service).toBeTruthy();
  }));
});
