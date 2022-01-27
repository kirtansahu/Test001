// ===========================================================================
//  Object: SyncWithSiebelInterfaceController_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde
// Purpose: Unit Test Class for SyncWithSiebelInterfaceController.
// ===========================================================================
// Changes :
// ===========================================================================

@istest
public class SyncWithSiebelInterfaceController_Test {
	@istest
	public static void sampleMethod() {
		//Create Account
		TestSetupDataUtil.insertAccountRecords(2);
		//Fetch Accounts
		List<Account> acc = [SELECT Id, Name FROM Account];
		//Create Contact
		Contact conObj = new Contact(
			LastName = 'Test',
			FirstName = 'Test',
			AccountId = acc[0].Id,
			Email = 'abcd@GMAIL.COM'
		);
		insert conObj;
		//Asssert Statements
		System.assertEquals(acc.Size(), 2);
		System.assertNotEquals(conObj.Id, null);
		test.startTest();
		SyncWithSiebelInterfaceController.siebelSyncIntegration(conObj.Id);
		SyncWithSiebelInterfaceController.checkPrimaryAccount(conObj.Id);
		test.stopTest();
	}
}