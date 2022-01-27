// ===========================================================================
//  Object	: EmailMessageTriggerHandler
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Handler Class contains all logic for EmailMessageTrigger.
// ===========================================================================

public class EmailMessageTriggerHandler {
	private final static String EMAIL_STATUS_NEW = '0';
	private final static String EMAIL_STATUS_SENT = '3';
	private final static String CASE_HISTORY_FIELD = 'Email';
	private final static String CASE_ORIGIN_QUEUE = 'Queue';

	// Method Name: recieverEmailQueueCase
	// Author: Abinash Panigrahi
	// Description: Method to reflect Case records with Receiver Email Queue address and do Direct Queue Routing
	// Parameter 1: newRec - List of the new versions of the Case records
	// Return: Null
	public static void recieverEmailQueueCase(List<EmailMessage> newRec) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('EmailMessageTriggerHandler.recieverEmailQueueCase')) {
			CommonUtilities.debug('Inside recieverEmailQueueCase Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Fetch Tech Support Record Type Id
			List<String> caseRecordTypeName = caseRecordTypes(Label.EMAIL_ASSIGNMENT_RULE_RECORDTYPE);

			//Instance to store Parent Case and Receiver Email Address
			Map<Id, String> caseReceiverEmailMap = new Map<Id, String>();
			//Instance to store Parent Case with multiple Email address in To section
			Set<Id> caseWithMultipleQueues = new Set<Id>();
			//Loop Logic
			//Filter all Email Message with Status as New, Incoming as True and always assosiated with New Case
			for (EmailMessage em : newRec) {
				if (
					em.Status == EMAIL_STATUS_NEW &&
					em.ParentId != null &&
					em.Incoming == true &&
					!caseReceiverEmailMap.containsKey(em.ParentId)
				) {
					caseReceiverEmailMap.put(em.ParentId, em.ToAddress);

					//Check if To Address contain Multiple Queue mailbox or not
					if (em.ToAddress != null && em.ToAddress.contains(';')) {
						caseWithMultipleQueues.add(em.ParentId);
					}
				}
			}

			CommonUtilities.debug('caseReceiverEmailMap------->>>>>>>' + caseReceiverEmailMap);
			CommonUtilities.debug('caseWithMultipleQueues------->>>>>>>' + caseWithMultipleQueues);

			//Conditional SOQL Statement
			//Execute further logic only if new Email Message is received from Customer
			if (caseReceiverEmailMap != null) {
				//Fetch related new Cases - just now created by Customer Email
				//Relation Query included child object records - Case History and Email Message
				List<Case> toBeupdatedRec = new List<Case>(
					[
						SELECT
							Id,
							Receiver_Email__c,
							Email_Queue__c,
							(SELECT Id FROM EmailMessages WHERE Incoming = TRUE)
						FROM Case
						WHERE
							Id IN :caseReceiverEmailMap.keySet()
							AND Origin = :Label.CASE_EMAIL_ORIGIN
							AND RecordType.Name IN :caseRecordTypeName
							AND Receiver_Email__c = NULL
					]
				);

				CommonUtilities.debug('toBeupdatedRec------->>>>>>>' + toBeupdatedRec);

				//Fetch Direct Queue Assignment Master Data
				List<Case_Assignment_Helper__c> caseAssignmentHelperInfo = new List<Case_Assignment_Helper__c>(
					[
						SELECT Id, Mailbox_Id__c, Email_Queue__c
						FROM Case_Assignment_Helper__c
						WHERE Case_Origin__c = :CASE_ORIGIN_QUEUE AND Email_Queue__c != NULL
					]
				);

				CommonUtilities.debug('caseAssignmentHelperInfo------->>>>>>>' + caseAssignmentHelperInfo);

				//Instance to store Mailbox Id and Email Queue
				Map<String, String> mailboxQueueMap = new Map<String, String>();
				//Loop Logic
				//Populate the relationship value of above instance
				for (Case_Assignment_Helper__c cah : caseAssignmentHelperInfo) {
					mailboxQueueMap.put(cah.Mailbox_Id__c, cah.Email_Queue__c);
				}

				CommonUtilities.debug('mailboxQueueMap------->>>>>>>' + mailboxQueueMap);

				//Loop Logic
				//Populate Receiver Email Queue info
				for (Case cs : toBeupdatedRec) {
					//Check if this is first Email Message received from Customer
					if (caseReceiverEmailMap.containsKey(cs.Id) && cs.EmailMessages.size() == 1) {
						//Check for Single MailboxId Email Message
						if (!caseWithMultipleQueues.contains(cs.Id)) {
							//Update Receiver Email and Queue Owner information directly
							cs.Receiver_Email__c = caseReceiverEmailMap.get(cs.Id);
							if (mailboxQueueMap.containsKey(cs.Receiver_Email__c)) {
								cs.Email_Queue__c = mailboxQueueMap.get(cs.Receiver_Email__c);
								CommonUtilities.debug('cs.Email_Queue__c------->>>>>>>' + cs.Email_Queue__c);
							}
						} else if (cs.Email_Queue__c != null) {
							//Check if Email Message is addressed to multiple Queues in a single shot
							List<String> mailAliasSimilarQueue = new List<String>();
							//Find all main mailbox and alias matching with Queue Owner
							for (String mailbox : mailboxQueueMap.keySet()) {
								if (mailboxQueueMap.get(mailbox) == cs.Email_Queue__c) {
									mailAliasSimilarQueue.add(mailbox.remove(' '));
								}
							}

							//Find the Receiver Email for Case
							for (String toMail : caseReceiverEmailMap.get(cs.Id).remove(' ').split(';')) {
								if (mailAliasSimilarQueue.contains(toMail)) {
									cs.Receiver_Email__c = toMail;
									CommonUtilities.debug('cs.Receiver_Email__c------->>>>>>>' + cs.Receiver_Email__c);
								}
							}
						}
					}
				}

				//Exception Handling
				//Update Case records
				try {
					if (toBeupdatedRec.size() > 0) {
						update toBeupdatedRec;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'EmailMessageTriggerHandler',
						'recieverEmailQueueCase',
						'Trigger Logic',
						'Update Case',
						ex.getMessage(),
						System.today()
					);
				}
				CommonUtilities.debug('toBeupdatedRec------->>>>>>>' + toBeupdatedRec);
			}

			CommonUtilities.debug('Exit recieverEmailQueueCase Method');
		}
	}

	// Method Name: firstCaseAgentResponseTimeCalculation
	// Author: Abinash Panigrahi
	// Description: Method to calculate First Response Time based on Tech Support Email reply - Case and Agent Response Time
	// Parameter 1: newRec - List of the new versions of the Case records
	// Return: Null
	public static void firstCaseAgentResponseTimeCalculation(List<EmailMessage> newRec) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('EmailMessageTriggerHandler.firstCaseAgentResponseTimeCalculation')) {
			CommonUtilities.debug('Inside firstCaseAgentResponseTimeCalculation Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Fetch Tech Support Record Type Id
			List<String> caseRecordTypeName = caseRecordTypes(Label.CASE_ASSIGNMENT_RULE_RECORDTYPE);

			//Instance to classify all Sent Email communication
			Set<Id> caseIds = new Set<Id>();
			//Filter entire all email logs based on Sent Status, will have ReplyMessage relation and it needs to be outbound
			for (EmailMessage em : newRec) {
				if (em.Incoming == false && em.ReplyToEmailMessageId != null) {
					caseIds.add(em.ParentId);
				}
			}

			CommonUtilities.debug('caseIds------->>>>>>>' + caseIds);

			//Execute further logic if any Email message is related to Case is found
			if (caseIds != null) {
				//Fetch Aggregate Result based on count of Email message related to certain case
				//Main lookout is for first reply to Customer mail
				Map<Id, Integer> emailCount = new Map<Id, Integer>();
				for (AggregateResult ar : [
					SELECT Count(Id) total, ParentId
					FROM EmailMessage
					WHERE Incoming = FALSE AND ReplyToEmailMessageId != NULL AND ParentId IN :caseIds
					GROUP BY ParentId
				]) {
					emailCount.put((Id) ar.get('ParentId'), (Integer) ar.get('Total'));
				}

				CommonUtilities.debug('emailCount------->>>>>>>' + emailCount);

				//Fetch Case Assignment Helper records
				//Queue Owner and timezone relationship built up
				Map<String, String> queueTimezoneMap = new Map<String, String>();
				for (Case_Assignment_Helper__c cah : [
					SELECT Id, Email_Queue__c, TimeZone__c
					FROM Case_Assignment_Helper__c
					WHERE Email_Queue__c != NULL AND Case_Origin__c = :CASE_ORIGIN_QUEUE
				]) {
					queueTimezoneMap.put(cah.Email_Queue__c, cah.Timezone__c);
				}

				CommonUtilities.debug('queueTimezoneMap------->>>>>>>' + queueTimezoneMap);

				//loading valid Case records to process
				caseIds.clear();
				for (Id i : emailCount.keySet()) {
					if (emailCount.get(i) == 1) {
						caseIds.add(i);
					}
				}

				CommonUtilities.debug('caseIds------->>>>>>>' + caseIds);

				if (caseIds.size() > 0) {
					//Performing First Case Response Time and Agent Response Time calculation
					//First Tech Support reply Email Sent dateTime - Case Created/Opened datetime
					//Prepare the list of Case records to be updated
					List<Case> toBeUpdatedRec = new List<Case>();
					List<Case_KPI__c> kpiUpdates = new List<Case_KPI__c>();
					//List<EmailMessage> lstMsg=new List<EmailMessage>

					for (Case cs : [
						SELECT
							Id,
							Email_Queue__c,
							Case_KPI__c,
							CreatedDate,
							OwnerId,
							(
								SELECT Id, CreatedDate, CreatedById
								FROM EmailMessages
								WHERE
									Incoming = FALSE
									AND (NOT FromAddress LIKE '%autoreply%')
									AND (ReplyToEmailMessageId != NULL
									OR ReplyToEmailMessageCustomId__c != NULL)
								ORDER BY messageDate ASC
							),
							(SELECT Id, CreatedDate FROM Histories WHERE Field = 'Owner' ORDER BY CreatedDate DESC)
						FROM Case
						WHERE Id IN :caseIds AND RecordType.Name IN :caseRecordTypeName
					]) {
						CommonUtilities.debug('cs:' + cs);
						//Case First Response Time
						Decimal caseFirstResponseTime, agentResponseTime;
						if (
							cs.EmailMessages != null &&
							cs.EmailMessages.get(0) != null &&
							cs.Case_KPI__c != null &&
							cs.Email_Queue__c != null
						) {
							String timezoneSIDKey = queueTimezoneMap.get(cs.Email_Queue__c);
							CommonUtilities.debug('timezoneSIDKey------->>>>>>>' + timezoneSIDKey);
							if (timezoneSIDKey != null) {
								caseFirstResponseTime = KPIUtility.calculateKPIValue(
									cs.CreatedDate,
									cs.EmailMessages[0].CreatedDate,
									timezoneSIDKey
								);
								CommonUtilities.debug('caseFirstResponseTime------->>>>>>>' + caseFirstResponseTime);
								//cs.First_Response_Time__c = Decimal.valueOf(cs.EmailMessages[0].CreatedDate.getTime() - cs.CreatedDate.getTime())/(60*60*1000);
								//Agent First Response Time
								if (cs.Histories != null && cs.Histories.size() >= 2) {
									agentResponseTime = KPIUtility.calculateKPIValue(
										cs.Histories[0].CreatedDate,
										cs.EmailMessages[0].CreatedDate,
										timezoneSIDKey
									);
									CommonUtilities.debug('agentResponseTime------->>>>>>>' + agentResponseTime);
									//cs.Agent_Response_Time__c = Decimal.valueOf(cs.EmailMessages[0].CreatedDate.getTime() - cs.Histories[0].CreatedDate.getTime())/(60*60*1000);
								}
							}
						}

						//Assign Case Owner to particular Individual based on First Response Sent to Customer Email
						if (
							!String.valueOf(cs.OwnerId).startswith(Label.USER_RECORDID_PREFIX) &&
							cs.EmailMessages.get(0) != null
						) {
							cs.OwnerId = cs.EmailMessages[0].CreatedById;
							agentResponseTime = caseFirstResponseTime;
							CommonUtilities.debug('agentResponseTime------->>>>>>>' + agentResponseTime);
							//cs.Agent_Response_Time__c = cs.First_Response_Time__c;
						}
						toBeUpdatedRec.add(cs);
						CommonUtilities.debug('toBeUpdatedRec------->>>>>>>' + toBeUpdatedRec);

						//Prepare list of Case KPI records to be updated
						kpiUpdates.add(
							new Case_KPI__c(
								Id = cs.Case_KPI__c,
								Agent_Response_Time__c = agentResponseTime,
								First_Response_Time__c = caseFirstResponseTime
							)
						);
						CommonUtilities.debug('kpiUpdates------->>>>>>>' + kpiUpdates);
					}

					//Update KPI records
					//Exception Handling
					try {
						if (kpiUpdates.size() > 0) {
							update kpiUpdates;
							system.debug('kpiUpdates:' + kpiUpdates);
						}
					} catch (Exception ex) {
						//Create Apex Log
						ExceptionHandlerController.createException(
							'EmailMessageTriggerHandler',
							'firstResponseTimeCalculation',
							'Trigger Logic',
							'Update Case KPIs',
							ex.getMessage(),
							System.today()
						);
					}

					//Exception Handling
					//Update Case records
					try {
						if (toBeUpdatedRec.size() > 0) {
							update toBeUpdatedRec;
						}
					} catch (Exception ex) {
						//Create Apex Log
						ExceptionHandlerController.createException(
							'EmailMessageTriggerHandler',
							'firstResponseTimeCalculation',
							'Trigger Logic',
							'Update Case',
							ex.getMessage(),
							System.today()
						);
					}
				}
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit calculateCaseResolutionTime Method');
		}
	}

	// Method Name: handleDeleteFASAndTechSupportCaseEmailMessage
	// Author: Adarsh Sharma
	// Description: Method to add validation users cannot delete Email Message if the tech support/fas case status closed
	// Parameter 1: newRec - List of the new versions of the Task records
	// Return: Null
	public static void handleDeleteFASAndTechSupportCaseEmailMessage(List<EmailMessage> triggerOld) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('EmailMessageTrigger.handleDeleteFASAndTechSupportCaseEmailMessage')) {
			//Get Recordtype for Tech Support and FAS
			List<String> caseRecordTypeName = caseRecordTypes(Label.CASE_FAS_Tech_RECORDTYPE_FILTER);

			Set<Id> setCaseId = new Set<Id>();
			Set<Id> setCloseFASAndTechSupportCaseId = new Set<Id>();

			for (EmailMessage oEmailMessage : triggerOld) {
				if (oEmailMessage.ParentId != null) {
					setCaseId.add(oEmailMessage.ParentId);
				}
			}

			if (setCaseId.size() > 0) {
				for (Case oCase : [
					SELECT Id
					FROM Case
					WHERE Id IN :setCaseId AND RecordType.Name IN :caseRecordTypeName AND IsClosed = TRUE
				]) {
					setCloseFASAndTechSupportCaseId.add(oCase.Id);
				}
			}

			if (setCloseFASAndTechSupportCaseId.size() > 0) {
				for (EmailMessage oEmailMessage : triggerOld) {
					if (
						oEmailMessage.ParentId != null &&
						setCloseFASAndTechSupportCaseId.contains(oEmailMessage.ParentId)
					) {
						if (!CommonUtilities.isSystemAdminUserWithByPassValidation) {
							oEmailMessage.addError(Label.EMAIL_MESSAGE_CANNOT_DELETED);
						}
					}
				}
			}
		}
	}

	//Single Method to parse Case Record Types
	public static List<String> caseRecordTypes(String customLabel) {
		List<String> caseRecordType = new List<String>();
		if (String.isNotBlank(customLabel) && String.isNotEmpty(customLabel)) {
			caseRecordType = customLabel.split(',');
		}
		return caseRecordType;
	}
}