// ==============================================================================================
//  Class Name  			 : QuoteProductSyncController_Test
//  Realted Controller Name  : QuoteProductSyncController
//  Company     			 : Keste @ IDC
//  Author     				 : Jayaram Bevara
//  Purpose     			 : Unit test class for QuoteProductSyncController
// ==============================================================================================
@isTest
public class QuoteProductSyncController_Test {
	@testSetup
	public static void testSetupMethod() {
		//Insert Account Records
		List<Account> Accs = TestSetupDataUtil.insertAccountRecords(10);
		//Insert Contact Records
		List<Contact> conList = TestSetupDataUtil.insertContactRecordswithAcc(3, Accs);
		//Crete Custom Setting records
		Organization_Group_Division__c obj = new Organization_Group_Division__c();
		obj.Group_Division__c = 'LSG';
		obj.Name = 'Asian Organization';
		insert obj;
		//Insert Pricebook record
		Id pricebookId = Test.getStandardPricebookId();
		Pricebook2 oPricebook = new Pricebook2();
		oPricebook.Name = 'test';
		oPricebook.Currency_Code__c = 'USD';
		oPricebook.IsActive = true;
		insert oPricebook;
		//Insert Product record
		Product2 prod = new Product2(
			Name = 'Product X',
			ProductCode = 'PX_S',
			Group_Division__c = '  LSG',
			Unique_Id__c = '123',
			isActive = true
		);
		insert prod;

		//Insert PricebookEntry records
		PricebookEntry pbEntry = new PricebookEntry(
			Pricebook2Id = pricebookId,
			Product2Id = prod.Id,
			UnitPrice = 100.00,
			IsActive = true
		);
		insert pbEntry;

		PricebookEntry pbEntry1 = new PricebookEntry(
			Pricebook2Id = oPricebook.Id,
			Product2Id = prod.Id,
			UnitPrice = 100.00,
			IsActive = true
		);
		insert pbEntry1;

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

		//insert opportunityLineItem
		OpportunityLineItem oli = new OpportunityLineItem(
			OpportunityId = Opp.Id,
			Quantity = 5,
			Product2Id = prod.Id,
			PricebookEntryId = pbEntry1.Id,
			TotalPrice = 5 * pbEntry.UnitPrice
		);
		insert oli;
		//Assert Statements
		System.assertEquals(Accs.Size(), 10);
		System.assertEquals(conList.Size(), 3);
		System.assertNotEquals(Opp.Id, null);

		//insert Big Machine Configuration Record
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
		//insert Big Machine Quote Record
		BigMachines__Quote__c objBigMechInst = new BigMachines__Quote__c();
		objBigMechInst.BigMachines__Opportunity__c = Opp.Id;
		objBigMechInst.Siebel_Quote_Number__c = '8990088';
		objBigMechInst.BigMachines__Site__c = BCR.Id;
		objBigMechInst.Quote_Revenue__c = 100;
		insert objBigMechInst;
		//insert Big Machine Quote Product Record
		BigMachines__Quote_Product__c objBigMachQouProInst = new BigMachines__Quote_Product__c();
		objBigMachQouProInst.BigMachines__Quote__c = objBigMechInst.Id;
		objBigMachQouProInst.BigMachines__Product__c = prod.Id;
		objBigMachQouProInst.BigMachines__Description__c = 'GOAT SERUM';
		objBigMachQouProInst.BigMachines__Quantity__c = 1;
		objBigMachQouProInst.BigMachines__Sales_Price__c = 10;
		insert objBigMachQouProInst;
	}
	@isTest
	public static void doInitTestMethod() {
		BigMachines__Quote__c bigMechRecData = [
			SELECT Id, Siebel_Quote_Number__c
			FROM BigMachines__Quote__c
			WHERE Siebel_Quote_Number__c = '8990088'
			LIMIT 1
		];
		System.assertEquals(bigMechRecData.Siebel_Quote_Number__c, '8990088');
		QuoteProductSyncController.doInit(bigMechRecData.Id);
	}
	@isTest
	public static void opportunityProductDataTestMethod() {
		Opportunity oppRecData = [
			SELECT Id, Siebel_Quote_Number__c
			FROM Opportunity
			WHERE Siebel_Quote_Number__c = '9008665'
			LIMIT 1
		];
		System.assertEquals(oppRecData.Siebel_Quote_Number__c, '9008665');
		QuoteProductSyncController.opportunityProductData(oppRecData.Id);
	}
	@isTest
	public static void upsertOpportunityProductsTestMethod() {
		List<BigMachines__Quote_Product__c> quoteProductRecords = [
			SELECT Id, BigMachines__Description__c
			FROM BigMachines__Quote_Product__c
			WHERE BigMachines__Description__c = 'GOAT SERUM'
		];
		System.assertEquals(quoteProductRecords[0].BigMachines__Description__c, 'GOAT SERUM');
		Opportunity oppRecData = [SELECT Id FROM Opportunity WHERE Siebel_Quote_Number__c = '9008665' LIMIT 1];
		QuoteProductSyncController.upsertOpportunityProducts(quoteProductRecords, oppRecData.Id);
	}
}