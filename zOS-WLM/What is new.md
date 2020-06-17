WLM/SRM enhancements in z/OS V2.4 and for IBM z15
=================================================
* Workload Manager support for Tailored Fit Pricing colocated workloads delivers simplicity, transparency, and predictability of pricing. For a colocated solution, the system programmer creates tenant resource groups and tenant report classes in the WLM service definition, using either the ISPF WLM administrative application or the z/OSMF WLM task, to identify the WLM-classified workloads that constitute the approved solution workload.
* z/OS Workload Management supports now System Recovery Boost. Built into IBM z15, System Recovery Boost is an innovative solution that diminishes the impact of downtime, planned or unplanned, so you can restore service and recover workloads substantially faster than on previous IBM Z generations with zero increase in IBM software MSU consumption or cost. With System Recovery Boost, you can use your already-entitled Central Processors and zIIPs to unleash additional processing capacity on an LPAR-by-LPAR basis, providing a fixed-duration performance boost to reduce the length and mitigate the impact of downtime.
* With More Granular Ressource Controls Workload Manager allows now to deactivate Discretionary Goal Management in the service definition and exempt service classes from default IFAHONORPRIORITY or IIPHONORPRIORITY processing.
* With z/OS 2.4 the Performance of XML Format Service Definition reads and writes in the ISPF Administrative Application is improved.
* z/OS V2R4 will be the last release of the operating system that supports specifying service coefficients in the WLM service definition

WLM/SRM enhancements in z/OS V2.3
=================================
* Workload Manager in z/OS V2.3 incorporates the latest support for the IBM z14. Hiperdispatch has been enhanced memory-intensive applications to preferentially use the same common cache across workload balancing intervals. Also, z/OS WLM enhances compute- intensive applications to preferentially be subdivided across processors sharing common caches.
* WLM Sysplex Routing is now sensitive to upcoming but not yet active soft capping. This enables clients to optimize the four-hour rolling average for Workload License Charges.
* z/OS Workload Management provides a new control that allows service classes to be defined such that their specialty processor eligible work will not execute on general purpose processors. In addition, WLM resource groups are enhanced to limit the amount of real storage that may be used by the associated service classes.
* z/OS Workload Management (WLM) is enhanced with an option to cap a system to the MSU value that is specified as the soft cap limit regardless of the four-hour rolling average consumption.
* Workload Manager allows now goal definitions for average and percentile response time goals down to 1 ms.

WLM/SRM enhancements in z/OS V2.2
=================================
* Workload Manager in z/OS V2.2 incorporates the latest support for the IBM z13. This includes support for simultaneous multithreading (SMT) on zIIP specialty engines and SRM support for large real storage. Also, HiperDispatch was enhanced to consider additional capping situations.
* WLM enhancements for health based routing in a Parallel Sysplex® can improve availability through extended diagnostics and autonomic.
Fabric I/O Priority, extends Workload Management into the SAN fabric and can help when your most important workloads need best service.
* WLM support enables the new JES 2 Dependent Job Control.
* A new WLM API -IWM4OPTQ- allows monitoring product to dynamically retrieve a self-describing list of all IEAOPT parameters.
* The WLM support for WLM managed DB2 bufferpools (AUTOSIZE bufferpools) has been improved.

WLM/SRM enhancements in z/OS V2.1
=================================
* Relaxed ZAAP-ZIIP requirements: SRM changed to relief requirements for the IEAOPTxx ZAAPZIIP (“zAAP on zIIP”) option:
* No longer limits the zAAP on zIIP function based on the number of zAAPs and/or the number of zIIPs installed on the machine.
* The zAAP on zIIP function continues to be limited to LPARs that have no zAAP. With this information users can, for example, set a goal, based on a required response time.
* Smoother capping with WLM managed softcapping.
* When IRD weight management is active the group capacity of an LPAR may be derived by the initial weight.
* New “Absolute Capping Limit” LPAR control.
* New Classification Qualifiers and Groups:
* New classification group types.
* Some new and modified work qualifier types for use in classification rules in the WLM service definition.
* Important service classes which are sensitive to I/O delay can now be assigned to priority group HIGH which ensures that they get always higher I/O priorities than the service classes assigned to group NORMAL.
* Improved granularity for resource groups.
* Up to 3000 Application Environments.

WLM/SRM enhancements in z/OS V1.13
==================================
Enhanced reporting:
* WLM reporting now provides a response time distribution for all service classes - also for service classes with an execution velocity or discretionary goal. For example, an RMF user can retrieve the response time for service class periods with velocity and discretionary goals.
* With this information users can, for example, set a goal, based on a required response time.
Enhanced processing of enclave tasks:
* WLM allows enclave tasks that have subtasks that were implicitly added to that enclave to leave the enclave.
* WLM also allows tasks that have non-enclave subtasks to join an enclave and have the subtasks implicitly joined to that enclave as well.

CICS response time management enhancement:
* Adjust WLM management of CICS/IMS regions to a Work Manager/Consumer model.

Support for SLEDrunner z:
* Optimized processing of IO requests in a DS8700 storage server by consideration of the WLM importance and goal fulfillment of the related work.
