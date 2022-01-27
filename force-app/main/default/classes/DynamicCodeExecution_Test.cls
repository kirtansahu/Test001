// ===========================================================================
//  Object: DynamicCodeExecutionTest
//  Company: Keste LLC
//  Author: Basant Kumar Verma
//  Purpose: Test Class for DynamicCodeExecution
// ===========================================================================
@istest
public class DynamicCodeExecution_Test {
	static testMethod void unitTest() {
		Boolean flag = DynamicCodeExecution.allowExecution('DO NOT DELETE.DO NOT DELETE');
		System.assertEquals(flag, false);
		flag = DynamicCodeExecution.allowExecution('NOROW.NOROW.NOROW');
		System.assertEquals(flag, true);
	}
}