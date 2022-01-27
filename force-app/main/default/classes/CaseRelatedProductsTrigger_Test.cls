/***************************************************************************************
 * @description: This is used as test class for CaseRelatedProductsTrigger and its handler
 * @company: Keste Dev
 * @author: Adarsh Sharma
 * @date: 28 Jan, 2020
 ***************************************************************************************/
@isTest
public class CaseRelatedProductsTrigger_Test {
	@testSetup
	public static void createTestData() {
		Account oAccount = new Account();
		oAccount.Name = 'Site SGN';
		oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		oAccount.Unique_Id__c = '1004';
		oAccount.Parent_Unique_Id__c = '1003';
		oAccount.Primary_Bill_To_Unique_Id__c = '1005';
		oAccount.Child_Unique_Id__c = '1006';
		oAccount.BillingCountryCode = 'US';
		oAccount.Exclude_From_Hierarchy__c = true;
		insert oAccount;

		Contact oContact = new Contact();
		oContact.AccountId = oAccount.Id;
		oContact.FirstName = 'Test';
		oContact.LastName = 'Test';
		oContact.Email = 'test@test.com';
		insert oContact;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.ContactId = oContact.Id;
		oCase.AccountId = oAccount.Id;
		oCase.Origin = 'Email';
		insert oCase;

		List<Product2> lstProduct = new List<Product2>();
		Product2 oProduct;
		oProduct = new Product2();
		oProduct.Name = 'Test';
		oProduct.Unique_Id__c = 'test1';
		lstProduct.add(oProduct);
		oProduct = new Product2();
		oProduct.Name = 'Test New';
		oProduct.Unique_Id__c = 'test2';
		lstProduct.add(oProduct);
		insert lstProduct;
	}

	@isTest
	public static void testPrimaryCaseRelatedProducts() {
		Case oCase = [SELECT ID, Primary_Product__c FROM Case];
		system.assertEquals(null, oCase.Primary_Product__c);
		List<Product2> lstProduct = [SELECT Id, Name FROM Product2];

		Test.startTest();
		//Create Case Related Product Records
		List<Case_Related_Products__c> lstCaseRelatedProducts = new List<Case_Related_Products__c>();
		Case_Related_Products__c oCaseRelatedProducts;
		oCaseRelatedProducts = new Case_Related_Products__c();
		oCaseRelatedProducts.Case__c = oCase.Id;
		oCaseRelatedProducts.Primary__c = false;
		oCaseRelatedProducts.Product__c = lstProduct[0].Id;
		lstCaseRelatedProducts.add(oCaseRelatedProducts);
		insert lstCaseRelatedProducts;

		lstCaseRelatedProducts = [SELECT Id, Primary__c FROM Case_Related_Products__c];
		System.assertEquals(true, lstCaseRelatedProducts[0].Primary__c);

		lstCaseRelatedProducts = new List<Case_Related_Products__c>();
		oCaseRelatedProducts = new Case_Related_Products__c();
		oCaseRelatedProducts.Case__c = oCase.Id;
		oCaseRelatedProducts.Primary__c = false;
		oCaseRelatedProducts.Product__c = lstProduct[1].Id;
		lstCaseRelatedProducts.add(oCaseRelatedProducts);
		insert lstCaseRelatedProducts;

		lstCaseRelatedProducts = [SELECT Id, Primary__c FROM Case_Related_Products__c];
		System.assertEquals(true, lstCaseRelatedProducts[0].Primary__c);

		Test.stopTest();
	}

	@isTest
	public static void testPopulateCasePrimaryProduct() {
		Case oCase = [SELECT ID, Primary_Product__c FROM Case];
		system.assertEquals(null, oCase.Primary_Product__c);
		List<Product2> lstProduct = [SELECT Id, Name FROM Product2];

		Test.startTest();
		//Create Case Related Product Records
		List<Case_Related_Products__c> lstCaseRelatedProducts = new List<Case_Related_Products__c>();
		Case_Related_Products__c oCaseRelatedProducts;
		oCaseRelatedProducts = new Case_Related_Products__c();
		oCaseRelatedProducts.Case__c = oCase.Id;
		oCaseRelatedProducts.Primary__c = false;
		oCaseRelatedProducts.Product__c = lstProduct[0].Id;
		oCaseRelatedProducts.E1_Complaint_Product__c = true;
		lstCaseRelatedProducts.add(oCaseRelatedProducts);
		oCaseRelatedProducts = new Case_Related_Products__c();
		oCaseRelatedProducts.Case__c = oCase.Id;
		oCaseRelatedProducts.Primary__c = false;
		oCaseRelatedProducts.Product__c = lstProduct[1].Id;
		lstCaseRelatedProducts.add(oCaseRelatedProducts);
		insert lstCaseRelatedProducts;

		lstCaseRelatedProducts = [SELECT Id, Primary__c, Product__c FROM Case_Related_Products__c];
		System.assertEquals(true, lstCaseRelatedProducts[0].Primary__c);
		System.assertEquals(false, lstCaseRelatedProducts[1].Primary__c);

		oCase = [SELECT ID, Primary_Product__c FROM Case];
		System.assertEquals(oCase.Primary_Product__c, lstCaseRelatedProducts[0].Product__c);
		System.assertNotEquals(oCase.Primary_Product__c, lstCaseRelatedProducts[1].Product__c);

		//Update Case Related Products
		lstCaseRelatedProducts[0].Primary__c = false;
		lstCaseRelatedProducts[1].Primary__c = true;
		update lstCaseRelatedProducts;

		oCase = [SELECT ID, Primary_Product__c FROM Case];
		System.assertEquals(oCase.Primary_Product__c, lstCaseRelatedProducts[1].Product__c);
		System.assertNotEquals(oCase.Primary_Product__c, lstCaseRelatedProducts[0].Product__c);

		try {
			//delete lstCaseRelatedProducts;
		} catch (Exception ex) {
		}

		lstCaseRelatedProducts[0].E1_Complaint_Product__c = false;
		lstCaseRelatedProducts[0].Primary__c = false;
		lstCaseRelatedProducts[1].E1_Complaint_Product__c = true;
		lstCaseRelatedProducts[1].Primary__c = true;
		update lstCaseRelatedProducts;

		lstCaseRelatedProducts[0].E1_Complaint_Product__c = false;
		lstCaseRelatedProducts[1].E1_Complaint_Product__c = false;
		update lstCaseRelatedProducts;
		delete lstCaseRelatedProducts;

		Test.stopTest();
	}
}