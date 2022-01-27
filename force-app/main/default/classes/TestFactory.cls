@isTest
public class TestFactory {
	@isTest
	public static void getSupportRequest() {
		Support_Request__c SR = new Support_Request__c(
			Status__c = 'New',
			Subject__c = 'Test Subject',
			Salesforce_Issue__c = 'Account',
			Issue_Detail__c = 'Data Load',
			Region__c = 'NA',
			Assigned_To__c = 'Michele Lydecker'
		);
		insert SR;

		SR.Assigned_To__c = '';
		update SR;

		SR.Assigned_To__c = 'Michele Lydecker';
		update SR;
	}
}