// ===========================================================================
//  Object	: EmailMessageTriggerHandler_Test
// 	Company	: Keste @IDC
//  Author	: Adarsh Sharma
// 	Purpose	: Unit Test Class for EmailMessageTriggerHandler And EmailMessageTrigger.
// ===========================================================================
@isTest
public class EmailMessageTriggerHandler_Test {
	@testSetup
	public static void createTestData() {
		//Create Account Record
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

		//Create Contact Record
		Contact oContact = new Contact();
		oContact.AccountId = oAccount.Id;
		oContact.FirstName = 'Technical ';
		oContact.LastName = 'Service';
		oContact.Email = 'mastercontact@thermofisher.com';
		insert oContact;

		//Create Case Record
		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.ContactId = oContact.Id;
		oCase.AccountId = oAccount.Id;
		oCase.Origin = 'Email';
		insert oCase;

		Case_Assignment_Helper__c oCaseAssignmentHelper = new Case_Assignment_Helper__c();
		oCaseAssignmentHelper.Case_Origin__c = 'Queue';
		oCaseAssignmentHelper.Keywords__c = 'Test';
		oCaseAssignmentHelper.Email_Queue__c = 'Test';
		oCaseAssignmentHelper.Mailbox_Id__c = 'test@xyz.org';
		oCaseAssignmentHelper.Timezone__c = 'GMT';
		insert oCaseAssignmentHelper;

		//Create Case History Records
		List<CaseHistory> lstCaseHistory = new List<CaseHistory>();
		CaseHistory oCaseHistory;
		oCaseHistory = new CaseHistory();
		oCaseHistory.CaseId = oCase.Id;
		oCaseHistory.Field = 'Owner';
		lstCaseHistory.add(oCaseHistory);

		oCaseHistory = new CaseHistory();
		oCaseHistory.CaseId = oCase.Id;
		oCaseHistory.Field = 'Owner';
		lstCaseHistory.add(oCaseHistory);
		insert lstCaseHistory;
	}

	@isTest
	public static void testRecieverEmailQueueCase() {
		Case oCase = [SELECT ID, OwnerId FROM Case];

		EmailMessage oEmailMessage;
		oEmailMessage = new EmailMessage();
		oEmailMessage.FromAddress = 'test@abc.org';
		oEmailMessage.ToAddress = 'test@xyz.org;test@xyzq.com';
		oEmailMessage.Subject = 'Test email';
		oEmailMessage.HtmlBody = 'Test email body';
		oEmailMessage.ParentId = oCase.Id;
		oEmailMessage.Status = '0';
		oEmailMessage.Incoming = true;
		insert oEmailMessage;

		//Create EmailMessage Records
		EmailMessage oEmailMessage1 = new EmailMessage();
		oEmailMessage1.FromAddress = 'test@abc.org';
		oEmailMessage1.Incoming = true;
		oEmailMessage1.ToAddress = 'test@xyz.org;test@xyzq.com';
		oEmailMessage1.Subject = 'Test email';
		oEmailMessage1.HtmlBody = 'Test email body';
		oEmailMessage1.ParentId = oCase.Id;
		oEmailMessage1.Status = '0';
		oEmailMessage1.ReplyToEmailMessageId = oEmailMessage.Id;
		insert oEmailMessage1;

		delete oEmailMessage1;
	}

	@isTest
	public static void testfirstCaseAgentResponseTimeCalculation() {
		Case oCase = [SELECT ID, OwnerId, Status FROM Case];
		Case_Assignment_Helper__c oCaseAssignmentHelper = [
			SELECT Id, Timezone__c, Email_Queue__c
			FROM Case_Assignment_Helper__c
		];

		//Update Case OwnerId with current user
		oCase.OwnerId = UserInfo.getUserId();
		oCase.Email_Queue__c = oCaseAssignmentHelper.Email_Queue__c;
		update oCase;

		oCaseAssignmentHelper.Timezone__c = 'GMT';
		update oCaseAssignmentHelper;

		//Create EmailMessage Record
		EmailMessage email = new EmailMessage();
		email.FromAddress = 'test@abc.org';
		email.Incoming = true;
		email.ToAddress = 'test@xyz.org';
		email.Subject = 'Test email';
		email.HtmlBody = 'Test email body';
		//email.ParentId = oCase.Id;
		email.Status = '3';
		email.Incoming = false;
		insert email;

		//Create EmailMessage Record
		EmailMessage email1 = new EmailMessage();
		email1.FromAddress = 'test@abc.org';
		email1.Incoming = true;
		email1.ToAddress = 'test@xyz.org;test@xyzq.com';
		email1.Subject = 'Test email';
		email1.HtmlBody = 'Test email body';
		email1.ParentId = oCase.Id;
		email1.Status = '3';
		email1.ReplyToEmailMessageId = email.Id;
		email1.Incoming = false;
		insert email1;

		oCase.Status = 'Closed';
		oCase.Email_Queue__c = oCaseAssignmentHelper.Email_Queue__c;
		update oCase;

		try {
			delete email1;
		} catch (Exception ex) {
		}
	}

	@isTest
	public static void testRecieverEmailQueueCaseV2() {
		Case oCase = [SELECT ID, OwnerId FROM Case];

		EmailMessage oEmailMessage;
		oEmailMessage = new EmailMessage();
		oEmailMessage.FromAddress = 'test@abc.org';
		oEmailMessage.ToAddress = 'test@xyz.org';
		oEmailMessage.Subject = 'Test email';
		oEmailMessage.HtmlBody = 'Test email body';
		oEmailMessage.ParentId = oCase.Id;
		oEmailMessage.Status = '0';
		oEmailMessage.Incoming = true;
		insert oEmailMessage;

		//Create EmailMessage Records
		EmailMessage oEmailMessage1 = new EmailMessage();
		oEmailMessage1.FromAddress = 'test@abc.org';
		oEmailMessage1.Incoming = true;
		oEmailMessage1.ToAddress = 'test@xyz.org;test@xyzq.com';
		oEmailMessage1.Subject = 'Test email';
		oEmailMessage1.HtmlBody = 'Test email body';
		oEmailMessage1.ParentId = oCase.Id;
		oEmailMessage1.Status = '0';
		oEmailMessage1.ReplyToEmailMessageId = oEmailMessage.Id;
		insert oEmailMessage1;

		delete oEmailMessage1;
	}
}