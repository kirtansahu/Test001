// ===========================================================================
//	Object	: selectedSizeWorkaround_Test
//	Company	: Keste @ IDC
//	Author	: Rambabu Gadde
//	Purpose	: Unit Test Class for selectedSizeWorkaround.
// ===========================================================================
@istest
public class selectedSizeWorkaround_Test {
	@istest
	// Method Name: unitTest
	// Author: Rambabu
	// Description: Method to test mass Update on Opportunity
	public static void unitTest() {
		//Insert Account Records
		List<Account> accList = TestSetupDataUtil.insertAccountRecords(10);
		List<Contact> conList = TestSetupDataUtil.insertContactRecordswithAcc(1, accList);
		List<Opportunity> opList = new List<Opportunity>();
		//Create Opportunity Record
		Opportunity oppObj = new Opportunity(
			Name = 'Test Opportunity',
			CloseDate = System.today(),
			StageName = 'New',
			Confidence__c = '10%',
			AccountId = accList[0].Id,
			Primary_Contact__c = conList[0].id
		);
		opList.add(oppObj);
		insert opList;
		Test.startTest();
		//Assertion Statements
		System.assertNotEquals(opList, null);
		System.assertEquals(accList.Size(), 10);
		System.assertEquals(conList.size(), 1);
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(opList);
		selectedSizeWorkaround ext = new selectedSizeWorkaround(stdSetController);
		ext.getMySelectedSize();
		ext.getMyRecordsSize();
		Test.stopTest();
	}
}