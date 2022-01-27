// ===========================================================================
//  Object	: CreateAgreementVFController_Test
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Unit Test Class for CreateAgreementVFController
// ===========================================================================

@isTest
public class CreateAgreementVFController_Test {
	@isTest
	public static void unitTest() {
		// Create Account
		Account testRec = new Account();
		testRec.Name = 'Test Account';
		testRec.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get('Site SGN')
			.getRecordTypeId();
		insert testRec;

		// Create Quoute
		Apexpages.currentpage().getparameters().put('Id', testRec.id);
		Apexpages.StandardController scObj = new Apexpages.StandardController(
			testRec
		);
		CreateAgreementVFController apxObj = new CreateAgreementVFController(
			scObj
		);
		apxObj.stdCntrlr = testRec;
		apxObj.onLoad();
		apxObj.back();
	}

	@isTest
	public static void unitTest2() {
		// Create Oracle CPQ Cloud Site record
		BigMachines__Configuration_Record__c oracleConfigRec = new BigMachines__Configuration_Record__c();
		oracleConfigRec.BigMachines__bm_site__c = '01';
		oracleConfigRec.BigMachines__Connected_App_Name__c = 'Oracle_CPQ_Cloud';
		oracleConfigRec.BigMachines__process_id__c = '011';
		oracleConfigRec.BigMachines__action_id_copy__c = '022';
		oracleConfigRec.BigMachines__action_id_open__c = '033';
		oracleConfigRec.BigMachines__document_id__c = '004';
		oracleConfigRec.BigMachines__version_id__c = '005';
		oracleConfigRec.BigMachines__process__c = 'sample';
		oracleConfigRec.BigMachines__Primary_Commerce_Process__c = true;
		oracleConfigRec.BigMachines__Is_Active__c = true;
		insert oracleConfigRec;

		// Create Oracle User
		BigMachines__Oracle_User__c oracleUserRec = new BigMachines__Oracle_User__c();
		oracleUserRec.BigMachines__Allow_Quote_Creation__c = true;
		oracleUserRec.BigMachines__Provisioned__c = true;
		oracleUserRec.BigMachines__Salesforce_User__c = UserInfo.getUserId();
		oracleUserRec.BigMachines__User_Groups__c = 'SalesAgent';
		oracleUserRec.BigMachines__Oracle_CPQ_Cloud_Site__c = oracleConfigRec.Id;
		insert oracleUserRec;

		// Create Account
		Account testRec = new Account();
		testRec.Name = 'Test Account';
		testRec.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get('Site SGN')
			.getRecordTypeId();
		insert testRec;

		// Create Quoute
		Apexpages.currentpage().getparameters().put('Id', testRec.id);
		Apexpages.StandardController scObj = new Apexpages.StandardController(
			testRec
		);
		CreateAgreementVFController apxObj = new CreateAgreementVFController(
			scObj
		);
		apxObj.stdCntrlr = testRec;
		apxObj.onLoad();
		apxObj.back();
	}
}