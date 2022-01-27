// ===========================================================================
//  Object: ExceptionHandlerController
//  Company: Keste LLC
//  Author: Keste - IDC
//  Purpose: Handler class used for exception handling to log into Apex_Log object.
// ===========================================================================

public class ExceptionHandlerController {
	// Method Name: createException
	// Author: Abinash panigrahi
	// Description: Method to track all Exception with details, if occured
	// Parameter 1: clsName - Name of Main Class
	// Parameter 2: methodName - Name of function in which error occured
	// Parameter 3: ClsType - Functionality of Main Class
	// Parameter 4: comments - Action trying to execute
	// Parameter 5: exc - Exception Object
	// Parameter 6: Fixdte - Date/Time at which Error occured
	// Return: Null
	public static void createException(
		String clsName,
		String methodName,
		String ClsType,
		String comments,
		String strException,
		Datetime Fixdte
	) {
		if (DynamicCodeExecution.allowExecution('ExceptionHandlerController.createException')) {
			createIntegrationException(clsName, methodName, ClsType, comments, strException, Fixdte, null, null, null);
		}
	}

	// Method Name: createException
	// Author: Abinash panigrahi
	// Description: Method to track all Exception with details, if occured
	// Parameter 1: clsName - Name of Main Class
	// Parameter 2: methodName - Name of function in which error occured
	// Parameter 3: ClsType - Functionality of Main Class
	// Parameter 4: comments - Action trying to execute
	// Parameter 5: exc - Exception Object
	// Parameter 6: Fixdte - Date/Time at which Error occured
	// Parameter 7: jsonRequest - JSON Interation Request
	// Parameter 8: jsonResponse - JSON Integration Response
	// Parameter 9: status - Integration Status
	// Return: Null
	public static void createIntegrationException(
		String clsName,
		String methodName,
		String ClsType,
		String comments,
		String strException,
		Datetime Fixdte,
		String jsonRequest,
		String jsonResponse,
		String status
	) {
		if (DynamicCodeExecution.allowExecution('ExceptionHandlerController.createException')) {
			Map<String, String> textMap = handleShortandLongTextLength(
				strException,
				comments,
				'Complete Error Message'
			);
			strException = textMap.get('shortText');
			comments = textMap.get('longText');

			textMap = handleShortandLongTextLength(ClsType, comments, 'Complete Application Name');
			ClsType = textMap.get('shortText');
			comments = textMap.get('longText');

			textMap = handleShortandLongTextLength(clsName, comments, 'Complete Location');
			clsName = textMap.get('shortText');
			comments = textMap.get('longText');

			textMap = handleShortandLongTextLength(methodName, comments, 'Complete Method Name');
			methodName = textMap.get('shortText');
			comments = textMap.get('longText');

			comments = handleLongTextLength(comments);
			jsonRequest = handleLongTextLength(jsonRequest);
			jsonResponse = handleLongTextLength(jsonResponse);

			String ofmInstanceId;
			if (
				jsonResponse != null &&
				(jsonResponse.contains('OFMInstanceId') || jsonResponse.contains('TransactionId'))
			) {
				JSONParser parser = JSON.createParser(jsonResponse);

				while (parser.nextToken() != null) {
					if (
						(parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
						((parser.getText() == 'OFMInstanceId') || (parser.getText() == 'TransactionId'))
					) {
						parser.nextToken();
						//Fetch Transaction Id key-value pair
						ofmInstanceId = parser.getText();
					}
				}
			}

			Apex_Log__c e = new Apex_Log__c();
			if (ofmInstanceId != null)
				e.Error_Message__c = ofmInstanceId;
			else
				e.Error_Message__c = strException;
			e.Method_name__c = methodName;
			e.Location__c = clsName;
			e.Application_Name__c = ClsType;
			e.Log_Comments__c = comments;
			e.Fixed_Date__c = Fixdte;
			e.Integration_User__c = userInfo.getUserId();
			e.Integration_Request__c = jsonRequest;
			e.Integration_Response__c = jsonResponse;
			e.Integration_Status__c = status;
			insert e;
		}
	}

	// Method Name: handleShortandLongTextLength
	// Author: Basant Kumar Verma
	// Description: Method to handle the Short text field and append it to long text area fields if shot text field is more thne 255 char
	// Parameter 1: shortText - Short Text String
	// Parameter 2: longText - Long Text String
	// Parameter 3: shortTextTitle - Title to be added before the short text detaild
	// Return: Map<String, String> - Map of updated short and long text fields
	private static Map<String, String> handleShortandLongTextLength(
		String shortText,
		String longText,
		String shortTextTitle
	) {
		Map<String, String> textMap = new Map<String, String>();

		if (!String.isEmpty(shortText) && !String.isBlank(shortText) && shortText.length() > 255) {
			if (String.isEmpty(longText) || String.isBlank(longText) || longText.length() <= 255) {
				String tempStr = shortText;
				shortText = longText;
				longText = tempStr;
			} else {
				longText += '\n\n' + shortTextTitle + ': \n' + shortText;
				shortText = shortText.substring(0, 255);
			}
		}

		textMap.put('shortText', shortText);
		textMap.put('longText', longText);
		return textMap;
	}

	// Method Name: handleLongTextLength
	// Author: Basant Kumar Verma
	// Description: Method to handle the long text area fields to not go beyond 32768 char
	// Parameter 1: longText - Long Text String
	// Return: String - Truncated Long Text String
	private static String handleLongTextLength(String longText) {
		if (!String.isEmpty(longText) && !String.isBlank(longText) && longText.length() > 32768) {
			longText = longText.substring(0, 32768);
		}
		return longText;
	}
}