## README 
```
** Beginning of Copyright and License **

Copyright 2021 IBM Corp.                                           
                                                                    
Licensed under the Apache License, Version 2.0 (the "License");    
you may not use this file except in compliance with the License.   
You may obtain a copy of the License at                            
                                                                    
http://www.apache.org/licenses/LICENSE-2.0                         
                                                                   
Unless required by applicable law or agreed to in writing, software 
distributed under the License is distributed on an "AS IS" BASIS,  
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  
See the License for the specific language governing permissions and  
limitations under the License.                    

** End of Copyright and License **        
```

## Overview

These Java classes act as plugins to the SMF processor found in the SMF_CORE project
in this same repository with the intent of helping analyze WebSphere SMF records
type 120-9, -10, -11, and -12.  

Compilation and execution of these classes requires the SMF_CORE project and the 
SMF_WAS project from this same github repository.

All of the plugins except 'ReWrite' treat the parameter string following the plugin 
name in the invocation as an output file name.

- **AffinityCreation** - Version 8 of WebSphere Application Server includes information about affinities in the SMF 120-9
record. An affinity is usually created when an HTTP request creates an HTTPSession object
(although there are other ways you can get an affinity). So I built a couple of reports to take a look
at affinity data.

  The first report looks at affinity creation over time. It groups affinity information by servant within a
particular server. The server name and servant identifiers are in a header line. That is followed by
CSV data showing the number of affinities created over time. You can count affinities per hour, per
minute, or per second.

  You can control the granularity of the report by setting <samp>com.ibm.ws390.smf.plugins.AffinityCreation.Interval</samp> 
to <samp>Hours</samp>, <samp>Minutes</samp>, or <samp>Seconds</samp>.  The default is <samp>Seconds</samp>.

- **Affinity Report** - If you have an application that creates affinities it might be nice to know if they are actually being
used. An affinity usually represents an actual HTTPSession object in memory in a servant region.
If left unused there is an expiration timer that will delete them. However, they remain in the heap
until that timer runs out. An application that is creating session objects that are never used is
causing unnecessary overhead. On the other hand, just knowing how creating affinities are being
used might tell you something.

  If you are running on WAS V8 the SMF 120-9 record will contain affinity data. This report consists
of one row of CSV data for each created affinity. For each affinity we report the creation time (in
human-readable and STCK millisecond values), the server and servant where the affinity was
created, the actual affinity token, the number of times the affinity was used after it was created, and
the URI of the HTTP request that created the affinity.

  The actual token isn't very useful, but it is what makes the rows unique.

- **AsyncCSVExport** - WebSphere traditional writes SMF 120-9 records for both 'normal' dispatched requests and for
async work scheduled from inside a servant region. These records are missing some of the
request-based sections in the normal subtype 9 records, but have an additional async work section.

  This plugin extracts and formats just these subtype 9 records, skipping the normal ones.
Invocation is exactly like CSVExport except the plugin name is AsyncCSVExport.


- **ClusterRespRatio** - For each cluster for which data is found (120-9 records), a count is reported of the 
number of records where the enclave-delete response ratio is greater than 100.  The response ratio is equal to
100 if the request completed in exactly the goal for the service class into which the request was classified.  

  A ratio greater than 100 means the request missed the goal.  Remember that it can be ok for some requests to
miss the goal response time depending on how the service class is defined.

- **CSVExport** - This plugin generates a file with one record per SMF 120-9 record processed. Most of the fields
from the SMF record are turned into comma-separated-values in the file. The time stamps are
presented in both human-readable values and STCK values converted to milliseconds. Math is done
with the millisecond values to calculate the time spent in each stage (e.g. in the WLM queue).
Records for async work are ignored.

- **DispatchThreadUsage** - This report determines the total time for which it has SMF data for work executed in each servant
region. It then examines the dispatch begin/end time for every request and tracks the total time for
which each dispatch TCB was actually dispatching something. It also tracks CPU time and
determines the total CPU time used by requests dispatched on each TCB.

  A summary report, in CSV, shows how many requests were processed by each TCB and what
percent of the total report time was spent in dispatch and what percent of the dispatch time was
spent using CPU.

  This report ignores async work and internal work. Internal work is ignored automatically since it
runs on a different thread pool.

- **FindHighWaterInQueue** - How deep did the WLM queue get? This plugin tries to determine how bad it got, for the available
data. It scans all the data and determines the earliest time something was placed on the queue and
the latest time something was taken off. It then goes through that time range, millisecond by
millisecond, looking at each request to see if it was on the queue during that millisecond. The
report shows, for each millisecond in the window, how many requests were on the queue at that
time. Async work is ignored.

  Sounds very slow and could produce a huge volume of output. And it is both. To get around that,
