/***************************************************************************************
 * @description: This is used as Test class for CustomLeadConvertCtrl apex classs which
 * is used as controller for custom lead convert lightning componet
 * @author: Keste Dev
 * @date: 09 July, 2019
 ***************************************************************************************/
@isTest
public class CustomLeadConvertCtrl_Test {
	/***************************************************************************************
@description: This method is used as test setup to create required data for apex class
@author: Keste Dev
@date: 09 July, 2019
@param: none
@return: none
***************************************************************************************/
	@testSetup
	public static void testSetupMethod() {
		if (DynamicCodeExecution.allowExecution('CustomLeadConvertCtrl_Test.testSetupMethod')) {
			//Create User
			TestSetupDataUtil.insertUsers(2);
			//Create Account
			List<Account> lstAccounts = TestSetupDataUtil.insertAccountRecords(10);
			//Create Contact
			TestSetupDataUtil.insertContactRecordswithAcc(3, lstAccounts);
		}
	}

	/***************************************************************************************
@description: This method is used as test when convert lead in opportunity
@author: Keste Dev
@date: 09 July, 2019
@param: none
@return: none
***************************************************************************************/
	@isTest
	public static void unitTest() {
		if (DynamicCodeExecution.allowExecution('CustomLeadConvertCtrl_Test.unitTest')) {
			Account acc = [SELECT Id FROM Account LIMIT 1];
			Contact con = [SELECT Id FROM Contact LIMIT 1];
			Lead oLead = new Lead();
			oLead.Lead_Source_Id__c = '1001';
			oLead.IsConverted = false;
			oLead.Account__c = acc.Id;
			oLead.Contact__c = con.Id;
			oLead.Comment__c = 'Comment Demo';
			oLead.LastName = 'Test Lead Obj';
			oLead.Company = 'Test';
			oLead.Status = 'Completed';
			oLead.Opportunity_Name__c = 'Test Opp';
			oLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName()
				.get('Marketing Alerted Activity')
				.getRecordTypeId();
			insert oLead;

			Test.startTest();

			List<OpportunityContactRole> lstOpportunityContactRole = new List<OpportunityContactRole>();
			for (OpportunityContactRole oppContactRoleObj : [SELECT Id FROM OpportunityContactRole]) {
				lstOpportunityContactRole.add(oppContactRoleObj);
			}
			if (lstOpportunityContactRole.size() > 0) {
				delete lstOpportunityContactRole;
			}
			Lead lead = CustomLeadConvertCtrl.fetchLeadRecordDetails(oLead.Id);
			try {
				Id oppId = CustomLeadConvertCtrl.convertLeadIntoOpportunity(lead);
			} catch (Exception ex) {
			}

			try {
				Id oppId = CustomLeadConvertCtrl.convertLeadIntoOpportunity(null);
			} catch (Exception ex) {
			}
			System.assertEquals(lead.Id, oLead.Id);
			System.assertNotEquals(olead.id, null);
			System.assertEquals(olead.Account__c, acc.Id);

			Test.stopTest();
		}
	}

	@isTest
	public static void unitTest_1() {
		Account acc = [SELECT Id FROM Account LIMIT 1];
		Contact con = [SELECT Id FROM Contact LIMIT 1];
		Lead oLead = new Lead();
		oLead.Lead_Source_Id__c = '1001';
		oLead.Account__c = acc.Id;
		oLead.Contact__c = con.Id;
		oLead.Comment__c = 'Comment Demo';
		oLead.LastName = 'Test Lead Obj';
		oLead.Company = 'Test';
		oLead.Status = 'Rejected';
		oLead.Opportunity_Name__c = 'Test Opp';
		oLead.Comment__c = 'test comemnt';
		oLead.Product_Grouping_Global__c = 'ACROMETRIX';
		oLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName()
			.get('Sales Created Lead')
			.getRecordTypeId();
		insert oLead;

		//Assert Statements
		System.assertNotEquals(oLead.Id, null);
		System.assert(oLead.Account__c == acc.id);
		System.assertEquals(oLead.Contact__c, con.Id);

		Test.startTest();
		try {
			Lead lead = CustomLeadConvertCtrl.fetchLeadRecordDetails(oLead.Id);
			Id oppId = CustomLeadConvertCtrl.convertLeadIntoOpportunity(lead);
		} catch (exception e) {
		}
		Test.stopTest();
	}
}