// ===========================================================================
//  Object	: UserTriggerHandler_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Test class for UserTriggerHandler.
// ===========================================================================
@istest(SeeAllData=false)
public class UserTriggerHandler_Test {
	@istest
	public static void unitTest() {
		System.runAs(new User(Id = userInfo.getUserId())) {
			Map<Id, String> userTimeZoneMap = new Map<Id, String>();
			//Insert Users
			List<User> u = TestSetupDataUtil.insertUsers(2);
			//Assert Statements
			System.assertEquals(u.Size(), 2);
			Map<Id, User> userResult = new Map<id, User>();
			for (user t : u) {
				userResult.put(t.id, t);
				userTimeZoneMap.put(t.Id, t.TimeZoneSidKey);
			}

			List<BigMachines__Oracle_User__c> lstBigMachinesOracleUser = new List<BigMachines__Oracle_User__c>();
			BigMachines__Oracle_User__c oBigMachinesOracleUser = new BigMachines__Oracle_User__c();
			oBigMachinesOracleUser.BigMachines__Time_Zone__c = userTimeZoneMap.get(UserInfo.getUserId());
			oBigMachinesOracleUser.BigMachines__Salesforce_User__c = UserInfo.getUserId();
			lstBigMachinesOracleUser.add(oBigMachinesOracleUser);

			UserTriggerHandler.oracleUserSync(u, userResult);
			UserTriggerHandler.oracleUserSync(u, null);
			UserTriggerHandler.getOracleUsers(userTimeZoneMap);
			UserTriggerHandler.fetchOracleUsersToUpdate(lstBigMachinesOracleUser, userTimeZoneMap);
			UserTriggerHandler.getOracleUsersWithMatchTimeZone(userTimeZoneMap);
		}
	}
	@istest
	public static void unit_Test() {
		System.runAs(new User(Id = userInfo.getUserId())) {
			Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
			User u1 = new User(
				LastName = 'Test 1',
				Email = 'test1@test.com',
				Username = 'Test_test' + System.now().getTime() + '@test.com',
				Alias = 'test1',
				ProfileId = profileId,
				TimeZoneSidKey = 'America/Los_Angeles',
				IsActive = false,
				EmailEncodingKey = 'UTF-8',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US'
			);
			insert u1;
			//Assert Statement
			System.assertNotEquals(u1.Id, null);
			System.assertEquals(u1.ProfileId, profileId);
			List<User> userlist = [
				SELECT Id, Name, Isactive, LanguageLocaleKey, TimeZoneSidKey
				FROM User
				WHERE Id = :u1.Id
			];
			userlist[0].LanguageLocaleKey = 'en_US';
			userlist[0].isactive = true;
			update userlist;
			//Assert Statements
			System.assertEquals(userlist[0].LanguageLocaleKey, 'en_US');
			System.assertEquals(userlist[0].isactive, true);
			System.assertNotEquals(userlist.size(), null);
			map<id, User> result = new Map<Id, User>();
			for (User u : userlist) {
				result.put(u.id, u);
			}
			UserTriggerHandler.oracleUserSync(userlist, Result);
		}
	}
}