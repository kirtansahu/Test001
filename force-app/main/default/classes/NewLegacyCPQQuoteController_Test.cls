// ===========================================================================
//  Object	: NewLegacyCPQQuoteController_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Unit Test Class for NewLegacyCPQQuoteController
// ===========================================================================
@istest
public class NewLegacyCPQQuoteController_Test {
	@istest
	public static void unitTest() {
		//Insert Account records
		List<Account> accList = TestSetupDataUtil.insertAccountRecords(10);
		//Insert Contact Records
		List<Contact> conList = TestSetupDataUtil.insertContactRecordswithAccount(3, accList);
		//Create Opportunity Record
		Opportunity oplist = new Opportunity(
			Name = 'test',
			Accountid = accList[0].id,
			CloseDate = System.today(),
			Siebel_Row_Id__c = '123',
			Primary_Contact__c = conList[0].id,
			StageName = 'New',
			Confidence__c = '70%',
			Reason_Won_Lost__c = 'Won/Lost - Price'
		);
		insert oplist;
		Test.startTest();
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(
			new List<Opportunity>{ oplist }
		);
		NewLegacyCPQQuoteController newController = new NewLegacyCPQQuoteController(stdSetController);
		newController.oppId = oplist.id;
		newController.onLoad();
		newController.back();
		Test.stopTest();
		//Assert Statements
		System.assertEquals(accList.size(), 10);
		System.assertEquals(conList.size(), 3);
		System.assertNotEquals(oplist.id, null);
	}
	@istest
	public static void unitTest_1() {
		//Insert Account records
		List<Account> accList = TestSetupDataUtil.insertAccountRecords(10);
		//Insert Contact Records
		List<Contact> conList = TestSetupDataUtil.insertContactRecordswithAccount(3, accList);
		//Create Opportunity Record
		Opportunity oplist = new Opportunity(
			Name = 'test',
			Accountid = accList[0].id,
			CloseDate = System.today(),
			Siebel_Row_Id__c = '123',
			Primary_Contact__c = conList[0].id,
			StageName = 'New',
			Confidence__c = '70%',
			Reason_Won_Lost__c = 'Won/Lost - Price'
		);
		insert oplist;
		Test.startTest();
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(
			new List<Opportunity>{ oplist }
		);
		NewLegacyCPQQuoteController newController = new NewLegacyCPQQuoteController(stdSetController);
		newController.oppId = null;
		newController.onLoad();
		apexpages.currentpage().getparameters().put('id', oplist.id);
		ApexPages.StandardSetController stdSetController1 = new ApexPages.StandardSetController(
			new List<Opportunity>{ oplist }
		);
		NewLegacyCPQQuoteController newController1 = new NewLegacyCPQQuoteController(stdSetController1);
		newController1.oppId = accList[0].id;
		newController1.onLoad();
		newController1.back();
		Test.stopTest();
		//Assert Statements
		System.assertEquals(accList.size(), 10);
		System.assertEquals(conList.size(), 3);
		System.assertNotEquals(oplist.id, null);
		System.assert(oplist.AccountId == accList[0].id);
	}
}