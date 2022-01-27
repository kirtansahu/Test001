// ===========================================================================
//  Object	: CaseTriggerHandler
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Handler Class contains all logic for CaseTrigger.
// ===========================================================================

public class CaseTriggerHandler {
	private final static String AWS_INTEGRATION_STATUS_NEW = 'New';
	private final static String AWS_INTEGRATION_STATUS_RETRY = 'Retry';

	private final static String CASE_ORIGIN_EMAIL = 'Email';
	private final static String CASE_ORIGIN_WEB = 'Web';
	private final static String CASE_ORIGIN_INSTRUMENT = 'Instrument';
	private final static String CASE_ORIGIN_QUEUE = 'Queue';
	private final static String CASE_MERGE_HISTORY = 'CaseMerged';
	private final static String QUEUE_PREFIX_RECORDID = '00G';
	private final static String CASE_PRIORITY_MEDIUM = 'Medium';
	private final static String CASE_PRIORITY_HIGH = 'High';
	private final static String CASE_DEFAULT_QUEUE = 'Default Queue';
	private final static String CASE_DEFAULT_TEMPLATE = 'TEMPL_002';

	// Method Name: automateCaseStatusSubstatusChange
	// Author: Abinash Panigrahi
	// Description: Method to set predefined rules for Case Status and Sub-status based on certain criteria condition
	// Parameter 1: newRec - List of the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return: Null
	public static void automateCaseStatusSubstatusChange(List<Case> newRec, Map<Id, Case> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.automateCaseStatusSubstatusChange')) {
			CommonUtilities.debug('Inside automateCaseStatusSubstatusChange Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Fetch Agent Unassigned Queue
			Id agentUnassigned = [
				SELECT Id, QueueId
				FROM QueueSobject
				WHERE Queue.Name = :Label.CASE_DEFAULT_OWNER_AGENT_UNASSIGNED
				LIMIT 1
			]
			.QueueId;

			//Get Recordtype for Tech Support and FAS
			Set<Id> caseRecordTypeIds = caseFilterRecordTypes;

			//Get User Object prefix
			String userPrefix = User.sobjecttype.getDescribe().getKeyPrefix();

			//FAS Recordtype Id
			Id fasCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('FAS').getRecordTypeId();

			//Loop Logic
			//Check for Case Status and Substatus
			for (Case caseObj : newRec) {
				//Check for Valid RecordType
				if (caseRecordTypeIds != null && caseRecordTypeIds.contains(caseObj.RecordTypeId)) {
					if (caseObj.RecordTypeId == fasCaseRecordTypeId) {
						//‘New’ : System should auto-populate case status = New for all cases which get created, and where agent owner field = Agent Assigned; system defaults value to 'Assigned'.
						if (oldMap == null && caseObj.Status == 'New') {
							caseObj.Sub_Status__c = 'Assigned';
						}

						//‘Open’ :when a case with status ‘New’ gets assigned i.e. agent owner field is populated, system defaults sub-status value to 'Assigned'.
						if (
							oldMap != null &&
							caseObj.Status == 'New' &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							userPrefix != null &&
							String.valueOf(caseObj.OwnerId).startsWith(userPrefix)
						) {
							caseObj.Sub_Status__c = 'Assigned';
						}
						//‘Open’ :when a case with status ‘Open’ gets assigned i.e. agent owner field is populated, system defaults sub-status value to 'Assigned'.
						if (
							oldMap != null &&
							caseObj.Status == 'Open' &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							userPrefix != null &&
							String.valueOf(caseObj.OwnerId).startsWith(userPrefix)
						) {
							caseObj.Sub_Status__c = 'Assigned';
						}

						//‘Pending Internal’ :Case status = Pending Internal, when a case with status ‘Pending Internal’ gets assigned i.e. agent owner field changes from 'Agent unassigned' to agent 'X', system defaults sub-status value to 'Assigned'.
						if (
							oldMap != null &&
							caseObj.Status == 'Pending Internal' &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							oldMap.get(caseObj.Id).OwnerId == agentUnassigned &&
							agentUnassigned != null
						) {
							caseObj.Sub_Status__c = 'Follow-Up';
						}

						//‘Pending Customer’ :Case status = Pending Customer, when a case with status ‘Pending Customer	’ gets assigned i.e. agent owner field changes from 'Agent unassigned' to agent 'X', system defaults sub-status value to 'Assigned'.
						if (
							oldMap != null &&
							caseObj.Status == 'Pending Customer' &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							oldMap.get(caseObj.Id).OwnerId == agentUnassigned &&
							agentUnassigned != null
						) {
							caseObj.Sub_Status__c = 'Follow-Up';
						}

						//‘Re-Opened’ :When a case status on a Case changes from 'Closed' to 'Open', defaults sub-status value to 'Re-opened'.
						if (
							oldMap != null &&
							caseObj.Status == 'Open' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status &&
							oldMap.get(caseObj.Id).Status == 'Closed'
						) {
							caseObj.Sub_Status__c = 'Re-Opened';
						}

						//‘Pending Internal' : When case status is changed from 'X' to 'Pending Internal', user manually selects sub-status value, which can also be NULL (or "None")
						if (
							oldMap != null &&
							caseObj.Status == 'Pending Internal' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status
						) {
							caseObj.Sub_Status__c = null;
						}

						//‘Closed' : When case status is changed from 'X' to 'Closed', system defaults sub-status value to 'Resolved'. User can manually change this to 'Don't Survey'
						if (
							oldMap != null &&
							caseObj.Status == 'Closed' &&
							caseObj.Sub_Status__c != 'Don\'t Survey' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status
						) {
							caseObj.Sub_Status__c = 'Resolved';
						}
						//When case is merged status is set to 'Merged', system default sub-status value to 'Merged Cancelled'
						if (
							oldMap != null &&
							caseObj.Status == 'Merged' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status
						) {
							caseObj.Sub_Status__c = 'Merged Cancelled';
						}
					} else {
						//RAID LOG Item
						//Get Case Origin qualified for Defaulting Logic
						List<String> defaultOrigins = String.valueOf(Label.CASE_DEFAULT_STATUS_QUALIFY_ORIGIN)
							.split(',');

						//For Manually Created Cases - Status should default to 'Open' and Substatus to 'Assigned'
						if (oldMap == null && caseObj.Status == 'New' && caseObj.Origin == 'Manually Created') {
							caseObj.Sub_Status__c = 'Assigned';
							caseObj.Status = 'Open';
							caseObj.OwnerId = UserInfo.getUserId();
						}

						//‘New’ : System should auto-populate case status = New for all cases which get created, and where agent owner field = Agent unassigned; system defaults value to 'Unassigned'.
						if (oldMap == null && caseObj.Status == 'New' && defaultOrigins.contains(caseObj.Origin)) {
							caseObj.Sub_Status__c = 'Unassigned';
						}

						//‘Open’ :Case status = Open, when a case with status ‘New’ gets assigned i.e. agent owner field changes from 'Agent unassigned' to agent 'X', system defaults sub-status value to 'Assigned'.
						if (
							oldMap != null &&
							caseObj.Status == 'New' &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							oldMap.get(caseObj.Id).OwnerId == agentUnassigned &&
							agentUnassigned != null
						) {
							caseObj.Status = 'Open';
							caseObj.Sub_Status__c = 'Assigned';
						}
						//‘Open’ :Case status = Open, when a case with status ‘Open’ gets assigned i.e. agent owner field changes from 'Agent unassigned' to agent 'X', system defaults sub-status value to 'Assigned'.
						if (
							oldMap != null &&
							caseObj.Status == 'Open' &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							oldMap.get(caseObj.Id).OwnerId == agentUnassigned &&
							agentUnassigned != null
						) {
							caseObj.Status = 'Open';
							caseObj.Sub_Status__c = 'Assigned';
						}

						//‘Pending Internal’ :Case status = Pending Internal, when a case with status ‘Pending Internal’ gets assigned i.e. agent owner field changes from 'Agent unassigned' to agent 'X', system defaults sub-status value to 'Assigned'.
						if (
							oldMap != null &&
							caseObj.Status == 'Pending Internal' &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							oldMap.get(caseObj.Id).OwnerId == agentUnassigned &&
							agentUnassigned != null
						) {
							caseObj.Status = 'Pending Internal';
							caseObj.Sub_Status__c = 'Follow-Up';
						}

						//‘Pending Customer’ :Case status = Pending Customer, when a case with status ‘Pending Customer	’ gets assigned i.e. agent owner field changes from 'Agent unassigned' to agent 'X', system defaults sub-status value to 'Assigned'.
						if (
							oldMap != null &&
							caseObj.Status == 'Pending Customer' &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							oldMap.get(caseObj.Id).OwnerId == agentUnassigned &&
							agentUnassigned != null
						) {
							caseObj.Status = 'Pending Customer';
							caseObj.Sub_Status__c = 'Follow-Up';
						}

						//'Closed' : When case status is changed from 'X' to 'Closed', system defaults sub-status value to 'Resolved'. User can manually change this to 'Don't Survey'
						if (
							oldMap != null &&
							caseObj.Type != 'Non-LSG' &&
							caseObj.Status == 'Closed' &&
							caseObj.Sub_Status__c != 'Don\'t Survey' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status
						) {
							caseObj.Sub_Status__c = 'Resolved';
						}

						if (
							oldMap != null &&
							caseObj.Type == 'Non-LSG' &&
							caseObj.Status == 'Closed' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status
						) {
							caseObj.Sub_Status__c = 'Don\'t Survey';
						}

						//'Pending Internal' : When case status is changed from 'X' to 'Pending Internal', user manually selects sub-status value, which can also be NULL (or "None")
						if (
							oldMap != null &&
							(caseObj.Status == 'Pending Internal' ||
							caseObj.Status == 'Pending Customer') &&
							caseObj.Status != oldMap.get(caseObj.Id).Status
						) {
							caseObj.Sub_Status__c = 'Follow-Up';
						}

						//When a case status on a Case changes from 'Closed' to 'Open', defaults sub-status value to 'Re-opened'
						if (
							oldMap != null &&
							caseObj.Status == 'Open' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status &&
							oldMap.get(caseObj.Id).Status == 'Closed'
						) {
							caseObj.Sub_Status__c = 'Re-Opened';
						}

						//When agent owner changed from agent x to agent unassigned, defaults sub-status value to 'Unassigned'
						if (
							oldMap != null &&
							caseObj.OwnerId == agentUnassigned &&
							caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId &&
							userPrefix != null &&
							String.valueOf(oldMap.get(caseObj.Id).OwnerId).startsWith(userPrefix)
						) {
							caseObj.Sub_Status__c = 'Unassigned';
						}

						//When case status is changed from 'X' to 'Cancelled', system default sub-status value to 'Spam'
						if (
							oldMap != null &&
							caseObj.Status == 'Cancelled' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status
						) {
							caseObj.Sub_Status__c = 'Spam';
						}
						//When case is merged status is set to 'Merged', system default sub-status value to 'Merged Cancelled'
						if (
							oldMap != null &&
							caseObj.Status == 'Merged' &&
							caseObj.Status != oldMap.get(caseObj.Id).Status
						) {
							caseObj.Sub_Status__c = 'Merged Cancelled';
						}
					}
				}
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit automateCaseStatusSubstatusChange Method');
		}
	}

	// Method Name: setupContactAccountValue
	// Author: Abinash panigrahi
	// Description: Method to update Case records after Contact Phone, Email is updated - Primary Account, Customer Contact needs to have latest value
	// Parameter 1: newRec - List of the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return: Null
	public static void setupContactAccountValue(List<Case> newRec, Map<Id, Case> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.setupContactAccountValue')) {
			CommonUtilities.debug('Inside setupContactAccountValue Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Instance to store Contact records with Email and Account
			Map<String, List<Id>> emailContactMap = new Map<String, List<Id>>();
			Map<Id, Id> contactAccountMap = new Map<Id, Id>();

			//Case RecordType Filter
			Set<Id> recordTypeIds = caseFilterRecordTypes;

			//Loop Logic
			//Populate above instance with key values
			for (Case cs : newRec) {
				//Check if Customer Email is populated for Insert or if its value is updated
				if (
					cs.SuppliedEmail != null &&
					(oldMap == null || (oldMap != null && cs.SuppliedEmail != oldMap.get(cs.Id).SuppliedEmail)) &&
					recordTypeIds.contains(cs.RecordTypeId)
				) {
					emailContactMap.put(cs.SuppliedEmail, new List<Id>());
				}
				//Check if Contact is manually changed for Update scenario
				if (
					oldmap != null &&
					oldMap.get(cs.Id).ContactId != cs.ContactId &&
					oldMap.get(cs.Id).AccountId == cs.AccountId &&
					recordTypeIds.contains(cs.RecordTypeId)
				) {
					contactAccountMap.put(cs.ContactId, null);
				}
			}

			CommonUtilities.debug('emailContactMap------->>>>>>>' + emailContactMap);
			CommonUtilities.debug('contactAccountMap------->>>>>>>' + contactAccountMap);

			//Conditional SOQL Statement
			if (emailContactMap != null || contactAccountMap != null) {
				List<Contact> relatedContacts = new List<Contact>(
					[
						SELECT Id, Email, AccountId
						FROM Contact
						WHERE
							(Email IN :emailContactMap.keySet()
							AND Email != NULL)
							OR (Id IN :contactAccountMap.keySet()
							AND AccountId != NULL)
						ORDER BY CreatedDate DESC
					]
				);

				//Loop Logic
				//Fetch related contact based on Email - Index field
				for (Contact con : relatedContacts) {
					//Populate above instance with mapping values
					if (emailContactMap.containsKey(con.Email)) {
						emailContactMap.get(con.Email).add(con.Id);
						contactAccountMap.put(con.Id, con.AccountId);
					}
					if (contactAccountMap.containsKey(con.Id)) {
						contactAccountMap.put(con.Id, con.AccountId);
					}
				}

				CommonUtilities.debug('emailContactMap------->>>>>>>' + emailContactMap);
				CommonUtilities.debug('contactAccountMap------->>>>>>>' + contactAccountMap);

				//Instance to store all new Customer Email intreacted for first time
				Set<String> noMatchingEmail = new Set<String>();
				//Loop Logic
				//Filter out all Customer Mails to find new Cusomer not existing in Salesforce org
				for (String eml : emailContactMap.keySet()) {
					List<Id> relatedContactIds = emailContactMap.get(eml);
					if (relatedContacts == null || relatedContacts.size() == 0) {
						noMatchingEmail.add(eml);
					}
				}

				CommonUtilities.debug('noMatchingEmail------->>>>>>>' + noMatchingEmail);

				//Conditional SOQL
				//Fetch Master Technical Support Contact to relate
				Contact masterTSContact = new Contact();
				if (noMatchingEmail != null) {
					for (Contact con : [
						SELECT Id, AccountId
						FROM Contact
						WHERE
							Email = :Label.CASE_TECHSUPPORT_MASTER_CONTACT_EMAIL
							AND Name = :Label.CASE_TECHSUPPORT_MASTER_CONTACT_NAME
						LIMIT 1
					]) {
						masterTSContact = con;
					}
				}

				CommonUtilities.debug('masterTSContact------->>>>>>>' + masterTSContact);

				//Loop Logic
				//If Customer Email is present in Multiple Contact -- Standard OOTB functionality fail
				//Then randomly select one Contact record to link with Case
				for (Case cs : newRec) {
					//Null Check
					if (
						cs.SuppliedEmail != null &&
						(oldMap == null || (oldMap != null && cs.SuppliedEmail != oldMap.get(cs.Id).SuppliedEmail)) &&
						recordTypeIds.contains(cs.RecordTypeId)
					) {
						//Customer Email Count more than 1 then update Contact and its assosiated Acccount
						if (
							emailContactMap.containsKey(cs.SuppliedEmail) &&
							emailContactMap.get(cs.SuppliedEmail).size() > 0 &&
							cs.ContactId == null
						) {
							cs.ContactId = emailContactMap.get(cs.SuppliedEmail)[0];
							if (contactAccountMap.containsKey(cs.ContactId)) {
								cs.AccountId = contactAccountMap.get(cs.ContactId);
							}
						}
						//Customer Email with no Contact Email Matching in Salesforce org-- Special Case
						//Need to relate Case with Master Tech Support Contact Record
						if (noMatchingEmail.contains(cs.SuppliedEmail) && masterTSContact != null) {
							cs.ContactId = masterTSContact.Id;
							cs.AccountId = masterTSContact.AccountId;
						}
					}
					if (
						oldmap != null &&
						oldMap.get(cs.Id).ContactId != cs.ContactId &&
						oldMap.get(cs.Id).AccountId == cs.AccountId &&
						recordTypeIds.contains(cs.RecordTypeId)
					) {
						//Change Account if Contact is manually updated
						if (contactAccountMap.containsKey(cs.ContactId)) {
							cs.AccountId = contactAccountMap.get(cs.ContactId);
						}
					}
				}
			}
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit setupContactAccountValue Method');
		}
	}

	// Method Name: webEmailOriginCaseEmailQueue
	// Author: Abinash panigrahi
	// Description: Method to decide Email Queue for Web/Email/Instrument origin Cases
	// Parameter 1: newRec - List of the new versions of the Case records
	// Return: Null
	public static void webEmailOriginCaseEmailQueue(List<Case> newRec) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.webEmailOriginCaseEmailQueue')) {
			CommonUtilities.debug('Inside webOriginCaseEmailQueue Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Instance to store different classification of Cases
			List<Case> webCases = new List<Case>();
			Map<String, String> webQueueMap = new Map<String, String>();
			Map<String, String> webTemplateMap = new Map<String, String>();
			List<Case> emailCases = new List<Case>();
			List<Case> instrumentCases = new List<Case>();
			Map<String, String> instrumentTemplateMap = new Map<String, String>();
			Map<String, String> regionQueueMap = new Map<String, String>();

			//Fetch Tech Support Record Type Id
			Set<Id> recordTypeIds = caseAssignmentRecordTypes;

			//Loop Logic
			//Differentiate based on Case Origin - Web or Email or Instrument Services
			for (case cs : newRec) {
				if (
					cs.Origin == CASE_ORIGIN_WEB &&
					cs.Web_Application_Area__c != null &&
					cs.Web_Country_Region__c != null &&
					recordTypeIds.contains(cs.RecordTypeId)
				) {
					webCases.add(cs);
					webQueueMap.put(cs.Web_Application_Area__c + '_' + cs.Web_Country_Region__c, null);
				} else if (
					cs.Origin == CASE_ORIGIN_EMAIL &&
					recordTypeIds.contains(cs.RecordTypeId) &&
					cs.Email_Queue__c == null
				) {
					emailCases.add(cs);
				} else if (
					cs.Origin == CASE_ORIGIN_INSTRUMENT &&
					cs.Web_Country_Region__c != null &&
					recordTypeIds.contains(cs.RecordTypeId)
				) {
					instrumentCases.add(cs);
					regionQueueMap.put(cs.Web_Country_Region__c, null);
				}
			}

			CommonUtilities.debug('emailCases------->>>>>>>' + emailCases);
			CommonUtilities.debug('webCases------->>>>>>>' + webCases);
			CommonUtilities.debug('instrumentCases------->>>>>>>' + instrumentCases);

			/* ******* WEB ORIGIN CASE ASSIGNMENT QUEUE LOGIC ********* */

			//Conditional SOQl Statement
			//Execute Logic further if Web Cases are found
			if (webQueueMap != null) {
				//Fetch Web Assignment Master Data
				List<Case_Assignment_Helper__c> caseAssignmentHelperInfo = new List<Case_Assignment_Helper__c>(
					[
						SELECT Id, Email_Queue__c, Web_Indetifier__c, Email_Template_Number__c
						FROM Case_Assignment_Helper__c
						WHERE
							Web_Indetifier__c IN :webQueueMap.keySet()
							AND Case_Origin__c = :CASE_ORIGIN_WEB
							AND Email_Queue__c != NULL
					]
				);

				//Fetch required attributes from Custom Object - Case Assignment Helper
				//Setup Mapping relationship between Webform attributes
				for (Case_Assignment_Helper__c cah : caseAssignmentHelperInfo) {
					webQueueMap.put(cah.Web_Indetifier__c, cah.Email_Queue__c);
					webTemplateMap.put(cah.Web_Indetifier__c, cah.Email_Template_Number__c);
				}

				CommonUtilities.debug('webQueueMap------->>>>>>>' + webQueueMap);

				//Loop Logic
				//Assign Email Queue Name based on Application Area and Country of Webform
				for (Case cs : webCases) {
					//Concatenation of Application Area and Country - Unique Identifier
					String webQueue = cs.Web_Application_Area__c + '_' + cs.Web_Country_Region__c;

					//Search for Email Queue specific to that Unique Identifier
					//Case Assignment - Web
					if (webQueueMap.containsKey(webQueue) && webQueueMap.get(webQueue) != null) {
						cs.Email_Queue__c = webQueueMap.get(webQueue);
						cs.Email_Template_Number__c = webTemplateMap.get(webQueue);
						cs.Priority = CASE_PRIORITY_MEDIUM;
						CommonUtilities.debug('cs.Email_Queue__c ------->>>>>>>' + cs.Email_Queue__c);
						CommonUtilities.debug(
							'cs.Email_Template_Number__c ------->>>>>>>' + cs.Email_Template_Number__c
						);
					} else {
						cs.Email_Queue__c = CASE_DEFAULT_QUEUE;
						cs.Email_Template_Number__c = CASE_DEFAULT_TEMPLATE;
						CommonUtilities.debug('cs.Email_Queue__c ------->>>>>>>' + cs.Email_Queue__c);
						CommonUtilities.debug(
							'cs.Email_Template_Number__c ------->>>>>>>' + cs.Email_Template_Number__c
						);
					}
				}
			}

			/* ******* EMAIL ORIGIN CASE ASSIGNMENT QUEUE LOGIC ********* */

			//Conditional SOQl Statement
			//Execute Logic further if Web Cases are found
			if (emailCases != null) {
				//Instance to store Keywords and Count of Occurance of it
				Map<String, String> keywordQueueMap = new Map<String, String>();
				Map<String, Integer> countMap = new Map<String, Integer>();

				//Fetch Keywords Assignment Master Data
				List<Case_Assignment_Helper__c> caseAssignmentHelperInfo = new List<Case_Assignment_Helper__c>(
					[
						SELECT Id, Keywords__c, Email_Queue__c
						FROM Case_Assignment_Helper__c
						WHERE Case_Origin__c = :CASE_ORIGIN_EMAIL AND Keywords__c != NULL AND Email_Queue__c != NULL
					]
				);

				//Fetch required attributes from Custom Object - Case Assignment Helper
				//Setup Mapping relationship between Email attributes
				for (Case_Assignment_Helper__c cah : caseAssignmentHelperInfo) {
					//Convert to Lowercase Unique Keywords
					keywordQueueMap.put(cah.Keywords__c.toLowerCase(), cah.Email_Queue__c);
					countMap.put(cah.Email_Queue__c, 0);
				}

				CommonUtilities.debug('keywordQueueMap------->>>>>>>' + keywordQueueMap);
				CommonUtilities.debug('countMap------->>>>>>>' + countMap);

				//Loop Logic
				//Email to Case Assignment Algorithm based on Scoring System
				for (Case cs : emailCases) {
					//Convert Email Subject and Body to lowercase for ease of comparision
					String subject = null, body = null;
					if (cs.Subject != null) {
						subject = CommonUtilities.stringReplaceAll(cs.Subject);
					}
					if (cs.Description != null) {
						body = CommonUtilities.stringReplaceAll(cs.Description);
					}
					//Gather up all matched Keyword
					String matchedKeywords;
					//Reset Scoring Counter of all Email Queues
					for (String queue : countMap.keySet()) {
						countMap.put(queue, 0);
					}

					CommonUtilities.debug('subject------->>>>>>>' + subject);
					CommonUtilities.debug('body------->>>>>>>' + body);
					CommonUtilities.debug('countMap------->>>>>>>' + countMap);

					//To Identify all the keyword match with Current case and update Scoring counters accordingly
					for (String keyword : keywordQueueMap.keySet()) {
						//Fetch Current Count of related Email Queue
						String currQueue = keywordQueueMap.get(keyword);
						//Find number of matches with Keyword both in Body and Subject
						Integer currCount = countMap.get(currQueue);
						if (subject != null) {
							Integer lCount = 0;
							if (keyword.contains(' ')) {
								lCount = subject.countMatches(keyword);
							} else if (subject.countMatches(keyword) > 0) {
								lCount = CommonUtilities.countMatches(subject, keyword);
							}
							CommonUtilities.debug('SUBJECT ------->>>>>>>' + lCount);
							currCount = currCount + lCount;
							if (lCount > 0) {
								matchedKeywords = matchedKeywords + keyword + ' ' + String.valueOf(lCount) + ',';
								CommonUtilities.debug(
									'Matcked Keyword------->>>>>>>' +
									keyword +
									'------->>>>>>>' +
									lCount
								);
							}
						}
						if (body != null) {
							Integer lCount = 0;
							if (keyword.contains(' ')) {
								lCount = body.countMatches(keyword);
							} else if (body.countMatches(keyword) > 0) {
								lCount = CommonUtilities.countMatches(body, keyword);
							}
							CommonUtilities.debug('BODY ------->>>>>>>' + lCount);
							currCount = currCount + lCount;
							if (lCount > 0) {
								matchedKeywords = matchedKeywords + keyword + ' ' + String.valueOf(lCount) + ',';
								CommonUtilities.debug(
									'Matcked Keyword------->>>>>>>' +
									keyword +
									'------->>>>>>>' +
									lCount
								);
							}
						}
						//Update Counter
						countMap.put(currQueue, currCount);
					}

					CommonUtilities.debug('countMap------->>>>>>>' + countMap);

					//Calculate Highest occured keyword belonging to an Email Queue
					Integer maxValue = 0;
					List<Integer> countList = countMap.values();
					countList.sort();
					if (countList.size() > 1) {
						maxValue = countList[countList.size() - 1];
					}

					CommonUtilities.debug('countList------->>>>>>>' + countList);
					CommonUtilities.debug('maxValue------->>>>>>>' + maxValue);

					//Find the Email Queue to be assigned to Case based on Max value
					String assignedQueue;
					Integer maxSameValue = 0;
					Map<String, Integer> maxSameValueQueue = new Map<String, Integer>();
					for (String queue : countMap.keySet()) {
						if (countMap.get(queue) == maxValue) {
							assignedQueue = queue;
							maxSameValue++;
							//Add to instance for Priority Assignment check
							maxSameValueQueue.put(queue, 0);
						}
					}

					CommonUtilities.debug('maxCount------->>>>>>>' + maxSameValue);
					CommonUtilities.debug('assignedQueue------->>>>>>>' + assignedQueue);

					//If and only If there is tie between two or more Email Queue, then assigned to Global Queue
					if (maxValue == 0) {
						assignedQueue = Label.CASE_ASSIGNMENT_RULE_NO_MATCH_CONDITION;
					} else if (maxSameValue > 1) {
						//If Queues are having same Keyword counts
						//Tie Situation - Queue Priority Check

						//Fetch Keywords Assignment Master Data and Assign the Queue Priority
						for (Case_Assignment_Helper__c cah : [
							SELECT Id, Score__c, Email_Queue__c
							FROM Case_Assignment_Helper__c
							WHERE
								Case_Origin__c = :CASE_ORIGIN_QUEUE
								AND Score__c != NULL
								AND Email_Queue__c IN :maxSameValueQueue.keySet()
						]) {
							if (maxSameValueQueue.containsKey(cah.Email_Queue__c)) {
								maxSameValueQueue.put(cah.Email_Queue__c, Integer.valueOf(cah.Score__c));
							}
						}

						CommonUtilities.debug('maxSameValueQueue------->>>>>>>' + maxSameValueQueue);

						//Look for Highest Priority Queue Value
						countList.clear();
						countList = maxSameValueQueue.values();
						countList.sort();
						if (countList.size() > 1) {
							maxValue = countList[countList.size() - 1];
						}

						CommonUtilities.debug('maxValue------->>>>>>>' + maxValue);

						//Assign the Queue
						for (String queue : maxSameValueQueue.keySet()) {
							if (maxSameValueQueue.get(queue) == maxValue) {
								assignedQueue = queue;
							}
						}

						CommonUtilities.debug('assignedQueue------->>>>>>>' + assignedQueue);
					}

					//Email-to-Case Assignment is done
					cs.Email_Queue__c = assignedQueue;
					cs.Matched_Keyword__c = JSON.serialize(matchedKeywords);
					cs.Priority = CASE_PRIORITY_MEDIUM;
					CommonUtilities.debug('cs.Email_Queue__c------->>>>>>>' + cs.Email_Queue__c);
				}
			}

			/* ******* INSTRUMENT SERVICES ORIGIN CASE ASSIGNMENT QUEUE LOGIC ********* */

			//Conditional SOQl Statement
			//Execute Logic further if Instrument Cases are found
			if (instrumentCases != null) {
				//Fetch Instrument Assignment Master Data
				List<Case_Assignment_Helper__c> caseAssignmentHelperInfo = new List<Case_Assignment_Helper__c>(
					[
						SELECT Id, Country_Region__c, Email_Queue__c, Email_Template_Number__c
						FROM Case_Assignment_Helper__c
						WHERE
							Case_Origin__c = :CASE_ORIGIN_INSTRUMENT
							AND Country_Region__c IN :regionQueueMap.keySet()
							AND Email_Queue__c != NULL
					]
				);

				//Complete the mapping between Contry/Region and Queue Name for Instrument Cases
				for (Case_Assignment_Helper__c cah : caseAssignmentHelperInfo) {
					if (regionQueueMap.containsKey(cah.Country_Region__c)) {
						regionQueueMap.put(cah.Country_Region__c, cah.Email_Queue__c);
						instrumentTemplateMap.put(cah.Country_Region__c, cah.Email_Template_Number__c);
					}
				}

				//Loop Logic
				//Assign Email Queue Name based on Country/Region of Instrument
				for (Case cs : instrumentCases) {
					//Search for Email Queue specific to that Region
					//Case Assignment - Instrument
					if (
						regionQueueMap.containsKey(cs.Web_Country_Region__c) &&
						regionQueueMap.get(cs.Web_Country_Region__c) != null
					) {
						cs.Email_Queue__c = regionQueueMap.get(cs.Web_Country_Region__c);
						cs.Email_Template_Number__c = instrumentTemplateMap.get(cs.Web_Country_Region__c);
						cs.Priority = CASE_PRIORITY_HIGH;
						CommonUtilities.debug('cs.Email_Queue__c ------->>>>>>>' + cs.Email_Queue__c);
						CommonUtilities.debug(
							'cs.Email_Template_Number__c ------->>>>>>>' + cs.Email_Template_Number__c
						);
					} else {
						cs.Email_Queue__c = CASE_DEFAULT_QUEUE;
						cs.Email_Template_Number__c = CASE_DEFAULT_TEMPLATE;
						CommonUtilities.debug('cs.Email_Queue__c ------->>>>>>>' + cs.Email_Queue__c);
						CommonUtilities.debug(
							'cs.Email_Template_Number__c ------->>>>>>>' + cs.Email_Template_Number__c
						);
					}
				}
			}

			CommonUtilities.debug('webCases------->>>>>>>' + webCases);
			CommonUtilities.debug('emailCases------->>>>>>>' + emailCases);
			CommonUtilities.debug('instrumentCases------->>>>>>>' + instrumentCases);
			CommonUtilities.debug('Exit webOriginCaseEmailQueue Method');
		}
	}

