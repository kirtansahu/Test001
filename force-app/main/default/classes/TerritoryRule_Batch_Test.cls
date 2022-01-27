// ===========================================================================
//  Object  :  TerritoryRule_Batch_Test
//  Company  : Keste @IDC
//  Author  :  Abinash Panigrahi
//  Purpose  : Test Class to get coverage for TerritoryRule_Batch
// ===========================================================================

@isTest
public class TerritoryRule_Batch_Test {
	@testSetup
	public static void testDataSetupBatch() {
		// Get Territory Type
		Territory2Type terrTypeRec = [SELECT Id FROM Territory2Type LIMIT 1];

		// Get Metadata
		Parent_Territory_Node__mdt metaData = [
			SELECT Id, Territory_Model_Name__c
			FROM Parent_Territory_Node__mdt
			LIMIT 1
		];

		// Insert Model
		Territory2Model modelObj = new Territory2Model();
		modelObj.Name = 'Test Model';
		modelObj.DeveloperName = 'X_Test_123';
		insert modelObj;

		// Get Model
		Territory2Model modelObj2 = [SELECT Id FROM Territory2Model WHERE Name = :metaData.Territory_Model_Name__c];

		// Insert Territory
		Territory2 terrObj = new Territory2();
		terrObj.Name = 'Test Territory';
		terrObj.DeveloperName = 'X_Test_123';
		terrObj.Territory2TypeId = terrTypeRec.Id;
		terrObj.Territory2ModelId = modelObj2.Id;
		terrObj.AccountAccessLevel = 'Edit';
		terrObj.CaseAccessLevel = 'Edit';
		terrObj.OpportunityAccessLevel = 'Edit';
		insert terrObj;
	}

	@isTest
	public static void unitSuccessTest() {
		// Insert Rule
		createRule();

		Test.startTest();

		// First Run
		Id batchProcessedId = Database.executeBatch(new TerritoryRule_Batch(), 1);

		Test.stopTest();

		// Fetch Backend Object Records
		List<ObjectTerritory2AssignmentRule> sysRules = [
			SELECT ID
			FROM ObjectTerritory2AssignmentRule
			WHERE MasterLabel LIKE '%Test Rule%'
		];
		//System.assertEquals(sysRules.size(), 1);
		List<RuleTerritory2Association> sysRuleAssoc = [
			SELECT Id
			FROM RuleTerritory2Association
			WHERE RuleId IN :sysRules
		];
		//System.assertEquals(sysRuleAssoc.size(), 1);

		// Update Stagging Records
		Territory_Rule__c testObj = [
			SELECT Id, Is_Batch_Processed__c
			FROM Territory_Rule__c
			WHERE Is_Batch_Processed__c = TRUE
			LIMIT 1
		];
		testObj.Is_Batch_Processed__c = false;
		update testObj;

		// Incremental Run
		batchProcessedId = Database.executeBatch(new TerritoryRule_Batch(), 1);
	}

	@isTest
	public static void unitErrorTest() {
		// Insert Rule
		createRule();

		// Fetch Records
		List<Territory_Rule__c> testObj = [SELECT Id, Condition1_Operator__c FROM Territory_Rule__c LIMIT 1];

		Test.startTest();

		// Error Run
		try {
			// Scramble Data
			testObj[0].Condition1_Operator__c = 'Test';
			update testObj[0];
		} catch (DMLException err) {
			try {
				// Run Exception Message
				TerritoryRule_Batch obje = new TerritoryRule_Batch();
				obje.createExceptionLogs(testObj, 'Test', err, Database.setSavepoint(), testObj[0]);
			} catch (Exception ex) {
			}
		}

		Test.stopTest();
	}

	public static void createRule() {
		// Get Metadata
		Parent_Territory_Node__mdt metaData = [
			SELECT Id, Territory_Model_Name__c
			FROM Parent_Territory_Node__mdt
			LIMIT 1
		];

		// Insert Rule
		Territory_Rule__c testObj = new Territory_Rule__c();

		testObj.Condition1_Field__c = 'Account Name';
		testObj.Condition1_Operator__c = 'equals';
		testObj.Condition1_Value__c = 'Test';
		testObj.Condition2_Field__c = 'Account Name';
		testObj.Condition2_Operator__c = 'equals';
		testObj.Condition2_Value__c = 'Test';

		testObj.Assigned_Territories__c = 'Test Territory';
		testObj.Rule_Name__c = 'Test Rule';
		testObj.Filter_Criteria__c = '1 AND 2';
		testObj.Territory_Model_Name__c = metaData.Territory_Model_Name__c;
		testObj.IsActive__c = true;
		testObj.Is_Batch_Processed__c = false;

		insert testObj;
	}
}