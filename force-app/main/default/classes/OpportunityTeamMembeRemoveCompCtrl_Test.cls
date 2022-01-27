/***************************************************************************************
 * @description: This is used as Test class for OpportunityTeamMemberRemoveCompCtrl apex
 * classs which is used as controller for remove current user from Opportunity Team Member
 * @author: Adarsh Sharma
 * @copyright: Keste Dev
 * @date: 23 March, 2020
 ***************************************************************************************/
@isTest
public class OpportunityTeamMembeRemoveCompCtrl_Test {
	@isTest
	public static void testRemoveOpportunityTeamMember() {
		//create Account Record
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		Account oAccount = new Account();
		oAccount.Name = 'Test Account';
		oAccount.RecordTypeId = RecordTypeId;
		oAccount.ERP_Account_Id__c = '234';
		oAccount.Unique_Id__c = 'test';
		insert oAccount;

		List<Contact> lstContact = TestSetupDataUtil.insertContactRecordswithAcc(1, new List<Account>{ oAccount });

		List<user> uu = TestSetupDataUtil.insertUsers(2);
		uu[0].Primary_Position__c = 'test';
		uu[0].User_External_Id__c = '0101';
		update uu;

		//Assert Statements
		System.assertNotEquals(oAccount.Id, null);
		System.assertEquals(lstContact.size(), 1);

		Opportunity opp = new Opportunity();
		opp.Name = 'test';
		opp.AccountId = oAccount.id;
		opp.closeDate = System.today();
		opp.Siebel_Row_Id__c = '4243';
		opp.StageName = 'new';
		opp.Confidence__c = '30%';
		opp.Primary_Contact__c = lstContact[0].id;
		insert opp;

		System.assertNotEquals(opp.Id, null);
		System.assertEquals(opp.AccountId, oAccount.Id);
		System.assertEquals(opp.Primary_Contact__c, lstContact[0].id);

		List<OpportunityTeamMember> lstOpportunityTeamMember = new List<OpportunityTeamMember>();
		OpportunityTeamMember oOpportunityTeamMember;
		oOpportunityTeamMember = new OpportunityTeamMember();
		oOpportunityTeamMember.OpportunityId = opp.Id;
		oOpportunityTeamMember.UserId = userinfo.getUserId();
		oOpportunityTeamMember.OpportunityAccessLevel = 'Edit';
		oOpportunityTeamMember.TeamMemberRole = 'Sales Rep';
		lstOpportunityTeamMember.add(oOpportunityTeamMember);

		oOpportunityTeamMember = new OpportunityTeamMember();
		oOpportunityTeamMember.OpportunityId = opp.Id;
		oOpportunityTeamMember.UserId = uu[0].Id;
		oOpportunityTeamMember.OpportunityAccessLevel = 'Edit';
		oOpportunityTeamMember.TeamMemberRole = 'Sales Rep';
		lstOpportunityTeamMember.add(oOpportunityTeamMember);
		insert lstOpportunityTeamMember;

		Test.startTest();
		OpportunityTeamMemberRemoveCompCtrl.fetchCurrentUserTeamMember(opp.Id);
		OpportunityTeamMemberRemoveCompCtrl.deleteOpportunityTeamMember(lstOpportunityTeamMember[1].Id);
		try {
			OpportunityTeamMemberRemoveCompCtrl.deleteOpportunityTeamMember(lstOpportunityTeamMember[0].Id);
		} catch (Exception ex) {
		}

		try {
			OpportunityTeamMemberRemoveCompCtrl.deleteOpportunityTeamMember(null);
		} catch (Exception ex) {
		}
		Test.stopTest();
	}
}