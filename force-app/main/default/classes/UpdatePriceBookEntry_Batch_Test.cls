// ===========================================================================
//  Object  : UpdatePriceBookEntry_Batch_Test
//  Company : Keste @IDC
//  Author  : Rambabu Gadde
//  Purpose : Unit Test Class for UpdatePriceBookEntry_Batch And UpdatePriceBookEntry_Schedule.
// ===========================================================================
@isTest
public class UpdatePriceBookEntry_Batch_Test {
	@isTest
	public static void test1() {
		//create product
		Product2 p = new Product2();
		p.Name = 'testproduct';
		insert p;
		Product2 p1 = new Product2(name = 'testData');
		insert p1;

		Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);

		Id pricebookId = Test.getStandardPricebookId();

		Pricebook2 oPricebook = new Pricebook2();
		oPricebook.Name = 'test';
		oPricebook.Currency_Code__c = 'USD';
		oPricebook.IsActive = true;
		insert oPricebook;

		PricebookEntry standardPrice = new PricebookEntry(
			Pricebook2Id = standardPB.Id,
			CurrencyIsoCode = 'USD',
			Product2Id = p.Id,
			UnitPrice = 10000,
			IsActive = true,
			UseStandardPrice = false
		);
		insert standardPrice;
		//Assert Statements
		System.assertNotEquals(oPricebook.Id, null);
		System.assertNotEquals(p1.Id, null);

		PricebookEntry standardPriceP1 = new PricebookEntry(
			Pricebook2Id = standardPB.Id,
			CurrencyIsoCode = 'USD',
			Product2Id = p1.Id,
			UnitPrice = 10000,
			IsActive = true,
			UseStandardPrice = false
		);
		insert standardPriceP1;

		//create pricebookEntry
		PricebookEntry standardPrice1 = new PricebookEntry(
			Pricebook2Id = oPricebook.id,
			Product2Id = p.Id,
			UnitPrice = 100,
			CurrencyIsoCode = 'USD',
			IsActive = true
		);
		insert standardPrice1;

		//Assert Statements
		System.assertEquals(standardPrice1.Pricebook2Id, oPricebook.Id);
		System.assertNotEquals(standardPrice1.Id, null);

		//create priceBook
		Id standardPriceBookId = Test.getStandardPricebookId();

		list<Price_Book_Entry__c> pricebooklist = new List<Price_Book_Entry__c>();
		for (Integer i = 0; i < 100; i++) {
			Price_Book_Entry__c pricebook = new Price_Book_Entry__c();
			pricebook.Name = 'testpricebook' + i;
			pricebook.Start_Date__c = Date.today();
			pricebook.End_Date__c = Date.today() + 30;
			pricebook.List_Price__c = 100;
			// change product
			pricebook.Product__c = p.Id;
			pricebook.Price_Book__c = oPricebook.Id;
			pricebooklist.add(pricebook);
		}

		list<Price_Book_Entry__c> pricebooklist1 = new List<Price_Book_Entry__c>();
		for (Integer i = 0; i < 100; i++) {
			Price_Book_Entry__c pricebook = new Price_Book_Entry__c();
			pricebook.Name = 'testpricebook' + i;
			pricebook.Start_Date__c = Date.today();
			pricebook.End_Date__c = Date.today() + 30;
			pricebook.List_Price__c = 100;
			// change product
			pricebook.Product__c = p1.Id;
			pricebook.Price_Book__c = oPricebook.Id;
			pricebooklist1.add(pricebook);
		}
		Database.insert(pricebooklist, false);
		Database.insert(pricebooklist1, false);
		//create Custom pricebook
		System.assertEquals(pricebooklist.Size(), 100);
		List<PriceBook2> pb = [SELECT Id FROM Pricebook2];
		Set<Id> keys = new Set<Id>();
		for (PriceBook2 p2 : pb) {
			keys.add(p2.id);
		}

