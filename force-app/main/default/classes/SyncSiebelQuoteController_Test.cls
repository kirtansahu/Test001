// ===========================================================================
//	Object	: SyncSiebelQuoteController_Test
//	Company	: Keste @ IDC
//	Author	: Rambabu Gadde
//	Purpose	: Unit Test Class for SyncSiebelQuoteController.
// ===========================================================================
@isTest
public class SyncSiebelQuoteController_Test {
	@isTest
	public static void onLoadTest() {
		//Insert Account Records
		List<Account> Accs = TestSetupDataUtil.insertAccountRecords(10);
		//Insert Contact Records
		List<Contact> conList = TestSetupDataUtil.insertContactRecordswithAcc(3, Accs);
		//create Opportunity Record
		Opportunity Opp = new Opportunity();
		Opp.Name = Accs[0].Name;
		Opp.StageName = 'New';
		Opp.CloseDate = System.today();
		opp.Siebel_Quote_Number__c = '9008665';
		Opp.AccountId = Accs[0].Id;
		Opp.Primary_Contact__c = conList[0].id;
		Opp.Quote_Revenue__c = 100;
		insert Opp;
		//Assert Statements
		System.assertEquals(Accs.Size(), 10);
		System.assertEquals(conList.Size(), 3);
		System.assertNotEquals(Opp.Id, null);

		BigMachines__Configuration_Record__c BCR = new BigMachines__Configuration_Record__c();
		BCR.BigMachines__bm_site__c = 'Test BCR';
		BCR.BigMachines__process_id__c = '900098';
		BCR.BigMachines__action_id_copy__c = 'BER654';
		BCR.BigMachines__action_id_open__c = 'ACT778';
		BCR.BigMachines__document_id__c = 'DOC6654';
		BCR.BigMachines__version_id__c = 'VER0445';
		BCR.BigMachines__process__c = 'PVR5676';
		BCR.BigMachines__Is_Active__c = true;
		insert BCR;
		BigMachines__Quote__c BQ = new BigMachines__Quote__c();
		BQ.BigMachines__Opportunity__c = Opp.Id;
		BQ.Siebel_Quote_Number__c = '8990088';
		BQ.BigMachines__Site__c = BCR.Id;
		BQ.Quote_Revenue__c = 100;
		insert BQ;
		System.assertNotEquals(BQ.Id, null);
		System.assertEquals(BQ.BigMachines__Site__c, BCR.id);
		System.assertNotEquals(BCR.Id, null);
		apexpages.currentpage().getparameters().put('id', BQ.id);
		Apexpages.StandardController SC = new Apexpages.StandardController(BQ);
		SyncSiebelQuoteController SSQController = new SyncSiebelQuoteController(SC);
		SSQController.stdCntrlr = BQ;
		SSQController.onLoad();
		apexpages.currentpage().getparameters().put('id', null);
		Apexpages.StandardController SC1 = new Apexpages.StandardController(new BigMachines__Quote__c());
		SyncSiebelQuoteController SSQController1 = new SyncSiebelQuoteController(SC1);
		SSQController1.onLoad();
		apexpages.currentpage().getparameters().put('id', BCR.Id);
		Apexpages.StandardController SC3 = new Apexpages.StandardController(BCR);
		SyncSiebelQuoteController SSQController3 = new SyncSiebelQuoteController(SC3);
		SSQController3.onLoad();
		apexpages.currentpage().getparameters().put('id', null);
		Apexpages.StandardController SC2 = new Apexpages.StandardController(new BigMachines__Quote__c());
		SyncSiebelQuoteController SSQController2 = new SyncSiebelQuoteController(SC2);
		SSQController2.onLoad();
	}
}