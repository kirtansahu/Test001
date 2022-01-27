// ===========================================================================
//  Class Name 	: 	IntegrationUtility
// 	Company  	: 	Keste @IDC
//  Author		: 	Abinash Panigrahi
// 	Purpose		: 	Integration Util class to send the request to external system (this is common class to send the requests)
// 	Test Class	:
// ===========================================================================
// Changes		:	Basant Kumar Verma @ 07/19/2019 : Added use of isMockResponseSetupped
// ===========================================================================
public class IntegrationUtility {
	//Extra variable to help test class in code coverage
	@TestVisible
	private static Boolean isMockResponseSetupped = false;

	// Method Name: SF_Siebel_Sync
	// Description: generic Method to send sync request to Sieble
	// Parameter 1: String req - JSON Request Body
	// Parameter 2: String operationType - Operation type, such as INSERT, UPDATE, DELETE
	// Parameter 2: String objectName - sObject API name for which the Callout is happening, such as CONTACT, OPPORTUNITY
	// Return: IntegrationResponse - Integration Response Warpper class
	public static IntegrationResponse SF_Siebel_Sync(
		String req,
		String operationType,
		String objectName,
		Boolean bulkJob
	) {
		//Integration Wrapper Class Instance
		IntegrationResponse intgRes = new IntegrationResponse();

		//OFM End Point
		String endpointURL;
		if (objectName == 'CONTACT') {
			if (bulkJob) {
				endpointURL = Label.Siebel_ENDPOINT;
			} else {
				endpointURL = Label.Siebel_ENDPOINT_NEW;
			}
		}
		if (objectName == 'OPPORTUNITY') {
			endpointURL = Label.Siebel_Opportunity_Endpoint;
		}
		System.debug('endpointURL --> ' + endpointURL);

		String contentType = 'application/json'; //;charset=UTF-8

		//Prepare Integration Request Header part
		Http http = new Http();
		HttpRequest request = new HttpRequest();

		/* --NAMED CREDENTIALS USED--
        //Credentials for Authentication
        String username = Label.Siebel_UserName;
        String password = Label.Siebel_Password;

        //To Set the integration header for all the integration related requests.
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader); */

		//Set required parameters to HTTP request
		if (operationType == 'INSERT' || operationType == 'UPDATE' || operationType == 'DELETE') {
			request.setMethod('POST');
		}

		request.setHeader('Content-Type', contentType);
		request.setBody(req);
		request.setTimeout(120000);
		request.setEndpoint(endpointURL);
		intgRes.request = request;

		//Mock Response created to be used in Test Execution
		if (!Test.isRunningTest() || isMockResponseSetupped) {
			intgRes.response = http.send(request);
		} else {
			HttpResponse res = new HttpResponse();
			res.setBody('{"siebelId": ' + Math.random() + '}'); //Insert Mock resposne
			res.setStatusCode(200);
			intgRes.response = res;
		}

		//Debug Logs
		System.debug('intgRes.response --> ' + intgRes.response);
		System.debug('intgRes.response --> ' + intgRes.response.getStatus());
		System.debug('intgRes.response --> ' + intgRes.response.getBody());
		System.debug('intgRes.response --> ' + intgRes.response.getStatusCode());
		System.debug('intgRes.response --> ' + intgRes.response.toString());

		//Return JSON Response recieved from OFM
		return intgRes;
	}

	// Method Name: SynctoSiebel
	// Author: Basant Kumar Verma
	// Description: Method to make Asynchronous Multiple Callout for Siebel Sync
	// Parameter 1: String parentObjectAPIName - Parent/Header level Object API Name
	// Parameter 2: Set<Id> setOfRecordIds - Set of record ids to be sysnced
	// parameter 3: String OperationType - Sync Operation Type
	// Parameter 4: relatedOperationType - Child Object Operation Performed
	// Parameter 5: String objectName - actual Object name on which the integration is fired
	// Return: Null
	public static void SynctoSiebel(
		String parentObjectAPIName,
		Set<Id> setOfRecordIds,
		String OperationType,
		String relatedOperationType,
		String objectName
	) {
		if (setOfRecordIds.size() > 0) {
			List<Set<Id>> listOfIdSets = new List<Set<Id>>();
			Set<Id> tempSetOfIds = new Set<Id>();
			for (Id recordId : setOfRecordIds) {
				if (tempSetOfIds.size() == 0) {
					listOfIdSets.add(tempSetOfIds);
				}
				tempSetOfIds.add(recordId);
				if (tempSetOfIds.size() == 10) {
					tempSetOfIds = new Set<Id>();
				}
			}

			for (Set<Id> recordIdSet : listOfIdSets) {
				//Call Queable Class for Single record processing
				//Pass Object & DML Operation tag
				SiebelSync oSiebelSync = new SiebelSync();
				oSiebelSync.parentObjectAPIName = parentObjectAPIName;
				oSiebelSync.setRecordIds = recordIdSet;
				oSiebelSync.OperationType = OperationType;
				oSiebelSync.relatedOperationType = relatedOperationType;
				oSiebelSync.objectName = objectName;
				//Asynchronous Callout
				System.enqueueJob(oSiebelSync);
			}
		}
	}

