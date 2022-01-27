// =================================================================================================
//  Object: OpportunityTeamMemberTriggerHandler_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde
// Purpose: Unit Test Class for OpportunityTeamMemberTriggerHandler And OpportunityTeamMemberTrigger.
// =================================================================================================
// Changes:
// =================================================================================================

@istest
public class OpportunityTeamMemberTriggerHandler_Test {
	@istest
	public static void updateOpportunityOwnertest() {
		//create Account Record
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = RecordTypeId;
		a.ERP_Account_Id__c = '234';
		a.Unique_Id__c = 'test';
		insert a;
		List<Account> accList = TestSetupDataUtil.insertAccountRecords(2);
		List<Contact> lstContact = TestSetupDataUtil.insertContactRecordswithAcc(1, accList);
		List<user> uu = TestSetupDataUtil.insertUsers(2);
		uu[0].Primary_Position__c = 'test';
		uu[0].User_External_Id__c = '0101';
		update uu;
		//Assert Statements
		System.assertNotEquals(a.Id, null);
		System.assertEquals(lstContact.size(), 1);

		Opportunity opList = new Opportunity(
			Name = 'test',
			AccountId = a.id,
			closeDate = System.today(),
			Siebel_Row_Id__c = '4243',
			StageName = 'new',
			Confidence__c = '30%',
			Primary_Contact__c = lstContact[0].id
		);
		insert opList;
		System.assertNotEquals(opList.Id, null);
		System.assertEquals(opList.AccountId, a.Id);
		System.assertEquals(opList.Primary_Contact__c, lstContact[0].id);
		OpportunityTeamMember oOpportunityTeamMember = new OpportunityTeamMember();
		oOpportunityTeamMember.OpportunityId = opList.Id;
		oOpportunityTeamMember.UserId = userinfo.getUserId();
		oOpportunityTeamMember.OpportunityAccessLevel = 'Edit';
		oOpportunityTeamMember.TeamMemberRole = 'Sales Rep';
		oOpportunityTeamMember.isPrimary__c = true;
		insert oOpportunityTeamMember;

		//Assert Statement
		System.assertNotEquals(oOpportunityTeamMember.id, null);
		System.assert(oOpportunityTeamMember.OpportunityId == opList.Id);
		oOpportunityTeamMember.isPrimary__c = false;
		update oOpportunityTeamMember;

		//Assert Statements
		System.assertEquals(oOpportunityTeamMember.isPrimary__c, false);
		delete oOpportunityTeamMember;
	}
}