		Test.startTest();
		UpdatePriceBookEntry_Batch obj = new UpdatePriceBookEntry_Batch(oPricebook.Id, keys);
		obj.createPricebookEntry(pricebooklist[0], pricebookList[0].Price_Book__c);
		DataBase.executeBatch(obj);
		Test.stopTest();
	}

	@isTest
	public static void testSchedule() {
		test.startTest();
		//create product
		Product2 p = new Product2();
		p.Name = 'testproduct';
		insert p;
		Product2 p1 = new Product2(name = 'testData');
		insert p1;

		Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);

		Id pricebookId = Test.getStandardPricebookId();

		List<Pricebook2> lstPricebook = new List<Pricebook2>();
		Pricebook2 oPricebook;
		oPricebook = new Pricebook2();
		oPricebook.Name = 'test';
		oPricebook.Currency_Code__c = 'USD';
		oPricebook.IsActive = true;
		lstPricebook.add(oPricebook);
		oPricebook = new Pricebook2();
		oPricebook.Name = 'test2';
		oPricebook.Currency_Code__c = 'USD';
		oPricebook.IsActive = true;
		lstPricebook.add(oPricebook);
		insert lstPricebook;

		PricebookEntry standardPrice = new PricebookEntry(
			Pricebook2Id = standardPB.Id,
			CurrencyIsoCode = 'USD',
			Product2Id = p.Id,
			UnitPrice = 10000,
			IsActive = true,
			UseStandardPrice = false
		);
		insert standardPrice;
		//Assert Statements
		System.assertNotEquals(oPricebook.Id, null);
		System.assertNotEquals(p1.Id, null);

		PricebookEntry standardPriceP1 = new PricebookEntry(
			Pricebook2Id = standardPB.Id,
			CurrencyIsoCode = 'USD',
			Product2Id = p1.Id,
			UnitPrice = 10000,
			IsActive = true,
			UseStandardPrice = false
		);
		insert standardPriceP1;

		//create pricebookEntry
		PricebookEntry standardPrice1 = new PricebookEntry(
			Pricebook2Id = lstPricebook[0].id,
			Product2Id = p.Id,
			UnitPrice = 100,
			CurrencyIsoCode = 'USD',
			IsActive = true
		);
		insert standardPrice1;

		//Assert Statements
		System.assertEquals(standardPrice1.Pricebook2Id, lstPricebook[0].Id);
		System.assertNotEquals(standardPrice1.Id, null);

		//create priceBook
		Id standardPriceBookId = Test.getStandardPricebookId();

		list<Price_Book_Entry__c> pricebooklist = new List<Price_Book_Entry__c>();
		for (Integer i = 0; i < 100; i++) {
			Price_Book_Entry__c pricebook = new Price_Book_Entry__c();
			pricebook.Name = 'testpricebook' + i;
			pricebook.Start_Date__c = Date.today();
			pricebook.End_Date__c = Date.today() + 30;
			pricebook.List_Price__c = 100;
			// change product
			pricebook.Product__c = p.Id;
			pricebook.Price_Book__c = lstPricebook[0].Id;
			pricebooklist.add(pricebook);
		}

		list<Price_Book_Entry__c> pricebooklist1 = new List<Price_Book_Entry__c>();
		for (Integer i = 0; i < 100; i++) {
			Price_Book_Entry__c pricebook = new Price_Book_Entry__c();
			pricebook.Name = 'testpricebook' + i;
			pricebook.Start_Date__c = Date.today();
			pricebook.End_Date__c = Date.today() + 30;
			pricebook.List_Price__c = 100;
			// change product
			pricebook.Product__c = p1.Id;
			pricebook.Price_Book__c = lstPricebook[0].Id;
			pricebooklist1.add(pricebook);
		}
		Database.insert(pricebooklist, false);
		Database.insert(pricebooklist1, false);
		//create Custom pricebook
		System.assertEquals(pricebooklist.Size(), 100);
		system.schedule('TestTerritoryCheck', '0 0 23 * * ?', new UpdatePriceBookEntry_Schedule());
		test.stopTest();
	}
}