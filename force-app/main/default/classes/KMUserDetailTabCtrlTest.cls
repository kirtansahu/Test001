// ===========================================================================
//  Class Name  : KMUserDetailTabCtrlTest
//  Company     : Keste @IDC
//  Author      : Rambabu Gadde
//  Purpose     : test Class for KMUserDetailTabCtrl
// ===========================================================================
@istest
public class KMUserDetailTabCtrlTest {
	// Method Name: unitMethod
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@istest
	public static void unitMethod() {
		//create user
		Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(
			ProfileId = profileId.id,
			LastName = 'last',
			Email = 'foobar@thermofisher.com',
			Username = 'foobar@thermofisher.com.kmuserdetailtest',
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert u;
		u.CompanyName = 'sampletest';
		update u;
		//Assert Statements
		System.assertNotEquals(u.id, null);
		System.assertEquals(u.CompanyName, 'sampletest');
		test.startTest();
		KMUserDetailTabCtrl.getUserDetails();
		KMUserDetailTabCtrl.saveUserDetails(u);
		test.stopTest();
	}
}