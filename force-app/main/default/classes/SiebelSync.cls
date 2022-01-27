// ===========================================================================
//  Class Name  : SiebelSync
//  Company     : Keste @IDC
//  Author      : Vasavi Poranki/Abinash Panigrahi
//  Purpose     : Integration Queable Interface for Contact and Opportunity Siebel Integration
//  Test Class  : SiebelSync_Test
// ===========================================================================
public class SiebelSync implements Queueable, Database.AllowsCallouts {
	public String parentObjectAPIName;
	public String objectName;
	public String OperationType; // Accepts DML Operation Type
	public Set<Id> setRecordIds; //Bulkifying Records
	public String relatedOperationType; //Accepts DML Operation Type for Child Objects (If any)
	public String strApplicationName;
	public Boolean bulkJob;

	// Method Name: execute
	// Author: Abinash panigrahi
	// Description: Outbound Integration Interface to sync data from Salesforce to Siebel system
	// Parameter: QueueableContext context
	// Return: Null
	public void execute(QueueableContext context) {
		//Application Name -- Apex Log to identify Integration Request
		//Notify Integration request being processed for Header/Child object
		strApplicationName = objectName + ' - Integration - ' + relatedOperationType;

		//Contact Integration Interface Logic -- Outbound Callouts
		if (setRecordIds != null && setRecordIds.size() > 0) {
			//Fetch assosiated Contact records passed from Trigger
			List<sObject> recordList = fetchRecords(parentObjectAPIName, setRecordIds);

			//JSON Request Preparation based on Object and Operation tag
			Map<Id, String> objectJSONRequestMap = new Map<Id, String>();
			if (parentObjectAPIName == 'CONTACT') {
				objectJSONRequestMap = IntegrationRequestUtilty.getContactJSONRequest(
					OperationType,
					recordList,
					bulkJob
				);
			} else if (parentObjectAPIName == 'OPPORTUNITY') {
				objectJSONRequestMap = IntegrationRequestUtilty.getOpportunityJSONRequest(OperationType, recordList);
			}

			//Map of Integration Response wrapper
			Map<Id, IntegrationResponse> responseMap = new Map<Id, IntegrationResponse>();
			for (sObject obj : recordList) {
				Id recordId = (Id) obj.get('Id');
				if (objectJSONRequestMap.containsKey(recordId)) {
					//Send Outbound Callouts to External System
					IntegrationResponse intgRes = syncRecordWithSiebel(
						OperationType,
						strApplicationName,
						objectJSONRequestMap.get(recordId),
						parentObjectAPIName,
						bulkjob
					);
					//Collect All callout results
					responseMap.put(recordId, intgRes);
				}
			}

			//Process All Integration Results
			for (Id recordId : responseMap.keySet()) {
				processIntegrationResponse(
					strApplicationName,
					objectJSONRequestMap.get(recordId),
					responseMap.get(recordId)
				);
			}
		}
	}

	// Method Name: syncRecordWithSiebel
	// Author: Abinash panigrahi
	// Description: Integration Http Request/Callout made to External System and Response Handling
	// Parameter 1: OperationType - Record Header DML Operation Type
	// Parameter 2: strApplicationName - Notify Integration request being processed for Header/Child object
	// Parameter 3: jsonRequest - Request Body used in HTTP callouts
	// Parameter 4: objectName - Header Object Name
	// Return: IntegrationResponse - Integration Response wrapper
	public IntegrationResponse syncRecordWithSiebel(
		String OperationType,
		String strApplicationName,
		String jsonRequest,
		String objectName,
		Boolean bulkJob
	) {
		IntegrationResponse intRes = null;
		try {
			//Integration Response Handling
			//Http Request & Callout are made to External System
			intRes = IntegrationUtility.SF_Siebel_Sync(jsonRequest, OperationType, objectName, bulkJob);
		} catch (Exception ex) {
			//Create Apex Log incase any internal error occured during Integration process
			ExceptionHandlerController.createIntegrationException(
				'SiebelSync',
				'SiebelSync',
				strApplicationName,
				'Salesforce to Siebel Sync Failed',
				'Error Occured during the Sync. ' + ex.getMessage(),
				System.today(),
				jsonRequest,
				ex.getStackTraceString(),
				'Error'
			);
			return null;
		}
		return intRes;
	}

	// Method Name: processIntegrationResponse
	// Author: Basant Kumar Verma
	// Description: Methdo to Process the Integration Response
	// Parameter 1: String strApplicationName - Notify Integration request being processed for Header/Child object
	// Parameter 2: String jsonRequest - Request Body used in HTTP callouts
	// Parameter 3: IntegrationResponse intRes - Integration response wrapper
	public static void processIntegrationResponse(
		String strApplicationName,
		String jsonRequest,
		IntegrationResponse intRes
	) {
		//Instance to store Error messages
		List<String> errors = new List<String>();

		//Extra Null Check to avoid Exception
		if (intRes != null) {
			//JSON format Response received -- Important
			String jsonResponse = intRes.response.getBody();

			//If got Success Response, then Process record
			if (intRes.response.getStatusCode() == 200) {
				if (jsonResponse != null && jsonResponse != '') {
					//Perform JSON parsing of Immediate Response recieved
					JSONParser parser = JSON.createParser(jsonResponse);

					//Decode or Deserialize the JSON Response to recognizale content
					Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);

					//Create Apex Log to record JSON request & response
					ExceptionHandlerController.createIntegrationException(
						'SiebelSync',
						'SiebelSync',
						strApplicationName,
						'Salesforce to Siebel Sync is Successful',
						'',
						System.today(),
						jsonRequest,
						jsonResponse,
						'Success'
					);
				} else {
					//Create Apex Log, incase Success Response result doesnot contain desired value
					ExceptionHandlerController.createIntegrationException(
						'SiebelSync',
						'SiebelSync',
						strApplicationName,
						'Salesforce to Siebel Sync Failed',
						'Received Invalide Response',
						System.today(),
						jsonRequest,
						jsonResponse,
						'Error'
					);
				}
			} else {
				//Create Apex log to record request & error response
				ExceptionHandlerController.createIntegrationException(
					'SiebelSync',
					'SiebelSync',
					strApplicationName,
					'Salesforce to Siebel Sync Failed',
					intRes.response.getStatus(),
					System.today(),
					jsonRequest,
					jsonResponse,
					'Error'
				);
			}
		} else {
			//Create Apex log to record request & error response
			ExceptionHandlerController.createIntegrationException(
				'SiebelSync',
				'SiebelSync',
				strApplicationName,
				'Salesforce to Siebel Sync Failed',
				String.valueOf(intRes),
				System.today(),
				jsonRequest,
				String.valueOf(intRes),
				'Error'
			);
		}
	}

	// Method Name: fetchRecords
	// Author: Basant Kumar Verma
	// Description: Method to fetch sObject records using Dynamic SOQL Query
	// Parameter: String sObjectAPIName - sObject API Name
	// Parameter: Set<Id> setRecordIds - Set of Record Ids to be query
	// Return: List<sObject> - List of sObject to be retured
	public List<sObject> fetchRecords(String sObjectAPIName, Set<Id> setRecordIds) {
		String sSOQL = CommonUtilities.prepareQuery(sObjectAPIName, null, true) + ' WHERE Id IN: setRecordIds';
		return database.query(sSOQL);
	}
}