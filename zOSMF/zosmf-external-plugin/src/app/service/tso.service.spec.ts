import { TestBed } from '@angular/core/testing';

import { TsoService } from './tso.service';

describe('TsoService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: TsoService = TestBed.get(TsoService);
    expect(service).toBeTruthy();
  });
});
