/* ===========================================================================
	Class	: SGNAccountViewShipOnMap
 	Company	: Keste @ IDC
  	Author	: Karunakar Goud
 	Purpose	: Lightning Component to display Ship To child addresses of the parent SGN Account.
 =========================================================================== */
public without sharing class SGNAccountViewShipOnMap {
	//Method Name: childAddressMap
	//Author: Karunakar Goud
	//Description: Method which will return the child accounts records
	//Parameter 1: Parent Account record Id
	//Return: List of child accounts
	@AuraEnabled
	public static List<Account> childAddressMap(String recId) {
		List<Address> adressList = new List<Address>();
		List<Account> accList = new List<Account>();
		accList = [
			SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
			FROM Account
			WHERE ParentId = :recId AND RecordType.Name = :Label.ACCOUNT_RECORD_SHIPTO
		];
		return accList;
	}
}