// ===========================================================================
//  Object  : RelatedPricebookTrigger_Test
//  Company : Keste @IDC
//  Purpose : Unit Test Class for RelatedPricebookTrigger and its handler.
// ===========================================================================
@isTest
public class RelatedPricebookTrigger_Test {
	static testMethod void unitTest() {
		Test.startTest();
		Super_Price_Book_Request__c oSuperPriceBookRequest = new Super_Price_Book_Request__c();
		oSuperPriceBookRequest.Region__c = 'AP';
		oSuperPriceBookRequest.Requestor_Approver_Name__c = 'AD';
		oSuperPriceBookRequest.Super_Pricebook_Name__c = 'AD TEST US';
		oSuperPriceBookRequest.Country__c = 'United States';
		oSuperPriceBookRequest.isActive__c = true;
		insert oSuperPriceBookRequest;

		Set<Id> setRelatedPricebook = new Set<Id>();
		for (Related_Pricebook__c oRelatedPricebook : [
			SELECT ID, Price_Book__c
			FROM Related_Pricebook__c
			WHERE Super_Price_Book_Request__c = :oSuperPriceBookRequest.Id
		]) {
			setRelatedPricebook.add(oRelatedPricebook.Price_Book__c);
		}
		List<PricebookEntry> lstPricebookEntry = new List<PricebookEntry>();
		for (PricebookEntry oPricebookEntry : [
			SELECT ID
			FROM PricebookEntry
			WHERE Pricebook2Id IN :setRelatedPricebook
		]) {
			lstPricebookEntry.add(oPricebookEntry);
		}
		system.assertEquals(0, lstPricebookEntry.size());

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

		oSuperPriceBookRequest.isActive__c = true;
		update oSuperPriceBookRequest;

		Related_Pricebook__c oRelatedPricebook = new Related_Pricebook__c();
		oRelatedPricebook.Super_Price_Book_Request__c = oSuperPriceBookRequest.Id;
		oRelatedPricebook.Price_Book__c = oPriceBook.Id;
		oRelatedPricebook.isActive__c = true;
		insert oRelatedPricebook;

		for (Related_Pricebook__c oRelatedPricebooks : [
			SELECT ID, Price_Book__c
			FROM Related_Pricebook__c
			WHERE Super_Price_Book_Request__c = :oSuperPriceBookRequest.Id
		]) {
			setRelatedPricebook.add(oRelatedPricebooks.Price_Book__c);
		}
		for (PricebookEntry oPricebookEntry : [
			SELECT ID
			FROM PricebookEntry
			WHERE Pricebook2Id IN :setRelatedPricebook
		]) {
			lstPricebookEntry.add(oPricebookEntry);
		}
		system.assertEquals(1, lstPricebookEntry.size());

		Test.stopTest();
	}
}