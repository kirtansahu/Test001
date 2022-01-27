// ===========================================================================
//  Object: OpportunityProductLine_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde
// Purpose: Unit Test Class for OpportunityProductLineTrigger And OpportunityProductLineTriggerHandler.
// ===========================================================================
// Changes:
// ===========================================================================
@istest
public class OpportunityProductLine_Test {
	@istest
	public static void opportunityUnitTest() {
		//Insert Account Record
		List<Account> accnews = TestSetupDataUtil.insertAccountRecords(10);
		//Fetch All Account Records
		List<Account> accList = [SELECT Id, Name FROM Account];
		accList[0].ERP_Account_Id__c = 'test';
		update accList[0];
		//insert Contact Records
		TestSetupDataUtil.insertContactRecordswithAcc(3, accnews);
		//Fetch All Contact Records
		List<Contact> conList = [SELECT Id, Name FROM Contact];
		//Assert Statements
		System.assertEquals(accList.size(), 10);
		System.assertEquals(conList.Size(), 3);
		//create Opportunity Record
		Opportunity oppObj = new Opportunity(
			Name = 'Test Opportunity',
			Accountid = accList[0].id,
			CloseDate = System.today(),
			StageName = 'New',
			Siebel_Row_Id__c = '3673',
			Confidence__c = '10%',
			Primary_Contact__c = conList[0].id
		);
		insert oppObj;
		//create Product Line
		Product_Line__c pl = new Product_Line__c(
			Product_Line__c = 'test',
			Unique_Id__c = '123',
			IGOR_Code_Description__c = 'sample',
			Plan_Code__c = '01',
			Product_Group__c = 'trec'
		);
		insert pl;
		//create opportunity product line record
		List<Opportunity_Product_Line__c> opllist = new List<Opportunity_Product_Line__c>();
		Opportunity_Product_Line__c opl = new Opportunity_Product_Line__c();
		opl.Opportunity__c = oppObj.Id;
		opl.CurrencyIsoCode = 'USD';
		opl.Primary__c = true;
		opl.Product_Line__c = pl.id;
		opllist.add(opl);
		insert opllist;
		//Assert Statements
		System.assertNotEquals(pl.id, null);
		System.assertEquals(opllist.size(), 1);
		//Fetch All Opportunity Product Line Item
		List<Opportunity_Product_Line__c> opl1 = [
			SELECT Id, Opportunity__c, Product_Line__c, Primary__c
			FROM Opportunity_Product_Line__c
			WHERE Opportunity__c = :oppObj.Id
		];
		opl1[0].primary__c = false;
		update opl1;
		delete opl1;
		//Assert Statements
		System.assertEquals(opl1.size(), 1);
		System.assertnotEquals(oppObj.Id, null);
		Map<Id, Opportunity_Product_Line__c> mapResult = new Map<id, Opportunity_Product_Line__c>();
		for (Opportunity_Product_Line__c p : opl1) {
			mapResult.put(p.id, p);
		}
		//OpportunityProductLineTriggerHandler.syncDeletedOpportunityProductLineWithSiebel(opl1);
		// OpportunityProductLineTriggerHandler.afterDelete(opl1);
	}
}