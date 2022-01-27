/********************************************************************************
 * Object	: CPQ_MyApprovalCtr
 * Company	: Keste @ IDC
 * Author	: Basant Kumar verma
 * Purpose	: Controller Class for CPQ_MyApproval VF Page
 * This controller is to fetch the Site record so we can usethe configurations
 ********************************************************************************/
public with sharing class CPQ_MyApprovalCtr {
	//Class level property to fetch the dynamic value for the CPQ Process ID from the configuration Record (Site)
	public String cpqProcessId {
		get {
			if (cpqProcessId == null) {
				for (BigMachines__Configuration_Record__c ob : [
					SELECT Id, BigMachines__process_id__c
					FROM BigMachines__Configuration_Record__c
					WHERE BigMachines__Is_Active__c = TRUE
					ORDER BY CreatedDate DESC
					LIMIT 1
				]) {
					cpqProcessId = ob.BigMachines__process_id__c;
				}
			}
			return cpqProcessId;
		}
		protected set;
	}
}