	// Method Name: mergeHandlePrimaryProducts
	// Author: Abinash panigrahi
	// Description: Method to manage Case Merge scenario of handling multiple primary products at survivour cases
	// Parameter 1: newRec - List of the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return: Null
	public static void mergeHandlePrimaryProducts(List<Case> newRec, Map<Id, Case> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.mergeHandlePrimaryProducts')) {
			CommonUtilities.debug('Inside mergeHandlePrimaryProducts Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Instance to store Survivor  Case
			Set<String> caseNumber = new Set<String>();
			//Instance to store to be updated Case Related Products
			List<Case_Related_Products__c> primaryProductsToBeUpdated = new List<Case_Related_Products__c>();

			//Populate the master record CaseIds
			//Fetch all audit fields for Merged Cases
			String sSOQL = 'SELECT Id, CaseId, NewValue, OldValue, Field FROM CaseHistory ';
			sSOQL += ' WHERE CaseId IN: newRec AND Field =: CASE_MERGE_HISTORY ';

			if (!Test.isRunningTest()) {
				sSOQL += ' AND Case.Count_Primary_Product__c >1';
			}

			for (CaseHistory ch : database.query(sSOQL)) {
				caseNumber.add(ch.CaseId);
			}

			CommonUtilities.debug('caseNumber------->>>>>>>' + caseNumber);

			if (caseNumber.size() > 0) {
				String sSOQL_Case = ' SELECT Id, Count_Primary_Product__c, Primary_Product__c, ';
				sSOQL_Case += ' (SELECT Id, Primary__c, Product__c FROM Case_Related_Products__r WHERE Primary__c = true) ';
				sSOQL_Case += ' FROM Case';
				sSOQL_Case += ' WHERE Primary_Product__c != null AND Id IN: caseNumber';

				if (!Test.isRunningTest()) {
					sSOQL_Case += ' AND Count_Primary_Product__c >1';
				}
				//Fetch Case records with multiple Primary Products
				for (Case c : database.query(sSOQL_Case)) {
					//Check if Primary Product Count is more than 1
					if (
						c.Case_Related_Products__r.size() > 1 ||
						c.Count_Primary_Product__c > 1 ||
						Test.isRunningTest()
					) {
						for (Case_Related_Products__c crp : c.Case_Related_Products__r) {
							//Uncheck the Primary box for Victim's Product
							if (crp.Product__c != c.Primary_Product__c) {
								crp.Primary__c = false;
								//Add the Case Related Product record to list for Update
								primaryProductsToBeUpdated.add(crp);
							}
						}
					}
				}

				CommonUtilities.debug('primaryProductsToBeUpdated------->>>>>>>' + primaryProductsToBeUpdated);
			}

			//Update Case Related Product records
			//Exception Handling
			try {
				if (primaryProductsToBeUpdated.size() > 0) {
					update primaryProductsToBeUpdated;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'CaseTriggerHandler',
					'mergeHandlePrimaryProducts',
					'Trigger Logic',
					'Update Case Related Products',
					ex.getMessage(),
					System.today()
				);
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit mergeHandlePrimaryProducts Method');
		}
	}

	// Method Name: checkForWebFile
	// Author: Basant Kumar Verma
	// Description: Method to fetch AWS S3 File and store as Salsforce File.
	// Parameter 1: newRec - List of the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return: Null
	public static Boolean AWSS3CallMade = false;
	public static void checkForWebFile(List<Case> newRec, Map<Id, Case> oldMap) {
		if (!AWSS3CallMade) {
			Set<Id> caseIds = new Set<Id>();
			for (Case caseOb : newRec) {
				if (
					caseOb.Web_File_URL__c != null &&
					caseOb.Web_File_Name__c != null &&
					(caseOb.Web_File_AWS_Integration_Status__c == null ||
					caseOb.Web_File_AWS_Integration_Status__c == AWS_INTEGRATION_STATUS_NEW ||
					caseOb.Web_File_AWS_Integration_Status__c == AWS_INTEGRATION_STATUS_RETRY)
				) {
					if (
						oldMap == null ||
						caseOb.Web_File_AWS_Integration_Status__c !=
						oldMap.get(caseOb.Id).Web_File_AWS_Integration_Status__c ||
						caseOb.Web_File_Name__c != oldMap.get(caseOb.Id).Web_File_Name__c ||
						caseOb.Web_File_URL__c != oldMap.get(caseOb.Id).Web_File_URL__c
					) {
						caseIds.add(caseOb.Id);
					}
				}
			}

			if (caseIds.size() > 0) {
				AWSS3CallMade = true;
				AWS_S3_Utility.fetchFileFromURLs(caseIds);
			}
		}
	}

	// Method Name: multipleEmailMessageHandleScenario
	// Author: Abinash Panigrahi
	// Description: Method to set appropriate Queue Owner and Receiver Email based on Case Ownership and History
	// Parameter 1: newRec - List of the new versions of the Case records
	// Return: Null
	public static void multipleEmailMessageHandleScenario(List<Case> newRec) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.multipleEmailMessageHandleScenario')) {
			CommonUtilities.debug('Inside multipleEmailMessageHandleScenario Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Fetch Tech Support Record Type Id
			Set<Id> recordTypeIds = caseAssignmentRecordTypes;

			//Instance to store Queue name and record ids
			Map<Id, String> queueMap = new Map<Id, String>();
			for (Case cs : newRec) {
				if (
					String.valueOf(cs.OwnerId).startsWith(QUEUE_PREFIX_RECORDID) &&
					cs.Origin == CASE_ORIGIN_EMAIL &&
					recordTypeIds.contains(cs.RecordTypeId) &&
					!queueMap.containsKey(cs.OwnerId)
				) {
					CommonUtilities.debug('First System Owner --->>' + cs.OwnerId);
					queueMap.put(cs.OwnerId, null);
				}
			}

			//Fetch Queue records
			for (Group gp : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN :queueMap.keySet()]) {
				queueMap.put(gp.Id, gp.Name);
			}

			CommonUtilities.debug('queueMap------->>>>>>>' + queueMap);

			//Update Case with appropriate Queue Owner
			for (Case cs : newRec) {
				if (
					cs.Origin == CASE_ORIGIN_EMAIL &&
					recordTypeIds.contains(cs.RecordTypeId) &&
					String.valueOf(cs.OwnerId).startsWith(QUEUE_PREFIX_RECORDID) &&
					queueMap.containsKey(cs.OwnerId)
				) {
					if (queueMap.get(cs.OwnerId) != Label.CASE_DEFAULT_OWNER_AGENT_UNASSIGNED) {
						cs.Email_Queue__c = queueMap.get(cs.OwnerId);
						CommonUtilities.debug('cs.Email_Queue__c------->>>>>>>' + cs.Email_Queue__c);
					}
				}
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit multipleEmailMessageHandleScenario Method');
		}
	}

