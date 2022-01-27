// ===========================================================================
//  Class Name 	: NewOpportunityCls_Test
// 	Company  	: Keste @IDC
// 	Author      :Rambabu Gadde
// 	Purpose		: This apex class is worked as test class for NewOpportunitycmp - Lightning Component,
// 					which is used in 'New Opportunity' action at Contact level. This class will prefill
// 					the Contact and Account values under Opportunity Screen
// ===========================================================================
@isTest
public class NewOpportunityCls_Test {
	@testSetup
	public static void testData() {
		//Insert Custom Settings
		TestSetupDataUtil.insertAccountRecords(1);
	}

	@istest
	public static void myUnitTest() {
		list<Account> acc = [SELECT Id, Name FROM Account];
		Contact oContact = new Contact(
			lastname = 'test',
			firstname = 'testName',
			AccountId = acc[0].Id,
			Email = 'abcd@GMAIL.COM'
		);
		insert oContact;
		//Assert Statements
		System.assertEquals(acc.Size(), 1);
		System.assertEquals(oContact.Accountid, acc[0].id);
		System.assertNotEquals(oContact.id, null);

		String json = NewOpportunityCls.NewOppPrefill(oContact.id);
		System.assert(json != null);

		List<Opportunity> lstOpportunity = OpportunityController.populateValues();
		system.assertEquals(lstOpportunity.size(), 1);
		System.assertNotEquals(json, null);
	}
}