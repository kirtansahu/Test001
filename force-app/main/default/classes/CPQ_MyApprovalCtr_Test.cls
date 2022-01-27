// ===========================================================================
//  Object: CPQ_MyApprovalCtr_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde-tttt
// Purpose: Unit Test Class for CPQ_MyApprovalCtr.
// ===========================================================================
// Changes:
// ===========================================================================

@istest
public class CPQ_MyApprovalCtr_Test {
	@istest
	public static void unitTest() {
		//create Oracle CPQ Cloud Site Record
		BigMachines__Configuration_Record__c bcr = new BigMachines__Configuration_Record__c();
		bcr.BigMachines__process_id__c = 'sample';
		bcr.BigMachines__Is_Active__c = true;
		bcr.BigMachines__action_id_copy__c = 'sample1';
		bcr.BigMachines__action_id_open__c = 'sample2';
		bcr.BigMachines__bm_site__c = 'sample3';
		bcr.BigMachines__document_id__c = 'Data';
		bcr.BigMachines__process__c = 'Data1';
		bcr.BigMachines__version_id__c = 'Date2';
		insert bcr;
		//Assert Statements
		System.assertNotEquals(bcr.id, null);
		System.assertEquals(bcr.BigMachines__Is_Active__c, true);
		CPQ_MyApprovalCtr cpq = new CPQ_MyApprovalCtr();
		String test = cpq.cpqProcessId;
	}
}
