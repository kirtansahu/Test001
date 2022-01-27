/* ===========================================================================
Class: SGNAccountViewShipOnMap_Test
Company: Keste @IDC
Author: Karunakar Goud
Purpose: Test class for validating the methods from SGNAccountViewShipOnMap class.
===========================================================================*/
@isTest
public class SGNAccountViewShipOnMap_Test {
	@isTest
	static void childAddressMap_Test() {
		Test.startTest();
		Id siteSGNRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
		Account acc = new Account(Name = 'TestAccount1');
		acc.RecordTypeId = siteSGNRecTypeId;
		acc.Unique_Id__c = 'test';
		insert acc;
		System.assertNotEquals(acc.id, null);
		Id shipToRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Ship To').getRecordTypeId();
		Account childAcc = new Account(
			Name = 'TestChildAccount',
			ShippingStreet = '620 8th Avenue',
			ShippingCity = 'New York',
			ShippingState = 'New York',
			ShippingPostalCode = '10018',
			ShippingCountry = 'United States'
		);
		childAcc.ParentId = acc.Id;
		childAcc.RecordTypeId = shipToRecTypeId;
		childAcc.Unique_Id__c = 'test1';
		insert childAcc;
		//Assert Statements
		System.assertEquals(childAcc.ParentId, acc.Id);
		System.assertNotEquals(childAcc.Id, null);
		SGNAccountViewShipOnMap.childAddressMap(acc.Id);
		Test.stopTest();
	}
}