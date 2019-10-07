## z/OS Capacity Provisioning (CPM)

Performance and capacity management on System z needs to ensure that the work is being processed according to the service level agreements that are in place. If for example workload increase requires that the processing capacity needs to be increased to accommodate the grown workload, Capacity Provisioning can do that either autonomically or in a simple manual way. The capacity change could be implemented via a permanent capacity increase, or for seasonal or unpredictable peak periods either via a temporary capacity increase, a defined capacity increase, or a group capacity increase.

IBM System z provides the capability to quickly and nondisruptively activate additional processor capacity that is built directly into System z servers — IBM Capacity Upgrade on Demand (CUoD) for a permanent increase of processing capability, IBM On/Off Capacity on Demand (On/Off CoD) for a temporary capacity increase that lets you revert to your previous processing level whenever you wish, and Defined Capacity that allows you to soft-cap your processor resources.

Capacity Provisioning is designed to simplify the management of temporary capacity, defined capacity and group capacity. The scope of z/OS Capacity Provisioning is to address capacity requirements for relatively short term workload and processor utilization fluctuations for which On/Off Capacity on Demand or soft capping changes are applicable. It is not a replacement for the Capacity Management process. Capacity Provisioning should not be used for providing additional capacity to systems that have hard capping (initial capping or absolute capping) defined.

Capacity Provisioning can help you to manage processor capacity on IBM System z10 or later when a suitable On/Off Capacity on Demand record is available. Capacity Provisioning allows you to change the activation level of that On/Off CoD record with respect to general purpose capacity, and the number of zAAP or zIIP processors. Capacity Provisioning can also help you to manage Defined Capacity on IBM System z10 or later and LPARs with defined capacity, or IBM System z196 or later and LPARs with group capacity.

For general purpose capacity on subcapacity models CPM differentiates between „speed“ demand for higher capacity levels, and “unqualified” demand that could be satisfied by a capacity level increase as well as by additional processors.

Optionally, CPM can recommend to adjust the amount of logical processors of a monitored system.

CPM differentiates between different types of Provisioning Requests:

    Manually through commands (SE/HMC actions still possible, of course)
    Scheduled (time condition only)
    Conditional (based on workload condition or CPC-wide utilization condition).

Manual commands allow the adjustment of temporary capacity available on an On/Off Capacity on Demand record, for processor types:

    General purpose
    zAAP
    zIIP
    IFL
    ICF
    SAP.

as well as the adjustment of:

    Defined LPAR Capacity
    Defined Group Capacity
    Initial LPAR weights for processor types General purpose, zIIP or IFL.
    
The official CPM documentation can be found [here](https://www.ibm.com/support/knowledgecenter/SSLTBW_2.4.0/com.ibm.zos.v2r4.ieau100/ieauch1.htm).

This repository contains CPM  resources that might be useful to the z/OS community. Here you will find items of interest about new functions in z/OS CPM.

There are no warranties of any kind, and there is no service or technical support available for these materials from IBM. As a recommended practice, review carefully any materials that you download from this site before using them on a live system.

Though the materials provided herein are not supported by the IBM Service organization, your comments are welcomed by the developers, who reserve the right to revise or remove the materials at any time. To report a problem, or provide suggestions or comments, contact IBMCPM@de.ibm.com.
