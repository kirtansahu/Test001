// ===========================================================================
//  Object: NewOpportunity_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde
// Purpose: Unit Test Class for NewOpportunity.
// ===========================================================================
// Changes:
// ===========================================================================

@istest
public class NewOpportunity_Test {
	@istest
	public static void opportunityTestMethod() {
		//Insert Account Records
		TestSetupDataUtil.insertAccountRecords(10);
		//Fetch Account records
		List<Account> accList = [SELECT Id, Name FROM Account];
		//Insert Contact Records
		List<Contact> cons = TestSetupDataUtil.insertContactRecordswithAcc(3, accList);
		//create Opportunity Record
		Opportunity opList = new Opportunity(
			Name = 'test',
			CloseDate = System.today(),
			StageName = 'new',
			Confidence__c = '30%',
			AccountId = accList[0].Id,
			Primary_Contact__c = cons[0].id
		);
		insert opList;
		//Assert Statements
		System.assertEquals(accList.Size(), 10);
		System.assertEquals(cons.Size(), 3);
		System.assertNotEquals(opList.Id, null);
		NewOpportunity.NewOpportunityPrefill();
		NewOpportunity.getFields();
	}
}