	// Method Name: maintainAgentKPIStats
	// Author: Abinash Panigrahi
	// Description: Method to create/update KPI record assosiated with Case based on insert or update owner
	// Parameter 1: newRec - List of the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return: Null
	@future
	public static void maintainAgentKPIStats(Set<Id> recIds, Boolean isDML) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.maintainAgentKPIStats')) {
			CommonUtilities.debug('Inside maintainAgentKPIStats Method');
			CommonUtilities.debug('recIds------->>>>>>>' + recIds);

			//Fetch Tech Support Record Type Id
			Set<Id> recordTypeIds = caseFilterRecordTypes;

			//Get Case Record details
			List<Case> newRec = [
				SELECT Id, OwnerId, RecordTypeId, Case_KPI__c
				FROM Case
				WHERE Id IN :recIds AND RecordTypeId IN :recordTypeIds
			];

			//Instance to store KPI records yet to perform DML Operation
			List<Case_KPI__c> toBeInsertRec = new List<Case_KPI__c>();
			List<Case_KPI__c> toBeUpdateRec = new List<Case_KPI__c>();

			//Loop Logic
			//To distinguish between Case Insert or Owner Update scenario
			for (Case cs : newRec) {
				//When Case is created, one related KPI record will be inserted
				if (isDML) {
					//Check if Owner is Queue, then assign to Logged in User -- Only applicable to Insert scenario
					if (String.valueOf(cs.OwnerId).startsWith('00G')) {
						toBeInsertRec.add(
							new Case_KPI__c(
								Agent_Response_Time__c = 0,
								First_Response_Time__c = 0,
								Case_Resolution_Time__c = 0,
								Related_Case__c = cs.Id,
								OwnerId = UserInfo.getUserId()
							)
						);
					} else {
						toBeInsertRec.add(
							new Case_KPI__c(
								Agent_Response_Time__c = 0,
								First_Response_Time__c = 0,
								Case_Resolution_Time__c = 0,
								Related_Case__c = cs.Id,
								OwnerId = cs.OwnerId
							)
						);
					}
				} else {
					//When Case Owner assignment is changed, same will be reflected at KPI
					//Role Hierarachy Access level will be followed -- Private Sharing
					//Null Check
					if (cs.Case_KPI__c != null) {
						//Check if Owner is Queue, then assign to Logged in User -- Only applicable to Insert scenario
						if (String.valueOf(cs.OwnerId).startsWith('00G')) {
							toBeUpdateRec.add(new Case_KPI__c(Id = cs.Case_KPI__c, OwnerId = UserInfo.getUserId()));
						} else {
							toBeUpdateRec.add(new Case_KPI__c(Id = cs.Case_KPI__c, OwnerId = cs.OwnerId));
						}
					}
				}
			}

