// ===========================================================================
//  Class Name 	: IntegrationResponse
// 	Company  	: Keste @ IDC
//  Author		: Vasavi Poranki/Abinash Panigrahi
// 	Purpose		: Integration Util class to hold the Parameters from response
// ===========================================================================
public class IntegrationResponse {
	public List<Object> Errors { get; set; }
	public Boolean IsSuccess { get; set; }
	public Boolean IsLargeResponse { get; set; }
	public String recordId { get; set; }
	public String requestHeader { get; set; }
	public HttpResponse response { get; set; }
	public HttpRequest request { get; set; }
	public Exception ex { get; set; }
}