// ===========================================================================
//  Object	: PricingAgreementAccountSync_Test
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Unit Test Class for PricingAgreementAccountSync
// ===========================================================================

@isTest
public class PricingAgreementAccountSync_Test {

    @isTest
    public static void unitTest(){

        // Create Account
		Account oAccount1 = new Account();
        oAccount1.Name = 'Test Account #1';
        oAccount1.ERP_Account_Id__c = '123';
		oAccount1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get('Site SGN')
			.getRecordTypeId();
        insert oAccount1;

        Account oAccount2 = new Account();
        oAccount2.Name = 'Test Account #2';
        oAccount2.ERP_Account_Id__c = '456';
		oAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get('Ship To')
			.getRecordTypeId();
        insert oAccount2;

        Account oAccount3 = new Account();
        oAccount3.Name = 'Test Account #3';
        oAccount3.ERP_Account_Id__c = '789';
		oAccount3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get('National SGN')
			.getRecordTypeId();
        insert oAccount3;

        // Create Config Data
        BigMachines__Configuration_Record__c site = new BigMachines__Configuration_Record__c();
        site.BigMachines__bm_site__c = 'TEST';
        site.BigMachines__process_id__c = 'TEST';
        site.BigMachines__action_id_copy__c = 'TEST';
        site.BigMachines__action_id_open__c = 'TEST';
        site.BigMachines__document_id__c = 'TEST';
        site.BigMachines__version_id__c = 'TEST';
        site.BigMachines__process__c = 'TEST';
        site.BigMachines__Is_Active__c = true;
        site.BigMachines__Primary_Commerce_Process__c = true;
        insert site;

        // Insert Scenario
        BigMachines__Quote__c oQuote1 = new BigMachines__Quote__c();
        oQuote1.BigMachines__Account__c = oAccount1.Id;
        oQuote1.BigMachines__Site__c = site.Id;
        oQuote1.BigMachines_Quote_Type__c = 'E';
        oQuote1.Selected_SGN_s__c = '123';
        oQuote1.Selected_Ship_To_s__c = '456';
        insert oQuote1;

        // Update Scenario
        BigMachines__Quote__c oQuote2 = new BigMachines__Quote__c();
        oQuote2.BigMachines__Account__c = oAccount2.Id;
        oQuote2.BigMachines__Site__c = site.Id;
        oQuote2.BigMachines_Quote_Type__c = 'E';
        oQuote2.Selected_SGN_s__c = '';
        oQuote2.Selected_Ship_To_s__c = '';
        insert oQuote2;

        // Existing Data
        Account_Quote__c testObj = new Account_Quote__c(QuoteId__c = oQuote2.Id, AccountId__c = oAccount3.Id);
        insert testObj;

        oQuote2.Selected_SGN_s__c = '123';
        oQuote2.Selected_Ship_To_s__c = '456';
        update oQuote2;

        // Delete Data
        oQuote2.BigMachines__Status__c = 'Deleted';
        update oQuote2;

    }
}