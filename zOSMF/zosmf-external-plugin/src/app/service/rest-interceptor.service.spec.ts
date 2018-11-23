import { TestBed } from '@angular/core/testing';

import { RestInterceptorService } from './rest-interceptor.service';

describe('RestInterceptorService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: RestInterceptorService = TestBed.get(RestInterceptorService);
    expect(service).toBeTruthy();
  });
});
