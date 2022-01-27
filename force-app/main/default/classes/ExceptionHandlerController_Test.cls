// ===========================================================================
//  Object: ExceptionHandlerController_Test
//  Company: Keste @IDC
//  Author: Rambabu Gadde
//  Purpose: unit Test class for ExceptionHandlerController.
// ===========================================================================

@istest
public class ExceptionHandlerController_Test {
	@istest
	public static void unitTest() {
		//create Apex log
		Apex_Log__c aa = new Apex_Log__c(
			Application_Name__c = 'Trigger Logic',
			Location__c = 'UserTriggerHandler',
			Fixed_Date__c = System.now(),
			Error_Description__c = 'failed data',
			Log_Comments__c = 'Update Account Team',
			Error_Message__c = 'Update failed. First exception on row 0 with id a0K0j000001L7UzEAK; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Record cannot be Edited: []',
			Integration_Request__c = '',
			Integration_Response__c = '',
			Method_Name__c = 'triggerAccountTeamMember'
		);
		insert aa;
		//Assert Statement
		System.assertNotEquals(aa.Id, null);
		test.startTest();
		ExceptionHandlerController.createException(
			aa.Location__c,
			aa.Method_Name__c,
			'Apex Class',
			aa.Log_Comments__c,
			'Update failed. First exception on row 0 with id a0K0j000001L7UzEAK; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Record cannot be Edited: []',
			aa.Fixed_Date__c
		);
		ExceptionHandlerController.createIntegrationException(
			aa.Location__c,
			aa.Method_Name__c,
			'ApexClass',
			aa.Log_Comments__c,
			'Update failed. First exception on row 0 with id a0K0j000001L7UzEAK; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Record cannot be Edited: [] Update failed. First exception on row 0 with id a0K0j000001L7UzEAK; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Record cannot be Edited: []',
			aa.Fixed_Date__c,
			'200',
			'20033',
			'completed'
		);
		ExceptionHandlerController.createIntegrationException(
			aa.Location__c,
			aa.Method_Name__c,
			'ApexClass',
			'Testingdata Testingdata Testingdata Testingdata TestingdataTestingdataTestingdata Testingdata Testingdata TestingdataTestingdata Testingdata Testingdata TestingdataTestingdataTestingdata Testingdata Testingdata Testingdata Testingdata Testingdata Testingdata ',
			'Update failed. First exception on row 0 with id a0K0j000001L7UzEAK; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Record cannot be Edited: [] Update failed. First exception on row 0 with id a0K0j000001L7UzEAK; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Record cannot be Edited: []',
			aa.Fixed_Date__c,
			'200',
			'{"Status" : "Error","ExternalId" : "null","Error" : "ErrorComponen SBL-EAI-04397)", "TransactionId" : "2580927"}',
			'completed'
		);
		test.stopTest();
	}
}