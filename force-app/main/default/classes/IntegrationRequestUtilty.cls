// ===========================================================================
//  Object	: IntegrationRequestUtilty
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: To Create JSON Format Request Body for Outbound CallOuts.
// ==========================================================================
public class IntegrationRequestUtilty {
	//Method Name: getContactJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON Request for Contact record with its Childs
	//Parameter 1: String OperationType - DML Operation Type
	//Parameter 2: List<Contact> lstContact - List of
	//Return: Map of record Id with its JSON request string
	public static Map<Id, String> getContactJSONRequest(
		String OperationType,
		List<Contact> lstContact,
		Boolean bulkJob
	) {
		Map<Id, String> mapContactJSONRequest = new Map<Id, String>();
		if (OperationType == 'INSERT') {
			mapContactJSONRequest.putAll(getContactJSONRequest(lstContact, false, bulkJob));
		} else if (OperationType == 'UPDATE') {
			mapContactJSONRequest.putAll(getContactJSONRequest(lstContact, true, bulkJob));
		} else if (OperationType == 'DELETE') {
			mapContactJSONRequest.putAll(getDeleteContactJSONRequest(lstContact));
		}
		return mapContactJSONRequest;
	}

	//Method Name: getContactJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON Request for Contact record with its Childs - For Update Scenario
	//Parameter 1: List<Contact> lstContact - List of Contact records
	//Parameter 2: Boolean isUpdate - Boolean flag to distinguish between insert and update
	//Return: Map of record Id with its JSON request string
	public static Map<Id, String> getContactJSONRequest(List<Contact> lstContact, Boolean isUpdate, Boolean bulkJob) {
		Set<Id> setAccountId = new Set<Id>();
		Map<Id, String> mapContactJSONRequest = new Map<Id, String>();
		Map<Id, Account> mapAccount = new Map<Id, Account>();
		Map<Id, List<AccountContact>> mapAccountContactRelations = new Map<Id, List<AccountContact>>();
		Map<Id, List<ContactProfile>> mapContactProfiles = new Map<Id, List<ContactProfile>>();

		for (Contact oContact : lstContact) {
			if (oContact.AccountId != null) {
				setAccountId.add(oContact.AccountId);
			}
		}
		if (setAccountId.size() > 0) {
			for (Account acc : [SELECT Id, ERP_Account_Id__c, Unique_Id__c FROM Account WHERE Id IN :setAccountId]) {
				mapAccount.put(acc.Id, acc);
			}
		}

		for (Contact_Profile__c objCProfile : [
			SELECT
				Id,
				Contact_Profile_External_Id__c,
				Contact__c,
				Contact__r.Contact_External_Id__c,
				Profile__c,
				Profile__r.Unique_Id__c,
				Profile__r.Name,
				Tier_Type__c,
				Child_Profile_Id__c,
				Child_Profile_Name__c
			FROM Contact_Profile__c
			WHERE Contact__c IN :lstContact
		]) {
			ContactProfile objCP = new ContactProfile();
			//Not Mapping Salesforce Record Id to Siebel -- Not Required
			//objCP.Id = objCPRofile.Id;
			objCP.ContactId = objCPRofile.Contact__r.Contact_External_Id__c;
			objCP.ProfileId = objCPRofile.Profile__r.Unique_Id__c;
			objCP.ProfileName = objCPRofile.Profile__r.Name;
			//Tier1 Profile Information needed for Tier2 CP
			objCp.TierType = objCProfile.Tier_Type__c;
			objCp.ChildProfileName = objCProfile.Child_Profile_Name__c;
			objCp.ChildProfileId = objCProfile.Child_Profile_Id__c;
			if (!mapContactProfiles.containsKey(objCProfile.Contact__c)) {
				mapContactProfiles.put(objCProfile.Contact__c, new List<ContactProfile>());
			}
			mapContactProfiles.get(objCProfile.Contact__c).add(objCP);
		}

		for (AccountContactRelation objACRelation : [
			SELECT
				Id,
				ContactId,
				Contact.Contact_External_Id__c,
				IsShiptoPrimary__c,
				AccountId,
				Account.ERP_Account_Id__c,
				Account.Unique_Id__c,
				Account_Record_Type__c,
				Siebel_Row_Id__c,
				IsDirect,
				CreatedDate
			FROM AccountContactRelation
			WHERE ContactId IN :lstContact
		]) {
			AccountContact objAC = new AccountContact();
			//Not Mapping Salesforce Record Id and Siebel Row Id to Siebel -- Not Required
			//objAC.Id = objACRelation.Id;
			//objAC.Siebel_Row_Id = objACRelation.Siebel_Row_Id__c;

			//We will be replacing ERP Account Id (CSN or AccountName) with Unique Id field present at Account level -- OFM to do tranformation logic
			//objAC.AccountId = objACRelation.Account.ERP_Account_Id__c; //(objACRelation.IsDirect ? objACRelation.AccountId : objACRelation.Account.ERP_Account_Id__c);
			objAC.AccountId = objACRelation.Account.Unique_Id__c;

			//Parameter to distinguish Primary Shipto Flag value
			objAC.IsPrimaryShipto = objACRelation.IsShiptoPrimary__c;
			//Parameter to distinguish Primary SGN Account Flag value
			objAC.IsDirect = objACRelation.IsDirect;
			//Contact Siebel RowId
			if (objACRelation.Contact.Contact_External_Id__c == null) {
				objACRelation.Contact.Contact_External_Id__c = '';
			}
			objAC.ContactId = objACRelation.Contact.Contact_External_Id__c;
			//Added this Tag to differentiate SGN and ShipTo Account records in Siebel
			objAc.RecordType = objACRelation.Account_Record_Type__c;

			//Additional tag for E1 concerned
			if (objACRelation.CreatedDate >= System.now().addSeconds(-60)) {
				objAC.IsInsert = true;
			} else {
				objAC.IsInsert = false;
			}

			if (!mapAccountContactRelations.containsKey(objACRelation.ContactId)) {
				mapAccountContactRelations.put(objACRelation.ContactId, new List<AccountContact>());
			}
			mapAccountContactRelations.get(objACRelation.ContactId).add(objAC);
		}

		for (Contact oContact : lstContact) {
			//Mailing Address Transformation Logic -- Siebel Required Fields for Personal Address
			String mailingAddressRequired;
			if (
				oContact.MailingCountryCode != null ||
				oContact.MailingCity != null ||
				oContact.MailingStreet != null ||
				oContact.MailingPostalCode != null
			) {
				mailingAddressRequired = '';
				if (oContact.MailingCountryCode != null || !bulkJob) {
					mailingAddressRequired +=
						'"MailingCountryCode": ' +
						JSON.serialize(oContact.MailingCountryCode) +
						',';
				} else {
					mailingAddressRequired += '"MailingCountryCode": ".",';
				}
				if (oContact.MailingCity != null || !bulkJob) {
					mailingAddressRequired += '"MailingCity": ' + JSON.serialize(oContact.MailingCity) + ',';
				} else {
					mailingAddressRequired += '"MailingCity": ".",';
				}
				if (oContact.MailingStreet != null || !bulkJob) {
					mailingAddressRequired += '"MailingStreet": ' + JSON.serialize(oContact.MailingStreet) + ',';
				} else {
					mailingAddressRequired += '"MailingStreet": ".",';
				}
				if (oContact.MailingPostalCode != null || !bulkJob) {
					mailingAddressRequired +=
						'"MailingPostalCode": ' +
						JSON.serialize(oContact.MailingPostalCode) +
						',';
				} else {
					mailingAddressRequired += '"MailingPostalCode": ".",';
				}
			}
			if (mailingAddressRequired == null) {
				mailingAddressRequired = '';
			}

			//Contact Header Json create along with Child record info
			String json = '{ "ListOfContact": { "Contact": {';
			if (bulkJob) {
				json += '"Id" : ' + serializeJSON(oContact.Siebel_Id__c) + ',';
			} else {
				json += '"OFMInstanceId" : ' + serializeJSON('') + ',';
				json += '"List_of_Target_Systems__c" : ' + serializeJSON(oContact.List_of_Target_Systems__c) + ',';
				json += '"Contact_External_Id__c" : ' + serializeJSON(oContact.Contact_External_Id__c) + ',';
				json += '"LoginName" : ' + serializeJSON(oContact.Login_Name__c) + ',';
				json += '"X7UP_Account_Country__c" : ' + serializeJSON(oContact.X7UP_Account_Country__c) + ',';
				json +=
					'"Primary_Account_Country_Code__c" : ' +
					serializeJSON(oContact.Primary_Account_Country_Code__c) +
					',';
			}
			json += '"SFId" : ' + serializeJSON(oContact.Id) + ',';
			//json += '"AccountId": '+serializeJSON(oContact.AccountId)+',';
			json +=
				'"AccountId": ' +
				serializeJSON(
					(mapAccount.containskey(oContact.AccountId)
						? mapAccount.get(oContact.AccountId).Unique_Id__c
						: null)
				) +
				',';
			json += '"Building__c": ' + serializeJSON(oContact.Building__c) + ',';
			json += '"Web_Status__c": ' + serializeJSON(oContact.Web_Status__c) + ',';
			json += '"Active_Status_Flag__c": ' + serializeJSON(oContact.Active_Status_Flag__c) + ',';
			json += '"Alias__c": ' + serializeJSON(oContact.Alias__c) + ',';
			json += '"Phone": ' + serializeJSON(oContact.Phone) + ',';
			json += '"Comment__c": ' + serializeJSON(oContact.Comment__c) + ',';
			json += '"EOne_Id__c": ' + serializeJSON(oContact.EOne_Id__c) + ',';
			json += '"Email": ' + serializeJSON(oContact.Email) + ',';
			json += '"Alternate_Email_Address__c": ' + serializeJSON(oContact.Alternate_Email_Address__c) + ',';
			json += '"Fax": ' + serializeJSON(oContact.Fax) + ',';
			json += '"PI_First_Name__c": ' + serializeJSON(oContact.PI_First_Name__c) + ',';
			json += '"PI_Last_Name__c": ' + serializeJSON(oContact.PI_Last_Name__c) + ',';
			json += '"Income": ' + serializeJSON(oContact.Income__c) + ',';
			json += '"Title": ' + serializeJSON(oContact.Title) + ',';
			json += '"AB_Suppress_Gifts__c": ' + serializeJSON(oContact.AB_Suppress_Gifts__c) + ',';
			json += '"AB_Suppress_New_Products__c": ' + serializeJSON(oContact.AB_Suppress_New_Products__c) + ',';
			json += '"AB_Suppress_Special_Offers__c": ' + serializeJSON(oContact.AB_Suppress_Special_Offers__c) + ',';
			json +=
				'"AB_Suppress_Technical_Advice__c": ' +
				serializeJSON(oContact.AB_Suppress_Technical_Advice__c) +
				',';
			json += '"Customer_Brand__c": ' + serializeJSON(oContact.Customer_Brand__c) + ',';
			json += '"English_Name__c": ' + serializeJSON(oContact.English_Name__c) + ',';
			json += '"Profiling_Status__c": ' + serializeJSON(oContact.Profiling_Status__c) + ',';
			json += '"SAP_Contact_Number__c": ' + serializeJSON(oContact.SAP_Contact_Number__c) + ',';
			json += '"Suppress_Gifts__c": ' + serializeJSON(oContact.Suppress_Gifts__c) + ',';
			json += '"Suppress_New_Products__c": ' + serializeJSON(oContact.Suppress_New_Products__c) + ',';
			json += '"Suppress_Special_Offers__c": ' + serializeJSON(oContact.Suppress_Special_Offers__c) + ',';
			json += '"Suppress_Technical_Advice__c": ' + serializeJSON(oContact.Suppress_Technical_Advice__c) + ',';
			json += '"Web_Enabled_Flag__c": ' + serializeJSON(oContact.Web_Enabled_Flag__c) + ',';
			json += '"Discipline__c": ' + serializeJSON(oContact.Discipline__c) + ',';
			json += '"FacilityType__c": ' + serializeJSON(oContact.FacilityType__c) + ',';
			json += '"OrganizationType__c": ' + serializeJSON(oContact.OrganizationType__c) + ',';
			json += '"Lab_Name__c": ' + serializeJSON(oContact.Lab_Name__c) + ',';
			json += '"Language_Preference__c": ' + serializeJSON(oContact.Language_Preference__c) + ',';
			json += '"LastName": ' + serializeJSON(oContact.LastName) + ',';
			json += '"Gender__c": ' + serializeJSON(oContact.Gender__c) + ',';
			json += '"Salutation": ' + serializeJSON(oContact.Salutation) + ',';
			json += '"Member_Flag__c": ' + serializeJSON(oContact.Member_Flag__c) + ',';
			json += '"Phone_Opt_In__c": ' + serializeJSON(oContact.Phone_Opt_In__c) + ',';
			json += '"Email_Opt_In__c": ' + serializeJSON(oContact.Email_Opt_In__c) + ',';
			json += '"TF_B2B_Flag__c": ' + serializeJSON(oContact.TF_B2B_Flag__c) + ',';
			json += '"Type__c": ' + serializeJSON(oContact.Type__c) + ',';
			json += '"OtherPhone": ' + serializeJSON(oContact.OtherPhone) + ',';
			json += '"FirstName": ' + serializeJSON(oContact.FirstName) + ',';
			json += '"HomePhone": ' + serializeJSON(oContact.HomePhone) + ',';
			json += '"MiddleName__c": ' + serializeJSON(oContact.MiddleName__c) + ',';
			json += '"Nickname__c": ' + serializeJSON(oContact.Nickname__c) + ',';
			json += '"Suffix": ' + serializeJSON(oContact.Suffix) + ',';
			//json += '"Primary_Ship_To__c": '+serializeJSON(oContact.Primary_Ship_To__c)+',';
			json += '"Department__c": ' + serializeJSON(oContact.Department__c) + ',';
			json += '"EOne_Flag__c": ' + serializeJSON(oContact.EOne_Flag__c) + ',';
			json += '"Room__c": ' + serializeJSON(oContact.Room__c) + ',';
			json += '"SC_User__c": ' + serializeJSON(oContact.SC_User__c) + ',';
			json += '"Registration_Type__c": ' + serializeJSON(oContact.Registration_Type__c) + ',';
			json += '"Academic_Title__c": ' + serializeJSON(oContact.Academic_Title__c) + ',';
			json += '"ENTERPRISE_FLAG__c": ' + serializeJSON(oContact.ENTERPRISE_FLAG__c) + ',';
			json += '"PRIV_FLG__c": ' + serializeJSON(oContact.PRIV_FLG__c) + ',';
			json += '"SEND_FIN_FLG__c": ' + serializeJSON(oContact.SEND_FIN_FLG__c) + ',';
			json += '"SEND_NEWS_FLG__c": ' + serializeJSON(oContact.SEND_NEWS_FLG__c) + ',';
			json += '"SEND_PROMOTES_FLG__c": ' + serializeJSON(oContact.SEND_PROMOTES_FLG__c) + ',';
			json += '"SEND_SURVEY_FLG__c": ' + serializeJSON(oContact.SEND_SURVEY_FLG__c) + ',';
			json += '"VNTI_FLAG__c": ' + serializeJSON(oContact.VNTI_FLAG__c) + ',';
			json += '"MobilePhone": ' + serializeJSON(oContact.MobilePhone) + ',';
			//json += '"MailingStreet": '+serializeJSON(oContact.MailingStreet)+',';
			//json += '"MailingCity": '+serializeJSON(oContact.MailingCity)+',';
			//json += '"MailingCountryCode": '+serializeJSON(oContact.MailingCountryCode)+',';
			//json += '"MailingPostalCode": '+serializeJSON(oContact.MailingPostalCode)+',';
			json += mailingAddressRequired;
			json += '"MailingCounty__c": ' + serializeJSON(oContact.MailingCounty__c) + ',';
			json += '"MailingStateCode": ' + serializeJSON(oContact.MailingStateCode) + ',';
			json += '"MailingIncomplete__c": ' + serializeJSON(oContact.MailingIncomplete__c) + ',';
			json += '"MailingBuilding__c": ' + serializeJSON(oContact.MailingBuilding__c) + ',';
			json += '"MailingDepartment__c": ' + serializeJSON(oContact.MailingDepartment__c) + ',';
			json += '"MailingDistrict__c": ' + serializeJSON(oContact.MailingDistrict__c) + ',';
			json += '"MailingInstitute__c": ' + serializeJSON(oContact.MailingInstitute__c) + ',';
			json += '"MailingMailStop__c": ' + serializeJSON(oContact.MailingMailStop__c) + ',';
			json += '"MailingPOBox__c": ' + serializeJSON(oContact.MailingPOBox__c) + ',';
			json += '"MailingRoom__c": ' + serializeJSON(oContact.MailingRoom__c) + ',';

			List<ContactProfile> lstContactProfile = new List<ContactProfile>();
			if (mapContactProfiles.containsKey(oContact.Id)) {
				lstContactProfile = mapContactProfiles.get(oContact.Id);
			}
			if (lstContactProfile.size() > 0) {
				json += '\"ListOfContactProfile\":' + SYSTEM.JSON.serialize(lstContactProfile) + ',';
			} else if (isUpdate) {
				json += '\"ListOfContactProfile\": [],';
			}
			List<AccountContact> lstAccountContact;
			if (mapAccountContactRelations.containsKey(oContact.Id)) {
				lstAccountContact = mapAccountContactRelations.get(oContact.Id);
			}
			if (lstAccountContact != null && lstAccountContact.size() > 0) {
				json += '\"ListOfAccountContactRelation\":' + SYSTEM.JSON.serialize(lstAccountContact);
			} else {
				json += '\"ListOfAccountContactRelation\": []';
			}
			json += '}}}';
			json = json.replace('"null"', '""').replaceAll('\r\n', ' ');
			mapContactJSONRequest.put(oContact.Id, json);
		}
		return mapContactJSONRequest;
	}

