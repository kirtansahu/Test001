// ===========================================================================
//  Object  :  TerritoryAlignment_Batch_Test
//  Company  : Keste @IDC
//  Author  :  Abinash Panigrahi
//  Purpose  : Test Class to get coverage for TerritoryAlignment_Batch
// ===========================================================================

@isTest
public class TerritoryAlignment_Batch_Test {
	@testSetup
	public static void testDataSetupBatch() {
		// Get Territory Type
		Territory2Type terrTypeRec = [SELECT Id, MasterLabel FROM Territory2Type LIMIT 1];

		// Get Metadata
		Parent_Territory_Node__mdt metaData = [
			SELECT Id, Territory_Model_Name__c
			FROM Parent_Territory_Node__mdt
			LIMIT 1
		];

		// Insert Territory
		Territory_Hierarchy__c testObj = new Territory_Hierarchy__c();

		testObj.Tier1_Label__c = 'Test Record #1 Level 1 ';
		testObj.Tier1_Name__c = 'Test Record #1 Level 1 ';
		testObj.Tier1_User__c = UserInfo.getUserId();
		testObj.Tier1_Type__c = terrTypeRec.MasterLabel;
		testObj.Tier1_Channel__c = 'GEN B';

		testObj.Territory_Model_Name__c = metaData.Territory_Model_Name__c;
		testObj.Is_Active__c = true;
		testObj.Is_Batch_Processed__c = false;
		testObj.Role_in_Territory__c = 'IVGN Primary';

		testObj.Tier4_Label__c = 'Test Record #1 Level 4 ';
		testObj.Tier4_Name__c = 'Test Record #1 Level 4 ';
		testObj.Tier5_Label__c = 'Test Record #1 Level 5 ';
		testObj.Tier5_Name__c = 'Test Record #1 Level 5 ';
		testObj.Tier6_Label__c = 'Test Record #1 Level 6 ';
		testObj.Tier6_Name__c = 'Test Record #1 Level 6 ';
		testObj.Tier7_Label__c = 'Test Record #1 Level 7 ';
		testObj.Tier7_Name__c = 'Test Record #1 Level 7 ';

		insert testObj;
	}

	@isTest
	public static void unitSuccessTest() {
		Test.startTest();

		// First Run
		Id batchProcessedId = Database.executeBatch(new TerritoryAlignment_Batch(), 1);

		Test.stopTest();

		// Fetch Backend Object Records
		List<Territory2> sysTerrs = [SELECT ID FROM Territory2 WHERE Name LIKE '%Test Record #1%'];
		System.assertEquals(sysTerrs.size(), 5);
		List<UserTerritory2Association> sysUserAssoc = [
			SELECT Id
			FROM UserTerritory2Association
			WHERE Territory2Id IN :sysTerrs
		];
		System.assertEquals(sysUserAssoc.size(), 1);

		// Update Stagging Records
		Territory_Hierarchy__c testObj = [
			SELECT Id, Is_Batch_Processed__c
			FROM Territory_Hierarchy__c
			WHERE Is_Batch_Processed__c = TRUE
			LIMIT 1
		];
		testObj.Tier1_User__c = TestSetupDataUtil.insertUsers(1)[0].Id;
		testObj.Tier1_Channel__c = 'TSS A';
		testObj.Tier1_Type__c = null;
		testObj.Is_Batch_Processed__c = false;
		update testObj;

		// Incremental Run
		batchProcessedId = Database.executeBatch(new TerritoryAlignment_Batch(), 1);
	}

	@isTest
	public static void unitErrorTest() {
		// Fetch Records
		List<Territory_Hierarchy__c> testObj = [SELECT Id, Tier1_Channel__c FROM Territory_Hierarchy__c LIMIT 1];

		Test.startTest();

		// Error Run
		try {
			// Scramble Data
			testObj[0].Tier2_Channel__c = 'Test';
			update testObj[0];
		} catch (DMLException err) {
			try {
				// Run Exception Message
				TerritoryAlignment_Batch obje = new TerritoryAlignment_Batch();
				obje.createExceptionLogs(testObj, 'Test', err, Database.setSavepoint(), testObj[0]);
			} catch (Exception ex) {
			}
		}

		Test.stopTest();
	}
}