// ===========================================================================
//  Object	: AccountContactRelationHandler_Test
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Unit Test Class for AccountContactRelationHandler and AccountContactRelationHandler.
// ===========================================================================
@isTest
public class AccountContactRelationHandler_Test {
	@isTest
	public static void onAfterInsertTest() {
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = RecordTypeId;
		a.Unique_Id__c = 'test';
		insert a;
		Contact c = new Contact();
		c.LastName = 'TestContact';
		c.FirstName = 'TestContactName';
		c.AccountId = a.Id;
		c.Email = 'abcd@gmail.com';
		insert c;
		System.assert(c.Accountid == a.id);
		List<AccountContactRelation> ACRelations = [
			SELECT Id, AccountId, Account_Record_Type__c, ContactId, IsDirect
			FROM AccountContactRelation
		];
		CommonUtilities.debug('ACRelations' + ACRelations.size());
		System.assertEquals(ACRelations.size(), 1);
		AccountContactRelationHandler.makeCallout(ACRelations);
	}

	@isTest
	public static void onAfterInsertTest1() {
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = RecordTypeId;
		a.Unique_Id__c = 'test';
		insert a;
		Contact c = new Contact();
		c.LastName = 'TestContact';
		c.FirstName = 'TestContactName';
		c.AccountId = a.Id;
		c.Email = 'abcd@gmail.com';
		insert c;
		System.assert(c.Accountid == a.id);
		Account a1 = new Account();
		a1.Name = 'Test Account';
		a1.RecordTypeId = RecordTypeId;
		a1.Unique_Id__c = '123';
		insert a1;
		System.assertNotEquals(a1.id, null);

		AccountContactRelation ACR = new AccountContactRelation();
		ACR.AccountId = a1.Id;
		ACR.ContactId = c.Id;
		insert ACR;
		System.assert(ACR.Accountid == a1.id);

		List<AccountContactRelation> ACRelations = [
			SELECT
				Id,
				AccountId,
				Account_Record_Type__c,
				ContactId,
				Account_Unique_Id__c,
				IsDirect,
				Siebel_Row_Id__c,
				Contact_External_Id__c
			FROM AccountContactRelation
		];
		System.assertNotEquals(ACRelations.size(), 0);
		AccountContactRelationHandler.makeCallout(ACRelations);

		Map<Id, AccountContactRelation> OldMapACR = new Map<Id, AccountContactRelation>();
		for (AccountContactRelation ACR1 : ACRelations) {
			OldMapACR.put(ACR1.Id, ACR1);
		}
		delete ACR;
		// AccountContactRelationHandler.onAfterDelete(OldMapACR);
	}
}