	//Method Name: getDeleteContactJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON Request for Contact record with its Childs - For Delete Scenario
	//Parameter 1: List<Contact> lstContact - List of
	//Return: Map of record Id with its JSON request string
	public static Map<Id, String> getDeleteContactJSONRequest(List<Contact> lstContact) {
		Map<Id, String> mapContactJSONRequest = new Map<Id, String>();
		for (Contact oContact : lstContact) {
			String json = '{"Contact_External_Id__c":' + serializeJSON(oContact.Contact_External_Id__c) + '}';
			json = json.replace('"null"', '""');
			mapContactJSONRequest.put(oContact.Id, json);
		}
		return mapContactJSONRequest;
	}

	//Method Name: getDeleteACRelationJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON Request for AccountContactRelation Delete Scenario
	//Parameter 1: String strExternalId - Child record's external Id
	//Parameter 2: String strRelatedId - Parent Account record Id
	//Return: JSON request string
	public static String getDeleteACRelationJSONRequest(String strExternalId, String strRelatedId) {
		String jsonReq;
		jsonReq =
			'{ "ListOfContact": { "Contact": {' +
			'"Id":' +
			serializeJSON(strExternalId) +
			',' +
			'"Operation":"UPSERT",' +
			'"ListOfAccountContactRelation": [{' +
			'"AccountId":' +
			serializeJSON(strRelatedId) +
			',' +
			'"Operation":"DELETE" }]}}}';
		return jsonReq.replace('"null"', '""');
	}

