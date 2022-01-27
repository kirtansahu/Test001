// ===========================================================================
//  Class Name  : KMAccountReceivableService
//  Company     : Keste @IDC
//  Author      : Rambabu Gadde
//  Purpose     : Korean Mobility Account Receivable Tab Functionality
//  Test Class  : KMAccountReceivable_Test
// ===========================================================================

public without sharing class KMAccountReceivableService {
	public class ResponseARDetail {
		@auraEnabled
		public String orderType;
		@auraEnabled
		public integer orderNumber;
		@auraEnabled
		public String invoiceCompany;
		@auraEnabled
		public String orderStatus;
		@auraEnabled
		public String openAmount {
			get {
				if (this.openAmount != '0') {
					decimal outputvalues = decimal.valueOf(this.openAmount);
					Integer val = outputvalues.intValue();
					this.openAmount = 'KRW ' + String.valueOf(val.format());
					return this.openAmount;
				}
				return this.openAmount;
			}
			set;
		}
		@auraEnabled
		public String invoicedAmount {
			get {
				if (this.invoicedAmount != '0') {
					decimal outputvalues = decimal.valueOf(this.invoicedAmount);
					Integer val = outputvalues.intValue();
					this.invoicedAmount = 'KRW ' + String.valueOf(val.format());
					return this.invoicedAmount;
				}
				return this.invoicedAmount;
			}
			set;
		}
		@auraEnabled
		public String invoiceType;
		@auraEnabled
		public integer invoiceNumber;
		@auraEnabled
		public String customerPONumber;
		@auraEnabled
		public String invoiceDate;
		@auraEnabled
		public String daysOutstanding;
		//public String currency;
	}

	public class ResponseARHeader {
		@auraEnabled
		public String amountDue {
			get {
				if (this.amountDue != '0') {
					decimal outputvalues = decimal.valueOf(this.amountDue);
					Integer val = outputvalues.intValue();
					this.amountDue = this.currencyCode + ' ' + String.valueOf(val.format());
					return this.amountDue;
				}
				return this.amountDue;
			}
			set;
		}

		@auraEnabled
		public String openOrderAmount {
			get {
				if (this.openOrderAmount != '0') {
					decimal outputvalues = decimal.valueOf(this.openOrderAmount);
					Integer val = outputvalues.intValue();
					this.openOrderAmount = this.currencyCode + ' ' + String.valueOf(val.format());
					return this.openOrderAmount;
				}
				return this.openOrderAmount;
			}
			set;
		}
		@auraEnabled
		public String totalExposure {
			get {
				if (this.totalExposure != '0') {
					decimal outputvalues = decimal.valueOf(this.totalExposure);
					Integer val = outputvalues.intValue();
					this.totalExposure = this.currencyCode + ' ' + String.valueOf(val.format());
					return this.totalExposure;
				}
				return this.totalExposure;
			}
			set;
		}
		@auraEnabled
		public String creditLimit {
			get {
				if (this.creditLimit != '0') {
					decimal outputvalues = decimal.valueOf(this.creditLimit);
					Integer val = outputvalues.intValue();
					this.creditLimit = this.currencyCode + ' ' + String.valueOf(val.format());
					return this.creditLimit;
				}
				return this.creditLimit;
			}
			set;
		}
		@auraEnabled
		public String currencyCode;
	}

	public class ResponseHeader {
		public String responseStatusCode;
		public String responseStatus;
		public String responseStatusMsg;
	}
	@auraEnabled
	public ResponseARHeader responseARHeader;
	@auraEnabled
	public List<ResponseARDetail> responseARDetail;
	@auraEnabled
	public ResponseHeader responseHeader;

	// Method Name: parse
	// Author: Rambabu Gadde
	// Description: Methdo use to get AccountReceivable Header Data
	// Parameter 1: json.
	//Old CMDTs modified with new CMDTs

	public static KMAccountReceivableService parse(String json) {
		return (KMAccountReceivableService) System.JSON.deserialize(json, KMAccountReceivableService.class);
	}

	public static KMAccountReceivableService getOFMResponse(String shipTo) {
		KMAccountReceivableService results = new KMAccountReceivableService();
		String reqBody = '';
		HttpResponse response;
		try {
			reqBody = '{';
			if (shipTo != '') {
				reqBody += '"shipToNum" : "';
				reqBody += shipTo != '' ? (shipTo + '"') : null;
			}
			reqBody += '}';
			String ARHeaderEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_ARHeader');
			response = getResponse(reqBody, ARHeaderEndpoint);
			if (response.getStatusCode() == 200) {
				results = parse(response.getBody());
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivableService',
					'getOFMResponse',
					'KMAccountReceivable',
					'KM_OFM_ARHeader',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivableService',
					'getOFMResponse',
					'KMAccountReceivable',
					'KM_OFM_ARHeader',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
				throw new KMOFMCalloutException(response.getStatus());
			}
		} catch (Exception ex) {
			String errorMessage;
			if (ex.getTypeName() == 'KMOFMCalloutException') {
				errorMessage = ex.getMessage();
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivableService',
					'getOFMResponse',
					'KMAccountReceivable',
					'KM_OFM_ARHeader',
					'Error Occured while quering details. ' + ex.getMessage(),
					System.today(),
					reqBody,
					'',
					''
				);
				errorMessage = System.Label.KM_General_Error_Message;
			}
			throw new KMOFMCalloutException(errorMessage);
		}
		return results;
	}

	/* * * * * * * * * * * * * *
	 * Method Name: getResponse
	 * Purpose: Old endpoints modified with New Urls
	 * Author: Hardik Mehta
	 * Company: Keste
	 * Created Date: 30-June-2020
	 * Type: Method
	 * * * * * * * * * * * * * */
	public static HttpResponse getResponse(String reqBody, String endPointUrl) {
		HttpResponse objResponse = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		return objResponse;
	}
}