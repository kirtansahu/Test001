// ===========================================================================
//  Object	: CaseRelatedAssetsTrigger_Test
// 	Company	: Keste @IDC
//  Author	: Pradeep Chanda
// 	Purpose	: Unit Test Class for CaseRelatedAssetsTriggerHandler And CaseRelatedAssetsTrigger.
// ===========================================================================
@isTest
public class CaseRelatedAssetsTrigger_Test {
	@testSetup
	public static void createTestData() {
		List<Account> lstAccount = TestSetupDataUtil.insertAccountRecords(1);
		List<Contact> lstContact = TestSetupDataUtil.insertContactRecordswithAcc(1, lstAccount);

		List<Asset> lstAsset = new List<Asset>();
		for (Integer i = 1; i <= 2; i++) {
			Asset oAsset = new Asset();
			oAsset.Name = 'Test Asset' + i;
			oAsset.AccountId = lstAccount[0].Id;
			oAsset.ContactId = lstContact[0].Id;
			lstAsset.add(oAsset);
		}
		insert lstAsset;
	}

	@isTest
	public static void assetUpdateValidationTest() {
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];
		List<Asset> lstAsset = [SELECT Id FROM Asset];
		Test.startTest();
		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Email';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Status = 'New';
		oCase.Sub_Status__c = 'Unassigned';
		oCase.SuppliedEmail = 'mastercontact@thermofisher.com';
		oCase.Description = 'test';
		oCase.Subject = 'Test1 Case';
		oCase.AssetId = lstAsset[0].Id;
		insert oCase;

		oCase.AssetId = lstAsset[1].Id;
		update oCase;

		List<Case_Related_Assets__c> primaryAssetRecord = [
			SELECT Id, Name
			FROM Case_Related_Assets__c
			WHERE Primary__c = TRUE AND Case__c = :oCase.Id
			LIMIT 1
		];
		if (primaryAssetRecord.size() > 0) {
			try {
				delete primaryAssetRecord;
			} catch (exception ex) {
			}
		}
		Test.stopTest();
	}
}