	//Method Name: getDeleteCProfileJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON Request for Contact_Profile__c Delete Scenario
	//Parameter 1: String strExternalId - Child record's external Id
	//Parameter 2: String strRelatedName - related profile name
	//Parameter 2: String strRelatedId - Parent Account record Id
	//Return: JSON request string
	public static String getDeleteCProfileJSONRequest(
		String strExternalId,
		String strRelatedName,
		String strRelatedId,
		String strRelatedType
	) {
		String jsonReq;
		jsonReq =
			'{ "ListOfContact": { "Contact": {' +
			'"Id":' +
			serializeJSON(strExternalId) +
			',' +
			'"Operation":"UPSERT",' +
			'"ListOfContactProfile": [{' +
			'"TierType":' +
			serializeJSON(strRelatedType) +
			',' +
			'"ProfileId":' +
			serializeJSON(strRelatedId) +
			',' +
			'"ChildProfileId":' +
			serializeJSON(strRelatedName) +
			',' +
			'"Operation":"DELETE" }]}}}';
		return jsonReq.replace('"null"', '""');
	}

	//Method Name: getOpportunityJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON Request for Opportunity record with its Childs
	//Parameter 1: String OperationType - DML Operation Type
	//Parameter 2: List<Opportunity> lstOpportunity - List of opportunity ids
	//Return: Map of record Id with its JSON request string
	public static Map<Id, String> getOpportunityJSONRequest(String OperationType, List<Opportunity> lstOpportunity) {
		Map<Id, String> mapOpportunityJSONRequest = new Map<Id, String>();
		if (OperationType == 'INSERT') {
			mapOpportunityJSONRequest.putAll(createJSONOpp(lstOpportunity, false));
		} else if (OperationType == 'UPDATE') {
			mapOpportunityJSONRequest.putAll(createJSONOpp(lstOpportunity, true));
		}
		return mapOpportunityJSONRequest;
	}

