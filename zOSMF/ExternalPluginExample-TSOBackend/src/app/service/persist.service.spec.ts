import { TestBed } from '@angular/core/testing';

import { PersistService } from './persist.service';

describe('PersistService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: PersistService = TestBed.get(PersistService);
    expect(service).toBeTruthy();
  });
});
