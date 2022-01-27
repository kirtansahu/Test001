@isTest
private class SuperPriceBookRequest_Scheduler_Test {
	@testSetup
	public static void createTestData() {
		Super_Price_Book_Request__c oSuperPriceBookRequest = new Super_Price_Book_Request__c();
		oSuperPriceBookRequest.Region__c = 'AP';
		oSuperPriceBookRequest.Requestor_Approver_Name__c = 'AD';
		oSuperPriceBookRequest.Super_Pricebook_Name__c = 'AD TEST US';
		oSuperPriceBookRequest.Country__c = 'United States';
		oSuperPriceBookRequest.isActive__c = true;
		insert oSuperPriceBookRequest;

		Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);

		Id pricebookId = Test.getStandardPricebookId();

		PriceBook2 oPriceBook = new PriceBook2();
		oPriceBook.Name = 'Test';
		oPriceBook.IsActive = true;
		oPriceBook.CurrencyIsoCode = 'USD';
		oPriceBook.Currency_Code__c = 'USD';
		oPriceBook.Source_System__c = ' E1';
		insert oPriceBook;

		Product2 p = new Product2();
		p.Name = 'testproduct';
		insert p;

		PricebookEntry standardPrice = new PricebookEntry();
		standardPrice.Pricebook2Id = standardPB.Id;
		standardPrice.CurrencyIsoCode = 'USD';
		standardPrice.Product2Id = p.Id;
		standardPrice.UnitPrice = 10000;
		standardPrice.IsActive = true;
		standardPrice.UseStandardPrice = false;
		insert standardPrice;

		PricebookEntry customPrice = new PricebookEntry();
		customPrice.Pricebook2Id = oPriceBook.Id;
		customPrice.CurrencyIsoCode = 'USD';
		customPrice.Product2Id = p.Id;
		customPrice.UnitPrice = 10000;
		customPrice.IsActive = true;
		customPrice.UseStandardPrice = false;
		insert customPrice;

		Related_Pricebook__c oRelatedPricebook = new Related_Pricebook__c();
		oRelatedPricebook.Super_Price_Book_Request__c = oSuperPriceBookRequest.Id;
		oRelatedPricebook.Price_Book__c = oPriceBook.Id;
		oRelatedPricebook.isActive__c = true;
		insert oRelatedPricebook;
	}

	static testMethod void myUnitTest() {
		PriceBook2 oPriceBook = [SELECT Id FROM PriceBook2 WHERE Name = 'Test'];
		Super_Price_Book_Request__c oSuperPriceBook = [SELECT Id, Super_Pricebook__c FROM Super_Price_Book_Request__c];

		Integer superPBECount = 0;
		superPBECount = [SELECT COUNT() FROM PricebookEntry WHERE Pricebook2Id = :oSuperPriceBook.Super_Pricebook__c];
		Integer nativePBECount = 0;
		nativePBECount = [SELECT COUNT() FROM PricebookEntry WHERE Pricebook2Id = :oPriceBook.Id];
		System.assertNotEquals(nativePBECount, superPBECount);

		Test.startTest();
		system.schedule('TestSuperPriceBookRequestBatch', '0 0 23 * * ?', new SuperPriceBookRequest_Scheduler());
		Test.stopTest();
	}

	static testMethod void testExistingPBEForSuperPricebook() {
		Super_Price_Book_Request__c superPriceBookObj = [
			SELECT Id, Super_Pricebook_Name__c, Super_Pricebook__c, Super_Pricebook__r.Name
			FROM Super_Price_Book_Request__c
		];
		PriceBook2 oPriceBook = [SELECT Id FROM PriceBook2 WHERE Name = 'Test'];
		Product2 p = [SELECT id FROM Product2];

		PricebookEntry customPrice = new PricebookEntry();
		customPrice.Pricebook2Id = superPriceBookObj.Super_Pricebook__c;
		customPrice.CurrencyIsoCode = 'USD';
		customPrice.Product2Id = p.Id;
		customPrice.UnitPrice = 10000;
		customPrice.IsActive = true;
		customPrice.UseStandardPrice = false;
		insert customPrice;

		Integer superPBECount = 0;
		superPBECount = [SELECT COUNT() FROM PricebookEntry WHERE Pricebook2Id = :superPriceBookObj.Super_Pricebook__c];
		Integer nativePBECount = 0;
		nativePBECount = [SELECT COUNT() FROM PricebookEntry WHERE Pricebook2Id = :oPriceBook.Id];
		System.assertEquals(nativePBECount, superPBECount);

		Test.startTest();
		system.schedule('TestSuperPriceBookRequestBatch', '0 0 23 * * ?', new SuperPriceBookRequest_Scheduler());
		Test.stopTest();
	}
}