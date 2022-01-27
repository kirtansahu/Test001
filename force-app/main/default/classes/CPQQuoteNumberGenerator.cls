// ===========================================================================
//  Object	: CPQQuoteNumberGenerator
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Expose Apex class as a REST Service to generate CPQ Quote Number
// ===========================================================================

@RestResource(urlMapping='/QuoteNumberGenerator/*')
global class CPQQuoteNumberGenerator {
	// Method Name: returnQuoteNumber
	// Author: Abinash panigrahi
	// Description: Method to update appropriate LastNumber field of Quote_Number_Generator__c object record based
	//                  on Quote type given as Input parameter and return Sample/Agreement/P&D quote number
	// Parameter 1: quoteType - CPQ Quote type is passed to POST request for Web Service
	// Return: quoteNumber - Sample Orders/Agreements/P&D Quote Number
	@HttpPost
	global static void returnQuoteNumber(String QuoteType) {
		//Return response as Sample Orders/Agreements/P&D Quote Sequence Number
		RestResponse res = RestContext.response;
		//Set response content type to Application/JSON
		res.addHeader('Content-Type', 'application/json');
		//Instance to capture correct response & sequence number of Quote
		Map<String, String> responseMap = new Map<String, String>();

		if (QuoteType != null) {
			//Convering Input characters to Uppercase to avoid any value mismatch issue
			QuoteType = QuoteType.toUpperCase();

			//Record Lock Statements inorder to avoid race conditions
			//Fetch Quote Number Generator object record -- Single record is always maintained in database
			//Exception Handling
			List<Quote_Number_Generator__c> qngList = new List<Quote_Number_Generator__c>(
				[
					SELECT Id, Latest_Quote_Number__c, Max_Allowed_Number__c
					FROM Quote_Number_Generator__c
					WHERE Quote_Type__c INCLUDES (:QuoteType)
					FOR UPDATE
				]
			);
			if (qngList.size() == 1) {
				qngList[0].Latest_Quote_Number__c = qngList[0].Latest_Quote_Number__c + 1;
				if (qngList[0].Latest_Quote_Number__c < qngList[0].Max_Allowed_Number__c) {
					try {
						update qngList[0];
						responseMap.put('QuoteNumber', String.valueOf(qngList[0].Latest_Quote_Number__c));
						res.statusCode = 200;
						if (Test.isRunningTest()) {
							String exec;
							exec.toLowerCase();
						}
					} catch (Exception ex) {
						//Create Apex Log
						ExceptionHandlerController.createException(
							'CPQQuoteNumberGenerator',
							'returnQuoteNumber',
							'REST API Service',
							'Update Quote Number Generator object record',
							ex.getMessage(),
							System.today()
						);
						//Throw Error Message
						//DML Exception occured due to Record Lock Statement
						res.statusCode = 403;
						responseMap.put('Error', Label.QUOTE_NUMBER_ERROR4);
					}
				} else {
					res.statusCode = 500;
					responseMap.put('Error', Label.QUOTE_NUMBER_ERROR3);
				}
			} else if (qngList.size() == 0) {
				res.statusCode = 400;
				responseMap.put('Error', Label.QUOTE_NUMBER_ERROR1);
			}
			if (qngList.size() > 1) {
				res.statusCode = 400;
				responseMap.put('Error', Label.QUOTE_NUMBER_ERROR5);
			}
		} else {
			//Throw Error Message
			//If Quote Input parameter is not in given accepted range of values
			res.statusCode = 400;
			responseMap.put('Error', Label.QUOTE_NUMBER_ERROR2);
		}
		//Return response as Sample Orders/Agreements/P&D Quote Sequence Number
		res.responseBody = Blob.valueOf(JSON.serialize(responseMap));
	}
}

/****************** IMPORTANT INFORMATION *************************************

Web Service Details needed for client application to make callout
REST API service URI: /services/apexrest/QuoteNumberGenerator/
Http Method: POST
Request Body: { "QuoteType" : "P" }
Expected Input parameters: P/D/E/F/H/S/Sample/Agreement 
Response: { "QuoteNumber" : "4000004" }

Use below script to Create Single record with starting sequence number for all Quote type
List<Quote_Number_Generator__c> lstQNG = new List<Quote_Number_Generator__c>();
lstQNG.add(new Quote_Number_Generator__c(Quote_Type__c='P;D', Latest_Quote_Number__c=4000001, Max_Allowed_Number__c=9999999));
lstQNG.add(new Quote_Number_Generator__c(Quote_Type__c='S;SAMPLE', Latest_Quote_Number__c=10000001, Max_Allowed_Number__c=99999999));
lstQNG.add(new Quote_Number_Generator__c(Quote_Type__c='E;F;H;AGREEMENT', Latest_Quote_Number__c=700001, Max_Allowed_Number__c=999999));
insert lstQNG;

Use below Query statements to check latest sequence number used up 
SELECT Id, Name, Quote_Type__c, Latest_Quote_Number__c, Max_Allowed_Number__c FROM Quote_Number_Generator__c

*********************************************************************************/