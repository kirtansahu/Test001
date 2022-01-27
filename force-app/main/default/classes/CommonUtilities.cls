// ===========================================================================
//  Object  : CommonUtilities
//  Company : Keste @ IDC
//  Author  : Vasavi Poranki
//  Purpose : Collection of common utility methods which are used from multiple places in the code
// ===========================================================================
public class CommonUtilities {
	//Public Static Variables to block the recursive calls
	public static boolean IsSiebelContactSync = false;
	public static boolean IsDuplicateRecord = false;
	public static Id systemAdminProfileId = null;
	//method to check if current logged in user is System Admin User with ByPass Checkbox
	public static Boolean isSystemAdminUserWithByPassValidation {
		get {
			if (isSystemAdminUserWithByPassValidation == null) {
				isSystemAdminUserWithByPassValidation = false;
				for (User u : [
					SELECT Id
					FROM User
					WHERE
						Id = :UserInfo.getUserId()
						AND Profile.Name = 'System Administrator'
						AND Bypass_Validation__c = TRUE
					LIMIT 1
				]) {
					isSystemAdminUserWithByPassValidation = true;
				}
			}
			return isSystemAdminUserWithByPassValidation;
		}
		protected set;
	}

	//Single Method to print the debug statement from all over the code
	public static void debug(String debugStr) {
		if (DynamicCodeExecution.allowExecution('CommonUtilities.debug')) {
			System.debug('KESTE_IDC_DEBUG: ' + debugStr);
		}
	}

	//Single Method to print the debug statement from all over the code
	public static void debug(Object obj) {
		debug(JSON.serialize(obj));
	}

	//method to check if current logged in user is Integration or Migration user
	public static Boolean isIntegrationOrMigrationUser() {
		return (isIntegrationUser() || isMigrationUser());
	}

	//method to check if current logged in user is Integration user
	public static Boolean isIntegrationUser() {
		String username = UserInfo.getUserName().split('@')[0];
		return (username == Label.USERNAME_SYSTEMINTEGRATION);
	}

	//method to check if current logged in user is Migration user
	public static Boolean isMigrationUser() {
		String username = UserInfo.getUserName().split('@')[0];
		return (username == Label.USERNAME_INFORMATICA);
	}

	//method to check if current logged in user is System Admin user
	public static Boolean isSystemAdminUser() {
		String userProfileId = UserInfo.getProfileId();
		if (systemAdminProfileId == null) {
			for (PermissionSet p : [
				SELECT Id, ProfileId, Profile.Name, IsCustom
				FROM PermissionSet
				WHERE Iscustom = FALSE AND Profile.Name = 'System Administrator'
				LIMIT 1
			]) {
				systemAdminProfileId = p.ProfileId;
			}
		}
		return (userProfileId == systemAdminProfileId);
	}

	//method to check if current logged in user is CPQ Integration user
	public static Boolean isCPQIntegrationUser() {
		Id userProfileId = UserInfo.getProfileId();
		Id cpqProfileId = [SELECT Id FROM Profile WHERE Name = 'CPQ Integration User' LIMIT 1].Id;
		return (userProfileId == cpqProfileId);
	}

	//Method to check if there is already a batch is in running stage for the same class
	//Return false if there is any, else return true
	public static Boolean isGoodToExecuteBatch(String batchClassName) {
		boolean canExecute = true;
		Set<String> allRunningStatuses = new Set<String>();
		allRunningStatuses.add('Queued');
		allRunningStatuses.add('Processing');
		allRunningStatuses.add('Preparing');
		allRunningStatuses.add('Holding');
		for (AsyncApexJob oAsyncApexJob : [
			SELECT Id
			FROM AsyncApexJob
			WHERE ApexClass.Name = :batchClassName AND Status IN :allRunningStatuses
			LIMIT 1
		]) {
			canExecute = false;
		}
		return canExecute;
	}

	//Method to check if in the recent execution of the batch all records failed
	public static Boolean isAllRecordsFailedInRecentExecution(String batchClassName) {
		Boolean isAllFailed = false;
		for (AsyncApexJob oAsyncApexJob : [
			SELECT Id, TotalJobItems, NumberOfErrors
			FROM AsyncApexJob
			WHERE ApexClass.Name = :batchClassName
			ORDER BY CreatedDate DESC
			LIMIT 1
		]) {
			if (oAsyncApexJob.TotalJobItems > 0 && oAsyncApexJob.TotalJobItems == oAsyncApexJob.NumberOfErrors) {
				isAllFailed = true;
			}
		}
		return isAllFailed;
	}

	//Method to create dynamic SOQL query
	public static String prepareQuery(String objName, Set<String> setAdditionalFields, Boolean bypassFLS) {
		Map<String, Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();
		Schema.sObjectType objType = globalDescription.get(objName);
		Schema.DescribeSObjectResult r1 = objType.getDescribe();
		Map<String, Schema.SObjectField> mapFieldList = r1.fields.getMap();
		Set<String> setFields = new Set<String>();
		if (setAdditionalFields != null && setAdditionalFields.size() > 0) {
			setFields = setAdditionalFields;
		}
		String strQuery = '';
		strQuery = 'SELECT ';
		for (Schema.SObjectField field : mapFieldList.values()) {
			Schema.DescribeFieldResult fieldResult = field.getDescribe();
			if (fieldResult.isAccessible() || bypassFLS) {
				setFields.add(fieldResult.getName());
			}
		}
		for (String fAPI : setFields) {
			strQuery += fAPI + ', ';
		}
		strQuery = strQuery.substring(0, strQuery.lastIndexOf(','));
		strQuery += ' FROM ' + objName + ' ';
		return strQuery;
	}

	//Method to do Exact Word Matching and provide the matched count -- Keyword Routing Logic
	public static Integer countMatches(String text, String match) {
		Integer iCount = 0;
		if (text != null && match != null && text.contains(match)) {
			for (String strWord : text.split(' ')) {
				if (strWord.equalsIgnoreCase(match)) {
					iCount++;
				}
			}
		}
		return iCount;
	}

	//Method to do pre-processing of Email Message Body and Subject to handle all Special Characters -- Keyword Routing Logic
	public static String stringReplaceAll(String text) {
		text = text.toLowerCase()
			.replaceAll('\\r\\n', ' ')
			.replaceAll('\\n', ' ')
			.replaceAll('\\t', ' ')
			.replaceAll('>', '> ')
			.replaceAll('<', ' <');
		String specialChars = Label.CASE_KEYWORD_MATCHING_SPECIAL_CHARACTERS_LIST;
		for (String s : specialChars.split('|')) {
			text = text.replace(s, ' ');
		}
		return text;
	}
	//Method to return Loggin User Profile Name
	public static String getLoginUserProfileName(String profileId) {
		return [SELECT Id, Name FROM Profile WHERE Id = :profileId].Name;
	}
}