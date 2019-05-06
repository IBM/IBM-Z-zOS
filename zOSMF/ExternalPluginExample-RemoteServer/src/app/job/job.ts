export class Job{

  jobname: String;
  jobid: String;
  // subsystem: String;
  owner: String;
  status: String;
  // type: String;
  retcode: String;
  clazz: String;
  // url: String;
  // filesUrl: String;

  constructor(jobname, jobid, owner, status, retcode, clazz) { 
    this.jobid = jobid;
    this.jobname = jobname;
    // this.subsystem = subsys;
    this.owner = owner;
    this.status = status;
    // this.type = type;
    this.clazz = clazz;
    this.retcode = retcode;
    // this.url = url;
    // this.filesUrl = filesUrl;
  }

}