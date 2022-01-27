// ===========================================================================
//  Object	: TerritoryAutomationRequest_Test
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Unit Test Class for TerritoryAutomationRequest_Schedulde
// ===========================================================================

@isTest
public with sharing class TerritoryAutomationRequest_Test {
	@isTest
	public static void unitTest() {
		// Create Request record
		Territory_Automation_Request__c testRec = new Territory_Automation_Request__c();
		testRec.Region__c = 'NA';
		testRec.Status__c = 'Submitted';
		testRec.Close_Date_From__c = System.today();
		testRec.Close_Date_To__c = System.today().addDays(1);
		testRec.Opportunity_Stage__c = 'New';
		testRec.Request_Type__c = 'Opportunity Realignment';
		insert testRec;

		Test.startTest();

		// Execute Schedulde Script
		System.schedule(
			'Territory Automation Requset',
			'0 15 0/1 1/1 * ? *',
			new TerritoryAutomationRequest_Schedulde()
		);

		Test.stopTest();
	}

	@isTest
	public static void unitTest2() {
		// Create Request record
		Territory_Automation_Request__c testRec = new Territory_Automation_Request__c();
		testRec.Region__c = 'NA';
		testRec.Status__c = 'Submitted';
		testRec.Existing_Owner__c = UserInfo.getUserId();
		testRec.New_Owner__c = UserInfo.getUserId();
		testRec.Territory_Label__c = 'Test';
		testRec.Request_Type__c = 'Opportunity Team Member Change';
		insert testRec;

		Test.startTest();

		// Execute Schedulde Script
		System.schedule(
			'Territory Automation Requset',
			'0 15 0/1 1/1 * ? *',
			new TerritoryAutomationRequest_Schedulde()
		);

		Test.stopTest();
	}

	@isTest
	public static void unitTest3() {
		// Create Request record
		Territory_Automation_Request__c testRec = new Territory_Automation_Request__c();
		testRec.Region__c = 'NA';
		testRec.Status__c = 'Submitted';
		testRec.Request_Type__c = 'Territory Hierarchy Sync';
		insert testRec;

		Test.startTest();

		// Execute Schedulde Script
		System.schedule(
			'Territory Automation Requset',
			'0 15 0/1 1/1 * ? *',
			new TerritoryAutomationRequest_Schedulde()
		);

		Test.stopTest();
	}

	@isTest
	public static void unitTest4() {
		// Create Request record
		Territory_Automation_Request__c testRec = new Territory_Automation_Request__c();
		testRec.Region__c = 'NA';
		testRec.Status__c = 'Submitted';
		testRec.Request_Type__c = 'Territory Rule Sync';
		insert testRec;

		Test.startTest();

		// Execute Schedulde Script
		System.schedule(
			'Territory Automation Requset',
			'0 15 0/1 1/1 * ? *',
			new TerritoryAutomationRequest_Schedulde()
		);

		Test.stopTest();
	}
}