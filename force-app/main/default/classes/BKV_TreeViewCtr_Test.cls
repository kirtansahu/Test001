// ===========================================================================
//  Object: BKV_TreeViewCtr_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde
// Purpose: Unit Test Class for ABKV_TreeViewCtr.
// ===========================================================================
// Changes:
// ===========================================================================

@istest
public class BKV_TreeViewCtr_Test {
	@istest
	// Method Name: buildTreeHirarchyTest
	// Author: Rambabu Gadde
	// Description: Method to test Insert Logic of TreeHirarchy
	//
	public static void buildTreeHirarchyTest() {
		//create User Role
		UserRole r = new UserRole(DeveloperName = 'MyCustomRole1', Name = 'My Role1', ParentRoleId = null);
		insert r;
		//Assert Statement
		System.assertNotEquals(r.Id, null);
		//create User
		User u = new User(
			ProfileId = [SELECT Id FROM Profile WHERE Name = 'system administrator']
			.Id,
			LastName = 'last',
			Email = 'puser000@amamama.com',
			Username = 'puser000@amamama.com' + System.currentTimeMillis(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			UserRoleId = r.Id
		);
		//Assert Statement
		System.assertEquals(u.UserRoleId, r.id);
		test.startTest();
		BKV_TreeViewCtr.buildTreeHirarchy();
		BKV_TreeViewCtr.deleteRole(r.id);
		BKV_TreeViewCtr.TreeHirarchy cc = new BKV_TreeViewCtr.TreeHirarchy('UNMATCHED', 'UNMATCHED', null, true);
		test.stopTest();
	}
}