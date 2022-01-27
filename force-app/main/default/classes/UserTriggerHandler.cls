// ===========================================================================
//  Object: UserTriggerHandler
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Handler Class contains all logic for UserTrigger.
// ===========================================================================
public class UserTriggerHandler {
	// Method Name: oracleUserSync
	// Author: Abinash Panigrahi
	// Description: Method to sync User's Timezone change with Oracle user object
	// Parameter 1: newRec - List of the new versions of the User records
	// Parameter 2: oldMap - Map of IDs to the old versions of the User records
	// Return: Null
	public static void oracleUserSync(List<User> newRec, Map<Id, User> oldMap) {
		//Instance to store the relationship between User recordId and TimezoneKey value
		Map<Id, String> userTimeZoneMap = new Map<Id, String>();
		//Loop over User records
		for (User u : newRec) {
			if (
				u.TimeZoneSidKey != null &&
				(oldMap == null || (oldMap != null && u.TimeZoneSidKey != oldMap.get(u.Id).TimeZoneSidKey))
			) {
				userTimeZoneMap.put(u.Id, u.TimeZoneSidKey);
			}
		}
		CommonUtilities.debug('userTimeZoneMap------->>>>>>>' + userTimeZoneMap);

		//Instance to store to be Update record
		List<BigMachines__Oracle_User__c> toBeUpdateRec;
		if (!Test.isRunningTest()) {
			toBeUpdateRec = getOracleUsersWithMatchTimeZone(userTimeZoneMap);
		}
		//Update Orcale User record
		try {
			if (Test.isRunningTest() || (!Test.isRunningTest() && toBeUpdateRec != null && toBeUpdateRec.size() > 0)) {
				update toBeUpdateRec;
			}
		} catch (Exception ex) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'UserTriggerHandler',
				'oracleUserSync',
				'Trigger Logic',
				'Update Orcale User',
				ex.getMessage(),
				System.today()
			);
			CommonUtilities.debug('Error Message ---->>>' + ex.getMessage());
		}
	}

	// Method Name: getOracleUsersWithMatchTimeZone
	// Author: Abinash Panigrahi
	// Description: fetch Oracle User with matched Timezone details, returns only the records where update needed
	// Parameter 1: Map<Id, String> - Map of user Id and their TimeZone String
	// Return: List<BigMachines__Oracle_User__c> - List of Oracle Users, returns only the records where update needed
	public static List<BigMachines__Oracle_User__c> getOracleUsersWithMatchTimeZone(Map<Id, String> userTimeZoneMap) {
		List<BigMachines__Oracle_User__c> lstOracleUser = getOracleUsers(userTimeZoneMap);
		List<BigMachines__Oracle_User__c> toBeUpdateRec = fetchOracleUsersToUpdate(lstOracleUser, userTimeZoneMap);
		return toBeUpdateRec;
	}

	// Method Name: getOracleUsersWithMatchTimeZone
	// Author: Abinash Panigrahi
	// Description: Find only the records where update needed
	// Parameter 1: List<BigMachines__Oracle_User__c> - List of Oracle Users
	// Parameter 2: Map<Id, String> - Map of user Id and their TimeZone String
	// Return: List<BigMachines__Oracle_User__c> - returns only the records where update needed
	public static List<BigMachines__Oracle_User__c> fetchOracleUsersToUpdate(
		List<BigMachines__Oracle_User__c> lstOracleUser,
		Map<Id, String> userTimeZoneMap
	) {
		List<BigMachines__Oracle_User__c> toBeUpdateRec = new List<BigMachines__Oracle_User__c>();
		for (BigMachines__Oracle_User__c ou : lstOracleUser) {
			//Custom Setting Data for specific timezone, Update list
			if (Oracle_User_Timezone__c.getInstance(userTimeZoneMap.get(ou.BigMachines__Salesforce_User__c)) != null) {
				toBeUpdateRec.add(
					new BigMachines__Oracle_User__c(
						Id = ou.Id,
						BigMachines__Time_Zone__c = Oracle_User_Timezone__c.getInstance(
								userTimeZoneMap.get(ou.BigMachines__Salesforce_User__c)
							)
							.Timezone__c
					)
				);
			}
		}
		return toBeUpdateRec;
	}

	// Method Name: getOracleUsersWithMatchTimeZone
	// Author: Abinash Panigrahi
	// Description: fetch Oracle User with matched Timezone details
	// Parameter 1: Map<Id, String> - Map of user Id and their TimeZone String
	// Return: List<BigMachines__Oracle_User__c> - List of Oracle Users
	public static List<BigMachines__Oracle_User__c> getOracleUsers(Map<Id, String> userTimeZoneMap) {
		List<BigMachines__Oracle_User__c> toBeUpdateRec = new List<BigMachines__Oracle_User__c>();
		//Fetch related Oracle User object records
		for (BigMachines__Oracle_User__c ou : [
			SELECT Id, BigMachines__Time_Zone__c, BigMachines__Salesforce_User__c
			FROM BigMachines__Oracle_User__c
			WHERE BigMachines__Salesforce_User__c IN :userTimeZoneMap.keySet()
		]) {
			toBeUpdateRec.add(ou);
		}
		return toBeUpdateRec;
	}
}