			CommonUtilities.debug('toBeInsertRec------->>>>>>>' + toBeInsertRec);
			CommonUtilities.debug('toBeUpdateRec------->>>>>>>' + toBeUpdateRec);

			//Insert & Update KPI records
			//Exception Handling
			try {
				if (toBeInsertRec.size() > 0) {
					insert toBeInsertRec;
				}
				if (toBeUpdateRec.size() > 0) {
					update toBeUpdateRec;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'CaseTriggerHandler',
					'maintainAgentKPIStats',
					'Trigger Logic',
					'Insert & Update Case KPIs',
					ex.getMessage(),
					System.today()
				);
			}

			//Instance to store to be Updated Case records
			List<Case> updateCaseList = new List<Case>();
			//Loop Logic
			//Case record to hold relationship with KPI record -- One-to-One (Lookup)
			for (Case_KPI__c ck : toBeInsertRec) {
				updateCaseList.add(new Case(Id = ck.Related_Case__c, Case_KPI__c = ck.Id));
			}

			CommonUtilities.debug('updateCaseList------->>>>>>>' + updateCaseList);

			//Update Case records
			//Exception Handling
			try {
				if (updateCaseList.size() > 0) {
					update updateCaseList;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'CaseTriggerHandler',
					'maintainAgentKPIStats',
					'Trigger Logic',
					'Update Case',
					ex.getMessage(),
					System.today()
				);
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit maintainAgentKPIStats Method');
		}
	}

	// Method Name: calculateCaseResolutionTime
	// Author: Abinash Panigrahi
	// Description: Method to calculate Case Resolution Time based on difference between Close and Open DateTime
	// Parameter 1: newRec - List of the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return: Null
	public static void calculateCaseResolutionTime(List<Case> newRec, Map<Id, Case> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.calculateCaseResolutionTime')) {
			CommonUtilities.debug('Inside calculateCaseResolutionTime Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Fetch Tech Support Record Type Id
			Set<Id> recordTypeIds = caseAssignmentRecordTypes;

			//FAS Recordtype Id
			Id fasCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('FAS').getRecordTypeId();

			//Instance to hold values temporarily for KPI calculation
			Map<String, String> timezoneMap = new Map<String, String>();
			List<Case_KPI__c> toBeUpdatedRec = new List<Case_KPI__c>();

			//Loop Logic
			//Find Case records
			for (Case cs : newRec) {
				//Case records with Case Status set as Closed
				//Qualify for Case Resolution Time calculation logic
				if (
					cs.Status == 'Closed' &&
					cs.Status != oldMap.get(cs.Id).Status &&
					cs.Case_KPI__c != null &&
					cs.Email_Queue__c != null &&
					recordTypeIds.contains(cs.RecordTypeId)
				) {
					timezoneMap.put(cs.Email_Queue__c, null);
				}
				//Reopen Case record needs to have KPI value reset to 0
				//Added reset logic for FAS too
				if (
					oldMap.get(cs.Id).Status == 'Closed' &&
					cs.Status != oldMap.get(cs.Id).Status &&
					cs.Case_KPI__c != null
				) {
					toBeUpdatedRec.add(new Case_KPI__c(Id = cs.Case_KPI__c, Case_Resolution_Time__c = 0));
				}
			}

			//Conditional SOQL Query
			if (timezoneMap.size() > 0) {
				//Fetch related Case Assignment Helper records
				//Get relationship between Queue Owner and its agent's working Timezone
				for (Case_Assignment_Helper__c cah : [
					SELECT Id, Email_Queue__c, TimeZone__c
					FROM Case_Assignment_Helper__c
					WHERE
						Email_Queue__c IN :timezoneMap.keySet()
						AND Case_Origin__c = :CASE_ORIGIN_QUEUE
						AND Email_Queue__c != NULL
				]) {
					timezoneMap.put(cah.Email_Queue__c, cah.Timezone__c);
				}

				//Loop Logic
				//Find Closed Case records -- Run Case Resolution time calculation logic
				for (Case cs : newRec) {
					if (
						cs.Status == 'Closed' &&
						cs.Status != oldMap.get(cs.Id).Status &&
						cs.Case_KPI__c != null &&
						cs.Email_Queue__c != null &&
						recordTypeIds.contains(cs.RecordTypeId)
					) {
						String timezoneSIDKey = timezoneMap.get(cs.Email_Queue__c);
						if (timezoneSIDKey == null) {
							timezoneSIDKey = 'GMT';
						}
						//Case KPI value Update
						//Case Opened DateTime, Case Closed DateTime and Queue Owner Timezone
						Decimal caseResolutionTime = KPIUtility.calculateKPIValue(
							cs.CreatedDate,
							cs.ClosedDate,
							timezoneSIDKey
						);
						//Add to list to be picked up for DML< operation
						toBeUpdatedRec.add(
							new Case_KPI__c(Id = cs.Case_KPI__c, Case_Resolution_Time__c = caseResolutionTime)
						);
					}

					//RAID LOG Item
					//FAS Cases - Resolution Time Calculation
					if (
						cs.RecordTypeId == fasCaseRecordTypeId &&
						cs.Status == 'Closed' &&
						cs.Status != oldMap.get(cs.Id).Status &&
						cs.Case_KPI__c != null
					) {
						//Case KPI value Update
						//Case Opened DateTime, Case Closed DateTime and Queue Owner Timezone
						Long startDateTimeLong = cs.CreatedDate.getTime();
						Long endDateTimeLong = cs.ClosedDate.getTime();
						Decimal milliseconds = Decimal.valueOf(endDateTimeLong - startDateTimeLong);
						Decimal hoursDiff = milliseconds / (1000 * 60 * 60);
						//Add to list to be picked up for DML< operation
						toBeUpdatedRec.add(new Case_KPI__c(Id = cs.Case_KPI__c, Case_Resolution_Time__c = hoursDiff));
					}
				}
			}

			//Update KPI records
			//Exception Handling
			try {
				if (toBeUpdatedRec.size() > 0) {
					update toBeUpdatedRec;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'CaseTriggerHandler',
					'calculateCaseResolutionTime',
					'Trigger Logic',
					'Update Case KPIs',
					ex.getMessage(),
					System.today()
				);
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit calculateCaseResolutionTime Method');
		}
	}

	// Method Name: retriggerLegacyServiceRequest
	// Author: Abinash Panigrahi
	// Description: Method to calculate Case KPI values for all legacy
	// Parameter 1: newRec - List of the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return: Null
	public static void retriggerLegacyServiceRequest(List<Case> newRec, Map<Id, Case> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.retriggerLegacyServiceRequest')) {
			CommonUtilities.debug('Inside retriggerLegacyServiceRequest Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Fetch Tech Support Record Type Id
			Set<Id> recordTypeIds = caseAssignmentRecordTypes;
			//FAS Recordtype Id
			Id fasCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('FAS').getRecordTypeId();
			//Acceptable range of Origin qualifid for Calculation
			Set<String> originLegacy = new Set<String>{ CASE_ORIGIN_EMAIL, CASE_ORIGIN_INSTRUMENT, CASE_ORIGIN_WEB };

			//Loop Logic
			//Figure out all Legacy Service Request records which are triggered by Dataloader for reevaluation
			Set<Id> legacySR = new Set<Id>();
			Map<String, String> timezoneMap = new Map<String, String>();
			for (Case cs : newRec) {
				if (
					cs.Retrigger_Case_KPI__c &&
					cs.Retrigger_Case_KPI__c != oldMap.get(cs.Id).Retrigger_Case_KPI__c &&
					recordTypeIds.contains(cs.RecordTypeId) &&
					originLegacy.contains(cs.Origin)
				) {
					legacySR.add(cs.Id);
					timezoneMap.put(cs.Email_Queue__c, null);
				}

				//RAID LOG Item
				if (
					cs.Retrigger_Case_KPI__c &&
					cs.Retrigger_Case_KPI__c != oldMap.get(cs.Id).Retrigger_Case_KPI__c &&
					cs.RecordTypeId == fasCaseRecordTypeId
				) {
					legacySR.add(cs.Id);
				}
			}
			CommonUtilities.debug('legacySR------->>>>>>>' + legacySR);
			CommonUtilities.debug('timezoneMap------->>>>>>>' + timezoneMap);

			//Safe side DML -- to delete all KPI values, if any existing for Legacy SRs
			List<Case_KPI__c> toBeDeletedRec = [SELECT Id FROM Case_KPI__c WHERE Related_Case__c IN :legacySR];
			if (toBeDeletedRec.size() > 0) {
				delete toBeDeletedRec;
			}
			CommonUtilities.debug('toBeDeletedRec------->>>>>>>' + toBeDeletedRec);

			//Insert dummy KPI values related to Legacy SRs
			List<Case_KPI__c> toBeInsertedRec = new List<Case_KPI__c>();
			for (Case cs : newRec) {
				if (legacySR.contains(cs.Id)) {
					//Check if Owner is Queue, then assign to Logged in User -- Only applicable to Insert scenario
					if (String.valueOf(cs.OwnerId).startsWith('00G')) {
						toBeInsertedRec.add(
							new Case_KPI__c(
								Agent_Response_Time__c = 0,
								First_Response_Time__c = 0,
								Case_Resolution_Time__c = 0,
								Related_Case__c = cs.Id,
								OwnerId = UserInfo.getUserId()
							)
						);
					} else {
						toBeInsertedRec.add(
							new Case_KPI__c(
								Agent_Response_Time__c = 0,
								First_Response_Time__c = 0,
								Case_Resolution_Time__c = 0,
								Related_Case__c = cs.Id,
								OwnerId = cs.OwnerId
							)
						);
					}
				}
			}
			if (toBeInsertedRec.size() > 0) {
				insert toBeInsertedRec;
			}
			CommonUtilities.debug('toBeInsertedRec------->>>>>>>' + toBeInsertedRec);

			//Update the relationship between Case & KPI record -- One to One (Lookup)
			List<Case> updateCaseRelation = new List<Case>();
			for (Case_KPI__c ck : toBeInsertedRec) {
				updateCaseRelation.add(new Case(Id = ck.Related_Case__c, Case_KPI__c = ck.Id));
			}
			if (updateCaseRelation.size() > 0) {
				update updateCaseRelation;
			}
			CommonUtilities.debug('updateCaseRelation------->>>>>>>' + updateCaseRelation);

			//Conditional SOQL statement
			if (legacySR.size() > 0) {
				//Fetch all Queue and its locale timezone information
				for (Case_Assignment_Helper__c cah : [
					SELECT Id, Email_Queue__c, TimeZone__c
					FROM Case_Assignment_Helper__c
					WHERE
						Email_Queue__c IN :timezoneMap.keySet()
						AND Case_Origin__c = :CASE_ORIGIN_QUEUE
						AND TimeZone__c != NULL
				]) {
					timezoneMap.put(cah.Email_Queue__c, cah.Timezone__c);
				}
				CommonUtilities.debug('timezoneMap------->>>>>>>' + timezoneMap);

				//Get Case records along with Oldest Outgoing Email communication -- Fetch all required info required for our furture calculation
				//List<Case> legacyServiceRequestWithEmail =[SELECT Id,CreatedDate,ClosedDate,Email_Queue__c,Case_KPI__c,(SELECT Id,CreatedDate FROM EmailMessages WHERE Incoming = false ORDER BY CreatedDate LIMIT 1) FROM Case WHERE Id IN: legacySR AND RecordTypeId IN: recordTypeIds];
				List<Case> legacyServiceRequestWithEmail = [
					SELECT
						Id,
						Email_Queue__c,
						ClosedDate,
						Case_KPI__c,
						CreatedDate,
						OwnerId,
						(
							SELECT Id, CreatedDate, CreatedById
							FROM EmailMessages
							WHERE Incoming = FALSE AND (NOT FromAddress LIKE '%autoreply%')
							ORDER BY messageDate ASC
						),
						(SELECT Id, CreatedDate FROM Histories WHERE Field = 'Owner' ORDER BY CreatedDate DESC)
					FROM Case
					WHERE Id IN :legacySR AND RecordTypeId IN :recordTypeIds
				];

				CommonUtilities.debug('legacyServiceRequestWithEmail------->>>>>>>' + legacyServiceRequestWithEmail);

				//Use KPI Calculation logic to figure out Resolution & Response Time of Legacy SRs
				List<Case_KPI__c> toBeUpdatedRec = new List<Case_KPI__c>();
				for (Case cs : legacyServiceRequestWithEmail) {
					if (timezoneMap.containsKey(cs.Email_Queue__c)) {
						String localTimezone = timezoneMap.get(cs.Email_Queue__c);
						if (localTimezone != null) {
							//KPI Calculation

							Decimal resoltionTime = 0, responseTime = 0;
							if (cs.ClosedDate != null) {
								resoltionTime = KPIUtility.calculateKPIValue(
									cs.CreatedDate,
									cs.ClosedDate,
									localTimezone
								);
							}
							if (
								cs.EmailMessages != null &&
								cs.EmailMessages.size() > 0 &&
								cs.EmailMessages[0].CreatedDate != null
							) {
								responseTime = KPIUtility.calculateKPIValue(
									cs.CreatedDate,
									cs.EmailMessages[0].CreatedDate,
									localTimezone
								);
							}
							toBeUpdatedRec.add(
								new Case_KPI__c(
									Id = cs.Case_KPI__c,
									Agent_Response_Time__c = responseTime,
									First_Response_Time__c = responseTime,
									Case_Resolution_Time__c = resoltionTime
								)
							);
						}
					}
				}

				//FAS Cases - Resolution Time Calculation
				List<Case> fasCases = [
					SELECT Id, CreatedDate, ClosedDate, Case_KPI__c
					FROM Case
					WHERE RecordTypeId = :fasCaseRecordTypeId AND Id IN :legacySR
				];
				//Loop Logic
				//Update Case KPI record
				for (Case cs : fasCases) {
					if (cs.ClosedDate != null) {
						Long startDateTimeLong = cs.CreatedDate.getTime();
						Long endDateTimeLong = cs.ClosedDate.getTime();
						Decimal milliseconds = Decimal.valueOf(endDateTimeLong - startDateTimeLong);
						Decimal hoursDiff = milliseconds / (1000 * 60 * 60);
						toBeUpdatedRec.add(new Case_KPI__c(Id = cs.Case_KPI__c, Case_Resolution_Time__c = hoursDiff));
					}
				}

				//Update Case KPI records
				if (toBeUpdatedRec.size() > 0) {
					update toBeUpdatedRec;
				}
				CommonUtilities.debug('toBeUpdatedRec------->>>>>>>' + toBeUpdatedRec);
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit retriggerLegacyServiceRequest Method');
		}
	}

	// Method Name: handleKPIDeletion
	// Author: Basant Kumar Verma
	// Description: Method to delete the KPI record on deletion of parent Case
	// Parameter 1: caseList - List of the Case records which are delting
	// Return: Null
	public static void handleKPIDeletion(List<Case> caseList) {
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.handleKPIDeletion')) {
			Set<Id> caseKPIIds = new Set<Id>();
			for (Case c : caseList) {
				if (c.Case_KPI__c != null) {
					caseKPIIds.add(c.Case_KPI__c);
				}
			}

			if (!caseKPIIds.isEmpty()) {
				delete (new List<Case_KPI__c>([SELECT Id FROM Case_KPI__c WHERE Id IN :caseKPIIds]));
			}
		}
	}

	//Schema Describe Call
	private static Map<String, Schema.RecordTypeInfo> caseRecordTypesByName {
		get {
			if (caseRecordTypesByName == null) {
				caseRecordTypesByName = Schema.SObjectType.Case.getRecordTypeInfosByName();
			}
			return caseRecordTypesByName;
		}
		set;
	}

	//Get Recordtype for Tech Support and FAS
	private static Set<Id> caseFilterRecordTypes {
		get {
			if (caseFilterRecordTypes == null) {
				caseFilterRecordTypes = new Set<Id>();
				for (String rt : Label.CASE_ASSIGNMENT_RECORDTYPE_FILTER.split(',')) {
					if (caseRecordTypesByName != null && caseRecordTypesByName.containsKey(rt)) {
						caseFilterRecordTypes.add(caseRecordTypesByName.get(rt).getRecordTypeId());
					}
				}
			}
			return caseFilterRecordTypes;
		}
		set;
	}

	//Get Tech Support Record Type Id
	private static Set<Id> caseAssignmentRecordTypes {
		get {
			if (caseAssignmentRecordTypes == null) {
				caseAssignmentRecordTypes = new Set<Id>();
				for (String rt : Label.CASE_ASSIGNMENT_RULE_RECORDTYPE.split(',')) {
					if (caseRecordTypesByName != null && caseRecordTypesByName.containsKey(rt)) {
						caseAssignmentRecordTypes.add(caseRecordTypesByName.get(rt).getRecordTypeId());
					}
				}
			}
			return caseAssignmentRecordTypes;
		}
		set;
	}

	// Method Name: caseCloseValidation
	// Author: Pradeep Chanda
	// Last Modified : Jayaram B
	// Description: Method to throw error message when the case the case is cloded with open taks or events.
	// Parameter 1: newMap - Map of IDs to the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return: List of Cases
	public static void caseCloseValidation(Map<id, Case> newMap, Map<id, Case> oldMap) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.caseCloseValidation')) {
			Set<Id> closedCaseIdsSet = new Set<Id>();
			Set<Id> caseRecordTypeIdsSet = new Set<Id>();
			List<String> caseStatusList = new List<String>();
			if (String.IsNotBlank(Label.CASE_CLOSED_RECORD_TYPE_FILTERS)) {
				for (String recordType : Label.CASE_CLOSED_RECORD_TYPE_FILTERS.split(',')) {
					caseRecordTypeIdsSet.add(caseRecordTypesByName.get(recordType).getRecordTypeId());
				}
			}
			if (String.isNotBlank(Label.CASE_STATUS_RESTRICTION_FOR_OPEN_TASK)) {
				caseStatusList = Label.CASE_STATUS_RESTRICTION_FOR_OPEN_TASK.split(',');
			}
			//Fetch all newly closed cases.
			for (Id caseId : Trigger.newMap.keySet()) {
				if (
					caseStatusList.Contains(newMap.get(caseId).Status) &&
					caseRecordTypeIdsSet.contains(newMap.get(caseId).RecordTypeId)
				) {
					closedCaseIdsSet.add(caseId);
				}
			}
			//Check for open tasks
			for (AggregateResult openTasks : [
				SELECT Count(Id), WhatId
				FROM Task
				WHERE WhatId IN :closedCaseIdsSet AND IsClosed = FALSE
				GROUP BY WhatId HAVING Count(Id) > 0
			]) {
				Id caseId = (Id) openTasks.get('WhatId');
				Trigger.newMap.get(caseId).addError(Label.CASE_OPEN_TASKS_ERROR_MESSAGE);
			}
		}
	}

	// Method Name: casePrimaryAssetCreationUpdate
	// Author: Jayaram B
	// Description: Method to create a primary Asset record When Asset is selected in Case.
	// Parameter 1: newMap - Map of IDs to the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return:
	public static void casePrimaryAssetCreationUpdate(Map<id, Case> oldMap, Map<id, Case> newMap) {
		List<Case_Related_Assets__c> caseAssetDeleteList = new List<Case_Related_Assets__c>();
		List<Case_Related_Assets__c> caseAssetInsertList = new List<Case_Related_Assets__c>();
		List<Case_Related_Assets__c> caseAssetUpdateList = new List<Case_Related_Assets__c>();
		Map<Id, Case_Related_Assets__c> mapPrimaryAssestRec = new Map<Id, Case_Related_Assets__c>();
		for (Case_Related_Assets__c caseRelAssetRec : [
			SELECT Id, Name, Case__c
			FROM Case_Related_Assets__c
			WHERE Primary__c = TRUE AND Case__c IN :Trigger.newMap.keySet()
		]) {
			mapPrimaryAssestRec.put(caseRelAssetRec.Case__c, caseRelAssetRec);
		}
		for (Id caseRecId : Trigger.newMap.keySet()) {
			if (
				newMap.get(caseRecId).AssetId == null &&
				mapPrimaryAssestRec.Size() > 0 &&
				mapPrimaryAssestRec.ContainsKey(caseRecId)
			) {
				caseAssetDeleteList.add(mapPrimaryAssestRec.get(caseRecId));
			}
		}
		if (caseAssetDeleteList.Size() > 0) {
			delete caseAssetDeleteList;
		}
		for (Id caseRecId : Trigger.newMap.keySet()) {
			if (
				newMap.get(caseRecId).AssetId != null &&
				oldMap.get(caseRecId).AssetId != newMap.get(caseRecId).AssetId
			) {
				if (
					oldMap.get(caseRecId).AssetId != null &&
					mapPrimaryAssestRec.Size() > 0 &&
					mapPrimaryAssestRec.ContainsKey(caseRecId)
				) {
					Case_Related_Assets__c caseRelAssetRecord = new Case_Related_Assets__c(
						Id = mapPrimaryAssestRec.get(caseRecId).Id,
						Asset__c = newMap.get(caseRecId).AssetId
					);
					caseAssetUpdateList.add(caseRelAssetRecord);
				} else {
					Case_Related_Assets__c caseRelAssetRecord = new Case_Related_Assets__c(
						Case__c = caseRecId,
						Asset__c = newMap.get(caseRecId).AssetId,
						Primary__c = true
					);
					caseAssetInsertList.add(caseRelAssetRecord);
				}
			}
		}
		if (caseAssetInsertList.size() > 0) {
			insert caseAssetInsertList;
		}
		if (caseAssetUpdateList.size() > 0) {
			update caseAssetUpdateList;
		}
	}

	// Method Name: casePrimaryAssetCreationInert
	// Author: Jayaram B
	// Description: Method to create a primary Asset record to the Case when new Case is created.
	// Parameter 1: newMap - Map of IDs to the new versions of the Case records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Case records
	// Return:
	public static void casePrimaryAssetCreationInert(Map<id, Case> newMap) {
		List<Case_Related_Assets__c> caseAssetRecordsList = new List<Case_Related_Assets__c>();
		for (Id caseId : Trigger.newMap.keySet()) {
			if (newMap.get(caseId).AssetId != null) {
				Case_Related_Assets__c caseRelAssetRecord = new Case_Related_Assets__c(
					Case__c = caseId,
					Asset__c = newMap.get(caseId).AssetId,
					Primary__c = true
				);
				caseAssetRecordsList.add(caseRelAssetRecord);
			}
		}
		insert caseAssetRecordsList;
	}
	// Method Name: emailMessageForWebAndInstrumentOrigin
	// Author: Venkata Sai
	// Description: Method to insert a Email record for case origin 'Web'& 'Instrument'
	// Parameter 1: listCaseRecs - List of the Case records

	public static void emailMessageForWebAndInstrumentOrigin(List<Case> listCaseRecs) {
		if (DynamicCodeExecution.allowExecution('CaseTriggerHandler.emailMessageForWebAndInstrumentOrigin')) {
			CommonUtilities.debug('Inside emailMessageForWebAndInstrumentOrigin Method');

			List<EmailMessage> listEmailMessages = new List<EmailMessage>();
			Map<Id, case> mapCase = new Map<Id, case>();
			//Tech Support Recordtype Id
			Id techSuppCaseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
				.get('Tech Support')
				.getRecordTypeId();
			for (case caseObjRec : listCaseRecs) {
				if (
					caseObjRec.Origin == 'Web' ||
					caseObjRec.Origin == 'Instrument' &&
					caseObjRec.RecordTypeId == techSuppCaseRecTypeId
				) {
					mapCase.put(caseObjRec.Id, caseObjRec);
				}
			}
			for (Case obj : mapCase.values()) {
				EmailMessage emailMsg = new EmailMessage(
					ToAddress = obj.SuppliedEmail,
					Subject = 'Case ID ' + obj.CaseNumber,
					Status = '1',
					HtmlBody = obj.Description,
					TextBody = obj.Description,
					ParentId = obj.Id,
					MessageDate = obj.CreatedDate
				);
				listEmailMessages.add(emailMsg);
			}
			try {
				if (listEmailMessages.size() > 0) {
					insert listEmailMessages;
				}
			} catch (Exception ex) {
				ExceptionHandlerController.createException(
					'CaseTriggerHandler',
					'insertEmailRec',
					'Trigger Logic',
					'Insert Email',
					ex.getMessage(),
					System.today()
				);
			}
			CommonUtilities.debug('listEmailMessages------->>>>>>>' + listEmailMessages);
		}
		CommonUtilities.debug('Exit emailMessageForWebAndInstrumentOrigin Method');
	}
}