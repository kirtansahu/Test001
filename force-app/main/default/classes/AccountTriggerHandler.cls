// ===========================================================================
//  Object  : AccountTriggerHandler
//  Company : Keste @IDC
//  Author  : Abinash Panigrahi
//  Purpose : Handler Class contains all logic for AccountTrigger.
// ===========================================================================
public class AccountTriggerHandler {
	// Method Name: parentalSetup
	// Author: Abinash panigrahi
	// Description: Method to setup Parental Structure -- Insertion Action
	// Parameter 1: newRec - List of the new versions of the Account records
	// Return: Null
	// Changes Impact: ParentalSetupAccountTeamCascade_Batch, AccountTeamTriggerHandler
	public static void parentalSetup(List<Account> newRec) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTriggerHandler.parentalSetup')) {
			//Instance to store all NSGN,SGN,ShipTo Recordtype Ids
			Set<Id> recordTypeIds = new Set<Id>();
			recordTypeIds.add(NSGN_RECORDTYPE_ID);
			recordTypeIds.add(SGN_RECORDTYPE_ID);
			recordTypeIds.add(SHIPTO_RECORDTYPE_ID);

			//Instance to store all Unique Siebel Parent Row Ids
			Set<String> siebelParentIds = new Set<String>();
			//Populate the Instance with values
			for (Account a : newRec) {
				if (a.Parent_Unique_Id__c != null && recordTypeIds.contains(a.RecordTypeId)) {
					siebelParentIds.add(a.Parent_Unique_Id__c);
				}
				if (a.Primary_Bill_To_Unique_Id__c != null && a.RecordTypeId == SHIPTO_RECORDTYPE_ID) {
					siebelParentIds.add(a.Primary_Bill_To_Unique_Id__c);
				}
			}

			//Store relationship of Siebel Row Id and Salesforce Id
			Map<String, Id> siebelSFIdMap = new Map<String, Id>();
			for (Account a : [SELECT Id, Unique_Id__c FROM Account WHERE Unique_Id__c IN :siebelParentIds]) {
				siebelSFIdMap.put(a.Unique_Id__c, a.Id);
			}

