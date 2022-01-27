@isTest
public class CustomRollupUtilityBatch_Test {
	@testSetup
	public static void testSetupMethod() {
		List<Account> accNews = TestSetupDataUtil.insertAccountRecords(10);
		TestSetupDataUtil.insertPriceBookRecords(1);
		TestSetupDataUtil.insertContactRecordswithAcc(3, accNews);
	}

	@isTest
	public static void unitTest() {
		Account accObj = [SELECT Id, CurrencyIsoCode FROM Account LIMIT 1];
		List<Contact> cons1 = [SELECT Id, Name FROM Contact];

		List<Opportunity> oppList = new List<Opportunity>();
		Opportunity oppObj = new Opportunity();
		oppObj.Name = 'Test Opportunity';
		oppObj.CloseDate = System.today();
		oppObj.StageName = 'New';
		oppObj.Confidence__c = '10%';
		oppObj.AccountId = accObj.Id;
		oppObj.Primary_Contact__c = cons1[0].id;
		oppObj.CurrencyIsoCode = 'EUR';
		oppObj.Quote_Revenue__c = 100;
		oppList.add(oppObj);

		Opportunity oppObj2 = new Opportunity();
		oppObj2.Name = 'Test Opportunity';
		oppObj2.CloseDate = System.today();
		oppObj2.StageName = 'New';
		oppObj2.Confidence__c = '10%';
		oppObj2.AccountId = accObj.Id;
		oppObj2.Primary_Contact__c = cons1[0].id;
		oppObj2.CurrencyIsoCode = 'AED';
		oppObj2.Quote_Revenue__c = 200;
		oppList.add(oppObj2);
		insert oppList;

		BigMachines__Configuration_Record__c site = new BigMachines__Configuration_Record__c();
		site.BigMachines__bm_site__c = 'TEST';
		site.BigMachines__process_id__c = 'TEST';
		site.BigMachines__action_id_copy__c = 'TEST';
		site.BigMachines__action_id_open__c = 'TEST';
		site.BigMachines__document_id__c = 'TEST';
		site.BigMachines__version_id__c = 'TEST';
		site.BigMachines__process__c = 'TEST';
		site.BigMachines__Is_Active__c = true;
		site.BigMachines__Primary_Commerce_Process__c = true;
		insert site;

		List<BigMachines__Quote__c> qList = new List<BigMachines__Quote__c>();
		BigMachines__Quote__c oQuote1 = new BigMachines__Quote__c();
		oQuote1.BigMachines__Account__c = oppObj.AccountId;
		oQuote1.BigMachines__Opportunity__c = oppObj.Id;
		oQuote1.BigMachines__Site__c = site.Id;
		oQuote1.Quote_Revenue__c = 100;
		oQuote1.CurrencyIsoCode = 'GIP';
		qList.add(oQuote1);

		BigMachines__Quote__c oQuote2 = new BigMachines__Quote__c();
		oQuote2.BigMachines__Account__c = oppObj.AccountId;
		oQuote2.BigMachines__Opportunity__c = oppObj.Id;
		oQuote2.BigMachines__Site__c = site.Id;
		oQuote2.CurrencyIsoCode = 'TWD';
		oQuote2.Quote_Revenue__c = 100;
		qList.add(oQuote2);
		insert qList;

		oQuote2.BigMachines__Opportunity__c = oppObj2.Id;
		update oQuote2;

		Map<Id, BigMachines__Quote__c> qMap = new Map<Id, BigMachines__Quote__c>();
		for (BigMachines__Quote__c ob : qList) {
			qMap.put(ob.Id, ob);
		}

		Test.startTest();
		List<CustomRollupUtility.RollupFieldDetails> fieldDetails = new List<CustomRollupUtility.RollupFieldDetails>();
		fieldDetails.add(
			new CustomRollupUtility.RollupFieldDetails(
				'Quote_Revenue__c',
				'Quote_Revenue__c',
				CustomRollupUtility.ROLLUP_TYPE.SUM
			)
		);

		//INVALID Child Object API NAME
		CustomRollupUtility.doRollup(
			'INVALID__c',
			'BigMachines__Opportunity__c',
			'Opportunity',
			fieldDetails,
			qList,
			null
		);
		//INVALID Parent Object API NAME
		CustomRollupUtility.doRollup(
			'BigMachines__Quote__c',
			'BigMachines__Opportunity__c',
			'INVALID',
			fieldDetails,
			qList,
			null
		);
		//INVALID Reference Field API Name
		CustomRollupUtility.doRollup('BigMachines__Quote__c', 'INVALID__c', 'Opportunity', fieldDetails, qList, null);
		//INVALID Reference Field Data Type
		CustomRollupUtility.doRollup('BigMachines__Quote__c', 'Name', 'Opportunity', fieldDetails, qList, null);

		//INVALID Child Field API Name
		fieldDetails[0].childField = 'INVALID__c';
		CustomRollupUtility.doRollup(
			'BigMachines__Quote__c',
			'BigMachines__Opportunity__c',
			'Opportunity',
			fieldDetails,
			qList,
			null
		);
		//INVALID Child Field Data Type
		fieldDetails[0].childField = 'Name';
		CustomRollupUtility.doRollup(
			'BigMachines__Quote__c',
			'BigMachines__Opportunity__c',
			'Opportunity',
			fieldDetails,
			qList,
			null
		);

		//INVALID Parent Field API Name
		fieldDetails[0].childField = 'Quote_Revenue__c';
		fieldDetails[0].parentField = 'INVALID__c';
		CustomRollupUtility.doRollup(
			'BigMachines__Quote__c',
			'BigMachines__Opportunity__c',
			'Opportunity',
			fieldDetails,
			qList,
			null
		);
		//INVALID Parent Field Data Type
		fieldDetails[0].parentField = 'Name';
		CustomRollupUtility.doRollup(
			'BigMachines__Quote__c',
			'BigMachines__Opportunity__c',
			'Opportunity',
			fieldDetails,
			null,
			qMap
		);

		//All Valid Parameters
		fieldDetails[0].parentField = 'Quote_Revenue__c';
		CustomRollupUtility_Batch batchOb = new CustomRollupUtility_Batch(
			'BigMachines__Quote__c',
			'BigMachines__Opportunity__c',
			'Opportunity',
			fieldDetails
		);
		Database.executebatch(batchOb, 200);
		Test.stopTest();
	}
}