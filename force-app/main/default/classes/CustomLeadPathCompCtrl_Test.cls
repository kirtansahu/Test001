// ===========================================================================
//  Object	: CustomLeadPathCompCtrl_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Unit Test Class for CustomLeadPathCompCtrl.
// ===========================================================================
@istest
public class CustomLeadPathCompCtrl_Test {
	@istest
	public static void unitTest() {
		//insert Account Record
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = RecordTypeId;
		a.Unique_Id__c = 'test';
		insert a;
		System.assertNotEquals(a.Id, null);
		//insert Contact Record
		Contact c = new Contact();
		c.LastName = 'TestContact';
		c.FirstName = 'TestContactName';
		c.AccountId = a.Id;
		c.Email = 'abcd@gmail.com';
		insert c;
		//Assert Statements
		System.assert(c.Accountid == a.id);
		System.assertNotEquals(c.id, null);
		//insert Opportunity Record
		Opportunity oppObj = new Opportunity(
			Name = 'Test Opportunity',
			CloseDate = System.today(),
			StageName = 'New',
			Confidence__c = '10%',
			AccountId = a.Id,
			Primary_Contact__c = c.id
		);
		insert oppObj;
		//Insert Lead Record
		Lead oLead = new Lead();
		oLead.Lead_Source_Id__c = '1001';
		oLead.IsConverted = false;
		oLead.Account__c = a.Id;
		oLead.Contact__c = c.Id;
		oLead.Comment__c = 'Comment Demo';
		oLead.LastName = 'Test Lead Obj';
		oLead.Company = 'Test';
		oLead.Status = 'Rejected';
		oLead.Opportunity_Name__c = 'Test Opp';
		insert oLead;
		//Assert Statements
		System.assertNotEquals(oLead.id, null);
		test.startTest();
		CustomLeadPathCompCtrl.fetchLeadRecord(oLead.id);
		CustomLeadPathCompCtrl.fetchLeadStatusValues();
		CustomLeadPathCompCtrl.updateLeadRecord(oLead);

		//CustomLeadPathCompCtrl.fetchDependentPickListValue('lead','status','Lead Rejection Reason','lead');
		// CustomLeadPathCompCtrl.base64ToBits('sample');
		CustomLeadPathCompCtrl.fetchDependentPickListValue('Lead', 'Status', 'Lead_Rejection_Reason__c', 'Rejected');
		try {
			CustomLeadPathCompCtrl.convertLeadIntoOpportunity(oLead);
		} catch (exception e) {
		}
		try {
			CustomLeadPathCompCtrl.updateLeadRecord(new Lead());
			CustomLeadPathCompCtrl.updateLeadRecord(null);
		} catch (exception e) {
		}
		try {
			CustomLeadPathCompCtrl.convertLeadIntoOpportunity(new Lead());
			CustomLeadPathCompCtrl.convertLeadIntoOpportunity(null);
			CustomLeadPathCompCtrl.updateLeadRecord(null);
		} catch (exception e) {
		}
		test.stopTest();
	}
}