	//Method Name: createJSONOpp
	//Author: Keste @ IDC
	//Description: Method to build JSON Request for Opportunity record with its Childs
	//Parameter 1: List<Opportunity> lstOpportunity - List of opportunity ids
	//Parameter 2: Boolean isUpdate - Boolean flag to distinguish between insert and update scenario
	//Return: Map of record Id with its JSON request string
	public static Map<Id, String> createJSONOpp(List<Opportunity> lstOpportunity, Boolean isUpdate) {
		Set<Id> setOwnerId = new Set<Id>();
		Set<Id> setAccountId = new Set<Id>();
		Set<Id> setContactId = new Set<Id>();
		Map<Id, String> mapOpportunityJSONRequest = new Map<Id, String>();
		Map<Id, String> mapUserExternalId = new Map<Id, String>();
		Map<Id, Account> mapAccount = new Map<Id, Account>();
		Map<Id, Contact> mapContact = new Map<Id, Contact>();
		Map<Id, List<OpportunityTeamMember>> mapOpportunityTeamMembers = getOpportunityTeamMembers(lstOpportunity);
		Map<Id, List<OpportunityLineItem>> mapOpportunityLineItems = getOpportunityLineItems(lstOpportunity);
		Map<Id, List<Opportunity_Product_Line__c>> mapOpportunityProductLine = getProductLines(lstOpportunity);

		for (Opportunity opp : lstOpportunity) {
			if (opp.OwnerId != null && String.valueOf(opp.OwnerId).startsWith('005')) {
				setOwnerId.add(opp.OwnerId);
			}
			if (opp.AccountId != null) {
				setAccountId.add(opp.AccountId);
			}
			if (opp.Primary_Contact__c != null) {
				setContactId.add(opp.Primary_Contact__c);
			}
		}

		if (setOwnerId.size() > 0) {
			mapUserExternalId = getUserExternalId(setOwnerId);
		}

		if (setAccountId.size() > 0) {
			for (Account oAccount : [SELECT Id, Unique_Id__c, Name FROM Account WHERE Id IN :setAccountId]) {
				mapAccount.put(oAccount.Id, oAccount);
			}
		}

		if (setContactId.size() > 0) {
			for (Contact oContact : [SELECT Id, Contact_External_Id__c FROM Contact WHERE Id IN :setContactId]) {
				mapContact.put(oContact.Id, oContact);
			}
		}

		for (Opportunity opp : lstOpportunity) {
			String jsonReq = '{ "ListOfOpportunity": { "Opportunity": {';
			jsonReq += '"SFId" :' + serializeJSON(opp.Id) + ',';
			jsonReq += '"Id" :' + serializeJSON((isUpdate ? opp.Siebel_Row_Id__c : null)) + ',';
			jsonReq +=
				'"AccountId": ' +
				serializeJSON(
					(mapAccount.containsKey(opp.AccountId) ? mapAccount.get(opp.AccountId).Unique_Id__c : null)
				) +
				',';
			jsonReq +=
				'"Account_Name__c": ' +
				serializeJSON((mapAccount.containsKey(opp.AccountId) ? mapAccount.get(opp.AccountId).Name : null)) +
				',';
			//jsonReq += '"Primary_Contact__c": '+serializeJSON( (mapContact.containsKey(opp.Primary_Contact__c) ? mapContact.get(opp.Primary_Contact__c).Contact_External_Id__c : null) )+',';
			jsonReq += '"Primary_Contact__c": ' + serializeJSON(opp.Primary_Contact_Siebel_Id__c) + ',';
			jsonReq += '"Name": ' + serializeJSON(opp.Name) + ',';
			//jsonReq += '"Amount": '+serializeJSON(opp.Amount)+',';
			jsonReq += '"CloseDate": "' + opp.CloseDate + '",';
			jsonReq += '"StageName": ' + serializeJSON(opp.StageName) + ',';
			jsonReq += '"Confidence__c": ' + serializeJSON(opp.Confidence__c) + ',';
			jsonReq += '"Status__c": ' + serializeJSON(opp.Status__c) + ',';
			jsonReq += '"Rejection_Reason__c": ' + serializeJSON(opp.Rejection_Reason__c) + ',';
			jsonReq +=
				'"Primary_Revenue_Committed_Flag__c": ' +
				serializeJSON(opp.Primary_Revenue_Committed_Flag__c) +
				',';
			jsonReq += '"CurrencyIsoCode": ' + serializeJSON(opp.CurrencyIsoCode) + ',';
			//jsonReq += '"Siebel_Assignment_Excluded__c": '+serializeJSON(opp.Siebel_Assignment_Excluded__c)+',';
			//jsonReq += '"Currency_Exchange_Date__c": "'+opp.Currency_Exchange_Date__c+'",';
			jsonReq += '"Description": ' + serializeJSON(opp.Description) + ',';
			jsonReq +=
				'"OwnerId": ' +
				serializeJSON(
					(mapUserExternalId.containsKey(opp.OwnerId) ? mapUserExternalId.get(opp.OwnerId) : null)
				) +
				',';
			//jsonReq += '"CampaignId": '+serializeJSON(opp.CampaignId)+',';
			//jsonReq += '"Territory2Id": '+serializeJSON(opp.Territory2Id)+',';
			jsonReq += '"Reason_Won_Lost__c": ' + serializeJSON(opp.Reason_Won_Lost__c) + ',';
			//jsonReq += '"Consumable_Products__c": '+serializeJSON(opp.Consumable_Products__c)+',';
			jsonReq += '"Demo_Onsite__c": ' + serializeJSON(opp.Demo_Onsite__c) + ',';
			jsonReq += '"FOB__c": ' + serializeJSON(opp.FOB__c) + ',';
			//jsonReq += '"Lead_Capture_Date__c": "'+opp.Lead_Capture_Date__c+'",';
			//jsonReq += '"Lead_Score__c": '+serializeJSON(opp.Lead_Score__c)+',';
			//jsonReq += '"Request_Quote__c": '+serializeJSON(opp.Request_Quote__c)+',';
			//jsonReq += '"Request_Sales_Rep_Contact__c": '+serializeJSON(opp.Request_Sales_Rep_Contact__c)+',';
			jsonReq += '"Rev_Rec_At_Risk__c": ' + serializeJSON(opp.Rev_Rec_At_Risk__c) + ',';
			jsonReq += '"Direct_Indirect__c": ' + serializeJSON(opp.Direct_Indirect__c) + ',';
			jsonReq += '"DM_Forecast__c": ' + serializeJSON(opp.DM_Forecast__c) + ',';
			jsonReq += '"End_Customer_Account__c": ' + serializeJSON(opp.End_Customer_Account_ExternalId__c) + ',';
			//jsonReq += '"End_Customer_Contact__c": '+serializeJSON(opp.End_Customer_Contact_ExternalId__c)+',';
			jsonReq += '"End_Customer_Contact__c": ' + serializeJSON(opp.End_Customer_Contact_Siebel_Id__c) + ',';
			jsonReq += '"Consignment_Flag__c": ' + serializeJSON(opp.Consignment_Flag__c) + ',';
			//jsonReq += '"CID__c": '+serializeJSON(opp.CID__c)+',';
			//jsonReq += '"ICID__c": '+serializeJSON(opp.ICID__c)+',';
			jsonReq += '"Lost_Order_Detail__c": ' + serializeJSON(opp.Lost_Order_Detail__c) + ',';
			jsonReq += '"Opportunity_Source__c": ' + serializeJSON(opp.Opportunity_Source__c) + ',';
			jsonReq += '"Type": ' + serializeJSON(opp.Type) + ',';
			jsonReq += '"Rep_Estimated_Amount__c": ' + serializeJSON(opp.Rep_Estimated_Amount__c) + '';
			if (isUpdate) {
				jsonReq +=
					',' +
					'\"ListOfOpportunityProducts\":' +
					(mapOpportunityLineItems.containsKey(opp.Id)
						? getOpportunityProductJSON(mapOpportunityLineItems.get(opp.Id))
						: '[]');
				jsonReq +=
					',' +
					'\"ListOfOpportunityTeamMembers\":' +
					(mapOpportunityTeamMembers.containsKey(opp.Id)
						? getOpportunityTeamMemberJSON(mapOpportunityTeamMembers.get(opp.Id))
						: '[]');
				jsonReq +=
					',' +
					'\"ListOfOpportunityLine\":' +
					(mapOpportunityProductLine.containsKey(opp.Id)
						? getProductLineJSON(mapOpportunityProductLine.get(opp.Id))
						: '[]');
			}
			jsonReq += '}}}';
			jsonReq = jsonReq.replace('"null"', '""').replaceAll('\r\n', ' ');
			mapOpportunityJSONRequest.put(opp.Id, jsonReq);
		}

		return mapOpportunityJSONRequest;
	}

