import { TestBed, inject } from '@angular/core/testing';

import { AppRouteService } from './app-route.service';

describe('AppRouteService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [AppRouteService]
    });
  });

  it('should be created', inject([AppRouteService], (service: AppRouteService) => {
    expect(service).toBeTruthy();
  }));
});
