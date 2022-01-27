//===========================================================================
//	Object	:	ContactProfileHandler_Test
//	Company	:	Keste @IDC
//	Author	:	Abinash Panigrahi
//	Purpose	:	Unit Test Class for ContactProfile and ContactProfileHandler.
//===========================================================================
@isTest
public class ContactProfileHandler_Test {
	@isTest
	public static void ContactProfileTest() {
		List<Account> lstAcc = new List<Account>();
		lstAcc = TestSetupDataUtil.insertAccountRecords(2);
		List<Contact> lstCons = new List<Contact>();
		lstCons = TestSetupDataUtil.insertContactRecordswithAcc(lstAcc.size(), lstAcc);
		List<Profile__c> lstProfiles = new List<Profile__c>();
		lstProfiles = TestSetupDataUtil.insertProfileRecords(2);
		System.assertNotEquals(lstAcc.size(), null);
		System.assertNotEquals(lstCons.size(), null);
		System.assertNotEquals(lstProfiles.Size(), null);
		List<Contact_Profile__c> lstConProfiles = new List<Contact_Profile__c>();
		for (Integer i = 0; i < 1; i++) {
			Contact_Profile__c objCP = new Contact_Profile__c(
				Contact__c = lstCons[i].Id,
				Profile__c = lstProfiles[i].Id,
				Contact_Profile_External_Id__c = String.valueof(Math.random())
			);
			lstConProfiles.add(objCP);
		}
		insert lstConProfiles;
		System.assertNotEquals(lstConProfiles.size(), null);
		delete lstConProfiles[0];
		lstCons[0].AccountId = lstAcc[0].id;
		update lstCons[0];
	}
}