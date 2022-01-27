//===========================================================================
//  Object  :  AssetTriggerHandler_Test
//  Company  :  Keste @IDC
//  Author  :  Jayaram Bevara
//  Purpose  :  Unit Test Class for AssetTrigger
//===========================================================================
@isTest
private class AssetTriggerHandler_Test {
	// Method Name: testSetupMethod
	// Author: Jayaram.B
	// Description: Method to create Test Data to be used
	@testSetup
	public static void testSetupMethod() {
		//Insert Account Records
		List<Account> accList = TestSetupDataUtil.insertAccountRecords(1);
		//Insert Contact Records
		TestSetupDataUtil.insertContactRecordswithAcc(1, accList);
		List<Product2> lstProduct = new List<Product2>();
		Product2 oProduct = new Product2(Name = 'Test', Unique_Id__c = 'test1');
		lstProduct.add(oProduct);
		insert lstProduct;
	}
	// Method Name: deleteAssetRecordTest
	// Author: Jayaram.B
	// Description: Method to test Delete Logic of Asset Record
	@isTest
	public static void deleteAssetRecordTest() {
		//Fetch Inserted Account Records
		Account accObj = [SELECT Id, OwnerId FROM Account LIMIT 1];
		//Fetch Contact Records
		Contact conObj = [SELECT Id, AccountId, OwnerId FROM Contact LIMIT 1];
		//Insert Asset Record
		Asset assetRec = new Asset(AccountId = accObj.Id, ContactId = conObj.Id, Name = 'Test123456');
		insert assetRec;
		//Delete Asset Record
		try {
			delete assetRec;
		} catch (DmlException e) {
		}
	}
	// Method Name: updateAccountBackendFieldTest
	// Author: Jayaram.B
	// Description: Method to test Backend Field Update Logic of Asset Record
	@isTest
	public static void updateAccountBackendFieldTest() {
		//Fetch Inserted Account Records
		List<Account> accObj = [SELECT Id, Name, OwnerId FROM Account];
		//Fetch Contact Records
		List<Contact> conObj = [SELECT Id, LastName, FirstName, AccountId, OwnerId FROM Contact];
		//Fetch Prouct Records
		List<Product2> prodObj = [SELECT Id, Name, Unique_Id__c FROM Product2];
		//Create Account Record Map
		Map<Id, Account> accObjMap = new Map<Id, Account>([SELECT Id, Name, OwnerId FROM Account]);
		//Insert Asset Record
		Asset assetRec = new Asset(
			AccountId = accObj[0].Id,
			ContactId = conObj[0].Id,
			Product2Id = prodObj[0].Id,
			Name = 'Test123456'
		);
		insert assetRec;
		AssetTriggerHandler.updateBackendSearchFields(accObjMap, 'Account');
	}
	// Method Name: updateAccountBackendFieldTest
	// Author: Jayaram.B
	// Description: Method to test Backend Field Update Logic of Asset Record
	@isTest
	public static void updateContactBackendFieldTest() {
		//Fetch Inserted Account Records
		List<Account> accObj = [SELECT Id, Name, OwnerId FROM Account];
		//Fetch Contact Records
		List<Contact> conObj = [SELECT Id, LastName, FirstName, AccountId, OwnerId FROM Contact];
		//Fetch Prouct Records
		List<Product2> prodObj = [SELECT Id, Name, Unique_Id__c FROM Product2];
		//Create Contact Record Map
		Map<Id, Contact> conObjMap = new Map<Id, Contact>(
			[SELECT Id, LastName, FirstName, AccountId, OwnerId FROM Contact]
		);
		//Insert Asset Record
		Asset assetRec = new Asset(
			AccountId = accObj[0].Id,
			ContactId = conObj[0].Id,
			Product2Id = prodObj[0].Id,
			Name = 'Test123456'
		);
		insert assetRec;
		AssetTriggerHandler.updateBackendSearchFields(conObjMap, 'Contact');
	}
	// Method Name: updateProductBackendFieldTest
	// Author: Jayaram.B
	// Description: Method to test Backend Field Update Logic of Asset Record
	@isTest
	public static void updateProductBackendFieldTest() {
		//Fetch Inserted Account Records
		List<Account> accObj = [SELECT Id, Name, OwnerId FROM Account];
		//Fetch Contact Records
		List<Contact> conObj = [SELECT Id, LastName, FirstName, AccountId, OwnerId FROM Contact];
		//Fetch Prouct Records
		List<Product2> prodObj = [SELECT Id, Name, Unique_Id__c FROM Product2];
		//Create Product Record Map
		Map<Id, Product2> podObjMap = new Map<Id, Product2>([SELECT Id, Name, Unique_Id__c FROM Product2]);
		//Insert Asset Record
		Asset assetRec = new Asset(
			AccountId = accObj[0].Id,
			ContactId = conObj[0].Id,
			Product2Id = prodObj[0].Id,
			Name = 'Test123456'
		);
		insert assetRec;
		AssetTriggerHandler.updateBackendSearchFields(podObjMap, 'Product');
	}
}