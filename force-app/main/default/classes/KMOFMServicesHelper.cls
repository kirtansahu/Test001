// ===========================================================================
//  Class Name  : KMOFMServicesHelper
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     : Getting Service Endpoints from custom metadata types.
// ===========================================================================
public without sharing class KMOFMServicesHelper {
	// Method Name: getServiceEndpoint
	// Author: Sreenivas
	// Description: Methdo to get endpoint data from custom metadata types
	// Parameter : String serviceName - Request service name.
	public static string getServiceEndpoint(string serviceName) {
		String serviceURL = '';
		KM_OFM_Services__mdt OFMServiseConfig = [
			SELECT DeveloperName, Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = :serviceName
			LIMIT 1
		];
		if (OFMServiseConfig != null) {
			serviceURL = OFMServiseConfig.Endpoint__c;
		}
		return serviceURL;
	}
}