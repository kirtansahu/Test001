// ===========================================================================
//  Object	: ModifyStandardAccountTeam_Batch_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Unit Test Class for ModifyStandardAccountTeam_Batch.
// ===========================================================================
@isTest
public class ModifyStandardAccountTeam_Batch_Test {
	@istest
	public static void unitTest() {
		//insert Account Record
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = RecordTypeId;
		a.Unique_Id__c = 'test';
		insert a;
		//insert AccountTeamMember
		AccountTeamMember atm = new AccountTeamMember();
		atm.AccountId = a.id;
		atm.AccountAccessLevel = 'read';
		atm.TeamMemberRole = 'manager';
		atm.UserId = userinfo.getUserId();
		insert atm;
		//assert Statements
		System.assertNotEquals(a.id, null);
		System.assertNotEquals(atm.Id, null);
		test.startTest();
		Set<id> keys = new Set<id>();
		keys.add(userinfo.getUserId());
		ModifyStandardAccountTeam_Batch msb = new ModifyStandardAccountTeam_Batch(keys);
		database.executeBatch(msb);
		test.stopTest();
	}
}