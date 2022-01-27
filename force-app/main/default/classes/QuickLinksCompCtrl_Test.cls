// ===========================================================================
//  Object: QuickLinksCompCtrl_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde
// Purpose: Unit Test Class for QuickLinksCompCtrl.
// ===========================================================================
// Changes:
// ===========================================================================
@istest
public class QuickLinksCompCtrl_Test {
	@istest
	public static void unitTest() {
		//Create Custom Link Record
		Id RecordTypeId = Schema.SObjectType.Custom_Link__c.getRecordTypeInfosByName()
			.get('Custom Link')
			.getRecordTypeId();
		Custom_Link__c cLink = new Custom_Link__c();
		cLink.Label__c = 'sampledata';
		cLink.IsActive__c = true;
		cLink.Order__c = 1;
		cLink.Location__c = 'home';
		cLink.Link__c = 'https://ww';
		insert cLink;
		//create Custim Link Record
		Custom_Link__c cLink1 = new Custom_Link__c();
		cLink1.Label__c = 'sampledata';
		cLink1.IsActive__c = true;
		cLink1.Order__c = 2;
		cLink1.Link__c = 'https://ww';
		cLink1.Category__c = cLink.Id;
		cLink1.Location__c = 'home';
		cLink1.Collapsed__c = true;
		cLink1.RecordTypeId = RecordTypeId;
		insert cLink1;
		//Assert Statements
		System.assertNotEquals(cLink1.Id, null);
		System.assertNotEquals(cLink.Id, null);
		System.assertEquals(cLink1.Category__c, cLink.Id);
		Test.startTest();
		QuickLinksCompCtrl.fetchCategoryAndCustomLinks('home');
		Test.stopTest();
	}
}