// ===========================================================================
//	Object: DynamicCodeExecution
// 	Company: Keste LLC
//  Author: Basant Kumar Verma
// 	Purpose: Utility Class to Allow Dynamic Code Execution upto n granularity level
// ===========================================================================
public class DynamicCodeExecution {
	public static Map<String, Boolean> codeExecutionMap { get; set; }

	// Method Name: allowExecution
	// Author: Basant Kumar Verma
	// Description: Method to return if requested code unit is allowed to be executed
	// Parameter 1: codeUnitDetail - Fully Qualified name for the respective code unit to be checked for execution
	// Return: Boolean - Returns TRUE if code unit need to be executed and False if that is blocked
	public static Boolean allowExecution(String codeUnitDetail) {
		Boolean isAllowExecution = true;
		if (codeExecutionMap == null) {
			codeExecutionMap = new Map<String, Boolean>();
			for (Dynamic_Code_Execution__mdt dce : [
				SELECT Id, Apex_Class_Trigger_Name__c, Method_Name__c, Disable_Execution__c
				FROM Dynamic_Code_Execution__mdt
				WHERE Disable_Execution__c = TRUE
				ORDER BY Apex_Class_Trigger_Name__c, Method_Name__c
			]) {
				String unitDetails = dce.Apex_Class_Trigger_Name__c;
				if (String.isNotBlank(dce.Method_Name__c)) {
					unitDetails += '.' + dce.Method_Name__c;
				}
				codeExecutionMap.put(unitDetails, dce.Disable_Execution__c);
			}
		}
		if (codeExecutionMap.containsKey(codeUnitDetail)) {
			isAllowExecution = !codeExecutionMap.get(codeUnitDetail);
		}

		return isAllowExecution;
	}
}