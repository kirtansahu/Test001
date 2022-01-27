// ===========================================================================
//  Object	: MockHTTPResponse
// 	Company	: Keste @IDC
//  Author	: Basant Kumar Verma
// 	Purpose	: Mock response class for Success Scenario
// ===========================================================================
@isTest
global class MockHTTPResponse implements HttpCalloutMock {
	global String responseBody;
	global Integer statusCode;

	global MockHTTPResponse(Integer statusCode, String responseBody) {
		this.statusCode = statusCode;
		this.responseBody = responseBody;
	}

	// Implement this interface method
	global HTTPResponse respond(HTTPRequest req) {
		// Create a fake response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
		if (responseBody != null) {
			res.setBody(responseBody);
		}
		res.setStatusCode(statusCode);
		return res;
	}
}