	//Method Name: getUserExternalId
	//Author: Keste @ IDC
	//Description: Method to get map of user record id vs their external Ids
	//Parameter 1: Set<Id> setOwnerId - Set of user Ids to be fetched
	//Return: Map of user record Id with its External id
	public static Map<Id, String> getUserExternalId(Set<Id> setOwnerId) {
		Map<Id, String> mapUserExternalId = new Map<Id, String>();
		for (User oUser : [SELECT Id, User_External_Id__c FROM USER WHERE Id IN :setOwnerId]) {
			mapUserExternalId.put(oUser.Id, oUser.User_External_Id__c);
		}
		return mapUserExternalId;
	}

	//Method Name: getDeleteOpportunityProductsJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON record for Opportunity Product's Deletion
	//Parameter 1: String strExternalId - Child record's external Id
	//Parameter 2: String strRelatedId - related Product Id
	//Parameter 3: String strRelatedName - related Product name
	//Return: JSON Request String
	public static String getDeleteOpportunityProductsJSONRequest(
		String strExternalId,
		String strRelatedId,
		String strRelatedName
	) {
		String jsonReq;
		jsonReq =
			'{ "ListOfOpportunity": { "Opportunity": {' +
			'"Id":' +
			serializeJSON(strExternalId) +
			',' +
			'"Operation":"UPSERT",' +
			'"ListOfOpportunityProducts": [{' +
			'"ProductId":' +
			serializeJSON(strRelatedId) +
			',' +
			'"Product_Name__c":' +
			serializeJSON(strRelatedName) +
			',' +
			'"Operation":"DELETE" }]}}}';
		return jsonReq.replace('"null"', '""');
	}

	//Method Name: getDeleteOpportunityLineJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON record for Opportunity Line's Deletion
	//Parameter 1: String strExternalId - Child record's external Id
	//Parameter 2: String strRelatedId - related Product Line Id
	//Parameter 3: String strRelatedName - related Product Line name
	//Return: JSON Request String
	public static String getDeleteOpportunityLineJSONRequest(
		String strExternalId,
		String strRelatedId,
		String strRelatedName
	) {
		String jsonReq;
		jsonReq =
			'{ "ListOfOpportunity": { "Opportunity": {' +
			'"Id":' +
			serializeJSON(strExternalId) +
			',' +
			'"Operation":"UPSERT",' +
			'"ListOfOpportunityLine": [{' +
			'"Product_Line__c":' +
			serializeJSON(strRelatedId) +
			',' +
			'"Name":' +
			serializeJSON(strRelatedName) +
			',' +
			'"Operation":"DELETE" }]}}}';
		return jsonReq.replace('"null"', '""');
	}

	//Method Name: getDeleteOpportunityTeamMembersJSONRequest
	//Author: Keste @ IDC
	//Description: Method to build JSON record for Opportunity Team Member's Deletion
	//Parameter 1: String strExternalId - Child record's external Id
	//Parameter 2: String strRelatedId - related team member's user Id
	//Parameter 3: String strPositionId - team member's position
	//Return: JSON Request String
	public static String getDeleteOpportunityTeamMembersJSONRequest(
		String strExternalId,
		String strRelatedId,
		String strPositionId
	) {
		String jsonReq;
		jsonReq =
			'{ "ListOfOpportunity": { "Opportunity": {' +
			'"Id":' +
			serializeJSON(strExternalId) +
			',' +
			'"Operation":"UPSERT",' +
			'"ListOfOpportunityTeamMembers": [{' +
			'"UserId":' +
			serializeJSON(strRelatedId) +
			',' +
			'"Position__c":' +
			serializeJSON(strPositionId) +
			',' +
			'"Operation":"DELETE" }]}}}';
		return jsonReq.replace('"null"', '""');
	}

