// ===========================================================================
//  Object  : ContactTriggerHandler
//  Company : Keste @ IDC
//  Author  : Abinash Panigrahi
//  Purpose : Handler Class contains all logic for ContactTrigger.
// ===========================================================================
public class ContactTriggerHandler {
	public static String DUPLICATE_RULE_DEVELOPERNAME = Label.DUPLICATE_RULE_DEVELOPERNAME;
	public static String WEBSTATUS_WEBENABLED = Label.WEBSTATUS_WEBENABLED;

	// Method Name: duplicateRecordCreation
	// Author: Abinash Panigrahi
	// Description: Method to create DuplicateRecordItem & DuplicateRecordSet records
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Return: Null
	public static void duplicateRecordCreation(List<Contact> newRec) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.duplicateRecordCreation')) {
			CommonUtilities.debug('Inside duplicateRecordCreation method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Instance to store the mapping relationship between Record Id and DuplicateContact field value
			Map<Id, Id> conDuplicateMap = new Map<Id, Id>();
			//Instance to store Contact record with Duplicate contact relationship
			List<Contact> conList = new List<Contact>();
			for (Contact c : newRec) {
				if (c.Duplicate_Contact__c != null) {
					conList.add(c);
					conDuplicateMap.put(c.Id, c.Duplicate_Contact__c);
				}
			}

			CommonUtilities.debug('conList------->>>>>>>' + conList);
			CommonUtilities.debug('conDuplicateMap------->>>>>>>' + conDuplicateMap);

			if (conList != null && conList.size() > 0) {
				//Fetch Id of DuplicateRule assosiated with Contact Object
				Id duplicateRuleId = null;
				for (DuplicateRule dr : [
					SELECT Id
					FROM DuplicateRule
					WHERE DeveloperName = :DUPLICATE_RULE_DEVELOPERNAME
				]) {
					duplicateRuleId = dr.Id;
				}

				CommonUtilities.debug('duplicateRuleId------->>>>>>>' + duplicateRuleId);

				if (duplicateRuleId != null) {
					//DuplicateRecordSet --> Parent DuplicateRecordItem --> Child
					//Instance to create DuplicateRecordItem and DuplicateRecordSet
					List<DuplicateRecordSet> dupSetList = new List<DuplicateRecordSet>();
					List<DuplicateRecordItem> dupItemList = new List<DuplicateRecordItem>();

					//Map Contact Id with DuplicateRecordSet record
					Map<Id, DuplicateRecordSet> conDupSetMap = new Map<Id, DuplicateRecordSet>();
					//Create DuplicateRecordSet for each Contact Record which have DuplicateContact Relationship
					for (Contact c : conList) {
						DuplicateRecordSet ds = new DuplicateRecordSet();
						ds.DuplicateRuleId = duplicateRuleId;
						dupSetList.add(ds);
						conDupSetMap.put(c.Id, ds);
					}

					CommonUtilities.debug('dupSetList------->>>>>>>' + dupSetList);
					CommonUtilities.debug('conDupSetMap------->>>>>>>' + conDupSetMap);

					//Exception Handling
					//Insert DuplicateRecordSet record
					try {
						if (dupSetList.size() > 0) {
							insert dupSetList;
						}
					} catch (Exception ex) {
						//Create Apex Log
						ExceptionHandlerController.createException(
							'ContactTriggerHandler',
							'duplicateRecordCreation',
							'Trigger Logic',
							'Insert DuplicateRecordSet',
							ex.getMessage(),
							System.today()
						);
					}

					CommonUtilities.debug('dupSetList------->>>>>>>' + dupSetList);

					//Create DuplicateRecordItem record with Lookup relationship with each Contact Record
					//and Master-Detail relationship with DuplicateRecordSet Record
					//Relate both Contact Recod to same Duplicate Set
					for (Contact c : conList) {
						DuplicateRecordItem di = new DuplicateRecordItem();
						DuplicateRecordSet ds = conDupSetMap.get(c.Id);
						di.DuplicateRecordSetId = ds.Id;
						di.RecordId = c.Id;
						di.Contact_Record__c = c.Id;
						di.Contact_Description__c = c.Id + ':' + conDuplicateMap.get(c.Id);
						dupItemList.add(di);

						DuplicateRecordItem di2 = new DuplicateRecordItem();
						DuplicateRecordSet ds2 = conDupSetMap.get(c.Id);
						di2.DuplicateRecordSetId = ds2.Id;
						di2.RecordId = conDuplicateMap.get(c.Id);
						di2.Contact_Record__c = c.Id;
						di2.Contact_Description__c = c.Id + ':' + conDuplicateMap.get(c.Id);
						dupItemList.add(di2);
					}

					CommonUtilities.debug('dupItemList------->>>>>>>' + dupItemList);

					//Exception Handling
					////Insert DuplicateRecordItem record
					try {
						if (dupItemList.size() > 0) {
							insert dupItemList;
						}
					} catch (Exception ex) {
						//Create Apex Log
						ExceptionHandlerController.createException(
							'ContactTriggerHandler',
							'duplicateRecordCreation',
							'Trigger Logic',
							'Insert DuplicateRecordItem',
							ex.getMessage(),
							System.today()
						);
					}

					CommonUtilities.debug('dupItemList------->>>>>>>' + dupItemList);
					CommonUtilities.debug('Exit duplicateRecordCreation method');
				}
			}
		}
	}

	// Method Name: duplicateRecordCreation (Function Overloading)
	// Author: Abinash panigrahi
	// Description: Method to Create/Delete Duplicate Record Item & Set record after update of DuplicateContact relationship
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Contact records.
	// Return: Null
	public static void duplicateRecordCreation(List<Contact> newRec, Map<Id, Contact> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.duplicateRecordCreation')) {
			CommonUtilities.debug('Inside duplicateRecordCreation method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Instance to store Contact records to be followed up for Duplicate Record Item creation
			List<Contact> conList = new List<Contact>();
			//Instance to store Contact records to be followed up for deleting existing Duplicate Record Item
			List<Contact> existConList = new List<Contact>();
			for (Contact c : newRec) {
				CommonUtilities.debug('c.Duplicate_Contact__c--->>>>>' + c.Duplicate_Contact__c);
				CommonUtilities.debug(
					'oldMap.get(c.Id).Duplicate_Contact__c--->>>>>' + oldMap.get(c.Id).Duplicate_Contact__c
				);
				//Condition: Duplicate Contact field value changed from Null to Something
				if (c.Duplicate_Contact__c != oldMap.get(c.Id).Duplicate_Contact__c && c.Duplicate_Contact__c != null) {
					conList.add(c);
				}
				//Condition: Duplicate Contact field value changed from one value to another
				if (
					c.Duplicate_Contact__c != oldMap.get(c.Id).Duplicate_Contact__c &&
					c.Duplicate_Contact__c != null &&
					oldMap.get(c.Id).Duplicate_Contact__c != null
				) {
					existConList.add(oldMap.get(c.Id));
				}
				//Condition: Duplicate Contact field value changed from some value to Null
				if (
					c.Duplicate_Contact__c != oldMap.get(c.Id).Duplicate_Contact__c &&
					c.Duplicate_Contact__c == null &&
					oldMap.get(c.Id).Duplicate_Contact__c != null
				) {
					existConList.add(oldMap.get(c.Id));
				}
				//Condition: Duplicate Contact field value changed from Null to some value
				if (
					c.Duplicate_Contact__c != oldMap.get(c.Id).Duplicate_Contact__c &&
					c.Duplicate_Contact__c != null &&
					oldMap.get(c.Id).Duplicate_Contact__c == null
				) {
					existConList.add(oldMap.get(c.Id));
				}
			}

			CommonUtilities.debug('conList------->>>>>>>' + conList);
			CommonUtilities.debug('existConList------->>>>>>>' + existConList);

			//Instance to store DuplicateRecordItem Ids
			Set<String> driIds = new Set<String>();
			for (Contact c : existConList) {
				String temp = c.Id + ':' + c.Duplicate_Contact__c;
				driIds.add(temp);
			}

			CommonUtilities.debug('driIds------->>>>>>>' + driIds);

			if (driIds != null && driIds.size() > 0) {
				//Fetch all related DuplicateRecordItem records
				List<DuplicateRecordItem> iemList = new List<DuplicateRecordItem>(
					[SELECT Id FROM DuplicateRecordItem WHERE Contact_Description__c IN :driIds]
				);

				CommonUtilities.debug('iemList------->>>>>>>' + iemList);

				//Exception Handling
				//Delete DuplicateRecordItem record
				try {
					if (iemList.size() > 0) {
						delete iemList;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ContactTriggerHandler',
						'duplicateRecordCreation',
						'Trigger Logic',
						'Delete DuplicateRecordItem',
						ex.getMessage(),
						System.today()
					);
				}

				//Create Duplicate Record Item & Set to setup relationship with respective Contact Records
				if (conList.size() > 0) {
					duplicateRecordCreation(conList);
				}
				CommonUtilities.debug('Exit duplicateRecordCreation method');
			}
		}
	}

	// Method Name: duplicateRecordCreation (Function Overloading)
	// Author: Abinash panigrahi
	// Description: Method to delete Duplicate Record Item & Set record after Merging records
	// Parameter 1: oldRec - List of the old versions of the Contact records
	// Parameter 2: isDelete - Flag to check for Delete Operation.
	// Return: Null
	public static void duplicateRecordCreation(List<Contact> oldRec, Boolean isDelete) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.duplicateRecordCreation')) {
			CommonUtilities.debug('Inside duplicateRecordCreation method');
			CommonUtilities.debug('oldRec------->>>>>>>' + oldRec);

			//Instance to store all Survivour RecordId
			Set<Id> masterRecId = new Set<Id>();
			//Instance to store DuplicateRecordItem to be deleted
			Set<String> dupIds = new Set<String>();

			//Fetch all Duplicate Record Item Ids
			//If Victim record contains Duplicate Record Item Ids
			for (Contact c : oldRec) {
				CommonUtilities.debug('c.MasterRecordId------->>>>>>>' + c.MasterRecordId);
				masterRecId.add(c.Id);
				if (c.Duplicate_Contact__c != null) {
					String temp = c.Id + ':' + c.Duplicate_Contact__c;
					dupIds.add(temp);
				}
			}

			CommonUtilities.debug('masterRecId------->>>>>>>' + masterRecId);
			CommonUtilities.debug('dupIds------->>>>>>>' + dupIds);

			if (dupIds != null && dupIds.size() > 0) {
				//Fetch all Duplicate Record Item Ids
				//If Survivor record contains Duplicate Record Item Ids
				for (Contact c : [
					SELECT Id, Duplicate_Contact__c
					FROM Contact
					WHERE Duplicate_Contact__c IN :masterRecId
				]) {
					if (c.Duplicate_Contact__c != null) {
						String temp = c.Id + ':' + c.Duplicate_Contact__c;
						dupIds.add(temp);
					}
				}

				CommonUtilities.debug('dupIds------->>>>>>>' + dupIds);

				//Fetch all related Duplicate Record Item records to be deleted
				List<DuplicateRecordItem> driList = new List<DuplicateRecordItem>(
					[SELECT Id FROM DuplicateRecordItem WHERE Contact_Description__c IN :dupIds]
				);

				CommonUtilities.debug('driList------->>>>>>>' + driList);

				//Exception Handling
				//Delete DuplicateRecordItem record
				try {
					if (driList.size() > 0) {
						delete driList;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ContactTriggerHandler',
						'duplicateRecordCreation',
						'Trigger Logic',
						'Delete DuplicateRecordItem',
						ex.getMessage(),
						System.today()
					);
				}

				//Clear all Duplicate Contact lookup field value
				//ContactTriggerHandler.cloneErrorHandling(masterRecId);

				CommonUtilities.debug('Exit duplicateRecordCreation method');
			}
		}
	}

	// Method Name: cloneErrorHandling
	// Author: Abinash panigrahi
	// Description: Method to pass NULL value to Duplicate Contact lookup field
	// Parameter 1: newRecIds - Set of the new versions of the Contact records
	// Return: Null

	@future
	public static void cloneErrorHandling(Set<Id> newRecIds) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.cloneErrorHandling')) {
			CommonUtilities.debug('Inside cloneErrorHandling method');
			CommonUtilities.debug('newRecIds------->>>>>>>' + newRecIds);

			//Instance to store all related Contact records with Duplicate Contact field populated
			List<Contact> toBeUpdateRec = [
				SELECT Id, Duplicate_Contact__c
				FROM Contact
				WHERE Duplicate_Contact__c IN :newRecIds
			];
			//Update lookup field with NULL value
			for (Contact c : toBeUpdateRec) {
				c.Duplicate_Contact__c = null;
			}

			CommonUtilities.debug('toBeUpdateRec------->>>>>>>' + toBeUpdateRec);

			//Update Contact
			//Exceptional Handling
			try {
				if (toBeUpdateRec.size() > 0) {
					update toBeUpdateRec;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'ContactTriggerHandler',
					'cloneErrorHandling',
					'Trigger Logic',
					'Update Contact',
					ex.getMessage(),
					System.today()
				);
			}

			CommonUtilities.debug('Exit cloneErrorHandling method');
		}
	}

	// Method Name: createCampaignRec
	// Author: Abinash panigrahi
	// Description: Method to create Campaign with Campaign Member using Lead Source Id -- Insert Logic
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Contact records
	// Return: Null
	public static void createCampaignRec(List<Contact> newRec, Map<Id, Contact> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.createCampaignRec')) {
			CommonUtilities.debug('Inside createCampaignRec method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Handle Insert & Update Scenario -- Common Logic for both Case

			//Instance to store Unique Lead Source Ids and populate with values
			Set<String> leadSourceIds = new Set<String>();
			//Instance to store Contact Record ids
			Set<Id> conIds = new Set<Id>();
			//Instance to store to be Updated Rec
			List<Contact> toBeUpdatedRec = new List<Contact>();
			//Populate Set Instance with values
			for (Contact c : newRec) {
				if (
					c.Lead_Source_Id__c != null &&
					(oldMap == null || (oldMap != null && c.Lead_Source_Id__c != oldMap.get(c.Id).Lead_Source_Id__c))
				) {
					conIds.add(c.Id);
					leadSourceIds.add(c.Lead_Source_Id__c);
					toBeUpdatedRec.add(c);
				}
			}

			CommonUtilities.debug('conIds------->>>>>>>' + conIds);
			CommonUtilities.debug('leadSourceIds------->>>>>>>' + leadSourceIds);
			CommonUtilities.debug('toBeUpdatedRec------->>>>>>>' + toBeUpdatedRec);

			//Instance to map the relationship between Lead Source Id and Campaign RecordId
			Map<String, Id> leadSourceCampaignMap = new Map<String, Id>();
			for (Campaign cmp : [SELECT Id, StarTrack_Id__c FROM Campaign WHERE StarTrack_Id__c IN :leadSourceIds]) {
				leadSourceCampaignMap.put(cmp.StarTrack_Id__c, cmp.Id);
			}

			CommonUtilities.debug('leadSourceCampaignMap------->>>>>>>' + leadSourceCampaignMap);

			//Tnstance to store newly Campaign Record
			List<Campaign> toInsertCampaign = new List<Campaign>();
			//Create Campaign Record with StarTrackId populated
			for (Contact c : toBeUpdatedRec) {
				if (c.Lead_Source_Id__c != null && !leadSourceCampaignMap.containsKey(c.Lead_Source_Id__c)) {
					toInsertCampaign.add(
						new Campaign(Name = c.Lead_Source_Name__c, StarTrack_Id__c = c.Lead_Source_Id__c)
					);
				}
			}

			CommonUtilities.debug('toInsertCampaign------->>>>>>>' + toInsertCampaign);

			//Exception Handling
			//Insert Campaign record
			try {
				if (toInsertCampaign.size() > 0) {
					insert toInsertCampaign;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'ContactTriggerHandler',
					'createCampaignRec',
					'Trigger Logic',
					'Insert Campaign',
					ex.getMessage(),
					System.today()
				);
			}

			CommonUtilities.debug('toInsertCampaign------->>>>>>>' + toInsertCampaign);

			//Add newly Inserted record to Relationship map of Lead Source Id and Campaign RecordId
			for (Campaign cmp : toInsertCampaign) {
				leadSourceCampaignMap.put(cmp.StarTrack_Id__c, cmp.Id);
			}

			CommonUtilities.debug('leadSourceCampaignMap------->>>>>>>' + leadSourceCampaignMap);

			//Fetch Related Campaign Member records
			//Instance to store the relationship between CampaignId and its related Campaign Member's Contact RecordId
			Map<Id, List<Id>> campaignMemberMap = new Map<Id, List<Id>>();
			//Populate the Map relationship with values
			for (CampaignMember cm : [
				SELECT Id, ContactId, CampaignId
				FROM CampaignMember
				WHERE CampaignId IN :leadSourceCampaignMap.values() AND ContactId IN :conIds
			]) {
				if (!campaignMemberMap.containsKey(cm.CampaignId)) {
					campaignMemberMap.put(cm.CampaignId, new List<Id>());
				}
				campaignMemberMap.get(cm.CampaignId).add(cm.ContactId);
			}

			CommonUtilities.debug('campaignMemberMap------->>>>>>>' + campaignMemberMap);
			//Instance to store newly created CampaignMember record
			List<CampaignMember> toInsertCampaignMember = new List<CampaignMember>();
			//Create Campaign Member record
			for (Contact c : toBeUpdatedRec) {
				if (c.Lead_Source_Id__c != null && leadSourceCampaignMap.containsKey(c.Lead_Source_Id__c)) {
					List<Id> memberList = new List<Id>();
					if (campaignMemberMap.get(leadSourceCampaignMap.get(c.Lead_Source_Id__c)) != null) {
						memberList = campaignMemberMap.get(leadSourceCampaignMap.get(c.Lead_Source_Id__c));
					}

					if (memberList.size() == 0 || !memberList.contains(c.Id)) {
						toInsertCampaignMember.add(
							new CampaignMember(
								ContactId = c.Id,
								CampaignId = leadSourceCampaignMap.get(c.Lead_Source_Id__c),
								Status = 'Sent'
							)
						);
					}
				}
			}

			CommonUtilities.debug('toInsertCampaignMember------->>>>>>>' + toInsertCampaignMember);
			//Exception Handling
			//Insert CampaignMember record
			try {
				if (toInsertCampaignMember.size() > 0) {
					insert toInsertCampaignMember;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'ContactTriggerHandler',
					'createCampaignRec',
					'Trigger Logic',
					'Insert CampaignMember',
					ex.getMessage(),
					System.today()
				);
			}

			CommonUtilities.debug('toInsertCampaignMember------->>>>>>>' + toInsertCampaignMember);
			CommonUtilities.debug('Exit createCampaignRec method');
		}
	}

	// Method Name: phoneDataStandards
	// Author: Abinash panigrahi
	// Description: Method to change Phone number formatting in Contact record
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Contact records.
	// Return: Null
	public static void phoneDataStandards(List<Contact> newRec, Map<Id, Contact> oldMap) {
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.phoneDataStandards')) {
			Map<String, Map<String, Set<String>>> allowedPhoneFields = new Map<String, Map<String, Set<String>>>();

			allowedPhoneFields.put('Phone_Format__c', new Map<String, Set<String>>());
			allowedPhoneFields.get('Phone_Format__c').put('PhoneFormatCountry__c', new Set<String>());
			allowedPhoneFields.get('Phone_Format__c').get('PhoneFormatCountry__c').add('Phone');
			allowedPhoneFields.get('Phone_Format__c').get('PhoneFormatCountry__c').add('Fax');

			allowedPhoneFields.put('Mobile_Phone_Format__c', new Map<String, Set<String>>());
			allowedPhoneFields.get('Mobile_Phone_Format__c').put('Mobile_Phone_Format_Country__c', new Set<String>());
			allowedPhoneFields.get('Mobile_Phone_Format__c').get('Mobile_Phone_Format_Country__c').add('MobilePhone');

			Map<Id, String> accountMap = new Map<Id, String>();
			List<Contact> contactsToProcess = new List<Contact>();

			for (Contact c : newRec) {
				if (c.AccountId != null) {
					for (String formatConfig : allowedPhoneFields.keySet()) {
						for (String formatCountry : allowedPhoneFields.get(formatConfig).keySet()) {
							for (String phoneField : allowedPhoneFields.get(formatConfig).get(formatCountry)) {
								if (
									c.get(phoneField) != null &&
									(c.RetriggerPhoneFormatting__c ||
									oldMap == null ||
									((String) c.get(phoneField)) != ((String) oldMap.get(c.Id).get(phoneField)) ||
									((String) c.get(formatCountry)) != ((String) oldMap.get(c.Id).get(formatCountry)))
								) {
									accountMap.put(c.AccountId, null);
									contactsToProcess.add(c);
									break;
								}
							}
						}
					}
				}
			}

			if (!accountMap.isEmpty()) {
				for (Account acc : [
					SELECT Id, BillingCountry
					FROM Account
					WHERE Id IN :accountMap.keySet() AND BillingCountry != NULL
				]) {
					accountMap.put(acc.Id, acc.BillingCountry);
				}

				for (Contact c : contactsToProcess) {
					for (String formatConfig : allowedPhoneFields.keySet()) {
						for (String formatCountry : allowedPhoneFields.get(formatConfig).keySet()) {
							for (String phoneField : allowedPhoneFields.get(formatConfig).get(formatCountry)) {
								if (c.get(phoneField) != null) {
									PhoneFormatUtility wr = new PhoneFormatUtility(
										formatConfig,
										(String) c.get(phoneField),
										(String) c.get(formatCountry),
										accountMap.get(c.AccountId)
									);
									if (wr.isSuccess) {
										c.put(phoneField, wr.formatedPhone);
									} else {
										CommonUtilities.debug(
											'======== ' +
											phoneField +
											' Formating Failed: ' +
											wr.statusMessage
										);
									}
								}
							}
						}
					}
					c.RetriggerPhoneFormatting__c = false;
				}
			}
		}
	}

	// Method Name: restrictWebEnabledContact
	// Author: Abinash panigrahi
	// Description: Method to restrict Deletion of Web Enabled Contact record during Duplicate Set Merge
	// Parameter 1: oldRec - List of the old versions of the Contact records
	// Return: Null
	public static void restrictWebEnabledContact(List<Contact> oldRec) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.restrictWebEnabledContact')) {
			//Skip Method for Integration User and Migration User
			if (!CommonUtilities.isIntegrationOrMigrationUser()) {
				CommonUtilities.debug('Inside restrictWebEnabledContact method');
				CommonUtilities.debug('oldRec------->>>>>>>' + oldRec);

				for (Contact c : oldRec) {
					if (c.Web_Status__c == WEBSTATUS_WEBENABLED) {
						//Add Error Message
						c.addError(Label.CONTACT_MERGEERROR);
					}
				}

				CommonUtilities.debug('Exit restrictWebEnabledContact method');
			}
		}
	}

	// Method Name: onAfterInsert
	// Author: Abinash Panigrahi/Vasavi Poranki
	// Description: Method to send the Siebel Request when the Contact is Inserted
	// Parameter 1: lstnewCons - List of the new versions of the Contact records
	// Return: Null
	public static void onAfterInsert(List<Contact> lstnewCons) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.onAfterInsert')) {
			CommonUtilities.debug('Inside onAfterInsert method');
			CommonUtilities.debug('lstnewCons------->>>>>>>' + lstnewCons);

			//Instance to hold Multiple Header records for Callouts
			Set<Id> lstContactIdToSync = new Set<Id>();

			//Check for Prospect Account - excluding No Account Links
			Set<Id> prospectIds = prospectCheck(lstnewCons);

			//Multiple Callout Siebel Sync funcationality
			for (Contact objCon : lstnewCons) {
				if (!prospectIds.contains(objCon.AccountId) && objCon.List_of_Target_Systems__c != null) {
					lstContactIdToSync.add(objCon.Id);
				}
			}
			CommonUtilities.debug('lstContactIdToSync------->>>>>>>' + lstContactIdToSync);

			//Asynchronous Callout
			if (lstContactIdToSync.size() > 0) {
				IntegrationUtility.SynctoSiebelNew('CONTACT', lstContactIdToSync, 'INSERT', 'INSERT', 'CONTACT', false);
			}
			CommonUtilities.debug('Exit onAfterInsert method');
		}
	}

	// Method Name: onAfterUpdate
	// Author: Abinash panigrahi
	// Description: Method to change Phone number formatting in Contact record
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Contact records.
	// Return: Null
	public static void onAfterUpdate(List<Contact> lstnewCons, Map<Id, Contact> oldConMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.onAfterUpdate')) {
			CommonUtilities.debug('Inside onAfterUpdate method');
			CommonUtilities.debug('lstnewCons------->>>>>>>' + lstnewCons);
			CommonUtilities.debug('oldConMap------->>>>>>>' + oldConMap);

			//Fetch all Fields present in Contact Integration FieldSet
			Set<String> fieldSet = new Set<String>();
			for (
				Schema.FieldSetMember fields : Schema.SObjectType.Contact.fieldSets.getMap()
					.get('SiebelSync')
					.getFields()
			) {
				fieldSet.add(fields.getFieldPath());
			}

			CommonUtilities.debug('fieldSet------->>>>>>>' + fieldSet);

			//Instance to hold Multiple Header records for Callouts
			Set<Id> lstContactIdToSync = new Set<Id>();

			//Check for Prospect Account - excluding No Account Links
			Set<Id> prospectIds = prospectCheck(lstnewCons);

			//Loop Logic
			//Inbount Integration Callout is make, if certain Conditions are met
			for (Contact objCon : lstnewCons) {
				//Instance to avoid Recursive Callout for single record
				Boolean IsSync = false;
				if (
					oldConMap != null &&
					!prospectIds.contains(objCon.AccountId) &&
					objCon.List_of_Target_Systems__c != null
				) {
					//Check if any field value is changed for FieldSetMember
					//Then only send Integration Request
					for (string strFieldAPI : fieldSet) {
						if (objCon.get(strFieldAPI) != oldConMap.get(objCon.Id).get(strFieldAPI)) {
							//Contact objOldCon = oldConMap.get(objCon.Id);
							IsSync = true;
							break;
							CommonUtilities.debug('IsSync------->>>>>>>' + IsSync);
						}
					}
				}

				//To avoid mulitple callouts
				if (IsSync) {
					lstContactIdToSync.add(objCon.Id);
				}
			}

			//Asynchronous Callout
			if (lstContactIdToSync.size() > 0) {
				IntegrationUtility.SynctoSiebelNew('CONTACT', lstContactIdToSync, 'UPDATE', 'UPDATE', 'CONTACT', false);
			}
			CommonUtilities.debug('Exit onAfterUpdate method');
		}
	}

	// Method Name: prospectCheck
	// Author: Abinash Panigrahi
	// Description: Method to validate for Integration (Need not to send the request only when related Account is of type 'Prospect' and No Account Link)
	// Parameter 1: lstCon - List of the new versions of the Contact records
	// Return: mpSGNAcc - Set of Prospect Salesforce Id and Record
	public static Set<Id> prospectCheck(List<Contact> lstCon) {
		CommonUtilities.debug('Inside prospectCheck method');
		CommonUtilities.debug('lstCon------->>>>>>>' + lstCon);

		//Fetch Site SGN RecordType Id
		Id ProspectRecordId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Prospect').RecordTypeId;

		//Instance to store Account RecordIds
		Set<Id> stAccIds = new Set<Id>();
		//Instance to store only Prospect Account recordid and info
		Map<Id, Account> mpSGNAcc = new Map<Id, Account>();
		//Loop Logic
		//To Populate Instance with all Primary Account
		for (Contact objCon : lstCon) {
			if (objCon.AccountId != null) {
				stAccIds.add(objCon.AccountId);
			}
		}

		CommonUtilities.debug('stAccIds------->>>>>>>' + stAccIds);
		//Fetch related Prospect Records only
		if (stAccIds != null && stAccIds.size() > 0) {
			for (Account objAcc : [
				SELECT Id, Name, RecordTypeId, ERP_Account_Id__c
				FROM Account
				WHERE Id IN :stAccIds AND RecordTypeId = :ProspectRecordId AND No_Account_Link__c = FALSE
			]) {
				mpSGNAcc.put(objAcc.Id, objAcc);
			}
		}

		CommonUtilities.debug('mpSGNAcc------->>>>>>>' + mpSGNAcc);
		CommonUtilities.debug('Exit prospectCheck method');
		return mpSGNAcc.keySet();
	}

	// Method Name: duplicateRuleCheck
	// Author: Abinash panigrahi
	// Description: Method to populate Account SF Id in a text field in before trigger scenario
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Contact records.
	// Return: Null
	public static void duplicateRuleCheck(List<Contact> newRec, Map<Id, Contact> oldMap) {
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.duplicateRuleCheck')) {
			//Store all Unique combination
			Set<String> uniqueIds = new Set<String>();
			Set<Id> recordIds = new Set<Id>();
			Map<String, String> duplicateMap = new Map<String, String>();

			//Get Logged In User details
			Id profileId = userinfo.getProfileId();
			String profileName = [SELECT Id, Name FROM Profile WHERE Id = :profileId LIMIT 1].Name;
			List<String> bypassProfileNames = String.valueOf(Label.BYPASS_CONTACT_DUPLICATE_RULE_PROFILE_NAME)
				.split(',');

			//Always Populate Account recorid text version
			for (Contact c : newRec) {
				c.Account_Id__c = c.AccountId;
				c.Unique_Combination_ExternalId__c = c.FirstName + '_' + c.LastName + '_' + c.Email + '_' + c.AccountId;
				uniqueIds.add(c.Unique_Combination_ExternalId__c);
				if (oldMap != null) {
					recordIds.add(c.Id);
				}
			}

			//Fetch all existing Duplicate Contact records
			for (Contact c : [
				SELECT Id, Unique_Combination_ExternalId__c, Run_Duplicates__c
				FROM Contact
				WHERE Unique_Combination_ExternalId__c IN :uniqueIds AND Id NOT IN :recordIds
			]) {
				duplicateMap.put(c.Unique_Combination_ExternalId__c, c.Run_Duplicates__c);
			}

			//Dynamically populate Run Duplicate field to mark the difference
			for (Contact c : newRec) {
				//Populate Default prescribed values
				if (bypassProfileNames.contains(profileName)) {
					c.Run_Duplicates__c = null;
				} else {
					//Duplicate Record exist
					if (
						duplicateMap.containsKey(c.Unique_Combination_ExternalId__c) &&
						duplicateMap.get(c.Unique_Combination_ExternalId__c) == null
					) {
						c.addError(Label.BYPASS_CONTACT_DUPLICATE_RULE_EDGE_CASE_ERROR_MESSAGE_SCENARIO);
					} else {
						//Duplicate Record doesnot exist
						c.Run_Duplicates__c = 'YES';
					}
				}
			}
		}
	}

	// Method Name: prePopulateFields
	// Author: Basant Kumar Verma
	// Description: Method to prepopulate the Contact fields on before insert and update
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of the old versions of the Contact records
	// Return: Null
	public static void prePopulateFields(List<Contact> newRec, Map<Id, Contact> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.prePopulateFields')) {
			for (Contact c : newRec) {
				if (!CommonUtilities.isIntegrationUser()) {
					c.Last_Updated_Source_System__c = 'Salesforce';
				}
				if (c.Siebel_Id__c != null && oldMap == null && CommonUtilities.isIntegrationUser()) {
					c.Source_System__c = 'Legacy Siebel';
				}
				if (
					(oldMap == null && c.Web_Status__c == 'Registered') ||
					(oldMap != null &&
					oldMap.get(c.Id).Web_Status__c != c.Web_Status__c &&
					c.Web_Status__c == 'Registered')
				) {
					c.Web_Activation_Date__c = System.today();
				}
			}
		}
	}

	// Method Name: retriggerShipToInfo
	// Author: Abinash Panigrahi
	// Description: Method to populate correct Child Related ShipTo Accounts info
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of the old versions of the Contact records
	// Return: Null
	public static void retriggerShipToInfo(List<Contact> newRec, Map<Id, Contact> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.retriggerShipToInfo')) {
			Set<Id> conIds = new Set<Id>();
			Set<Id> allowedIds = new Set<Id>();
			for (Contact obj : newRec) {
				if (
					obj.Retrigger_Shipto_Exist__c &&
					obj.Retrigger_Shipto_Exist__c != oldMap.get(obj.Id).Retrigger_Shipto_Exist__c
				) {
					conIds.add(obj.Id);
				}
			}
			for (Contact obj : [
				SELECT
					Id,
					Is_Shipto_Exist__c,
					(SELECT Id FROM AccountContactRelations WHERE Account_Record_Type__c = 'SHIPTO')
				FROM Contact
				WHERE Id IN :conIds
			]) {
				if (obj.AccountContactRelations.size() > 0) {
					allowedIds.add(obj.Id);
				}
			}
			for (Contact obj : newRec) {
				if (conIds.contains(obj.Id)) {
					if (allowedIds.contains(obj.Id)) {
						obj.Is_Shipto_Exist__c = true;
					} else {
						obj.Is_Shipto_Exist__c = false;
					}
				}
			}
		}
	}

	// Method Name: siebelRecordIdentification
	// Author: Basant Kumar Verma
	// Description: Method to mark records which needs to be processed in Siebel Sync Batch job
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of the old versions of the Contact records
	// Return: Null
	public static void siebelRecordIdentification(List<Contact> newRec, Map<Id, Contact> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.siebelRecordIdentification')) {
			//Fetch all Fields present in Contact Integration FieldSet
			Set<String> fieldSet = new Set<String>();
			for (
				Schema.FieldSetMember fields : Schema.SObjectType.Contact.fieldSets.getMap()
					.get('SiebelSync')
					.getFields()
			) {
				fieldSet.add(fields.getFieldPath());
			}
			//Loop through all records and mark which record to qualify for Siebel transaction
			for (Contact obj : newRec) {
				if (oldMap == null) {
					obj.Is_Siebel_Processed__c = true;
				} else {
					//Check if any field value is changed for FieldSetMember
					//Then only send Integration Request
					for (string strFieldAPI : fieldSet) {
						if (obj.get(strFieldAPI) != oldMap.get(obj.Id).get(strFieldAPI)) {
							obj.Is_Siebel_Processed__c = true;
						}
					}
				}
			}
		}
	}
	// Method Name: invokeAssetContactBackendUpdate
	// Author: Jayaram B
	// Description: Method to Pass All FirstName or LastName Field Updated Contact records to AssetHandler
	// Parameter 1: newRec - List of the new versions of the Contact records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Contact records
	// Return: Null
	public static void invokeAssetContactBackendUpdate(List<Contact> newRec, Map<Id, Contact> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContactTriggerHandler.invokeAssetContactBackendUpdate')) {
			//Map to hold the FirstName or LastName Field Updated Contact Records
			Map<Id, Contact> mapConNameUpdate = new Map<Id, Contact>();
			for (Contact conRecData : newRec) {
				//Check FirstName or LastName Field Updatd or Not
				if (
					(oldMap.get(conRecData.Id).FirstName != conRecData.FirstName) ||
					(oldMap.get(conRecData.Id).LastName != conRecData.LastName)
				) {
					mapConNameUpdate.put(conRecData.Id, conRecData);
				}
			}
			if (mapConNameUpdate.size() > 0) {
				//Pass the FirstName or LastName Field Updated Contact Records to the AssetTriggerHandler
				AssetTriggerHandler.updateBackendSearchFields(mapConNameUpdate, 'Contact');
			}
		}
	}
}