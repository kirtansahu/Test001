// ===========================================================================
//  Object  : CreateNewCaseOpportunityExtension_Test
//  Company : Keste @IDC
//  Author  : Adarsh Sharma
//  Purpose : Unit Test Class for CreateNewCaseOpportunityPage and its controller.
// ===========================================================================
@isTest
public class CreateNewCaseOpportunityExtension_Test {
	@isTest
	public static void unitTest() {
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
		oAccount.Account_Status__c = 'Active';
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
		System.assertEquals(null, oCase.Opportunity__c);

		Opportunity oppObj = new Opportunity();
		oppObj.Name = 'Test Opportunity';
		oppObj.CloseDate = System.today();
		oppObj.StageName = 'New';
		oppObj.Confidence__c = '10%';
		oppObj.AccountId = oAccount.Id;
		oppObj.Primary_Contact__c = oContact.id;

		PageReference pageRef = Page.CreateNewCaseOpportunityPage; // Add your VF page Name here
		pageRef.getParameters().put('id', String.valueOf(oCase.Id));
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController stdCon = new ApexPages.StandardController(oCase);
		CreateNewCaseOpportunityExtension oController = new CreateNewCaseOpportunityExtension(stdCon);
		oController.opp = oppObj;
		oController.createNewOpportunity();
		oCase = [SELECT Id, Opportunity__c FROM Case];
		oppObj = [SELECT Id FROM Opportunity];
		System.assertEquals(oppObj.Id, oCase.Opportunity__c);
		List<LayoutSection> layoutSections = oController.layoutSections;
		try {
			oController.opp = new Opportunity();
			oController.createNewOpportunity();
		} catch (Exception ex) {
		}

		try {
			oController.opp = null;
			oController.createNewOpportunity();
		} catch (Exception ex) {
		}
	}

	@isTest
	public static void unitTest_1() {
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

		Opportunity oppObj = new Opportunity();
		oppObj.Name = 'Test Opportunity';
		oppObj.CloseDate = System.today();
		oppObj.StageName = 'New';
		oppObj.Confidence__c = '10%';
		oppObj.AccountId = oAccount.Id;
		oppObj.Primary_Contact__c = oContact.id;
		insert oppObj;

		oCase.Opportunity__c = oppObj.Id;
		update oCase;

		PageReference pageRef = Page.CreateNewCaseOpportunityPage; // Add your VF page Name here
		pageRef.getParameters().put('id', String.valueOf(oCase.Id));
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController stdCon = new ApexPages.StandardController(oCase);
		CreateNewCaseOpportunityExtension oController = new CreateNewCaseOpportunityExtension(stdCon);
	}
}