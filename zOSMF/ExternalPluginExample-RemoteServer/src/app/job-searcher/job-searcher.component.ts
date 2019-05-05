import { Component, OnInit } from '@angular/core';
import { JobService } from '../service/job.service';
import { AppRouteService } from '../service/app-route.service';
import { Job } from '../job/job';

@Component({
  selector: 'app-job-searcher',
  templateUrl: './job-searcher.component.html',
  styleUrls: ['./job-searcher.component.css']
})
export class JobSearcherComponent implements OnInit {
jobs:Job[] = new Array<Job>(0);
prefix: string;
owner: string;
  
  // parent.currentUserName
  constructor(private _jobService: JobService, private _appService: AppRouteService) {
  }
  
  ngOnInit() {
    // get jobs list from zos
    this._jobService.listJobs(null, null).subscribe( jobsData => {
      if (jobsData && jobsData.length > 0) {
        this.jsonArray2Jobs(jobsData);
      } else {
        console.log("response of geting jobs is empty");
      }
    }, error => console.log(error));
  }

  retrieveJobs() {
    // get jobs list from zos based on user input
    this._jobService.listJobs(this.prefix, this.owner).subscribe( jobsData => {
      // clear previous list
      this.jobs = new Array<Job>(0);
      if (jobsData && jobsData.length > 0) {
        this.jsonArray2Jobs(jobsData);
      } else {
        console.log("response of geting jobs is empty");
      }
    }, error => console.log("get job error: " + error));
  }

  // json array contains at least one job
  jsonArray2Jobs(jArray) {
    let jobname: String;
      let jobid: String;
      let owner: String;
      let status: String;
      let retcode: String;
      let clazz: String;
      for (let jobData of jArray) {
        jobname = jobData["jobname"];
        jobid = jobData["jobid"];
        owner = jobData["owner"];
        status = jobData["status"];
        retcode = jobData["retcode"];
        clazz = jobData["class"];
        let job = new Job(jobname, jobid, owner, status, retcode, clazz);
        this.jobs.push(job);
    }
  }

  save2Server() {
    this._appService.updateData(this.prefix, this.owner).subscribe(
      data => {}, 
      error => console.log("put server error: " + error));
  }

  refreshFromServer() {
    this._appService.retrieveData().subscribe(profileData => {
      if (profileData && profileData.length != 0) {
        this.prefix = profileData["prefix"];
        this.owner = profileData["owner"];
      }
    }, error => console.log("get server error: " + error));
  }
}
