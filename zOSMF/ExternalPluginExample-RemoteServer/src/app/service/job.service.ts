import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Job } from '../job/job';

@Injectable({
  providedIn: 'root'
})
export class JobService {
  jobs:Job[] = new Array<Job>(0);
  jobsUrl:string = "/restjobs/jobs";

  constructor(private http: HttpClient) { 
    for (let i=0; i < 8; i++) {
      let job = new Job('TESTJOB', 'JOB00023', 'IBMUSER', 'OUTPUT', 'CC 0000', 'A');
      this.jobs.push(job);
    }
  }

  listJobs(prefix, owner): Observable<any> {
    // return this.jobs;
    let url:string = this.jobsUrl;
    let hasParm = false;
    if (prefix != null && prefix.length != 0) {
      url = url + "?prefix=" + prefix;
      hasParm = true;
    }
    if (owner != null && owner.length != 0) {
      if (hasParm) url = url + "&owner=" + owner;
      else url = url + "?owner=" + owner;
    }
    return this.http.get(url);
  }
}