	//Method Name: getOpportunityTeamMembers
	//Author: Keste @ IDC
	//Description: Method to fetch all child team members for a list of Opportunities
	//Parameter 1: List<Opportunity> lstOpportunity - Opportunity record List
	//Return: Map of parent opportunity record Id wise all its child team members
	public static Map<Id, List<OpportunityTeamMember>> getOpportunityTeamMembers(List<Opportunity> lstOpportunity) {
		Map<Id, List<OpportunityTeamMember>> mapOpportunityTeamMembers = new Map<Id, List<OpportunityTeamMember>>();
		for (OpportunityTeamMember objOTMember : [
			SELECT
				Id,
				UserId,
				User.User_External_Id__c,
				TeamMemberRole,
				OpportunityId,
				Opportunity.Siebel_Row_Id__c,
				OpportunityAccessLevel,
				isPrimary__c,
				Position__c
			FROM OpportunityTeamMember
			WHERE OpportunityId IN :lstOpportunity AND User.User_External_Id__c != NULL
		]) {
			if (!mapOpportunityTeamMembers.containsKey(objOTMember.OpportunityId)) {
				mapOpportunityTeamMembers.put(objOTMember.OpportunityId, new List<OpportunityTeamMember>());
			}
			mapOpportunityTeamMembers.get(objOTMember.OpportunityId).add(objOTMember);
		}
		return mapOpportunityTeamMembers;
	}

	//Method Name: getOpportunityTeamMemberJSON
	//Author: Keste @ IDC
	//Description: Method to build JSON part for the child Opportunity team membere
	//Parameter 1: List<OpportunityTeamMember> lstOpportunityTeamMember - Opportunity Team member record List
	//Return: JSON Request String
	public static String getOpportunityTeamMemberJSON(List<OpportunityTeamMember> lstOpportunityTeamMember) {
		String OppTeamMemberJSON = '[';
		String glue = '';
		for (OpportunityTeamMember objOTMember : lstOpportunityTeamMember) {
			OppTeamMemberJSON += glue + '{';
			OppTeamMemberJSON += '"SFId":' + serializeJSON(objOTMember.Id) + ',';
			OppTeamMemberJSON += '"UserId":' + serializeJSON(objOTMember.User.User_External_Id__c) + ',';
			OppTeamMemberJSON += '"TeamMemberRole":' + serializeJSON(objOTMember.TeamMemberRole) + ',';
			OppTeamMemberJSON += '"OpportunityAccessLevel":' + serializeJSON(objOTMember.OpportunityAccessLevel) + ',';
			OppTeamMemberJSON += '"OpportunityId":' + serializeJSON(objOTMember.Opportunity.Siebel_Row_Id__c) + ',';
			OppTeamMemberJSON += '"isPrimary__c":' + objOTMember.isPrimary__c + ',';
			OppTeamMemberJSON += '"Position__c":' + serializeJSON(objOTMember.Position__c) + '';
			OppTeamMemberJSON += '}';
			glue = ',';
		}
		OppTeamMemberJSON = OppTeamMemberJSON.replace('"null"', '""');
		OppTeamMemberJSON += ']';
		return OppTeamMemberJSON;
	}

	//Method Name: getOpportunityLineItems
	//Author: Keste @ IDC
	//Description: Method to fetch all child opportunity line items for a list of Opportunities
	//Parameter 1: List<Opportunity> lstOpportunity - Opportunity record List
	//Return: Map of parent opportunity record Id wise all its child opportunity line items
	public static Map<Id, List<OpportunityLineItem>> getOpportunityLineItems(List<Opportunity> lstOpportunity) {
		Map<Id, List<OpportunityLineItem>> mapOpportunityLineItems = new Map<Id, List<OpportunityLineItem>>();
		for (OpportunityLineItem oppLineItem : [
			SELECT
				Id,
				Quantity,
				Product2Id,
				Product2.Unique_Id__c,
				OpportunityId,
				Product2.Alias_Name__c,
				Opportunity.Siebel_Row_Id__c,
				Primary__c,
				UnitPrice
			FROM OpportunityLineItem
			WHERE OpportunityId IN :lstOpportunity AND Product2.Unique_Id__c != NULL
		]) {
			if (!mapOpportunityLineItems.containsKey(oppLineItem.OpportunityId)) {
				mapOpportunityLineItems.put(oppLineItem.OpportunityId, new List<OpportunityLineItem>());
			}
			mapOpportunityLineItems.get(oppLineItem.OpportunityId).add(oppLineItem);
		}
		return mapOpportunityLineItems;
	}

