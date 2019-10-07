import { TestBed, inject } from '@angular/core/testing';

import { RestInterceptorService } from './rest-interceptor.service';

describe('RestInterceptorService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [RestInterceptorService]
    });
  });

  it('should be created', inject([RestInterceptorService], (service: RestInterceptorService) => {
    expect(service).toBeTruthy();
  }));
});
