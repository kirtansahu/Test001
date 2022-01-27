// ===========================================================================
//  Object: ChildDeleteSync
// Company: Keste @IDC
//  Author: Vasavi Poranki/Abinash Panigrahi
// Purpose: Integration Queable class to sync the Contact and Opportunity Child record deletion with Siebel
// ===========================================================================

public class ChildDeleteSync implements Queueable, Database.AllowsCallouts {
	public String strObjectName;
	public List<sObjectRecordWrapper> lstsObjectRecordWrapper;

	public void execute(QueueableContext context) {
		Map<String, String> mapJSONRequestWithEnternalId = new Map<String, String>();
		Map<String, String> mapObjectNameWithEnternalId = new Map<String, String>();

		//Map of Integration Response wrapper
		Map<String, IntegrationResponse> responseMap = new Map<String, IntegrationResponse>();

		for (sObjectRecordWrapper oWrapper : lstsObjectRecordWrapper) {
			String objectName;
			String jsonRequest;
			//Determine Header Object Name
			if (oWrapper.strObjectName == 'ACCOUNTCONTACTRELATION' || oWrapper.strObjectName == 'CONTACT_PROFILE__C') {
				objectName = 'CONTACT';
			}
			if (
				oWrapper.strObjectName == 'OPPORTUNITYTEAMMEMBER' ||
				oWrapper.strObjectName == 'OPPORTUNITYLINEITEM' ||
				oWrapper.strObjectName == 'OPPORTUNITY_PRODUCT_LINE__C'
			) {
				objectName = 'OPPORTUNITY';
			}
			//JSON Request Preparation based on Object
			//Delete Integration Request
			if (oWrapper.strObjectName == 'ACCOUNTCONTACTRELATION') {
				jsonRequest = IntegrationRequestUtilty.getDeleteACRelationJSONRequest(
					oWrapper.strExternalId,
					oWrapper.strRelatedId
				);
			} else if (oWrapper.strObjectName == 'CONTACT_PROFILE__C') {
				jsonRequest = IntegrationRequestUtilty.getDeleteCProfileJSONRequest(
					oWrapper.strExternalId,
					oWrapper.strRelatedName,
					oWrapper.strRelatedId,
					oWrapper.strRelatedType
				);
			} else if (oWrapper.strObjectName == 'OPPORTUNITYTEAMMEMBER') {
				jsonRequest = IntegrationRequestUtilty.getDeleteOpportunityTeamMembersJSONRequest(
					oWrapper.strExternalId,
					oWrapper.strRelatedId,
					oWrapper.strRelatedName
				);
			} else if (oWrapper.strObjectName == 'OPPORTUNITYLINEITEM') {
				jsonRequest = IntegrationRequestUtilty.getDeleteOpportunityProductsJSONRequest(
					oWrapper.strExternalId,
					oWrapper.strRelatedId,
					oWrapper.strRelatedName
				);
			} else if (oWrapper.strObjectName == 'OPPORTUNITY_PRODUCT_LINE__C') {
				jsonRequest = IntegrationRequestUtilty.getDeleteOpportunityLineJSONRequest(
					oWrapper.strExternalId,
					oWrapper.strRelatedId,
					oWrapper.strRelatedName
				);
			}
			mapObjectNameWithEnternalId.put(oWrapper.strExternalId, objectName);
			mapJSONRequestWithEnternalId.put(oWrapper.strExternalId, jsonRequest);
		}

		if (!mapJSONRequestWithEnternalId.IsEmpty()) {
			for (String strExternalId : mapJSONRequestWithEnternalId.keyset()) {
				//Send Outbound Callouts to External System
				IntegrationResponse intgRes = syncRecordWithSiebel(
					mapJSONRequestWithEnternalId.get(strExternalId),
					'DELETE',
					mapObjectNameWithEnternalId.get(strExternalId)
				);
				//Collect All callout results
				responseMap.put(strExternalId, intgRes);
			}
		}

		if (!responseMap.IsEmpty()) {
			for (String externalId : responseMap.keyset()) {
				processIntegrationResponse(
					mapObjectNameWithEnternalId.get(externalId),
					mapJSONRequestWithEnternalId.get(externalId),
					responseMap.get(externalId)
				);
			}
		}
	}

	public static void processIntegrationResponse(
		String strObjectName,
		String jsonRequest,
		IntegrationResponse intRes
	) {
		//Instance to store Error messages
		List<String> errors = new List<String>();
		String strApplicationName = strObjectName + ' - Integration - DELETE';
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
					'ChildDeleteSync',
					'ChildDeleteSync',
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
					'ChildDeleteSync',
					'ChildDeleteSync',
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
				'ChildDeleteSync',
				'ChildDeleteSync',
				strApplicationName,
				'Salesforce to Siebel Sync Failed',
				intRes.response.getStatus(),
				System.today(),
				jsonRequest,
				jsonResponse,
				'Error'
			);
		}
	}

	public IntegrationResponse syncRecordWithSiebel(String jsonRequest, String OperationType, String objectName) {
		IntegrationResponse intRes = null;
		try {
			//Integration Response Handling
			//Http Request & Callout are made to External System
			intRes = IntegrationUtility.SF_Siebel_Sync(jsonRequest, OperationType, objectName, false);
		} catch (Exception ex) {
			//Create Apex Log incase any internal error occured during Integration process
			ExceptionHandlerController.createIntegrationException(
				'ChildDeleteSync',
				'ChildDeleteSync',
				objectName + ' - Integration - DELETE',
				'Salesforce to Siebel Sync Failed',
				'Error Occured during the Sync. ' + ex.getMessage(),
				System.today(),
				jsonRequest,
				ex.getStackTraceString(),
				'Error'
			);
		}
		return intRes;
	}
}