			//Update ParentId to setup Account Hierarchy
			for (Account a : newRec) {
				if (
					a.Parent_Unique_Id__c != null &&
					recordTypeIds.contains(a.RecordTypeId) &&
					siebelSFIdMap.containsKey(a.Parent_Unique_Id__c)
				) {
					a.ParentId = siebelSFIdMap.get(a.Parent_Unique_Id__c);
				}

				//Exclude from Hierarchy Checkbox field
				if (
					a.Parent_Unique_Id__c != null &&
					recordTypeIds.contains(a.RecordTypeId) &&
					!siebelSFIdMap.containsKey(a.Parent_Unique_Id__c)
				) {
					a.Exclude_From_Hierarchy__c = true;
				}
				// Added Source_System__c == 'SAP' on 08/25
				if (
					a.Parent_Unique_Id__c != null &&
					a.RecordTypeId == SHIPTO_RECORDTYPE_ID &&
					(a.Primary_Bill_To_Unique_Id__c != null ||
					a.Child_Unique_Id__c != null ||
					a.Source_System__c == 'SAP')
				) {
					a.Exclude_From_Hierarchy__c = true;
				}

				//Primary BillTo Lookup field
				if (
					a.Primary_Bill_To_Unique_Id__c != null &&
					a.RecordTypeId == SHIPTO_RECORDTYPE_ID &&
					siebelSFIdMap.containsKey(a.Primary_Bill_To_Unique_Id__c)
				) {
					a.Primary_Bill_To__c = siebelSFIdMap.get(a.Primary_Bill_To_Unique_Id__c);
				}
			}
		}
	}

	// Method Name: updateParentalSetup
	// Author: Abinash panigrahi
	// Description: Method to setup Parental Structure -- Updation Action
	// Parameter 1: newRec - List of the new versions of the Account records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Account records
	// Return: Null
	// Changes Impact: ParentalSetupAccountTeamCascade_Batch, AccountTeamTriggerHandler
	public static void updateParentalSetup(List<Account> newRec, Map<Id, Account> oldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTriggerHandler.updateParentalSetup')) {
			//Instance to store Account records with changed Siebel Parent Row Id value
			List<Account> toBeUpdated = new List<Account>();
			for (Account a : newRec) {
				if (
					(a.Parent_Unique_Id__c != oldMap.get(a.Id).Parent_Unique_Id__c &&
					a.Parent_Unique_Id__c != null) ||
					(a.Primary_Bill_To_Unique_Id__c != oldMap.get(a.Id).Primary_Bill_To_Unique_Id__c &&
					a.Primary_Bill_To_Unique_Id__c != null) ||
					(a.Child_Unique_Id__c != oldMap.get(a.Id).Child_Unique_Id__c &&
					a.Child_Unique_Id__c != null)
				) {
					toBeUpdated.add(a);
				}
				//Condition: If Siebel Parent Row Id is changed to Blank, then remove Account record from Account Hierarchy
				if (a.Parent_Unique_Id__c != oldMap.get(a.Id).Parent_Unique_Id__c && a.Parent_Unique_Id__c == null) {
					a.ParentId = null;
				}
				//Condition: If Siebel Primary BillTo Row Id is changed to Blank, then remove Account record from Account Hierarchy
				if (
					a.Primary_Bill_To_Unique_Id__c != oldMap.get(a.Id).Primary_Bill_To_Unique_Id__c &&
					a.Primary_Bill_To_Unique_Id__c == null
				) {
					a.Primary_Bill_To__c = null;
				}
			}

			//Code-Reusability
			//Update ParentId with new value
			if (toBeUpdated.size() > 0) {
				parentalSetup(toBeUpdated);
			}

			//Upon Updating the Hierarchy, mark it as Excluded from Hierarchy
			for (Account a : toBeUpdated) {
				a.Exclude_From_Hierarchy__c = true;
			}
		}
	}

	// Method Name: shipToBillToRelationSetup
	// Author: Abinash panigrahi
	// Description: Method to setup Relationship between ShipTo & BillTo -- Updation Action
	// Parameter 1: newRec - List of the new versions of the Account records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Account records
	// Return: Null
	// Changes Impact: ParentalSetupAccountTeamCascade_Batch, AccountTeamTriggerHandler
	public static void shipToBillToRelationSetup(List<Account> newRec, Map<Id, Account> oldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTriggerHandler.shipToBillToRelationSetup')) {
			//Instance to store ShipTo account records
			List<Account> shipTo = new List<Account>();
			//Instance to store Child BillTo UniqueIds
			Set<String> childBillToIds = new Set<String>();
			//Instance to store to be Deleted ShipToBillTo junction records
			Set<Id> toBeDeleted = new Set<Id>();

			for (Account a : newRec) {
				//Check for Shipto RecordType
				if (a.RecordTypeId == SHIPTO_RECORDTYPE_ID) {
					//Check for change in Primary BillTo UniqueId value or Child UniqueId
					if (
						a.Child_Unique_Id__c != null &&
						(oldMap == null ||
						a.Child_Unique_Id__c != oldMap.get(a.Id).Child_Unique_Id__c)
					) {
						childBillToIds.add(a.Child_Unique_Id__c);
						shipTo.add(a);
					}
					if (oldMap != null && a.Child_Unique_Id__c != oldMap.get(a.Id).Child_Unique_Id__c) {
						toBeDeleted.add(a.Id);
					}
				}
			}

			if (toBeDeleted != null && toBeDeleted.size() > 0) {
				//Fetch existing related ShipToBillTo junction object records to be deleted
				List<ShipTo_BillTo__c> toBeDeletedRec = [
					SELECT Id
					FROM ShipTo_BillTo__c
					WHERE Ship_To__c IN :toBeDeleted
				];
				//Exception Handling
				//Delete BillToShipTo junction object records
				try {
					if (toBeDeletedRec.size() > 0) {
						delete toBeDeletedRec;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'AccountTriggerHandler',
						'shipToBillToRelationSetup',
						'Trigger Logic',
						'Delete BillToShipTo',
						ex.getMessage(),
						System.today()
					);
				}
			}

			if (childBillToIds != null && childBillToIds.size() > 0) {
				//Map to store relationship between UniqueId and RecordId of BillTo Account
				Map<String, Id> billToMap = new Map<String, Id>();
				//Fetch related BillTo Account records
				for (Account a : [SELECT Id, Unique_Id__c FROM Account WHERE Unique_Id__c IN :childBillToIds]) {
					billToMap.put(a.Unique_Id__c, a.Id);
				}

				//Instance to store to be inserted records
				List<ShipTo_BillTo__c> toBeInsertedRec = new List<ShipTo_BillTo__c>();
				//Create BillToShipTo junction object records for Child BillTo
				for (Account a : shipTo) {
					if (a.Child_Unique_Id__c != null && billToMap.containsKey(a.Child_Unique_Id__c)) {
						toBeInsertedRec.add(
							new ShipTo_BillTo__c(Ship_To__c = a.Id, Bill_To__c = billToMap.get(a.Child_Unique_Id__c))
						);
					}
				}

				//Exception Handling
				//Insert BillToShipTo junction object records
				try {
					if (toBeInsertedRec.size() > 0) {
						insert toBeInsertedRec;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'AccountTriggerHandler',
						'shipToBillToRelationSetup',
						'Trigger Logic',
						'Insert BillToShipTo',
						ex.getMessage(),
						System.today()
					);
				}
			}
		}
	}

	// Method Name: rollupPriceBook
	// Author: Abinash panigrahi
	// Description: Method to update rollup checkbox on Shipto Account records
	// Parameter 1: newRec - List of the new versions of the Account records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Account records
	// Return: Null
	public static void rollupPriceBook(List<Account> newRec, Map<Id, Account> oldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTriggerHandler.rollupPriceBook')) {
			//Mark the Rollup Checkbox for Shipto records
			//Check for Active Shiptos and Source System change
			//Capture Pricebook field not NULL and change in field value
			for (Account obj : newRec) {
				if (obj.RecordTypeId == SHIPTO_RECORDTYPE_ID) {
					if (
						(oldMap == null &&
						obj.Account_Status__c == 'Active' &&
						obj.Price_Book__c != null &&
						obj.Source_System__c != null) ||
						(oldMap != null &&
						(obj.Account_Status__c != oldMap.get(obj.Id).Account_Status__c ||
						obj.Price_Book__c != oldMap.get(obj.Id).Price_Book__c ||
						obj.Source_System__c != oldMap.get(obj.Id).Source_System__c))
					) {
						obj.Exclude_From_Rollup__c = true;
					}
				}
			}
		}
	}

	// Method Name: populateCountryWiseOrganizationRegion
	// Author: Abinash panigrahi
	// Description: Method to update Organization/Region field based on Country values
	// Parameter 1: newRec - List of the new versions of the Account records
	// Return: Null
	public static void populateCountryWiseOrganizationRegion(List<Account> newRec) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTriggerHandler.populateCountryWiseOrganization')) {
			//Instance to hold relationship between Country and Region values
			Map<String, String> regionMap = new Map<String, String>();
			for (Account a : newRec) {
				if (a.BillingCountryCode != null && a.RecordTypeId != SHIPTO_RECORDTYPE_ID) {
					regionMap.put(a.BillingCountryCode, null);
				}
				if (a.ShippingCountryCode != null && a.RecordTypeId == SHIPTO_RECORDTYPE_ID) {
					regionMap.put(a.ShippingCountryCode, null);
				}
			}

			//Query related Country-Region mapping
			for (Country_Region_Mapping__c cr : [
				SELECT Name, Country_Code__c, Region__c
				FROM Country_Region_Mapping__c
				WHERE Country_Code__c IN :regionMap.keySet()
			]) {
				regionMap.put(cr.Country_Code__c, cr.Region__c);
			}

			//Loop Logic
			//To load Organization field with proper data based on Country field
			for (Account a : newRec) {
				if (regionMap.containskey(a.BillingCountryCode) && a.RecordTypeId != SHIPTO_RECORDTYPE_ID) {
					a.Region__c = regionMap.get(a.BillingCountryCode);
				} else if (regionMap.containskey(a.ShippingCountryCode) && a.RecordTypeId == SHIPTO_RECORDTYPE_ID) {
					a.Region__c = regionMap.get(a.ShippingCountryCode);
				} else {
					a.Region__c = null;
				}
			}
		}
	}

	// Method Name: invokeAssetAccountBackendUpdate
	// Author: Jayaram B
	// Description: Method to Pass All Name Field Updated Account records to AssetHandler
	// Parameter 1: newRec - List of the new versions of the Account records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Account records
	// Return: Null
	public static void invokeAssetAccountBackendUpdate(List<Account> newRec, Map<Id, Account> oldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTriggerHandler.invokeAssetAccountBackendUpdate')) {
			//Map to hold the Name Field Updated Account Records
			Map<Id, Account> mapAccNameUpdate = new Map<Id, Account>();
			for (Account accRecData : newRec) {
				//Check Name Field Updatd or Not
				if (oldMap.get(accRecData.Id).Name != accRecData.Name) {
					mapAccNameUpdate.put(accRecData.Id, accRecData);
				}
			}
			if (mapAccNameUpdate.size() > 0) {
				//Pass the Name Field Updated Account Records to the AssetTriggerHandler
				AssetTriggerHandler.updateBackendSearchFields(mapAccNameUpdate, 'Account');
			}
		}
	}

	// Method Name: tagChildAccountsTerritoryAlignment
	// Author: Abinash Panigrahi
	// Description: Method to run asynchronous update logic for all child records of Site SGN
	// Parameter 1: newRec - List of the new versions of the Account records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Account records
	// Return: Null
	public static void tagChildAccountsTerritoryAlignment(List<Account> newRec, Map<Id, Account> oldMap) {
		if (DynamicCodeExecution.allowExecution('AccountTriggerHandler.invokeAssetAccountBackendUpdate')) {
			Boolean configAllow = [SELECT Shipto_Rolldown_Alignment__c FROM Parent_Territory_Node__mdt LIMIT 1]
			.Shipto_Rolldown_Alignment__c;

			if (configAllow) {
				Set<String> fieldSet = new Set<String>();
				for (
					Schema.FieldSetMember fields : Schema.SObjectType.Account.fieldSets.getMap()
						.get('Territory_Rules_Used_Fields')
						.getFields()
				) {
					fieldSet.add(fields.getFieldPath());
				}

				Set<Id> accIds = new Set<Id>();
				for (Account acc : newRec) {
					if (acc.RecordTypeId == SGN_RECORDTYPE_ID) {
						for (string strFieldAPI : fieldSet) {
							if (
								acc.get(strFieldAPI) != oldMap.get(acc.Id).get(strFieldAPI) ||
								(acc.TriggerAssignment__c &&
								acc.TriggerAssignment__c != oldMap.get(acc.Id).TriggerAssignment__c)
							) {
								accIds.add(acc.Id);
							}
						}
					} else if (acc.RecordTypeId == SHIPTO_RECORDTYPE_ID) {
						if (
							acc.TriggerAssignment__c &&
							acc.TriggerAssignment__c != oldMap.get(acc.Id).TriggerAssignment__c
						) {
							accIds.add(acc.Id);
						}
					}
				}

				if (accIds.size() > 0) {
					for (Account acc : [
						SELECT Id
						FROM Account
						WHERE ParentId IN :accIds AND RecordTypeId = :SHIPTO_RECORDTYPE_ID
					]) {
						accIds.add(acc.Id);
					}
					List<Territory_Realign__e> events = new List<Territory_Realign__e>();
					for (Id obj : accIds) {
						events.add(new Territory_Realign__e(RecordId__c = obj));
					}
					EventBus.publish(events);
				}
			}
		}
	}

	// Method Name: triggerPlatformEventAPICallout
	// Author: Abinash Panigrahi
	// Description: Method to make self-callout to trigger Territory Realignment
	// Parameter 1: accountId - SGN/ShipTo Account Record
	// Parameter 2: sessionId - Admin User current session info
	// Return: Null
	@future(callout=true)
	public static void triggerPlatformEventAPICallout(List<String> accountIds) {
		Boolean proceedFurther = false;
		List<Apex_Log__c> responseLogger = new List<Apex_Log__c>();
		for (Integer i = 1; i <= 1; i++) {
			if (proceedFurther) {
				break;
			}
			JSONGenerator jsGen = JSON.createGenerator(true);
			jsGen.writeStartObject();
			jsGen.writeFieldName('batchRequests');
			jsGen.writeStartArray();
			for (Integer j = 1; j <= 25; j++) {
				if ((i - 1) * 25 + j > accountIds.size()) {
					proceedFurther = true;
					break;
				}

				jsGen.writeStartObject();
				jsGen.writeStringField('method', 'PATCH');
				jsGen.writeStringField(
					'url',
					'/services/data/v50.0/sobjects/Account/' + accountIds.get((i - 1) * 25 + j - 1)
				);
				jsGen.writeFieldName('richInput');
				jsGen.writeStartObject();
				jsGen.writeStringField('TriggerAssignment__c', 'false');
				jsGen.writeEndObject();
				jsGen.writeEndObject();
			}
			jsGen.writeEndArray();
			jsGen.writeEndObject();
			jsGen.close();
			String requestBody = jsGen.getAsString();
			if (proceedFurther) {
				System.debug('Request -----> ' + jsGen.getAsString());
			}

			HttpRequest request = new HttpRequest();
			request.setEndpoint('callout:Territory_Realignment/services/data/v50.0/composite/batch/');
			request.setMethod('POST');
			request.setHeader('Sforce-Auto-Assign', 'true');
			request.setHeader('Content-Type', 'application/json');
			request.setTimeout(1000);

			request.setBody(requestBody);

			responseLogger.add(
				new Apex_Log__c(
					Location__c = 'TerritoryRealignmentCallout',
					Method_name__c = 'execute',
					Application_Name__c = 'Asynchronous Logic',
					Log_Comments__c = 'Trigger Territory Realignment for Accouncts updated from Dataloader - Workaround flow',
					Integration_Request__c = String.valueOf(request) + '\n' + requestBody,
					Integration_Status__c = 'Success',
					Fixed_Date__c = System.today()
				)
			);

			try {
				HttpResponse response = new Http().send(request);
				System.debug('Response -----> ' + response.getBody());
			} catch (Exception ex) {
			}
		}

		if (responseLogger.size() > 0) {
			insert responseLogger;
		}
	}

	//map of all account record types
	private static Map<String, Schema.RecordTypeInfo> accountRecordTypes {
		get {
			if (accountRecordTypes == null) {
				accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
			}
			return accountRecordTypes;
		}
		set;
	}
	//Global SGN Record Type ID
	public static Id GSGN_RECORDTYPE_ID {
		get {
			if (GSGN_RECORDTYPE_ID == null && accountRecordTypes != null) {
				GSGN_RECORDTYPE_ID = accountRecordTypes.get(Label.ACCOUNT_RECORD_GLOBAL_SGN).getRecordTypeId();
			}
			return GSGN_RECORDTYPE_ID;
		}
		protected set;
	}
	//BillTo Record Type ID
	public static Id BILLTO_RECORDTYPE_ID {
		get {
			if (BILLTO_RECORDTYPE_ID == null && accountRecordTypes != null) {
				BILLTO_RECORDTYPE_ID = accountRecordTypes.get(Label.ACCOUNT_RECORD_BILLTO).getRecordTypeId();
			}
			return BILLTO_RECORDTYPE_ID;
		}
		protected set;
	}
	//ShipTo Record Type ID
	public static Id SHIPTO_RECORDTYPE_ID {
		get {
			if (SHIPTO_RECORDTYPE_ID == null && accountRecordTypes != null) {
				SHIPTO_RECORDTYPE_ID = accountRecordTypes.get(Label.ACCOUNT_RECORD_SHIPTO).getRecordTypeId();
			}
			return SHIPTO_RECORDTYPE_ID;
		}
		protected set;
	}
	//SGN Record Type ID
	public static Id SGN_RECORDTYPE_ID {
		get {
			if (SGN_RECORDTYPE_ID == null && accountRecordTypes != null) {
				SGN_RECORDTYPE_ID = accountRecordTypes.get(Label.ACCOUNT_RECORD_SITE_SGN).getRecordTypeId();
			}
			return SGN_RECORDTYPE_ID;
		}
		protected set;
	}
	//National SGN Record Type ID
	public static Id NSGN_RECORDTYPE_ID {
		get {
			if (NSGN_RECORDTYPE_ID == null && accountRecordTypes != null) {
				NSGN_RECORDTYPE_ID = accountRecordTypes.get(Label.ACCOUNT_RECORD_NATIONAL_SGN).getRecordTypeId();
			}
			return NSGN_RECORDTYPE_ID;
		}
		protected set;
	}
	//Prospect Record Type ID
	public static Id PROSPECT_RECORDTYPE_ID {
		get {
			if (PROSPECT_RECORDTYPE_ID == null && accountRecordTypes != null) {
				PROSPECT_RECORDTYPE_ID = accountRecordTypes.get(Label.ACCOUNT_RECORD_PROSPECT).getRecordTypeId();
			}
			return PROSPECT_RECORDTYPE_ID;
		}
		protected set;
	}
}