and because queue spikes probably last longer than a millisecond anyway, you can specify how
many samples you want it to take across the interval. The default is 1000 samples.

  The timestamps are STCK values in milliseconds. You should be able to match it to a real time (or
close to one) in the CSVExport output.  You can adjust the number of samples by setting the property
<samp>com.ibm.ws390.smf.smf1209.FindHighWaterInQueue.Interval</samp>

- **LibertyBatchExport** - This plugin is the equivalent of CSVExport for the SMF 120-12 records written by Liberty for JSR-
352 Java Batch job execution. Records are written at job end, step end, partition end, and flow end (which record type is
indicated by a field in the record).

- **LibertyExport** - This plugin is the equivalent of CSVExport for the SMF 120-11 Version 2 and up records written by Liberty
for incoming HTTP requests as of 16.0.0.2.

- **LibertyResponseTimes** - This is the same as the ResponseTimes plugin described later, but using the Liberty 120-11 records 
instead of the 120-9 records from WebSphere traditional.

- **RequestDensity/RequestDensity2** - These two plugins look at the timestamps for each request and manage counters for the state the
request was in at one second intervals. We do this two ways. The first plugin, RequestDensity, just
increments a counter (e.g. the in-queue-in-this-second counter) when the request enters this state
in this second. So, for example, if a request gets put on the queue at 10:30:29 and stays there for 3
seconds, the “In Q” counter only gets bumped for that one second. So the report shows you how
many requests ENTERED each state during that second.
The second plugin, RequestDensity2, looks at the windows where the request was in each state
and increments the counters for all the seconds the request was in that state. So in our example
above, the “In Q” counter would be incremented for 10:30:29, 10:30:30, and 10:30:31. So the
resulting report shows you how many requests were IN each state during each second.
Note that with one-second granularity it is very possible for a single request to be in all four states in
the same second. 

  This report ignores async work. Use the ExcludeInternal filter to ignore internal work.
  
  Other weirdness... Suppose you know you have 40 dispatch threads and you know you are running
the server at full capacity. You would then expect to see “In Disp” at 40 most of the time. But
remember it can only report using data it has. If a request started running on a thread and finished
AFTER the cutoff for your set of SMF data, then the plugin doesn't have that SMF record. So if one
request was on a thread for the last 5 minutes of your data, but didn't finish until just after the cutoff
for your chunk of SMF data, then the report might show 39 requests “In Dispatch” for those last five
minutes, but really there were 40. We can't know what the other thread was doing until it finishes
and writes its SMF record. This is probably obvious, but I stared at one of these reports for quite a
while before I figured out where that other thread went.

  Update 10/11/13 – I decided to experiment with exploiting Chart.js (you can get a copy here
http://www.chartjs.org/). If you use RequestDensity2 and specify an output file that ends in “.html”
the plugin will generate HTML/Javascript. If you put that html file and chart.js in the same directory
and open the HTML file with your browser it will probably (no guarantees for different browser
support) show you a nice graph of how work is being processed. The blue line is work arriving in
the controller, the yellow line is work in the queue, the red line is work in dispatch, and the orange
line is work in completion. As the note below points out, the data produced is skipping seconds in
which nothing happens. So if the server is idle (or down) there should be a gap but the data and
graph won't show it. Also, due to limitations in Chart.js, we are only putting 600 data points (10
minutes) per chart. So if you have a larger data range you'll get multiple charts. And if you have
ten minutes (or a multiple) and a little bit you'll get a final graph with very few data points on it which
looks a little weird. Basically this support is experimental. When in doubt, look at the actual data.
But sometimes the picture helps.

  Note: Timestamps only appear for times where data exists. There can be gaps. It seemed better
to have to look for the gaps than have potentially huge swaths of zeros where nothing happened.

- **RequestsPerServer** - This is a good report to run if somebody just hands you a big pile of WebSphere SMF data. I
always run this first on any customer SMF data I receive. It gives me a quick overview of how much
data I have and what it represents.

  The plugin looks at each 120-9 record and remembers all the different servers that it finds. It keeps
track of the different types of work it sees for each server (e.g. HTTP, IIOP, etc.). When it is
finished it produces a report that shows the system name and server name for each server with the
counts of the different work types it saw. The data is provided in comma-separated-value format
(CSV) which is easily pulled into most spreadsheet programs. Here is some very basic output from
a dump of SMF data from just one server.

  If you have data for a lot of different servers a lot of internal requests (Mbeans, etc) then you might
