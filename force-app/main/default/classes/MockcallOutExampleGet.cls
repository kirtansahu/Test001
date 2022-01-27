/********************************************************************************
 * Object   : MockcallOutExampleGet
 * Company  : Keste @IDC
 * Author   : Abinash Panigrahi
 * Purpose  : HTTP Callout Mock Class for Test Class
 ********************************************************************************/
@isTest
global class MockcallOutExampleGet implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest hreq) {
		HTTPResponse htr = new HTTPResponse();
		htr.setBody('');
		htr.setStatusCode(401);
		htr.setHeader('Content-Type', 'application/json');
		return htr;
	}
}