@isTest
public class AWS_S3_Utility_Test {
	@testSetup
	public static void createTestData() {
		Account oAccount;
		List<Account> lstAccount = new List<Account>();
		oAccount = new Account();
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
		lstAccount.add(oAccount);
		oAccount = new Account();
		oAccount.Name = 'Site NEW SGN';
		oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		oAccount.Unique_Id__c = '1007';
		oAccount.Parent_Unique_Id__c = '1008';
		oAccount.Primary_Bill_To_Unique_Id__c = '1009';
		oAccount.Child_Unique_Id__c = '10010';
		oAccount.BillingCountryCode = 'US';
		oAccount.Exclude_From_Hierarchy__c = true;
		lstAccount.add(oAccount);
		insert lstAccount;

		List<Contact> lstContact = new List<Contact>();
		Contact oContact;
		oContact = new Contact();
		oContact.AccountId = lstAccount[0].Id;
		oContact.FirstName = 'Technical ';
		oContact.LastName = 'Service';
		oContact.Email = 'mastercontact@thermofisher.com';
		lstContact.add(oContact);
		oContact = new Contact();
		oContact.AccountId = lstAccount[1].Id;
		oContact.FirstName = 'Test';
		oContact.LastName = 'New Account';
		oContact.Email = 'mastercontact@thermofisher.com';
		lstContact.add(oContact);
		insert lstContact;
	}

	@isTest
	public static void testValidCalloutForFetchFileFromURLs() {
		Test.setMock(HttpCalloutMock.class, new MockHTTPResponse(200, Blob.valueOf('test').toString()));

		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Email';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Status = 'New';
		oCase.Sub_Status__c = 'Unassigned';
		oCase.SuppliedEmail = 'mastercontact@thermofisher.com';
		oCase.Description = 'test';
		oCase.Subject = 'Test1 Case';
		oCase.Web_File_Name__c = 'test';
		oCase.Web_File_AWS_Integration_Status__c = 'New';
		insert oCase;

		Test.startTest();
		AWS_S3_Utility.fetchFileFromURLs(new Set<Id>{ oCase.Id });
		Test.stopTest();
	}

	@isTest
	public static void testInValidCalloutForFetchFileFromURLs() {
		Test.setMock(HttpCalloutMock.class, new MockHTTPResponse(400, Blob.valueOf('test').toString()));

		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Email';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Status = 'New';
		oCase.Sub_Status__c = 'Unassigned';
		oCase.SuppliedEmail = 'mastercontact@thermofisher.com';
		oCase.Description = 'test';
		oCase.Subject = 'Test1 Case';
		oCase.Web_File_Name__c = 'test';
		oCase.Web_File_AWS_Integration_Status__c = 'New';
		oCase.Web_File_URL__c = 'test';
		insert oCase;

		Test.startTest();
		AWS_S3_Utility.fetchFileFromURLs(new Set<Id>{ oCase.Id });
		Test.stopTest();
	}
}