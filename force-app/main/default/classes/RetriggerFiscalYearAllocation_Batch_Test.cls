// ==============================================================================================
//  Class Name  			 : RetriggerFiscalYearAllocation_Batch_Test
//  Realted Controller Name  : RetriggerFiscalYearAllocation_Batch
//  Company     			 : Keste @ IDC
//  Author     				 : Jayaram Bevara
//  Purpose     			 : Unit test class for RetriggerFiscalYearAllocation_Batch
// ==============================================================================================
@isTest
public class RetriggerFiscalYearAllocation_Batch_Test {
	@isTest
	public static void construtWithParameterTestMethod() {
		//Insert Account Records
		List<Account> Accs = TestSetupDataUtil.insertAccountRecords(1);
		//Insert Contact Records
		List<Contact> conList = TestSetupDataUtil.insertContactRecordswithAcc(1, Accs);
		//create Opportunity Record
		Opportunity Opp = new Opportunity();
		Opp.Name = Accs[0].Name;
		Opp.StageName = 'New';
		Opp.CloseDate = System.today();
		opp.Siebel_Quote_Number__c = '9008665';
		Opp.AccountId = Accs[0].Id;
		Opp.Primary_Contact__c = conList[0].id;
		Opp.Quote_Revenue__c = 100;
		insert Opp;
		System.assertEquals(Opp.Quote_Revenue__c, 100);
		Test.startTest();
		DataBase.executeBatch(new RetriggerFiscalYearAllocation_Batch('2019,2020'));
		Test.stopTest();
	}
	@isTest
	public static void construtWithOutConTestMethod() {
		//Insert Account Records
		List<Account> Accs = TestSetupDataUtil.insertAccountRecords(1);
		//Insert Contact Records
		List<Contact> conList = TestSetupDataUtil.insertContactRecordswithAcc(1, Accs);
		//create Opportunity Record
		Opportunity Opp = new Opportunity();
		Opp.Name = Accs[0].Name;
		Opp.StageName = 'New';
		Opp.CloseDate = System.today();
		opp.Siebel_Quote_Number__c = '9008665';
		Opp.AccountId = Accs[0].Id;
		Opp.Primary_Contact__c = conList[0].id;
		Opp.Quote_Revenue__c = 100;
		insert Opp;
		System.assertEquals(Opp.Siebel_Quote_Number__c, '9008665');
		Test.startTest();
		DataBase.executeBatch(new RetriggerFiscalYearAllocation_Batch());
		Test.stopTest();
	}
}