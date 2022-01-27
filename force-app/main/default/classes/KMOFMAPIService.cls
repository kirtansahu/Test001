/* * * * * * * * * * * * * *
 * Class Name:   KMOFMAPIService
 * Purpose:      Class used to consume OFM web service to get the access token which can then be used in subsequent callouts to get the data.
 * Author:       Hardik Mehta
 * Company:      Keste @ IDC
 * Created Date: 30-June-2020
 * Type:         Class
 * Test Class :  KMOFMAPIServiceTest
 * * * * * * * * * * * * * */
public with sharing class KMOFMAPIService {
	public static KM_OFM_OAuth_Config__c config;

	/* * * * * * * * * * * * * *
	 * Method Name:  callToOFMAPI
	 * Purpose:      Method to check whether access token has expired or not and store in the custom object
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 30-June-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	public static HTTPResponse callToOFMAPI(String reqBody, String methodType, String endPointURL) {
		HTTPResponse objHttpresponse = new HTTPResponse();

		try {
			if (config == null) {
				config = getOAuthConfig();
			}

			//check if the record for OFM OAuth config is already present or not
			if (config != null) {
				//check if current access token is expired or not
				if (System.now() >= config.Expiry_Start_Datetime__c && System.now() <= config.Expiry_End_Datetime__c) {
					//perform the callout to get the data for the source API
					objHttpresponse = makeCallout(config.Access_Token__c, reqBody, methodType, endPointURL);
				} else {
					//make callout to get the new fresh access token
					getAndUpdateAccessToken(config);
					//perform the callout to get the data for the source API
					objHttpresponse = makeCallout(config.Access_Token__c, reqBody, methodType, endPointURL);
					if (config != null) {
						upsertOAuthConfig(JSON.serialize(config));
					}
				}
			} else {
				getAndUpdateAccessToken(null); //call method to get the access token & update in the config object

				objHttpresponse = makeCallout(config.Access_Token__c, reqBody, methodType, endPointURL); // make callout to actual API with new access token

				if (config != null)
					upsertOAuthConfig(JSON.serialize(config)); // upsert the config object with new access token
			}
		} catch (Exception exp) {
			System.debug('error callToOFMAPI ' + exp.getMessage());
			System.debug('stacktrace callToOFMAPI ' + exp.getStackTraceString());
			throw exp;
		}

		return objHttpresponse;
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  getAndUpdateAccessToken
	 * Purpose:      Method to get and update the access token when it expires or a new token is inserted at the start
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 30-June-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	private static void getAndUpdateAccessToken(KM_OFM_OAuth_Config__c objOAuthConfig) {
		//get OFM OAuth config data
		KM_OFM_OAuth_Settings__c accessTokenSettings = KM_OFM_OAuth_Settings__c.getOrgDefaults();

		String OAUTH_ENDPOINT_URL = accessTokenSettings.OAuth_Access_Token_URL__c;
		String CLIEND_ID = accessTokenSettings.Client_ID__c;
		String CLIENT_SECRET = accessTokenSettings.Client_Secret__c;

		String oauthAccessTokenBody =
			'grant_type=client_credentials' +
			'&client_id=' +
			CLIEND_ID +
			'&client_secret=' +
			CLIENT_SECRET;

		HttpResponse objResponse = getAccessToken(OAUTH_ENDPOINT_URL, oauthAccessTokenBody);

		if (objResponse != null && objResponse.getStatusCode() == 200) {
			Map<String, Object> accessTokenResponse = (Map<String, Object>) JSON.deserializeUntyped(
				objResponse.getBody()
			);

			if (objOAuthConfig != null && objOAuthConfig.Id != null) {
				// update the fresh access token to database object
				//update the access token here on the received OAuth config object
				objOAuthConfig.Access_Token__c = String.valueOf(accessTokenResponse.get('access_token'));
				objOAuthConfig.Token_Type__c = String.valueOf(accessTokenResponse.get('token_type'));
				objOAuthConfig.Expiry_Start_Datetime__c = System.now();
				objOAuthConfig.Expiry_End_Datetime__c = System.now()
					.addSeconds(Integer.valueOf(accessTokenResponse.get('expires_in')));
				//config = objOAuthConfig;
			} else {
				// insert the access token in the OFM OAuth Config object
				objOAuthConfig = new KM_OFM_OAuth_Config__c();
				objOAuthConfig.Name = 'OFM OAuth Configuration';
				objOAuthConfig.Access_Token__c = String.valueOf(accessTokenResponse.get('access_token'));
				objOAuthConfig.Token_Type__c = String.valueOf(accessTokenResponse.get('token_type'));
				objOAuthConfig.Expiry_Start_Datetime__c = System.now();
				objOAuthConfig.Expiry_End_Datetime__c = System.now()
					.addSeconds(Integer.valueOf(accessTokenResponse.get('expires_in')));
				config = objOAuthConfig;
			}
		}
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  getAccessToken
	 * Purpose:      Method to process Http Request to get access token
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 30-June-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	public static HttpResponse getAccessToken(String accessTokenURL, String reqBody) {
		HttpResponse objResponse = makeHttpRequest(reqBody, accessTokenURL, 'POST', 'OAuth API', null);
		return objResponse;
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  makeCallout
	 * Purpose:      Method to call Http Request
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 30-June-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	public static HTTPResponse makeCallout(String accessToken, String reqBody, String methodType, String endPointURL) {
		HTTPResponse objHttpresponse = makeHttpRequest(reqBody, endPointURL, methodType, 'OFM API', accessToken);
		return objHttpresponse;
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  makeHttpRequest
	 * Purpose:      Method to process Http Request for the actual call to the API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 30-June-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	private static HttpResponse makeHttpRequest(
		String reqBody,
		String endPointURL,
		String methodType,
		String source,
		String accessToken
	) {
		KM_OFM_OAuth_Settings__c accessTokenSettings = KM_OFM_OAuth_Settings__c.getOrgDefaults();
		Integer TIMEOUT = Integer.valueOf(accessTokenSettings.TimeOut__c);

		Http objHttp = new Http();
		HttpRequest objHttpRequest = new HttpRequest();

		objHttpRequest.setEndpoint(endPointURL); //set the endpoint URL to which request will be made
		objHttpRequest.setMethod(methodType); // set the method type i.e GET,POST,etc.
		objHttpRequest.setTimeout(TIMEOUT); // set the timeout

		if (source == 'OAuth API') {
			objHttpRequest.setHeader('Content-Type', 'application/x-www-form-urlencoded'); // set the header value for OAuth API
		} else if (source == 'OFM API' && String.isNotBlank(accessToken)) {
			objHttpRequest.setHeader('Authorization', 'Bearer ' + accessToken); // set access token to make call to OFM API to get data
			objHttpRequest.setHeader('Content-Type', 'application/json'); // set the content type
		}
		objHttpRequest.setBody(reqBody); // set the request body
		HTTPResponse objHttpresponse = objHttp.send(objHttpRequest); // make actual call to the API
		return objHttpresponse;
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  getOAuthConfig
	 * Purpose:      Method to retrieve & nitialize the oauth config object
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 07-August-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	public static KM_OFM_OAuth_Config__c getOAuthConfig() {
		//query on the config object to get the config record
		List<KM_OFM_OAuth_Config__c> OAuthConfigList = [
			SELECT Id, Access_Token__c, Expiry_Start_Datetime__c, Expiry_End_Datetime__c, Token_Type__c
			FROM KM_OFM_OAuth_Config__c
			LIMIT 1
		];
		//check if the record for OFM OAuth config is already present or not
		if (OAuthConfigList != null && OAuthConfigList.size() > 0) {
			return OAuthConfigList[0];
		} else {
			return null;
		}
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  upsertOAuthConfig
	 * Purpose:      Method to upsert the OAuth config record
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 07-August-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@future
	public static void upsertOAuthConfig(String strOAuthConfig) {
		KM_OFM_OAuth_Config__c objOAuthConfig = new KM_OFM_OAuth_Config__c();

		if (String.isNotBlank(strOAuthConfig)) {
			objOAuthConfig = (KM_OFM_OAuth_Config__c) JSON.deserialize(strOAuthConfig, KM_OFM_OAuth_Config__c.class);
			upsert objOAuthConfig;
		}
	}

	public static void callToOFMToRefreshToken() {
		try {
			if (config == null) {
				config = getOAuthConfig();
			}
			//check if the record for OFM OAuth config is already present or not
			if (config != null) {
				//check if current access token is expired or not
				if (System.now() >= config.Expiry_Start_Datetime__c && System.now() <= config.Expiry_End_Datetime__c) {
					System.debug('Token is Valid');
				} else {
					//make callout to get the new fresh access token
					getAndUpdateAccessToken(config);
					if (config != null) {
						upsertOAuthConfig(JSON.serialize(config));
					}
				}
			} else {
				getAndUpdateAccessToken(null); //call method to get the access token & update in the config object
				if (config != null)
					upsertOAuthConfig(JSON.serialize(config)); // upsert the config object with new access token
			}
		} catch (Exception exp) {
			System.debug('error callToOFMAPI ' + exp.getMessage());
			System.debug('stacktrace callToOFMAPI ' + exp.getStackTraceString());
			throw exp;
		}
	}
}