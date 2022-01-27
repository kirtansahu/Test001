// ==============================================================================================
//  Class Name  			 : RetriggerCaseKPICalculation_Batch_Test
//  Realted Controller Name  : RetriggerCaseKPICalculation_Batch
//  Company     			 : Keste @ IDC
//  Author     				 : Jayaram Bevara
//  Purpose     			 : Unit test class for RetriggerCaseKPICalculation_Batch
// ==============================================================================================
@isTest
public class RetriggerCaseKPICalculation_Batch_Test {
	@isTest
	public static void retriggerCaseKPICalculationTestMethod() {
		//Insert Product Record
		Product2 objProdInst = new Product2();
		objProdInst.Name = 'testproduct';
		insert objProdInst;
		//Insert Case Record
		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Email';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Status = 'New';
		oCase.Sub_Status__c = 'Unassigned';
		oCase.SuppliedEmail = 'mastercontact@thermofisher.com';
		oCase.Description = 'test';
		oCase.Primary_Product__c = objProdInst.Id;
		oCase.Subject = 'Test1 Case';
		insert oCase;

		System.assertEquals(oCase.Origin, 'Email');

		Test.startTest();
		DataBase.executeBatch(new RetriggerCaseKPICalculation_Batch());
		Test.stopTest();
	}
}