	//Method Name: getOpportunityProductJSON
	//Author: Keste @ IDC
	//Description: Method to build JSON part for the child Opportunity Line Item
	//Parameter 1: List<OpportunityLineItem> lstOpportunityLineItem - Opportunity Line Item record List
	//Return: JSON Request String
	public static String getOpportunityProductJSON(List<OpportunityLineItem> lstOpportunityLineItem) {
		String oppLineItemJSON = '[';
		String glue = '';
		for (OpportunityLineItem oppLineItem : lstOpportunityLineItem) {
			oppLineItemJSON += glue + '{';
			oppLineItemJSON += '"SFId":' + serializeJSON(oppLineItem.Id) + ',';
			oppLineItemJSON += '"OpportunityId":' + serializeJSON(oppLineItem.Opportunity.Siebel_Row_Id__c) + ',';
			oppLineItemJSON += '"ProductId":' + serializeJSON(oppLineItem.Product2.Unique_Id__c) + ',';
			oppLineItemJSON += '"Product_Name__c":' + serializeJSON(oppLineItem.Product2.Alias_Name__c) + ',';
			oppLineItemJSON += '"Primary__c":' + serializeJSON(oppLineItem.Primary__c) + ',';
			oppLineItemJSON += '"UnitPrice":' + serializeJSON(oppLineItem.UnitPrice) + ',';
			oppLineItemJSON += '"Quantity":' + serializeJSON(oppLineItem.Quantity) + '';
			oppLineItemJSON += '}';
			glue = ',';
		}
		oppLineItemJSON = oppLineItemJSON.replace('"null"', '""');
		oppLineItemJSON += ']';
		return oppLineItemJSON;
	}

	//Method Name: getOpportunityLineItems
	//Author: Keste @ IDC
	//Description: Method to fetch all child opportunity line items for a list of Opportunities
	//Parameter 1: List<Opportunity> lstOpportunity - Opportunity record List
	//Return: Map of parent opportunity record Id wise all its child opportunity line items
	public static Map<Id, List<Opportunity_Product_Line__c>> getProductLines(List<Opportunity> lstOpportunity) {
		Map<Id, List<Opportunity_Product_Line__c>> mapProductLines = new Map<Id, List<Opportunity_Product_Line__c>>();
		for (Opportunity_Product_Line__c oppProductline : [
			SELECT
				Id,
				Opportunity__c,
				Opportunity__r.Siebel_Row_Id__c,
				Primary__c,
				Product_Line__c,
				Product_Line__r.Unique_Id__c,
				Product_Line__r.Name
			FROM Opportunity_Product_Line__c
			WHERE Opportunity__c IN :lstOpportunity AND Product_Line__r.Unique_Id__c != NULL
		]) {
			if (!mapProductLines.containsKey(oppProductline.Opportunity__c)) {
				mapProductLines.put(oppProductline.Opportunity__c, new List<Opportunity_Product_Line__c>());
			}
			mapProductLines.get(oppProductline.Opportunity__c).add(oppProductline);
		}
		return mapProductLines;
	}

	//Method Name: getProductLineJSON
	//Author: Keste @ IDC
	//Description: Method to build JSON part for the child Opportunity Product Line
	//Parameter 1: List<Opportunity_Product_Line__c> lstProductLines - Opportunity Product Line record List
	//Return: JSON Request String
	public static String getProductLineJSON(List<Opportunity_Product_Line__c> lstProductLines) {
		String productLineJSON = '[';
		String glue = '';
		for (Opportunity_Product_Line__c oppProductline : lstProductLines) {
			productLineJSON += glue + '{';
			productLineJSON += '"SFId":' + serializeJSON(oppProductline.Id) + ',';
			productLineJSON +=
				'"Opportunity__c":' +
				serializeJSON(oppProductline.Opportunity__r.Siebel_Row_Id__c) +
				',';
			productLineJSON += '"Primary__c":' + oppProductline.Primary__c + ',';
			productLineJSON += '"Name":' + serializeJSON(oppProductline.Product_Line__r.Name) + ',';
			productLineJSON += '"Product_Line__c":' + serializeJSON(oppProductline.Product_Line__r.Unique_Id__c) + '';
			productLineJSON += '}';
			glue = ',';
		}
		productLineJSON = productLineJSON.replace('"null"', '""');
		productLineJSON += ']';
		return productLineJSON;
	}

	//Wrapper Class Name : ContactProfile
	//Author: Keste @ IDC
	//Description: Wrapper class to store Contact Profile Record detials
	public class ContactProfile {
		//public Id Id { get; set;}
		//public string Contact_Profile_External_Id { get; set;}
		public string ContactId { get; set; }
		public string ProfileId { get; set; }
		public string ProfileName { get; set; }
		public string TierType { get; set; }
		public string ChildProfileName { get; set; }
		public string ChildProfileId { get; set; }
	}

	//Wrapper Class Name : AccountContact
	//Author: Keste @ IDC
	//Description: Wrapper class to store Account Contact Role Record detials
	public class AccountContact {
		//public Id Id { get; set;}
		//public string Siebel_Row_Id { get; set;}
		public string AccountId { get; set; }
		public string ContactId { get; set; }
		public Boolean IsDirect { get; set; }
		public Boolean IsInsert { get; set; }
		public Boolean IsPrimaryShipto { get; set; }
		public string RecordType { get; set; }
	}

	//Method Name : serializeJSON
	//Author: Basant Verma @ KESTE IDC
	//Description: Generic Method to serailize the input string to a valid JSON format to avoid special char handing
	//Parameter 1: Object ob - Any Type input to be serialized
	//Return: JSON Formated String
	public static String serializeJSON(Object ob) {
		String serializedSring = '""';
		if (ob != null) {
			serializedSring = JSON.serialize(ob);
		}
		return serializedSring;
	}
}