	// Method Name: SynctoSiebel
	// Author: Basant Kumar Verma
	// Description: Method to make Asynchronous Multiple Callout for Siebel Sync
	// Parameter 1: String parentObjectAPIName - Parent/Header level Object API Name
	// Parameter 2: Set<Id> setOfRecordIds - Set of record ids to be sysnced
	// parameter 3: String OperationType - Sync Operation Type
	// Parameter 4: relatedOperationType - Child Object Operation Performed
	// Parameter 5: String objectName - actual Object name on which the integration is fired
	// Return: Null
	public static void SynctoSiebelNew(
		String parentObjectAPIName,
		Set<Id> setOfRecordIds,
		String OperationType,
		String relatedOperationType,
		String objectName,
		Boolean bulkjob
	) {
		if (setOfRecordIds.size() > 0) {
			List<Set<Id>> listOfIdSets = new List<Set<Id>>();
			Set<Id> tempSetOfIds = new Set<Id>();
			for (Id recordId : setOfRecordIds) {
				if (tempSetOfIds.size() == 0) {
					listOfIdSets.add(tempSetOfIds);
				}
				tempSetOfIds.add(recordId);
				if (tempSetOfIds.size() == 10) {
					tempSetOfIds = new Set<Id>();
				}
			}

			for (Set<Id> recordIdSet : listOfIdSets) {
				//Call Queable Class for Single record processing
				//Pass Object & DML Operation tag
				SiebelSync oSiebelSync = new SiebelSync();
				oSiebelSync.parentObjectAPIName = parentObjectAPIName;
				oSiebelSync.setRecordIds = recordIdSet;
				oSiebelSync.OperationType = OperationType;
				oSiebelSync.relatedOperationType = relatedOperationType;
				oSiebelSync.objectName = objectName;
				oSiebelSync.bulkJob = bulkJob;
				//Asynchronous Callout
				System.enqueueJob(oSiebelSync);
			}
		}
	}

	// Method Name: syncDeleteRecordWithSiebel
	// Author: Abinash panigrahi
	// Description: Method to make Asynchronous Multiple Callout for Siebel Sync
	// Parameter 1: lstsObjectRecordWrapper - Set of the Child Object Wrapper Class
	// Parameter 2: objName - Child Object Name
	// Return: Null
	public static void syncDeleteRecordWithSiebel(List<sObjectRecordWrapper> lstsObjectRecordWrapper, String objName) {
		List<List<sObjectRecordWrapper>> listOfListofWrapper = new List<List<sObjectRecordWrapper>>();
		List<sObjectRecordWrapper> tempListOfWrapper = new List<sObjectRecordWrapper>();
		for (sObjectRecordWrapper wr : lstsObjectRecordWrapper) {
			if (tempListOfWrapper.size() == 0) {
				listOfListofWrapper.add(tempListOfWrapper);
			}
			tempListOfWrapper.add(wr);
			if (tempListOfWrapper.size() == 10) {
				tempListOfWrapper = new List<sObjectRecordWrapper>();
			}
		}

		for (List<sObjectRecordWrapper> wrapperList : listOfListofWrapper) {
			ChildDeleteSync oChildDeleteSync = new ChildDeleteSync();
			oChildDeleteSync.lstsObjectRecordWrapper = wrapperList;
			oChildDeleteSync.strObjectName = objName;
			System.enqueueJob(oChildDeleteSync);
		}
	}
}