
IBM recommends following the best practices documented in these workflows when upgrading a coupling facility. These steps are 
intended to help you avoid unexpected delays or outages to applications that are using structures in coupling facilities. Follow all of the steps in the procedures.

workflow_pushpull.xml - Use for a “push/pull” of a CPC on which a coupling facility image resides OR when there is to be a power-on reset, POR, of the CPC on which the coupling facility image resides and there is a physical or logical change to the coupling facility.

workflow_PORNoChg.xml - Use for a POR of a CPC on which a coupling facility image resides. This procedure applies where there is to be a POR of a CPC on which a coupling facility resides and, across the POR, there are no physical or logical changes to the coupling facility.

workflow_disrupt.xml - Use for a disruptive coupling facility upgrade. The disruptive coupling facility upgrade procedure should be conformed to anytime the coupling facility image must be reactivated but the CPC on which the coupling facility resides is not going to be PORd. Most CFCC maintenance applications can be achieved concurrently. That is, the CF image does not need to be reactivated to pick up the new service level of CFCC. 

The reasons a CF image may need to be reactivated include: 
    the rare disruptive coupling facility code change, change to CFCC image storage requirements, and activating a new Coupling Facility Release level that is typically delivered with a System z driver upgrade.
    
For more information about upgrading a coupling facilty, see https://www.ibm.com/support/knowledgecenter/SSLTBW_2.2.0/com.ibm.zos.v2r2.ieaf100/toc.htm.
