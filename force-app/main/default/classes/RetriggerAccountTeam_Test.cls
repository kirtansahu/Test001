// ===========================================================================
//  Object: RetriggerAccountTeam_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde
// Purpose: Unit Test Class for RetriggerAccountTeam_Batch.
// ===========================================================================
// Changes:
// ===========================================================================

@isTest
public class RetriggerAccountTeam_Test {
	@istest
	public static void accountTestMethod() {
		//insert the Users
		TestSetupDataUtil.insertUsers(2);
		//Ftech All User
		List<user> u = [SELECT Id, Name, isactive FROM User WHERE isactive = TRUE LIMIT 1];
		Set<id> keys = new Set<id>();
		for (User uu : u) {
			keys.add(uu.id);
		}
		//Assert Statements
		System.assertEquals(u.size(), 1);
		System.assertNotEquals(keys.size(), null);
		//insert Account Records
		TestSetupDataUtil.insertAccountRecords(2);
		List<Account> acc = [SELECT Id, Name FROM Account];
		//insert AccountTeam
		Account_Team__c a = new Account_Team__c(
			AccountId__c = acc[0].id,
			IsUserActive__c = true,
			AccountAccessLevel__c = 'manager',
			UserId__c = u[0].id,
			Position__c = 'sample'
		);
		insert a;
		//Assert Statements
		System.assertEquals(acc.Size(), 2);
		System.assertEquals(a.AccountId__c, acc[0].id);
		System.assertNotEquals(a.Id, null);
		RetriggerAccountTeam_Batch rat = new RetriggerAccountTeam_Batch();
		rat = new RetriggerAccountTeam_Batch(keys);

		test.startTest();
		DataBase.executeBatch(rat);
		system.schedule('Test retiggerBatch Check123', '0 0 0 3 9 ? 2022', new RetriggerAccountTeam_Schedule());
		Test.stopTest();
	}
}