want to use the SMF 120-9 filter properties with the browser to thin out the data it handles for the
other plugins.

  Note that async work will only be recorded if you are running on WAS V8, have async beans
running, and have SMF recording for async work enabled.

  Update 10/11/13 – This report now also shows you the code level of the server (e.g. 8.0.0.7) as
well as the earliest and latest timestamps for records seen for this server. The level is based on the
first record we see for a particular server so if the data spans a migration of levels it will just report
the first one it sees.
  
  Update 10/28/13 - This report now also counts the number of SMF 120-10 records (outbound
requests) and reports it to the right of the ASYNC count.

  Update 6/4/21 - This report now also counts the number of records where the WLM enclave delete
response time ratio is greater than 100 (meaning the request missed the goal for whatever service
class it was assigned). This isn't necessarily bad (if you've got a goal of 95% complete in some
amount of time, WLM is allowed to miss the response time for 5% of the requests and still meet the
goal).

- **ResponseTimes** - This plugin shows averages of elapsed and CPU times. It does this per URI for HTTP requests.
For everything else it lumps it into 'null' (meaning the URI is 'null'...live with it). It also averages
across all the requests seen.

  So the report has the following columns:
  – number of requests seen per URI
  
  – average response time (completion minus received) per URI
  
  – average queue time per URI
  
  – average dispatch time per URI
  
  – average TCB CPU (in ms) per URI
  
  – average bytes received per URI
  
  – average bytes send (response) per URI
  
  If `-Dcom.ibm.ws390.smf.smf1209.useTime=[RECEIVED|QUEUED|DISPATCH_START|DISPATCH_END|RESPONDED]` is set, then
  response times are printed per unit time grouping by the specified request time (normally `RESPONDED`).
  The interval may be configured with `-Dcom.ibm.ws390.smf.smf1209.intervalType=[PER_SECOND|PER_MINUTE|PER_HOUR]`
  (defaults to `PER_MINUTE`). Statistics may also be further printed by a subgrouping with
  `-Dcom.ibm.ws390.smf.smf1209.breakdown=[NONE|BY_SERVER]` (default `NONE`).

- **ReWrite** - If you have a huge volume of data and you are using the filter properties as shown above to thin out
the amount being processed, it might be nice to just have less data. For some of the more complex
reports it can speed things up considerably if we don't have to read, parse, and then ignore a lot of
records we don't care about.

  This plugin simply reads in all the records that get past the filter properties and writes them back out
to a pre-allocated dataset.

  Allocate the new dataset with the same attributes as the original dataset.
  
  This only supports SMF 120-9 and 120-10 records.

- **SplitByServer** - Similar to ReWrite, this plugin tries to automatically break the data up by server name (a common
usage patter with ReWrite). Instead of telling it which server you are interested in, just have DD
cards whose name matches the server (or servers) for which you want data extracted.

  For example, if you have data from 100 different servers in one SMF data file but only care about
data from SERVER1 and SERVER2 then run the browser with DD’s allocated named SERVER1
and SERVER2. Data for those servers will be written into the appropriate file and data from other
servers will be ignored.

  The plugin will print messages indicating which servers it is keeping (and not keeping) data for. So
running with no DDs matching server names is kind of a cheap way to get a list of all the servers for
which you have data..

  Update April 1, 2019 (No foolin!) - You can also specify a DD that matches the short cluster name
and records for any server in that cluster will be written to that DD. This overrides a DD for a server
in the cluster. Put another way, if you have DD’s for SERVER1, SERVER2, and CLUSTERA and
both servers are in CLUSTERA then all the data will end up in that DD and nothing will go to the
two server-based DDs.

- **ThreadRequestDensity/ThreadRequestDensity2** - This pair of plugins track when requests begin (or end) dispatch on each thread in each servant
region. A report is produced, in CSV format, showing minute-by-minute for each servant region
how many requests started (or ended) dispatch on the available threads.

  ThreadRequestDensity uses the dispatch begin timestamps and ThreadRequestDensity2 uses the
dispatch end timestamps. Both reports ignore async work and internal work. Internal work is
ignored automatically since it runs on a separate thread pool.

  Update 10/11/13 – Both of these reports have been updated to include a count on the far right
showing the number of non-zero thread columns. Basically the count of threads that begin/ended
work in this minute. This can give you a quick look at how many threads are being used by the
server.

  Remember that, like other reports, this one skips rows where nothing happened. So if no work
started/ended in a given minute (because the server was idle, the server was down, or requests just
spanned multiple minutes) then there won't be rows for those minutes. So if you are looking at
thread usage over time, be careful about gaps.




