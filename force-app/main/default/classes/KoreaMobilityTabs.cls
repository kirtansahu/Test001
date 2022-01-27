// ===========================================================================
//  Class Name  : KoreaMobilityTabs
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     : Korean Mobility Product Tab Functionality
//  Test Class  :
// ===========================================================================
public without sharing class KoreaMobilityTabs {
	// Method Name: getCartData
	// Author: Sreenivas
	// Description: Method use to get All Product records Based on input Parameter.
	// Parameter 1: String recordName
	@AuraEnabled
	public static Map<string, object> getCartData() {
		Map<string, object> cartDataMap = new Map<string, object>();
		string userId = UserInfo.getUserId();
		String recordName = 'CartStoredData_' + userId;
		if (string.isNotBlank(recordName)) {
			KMOrderDetails__c ordDetailsRecord = new KMOrderDetails__c();
			try {
				ordDetailsRecord = [
					SELECT Id, Name, Products__c, OrderDetail__c, UserId__c
					FROM KMOrderDetails__c
					WHERE Name = :recordName AND UserId__c = :userId
					LIMIT 1
				];
			} catch (exception ex) {
				String exceptionMsg =
					'An Exception Occured ' +
					ex +
					' at line number ' +
					ex.getLineNumber() +
					'\n \nMore information on Error: \n' +
					ex.getStackTraceString();
			}
			List<Object> prodList = new List<Object>();
			Map<String, Object> orderDetailObj = new Map<String, Object>();
			if (ordDetailsRecord != null) {
				if (String.isNotBlank(ordDetailsRecord.Products__c)) {
					prodList = (List<Object>) JSON.deserializeUntyped(ordDetailsRecord.Products__c);
				}
				if (String.isNotBlank(ordDetailsRecord.OrderDetail__c)) {
					orderDetailObj = (Map<String, Object>) JSON.deserializeUntyped(ordDetailsRecord.OrderDetail__c);
				}
			}
			cartDataMap.put('productList', prodList);
			cartDataMap.put('orderDetails', orderDetailObj);
		}
		return cartDataMap;
	}

	// Method Name: saveCartData
	// Author: Sreenivas
	// Description: Method use to get All Product records Based on input Parameter.
	// Parameter 1: String recordName
	@AuraEnabled
	public static Boolean saveCartData(string productData, String orderDetails) {
		Boolean success = false;
		string userId = UserInfo.getUserId();
		String recordName = 'CartStoredData_' + userId;
		if (string.isNotBlank(recordName)) {
			KMOrderDetails__c ordDetailsRecord;
			try {
				ordDetailsRecord = [
					SELECT Id, Name, Products__c, OrderDetail__c, UserId__c
					FROM KMOrderDetails__c
					WHERE Name = :recordName AND UserId__c = :userId
					LIMIT 1
				];
			} catch (exception ex) {
				String exceptionMsg =
					'An Exception Occured ' +
					ex +
					' at line number ' +
					ex.getLineNumber() +
					'\n \nMore information on Error: \n' +
					ex.getStackTraceString();
			}
			List<Object> prodList = new List<Object>();
			Map<String, Object> orderDetailObj = new Map<String, Object>();
			if (ordDetailsRecord == null) {
				ordDetailsRecord = new KMOrderDetails__c();
				ordDetailsRecord.Name = recordName;
			}
			ordDetailsRecord.Products__c = productData;
			ordDetailsRecord.OrderDetail__c = orderDetails;
			ordDetailsRecord.UserId__c = userId;
			try {
				if (
					KMOrderDetails__c.sObjectType.getDescribe().isCreateable() &&
					KMOrderDetails__c.sObjectType.getDescribe().isUpdateable()
				) {
					upsert ordDetailsRecord;
					success = true;
				}
			} catch (exception ex) {
				String exceptionMsg =
					'An Exception Occured ' +
					ex +
					' at line number ' +
					ex.getLineNumber() +
					'\n \nMore information on Error: \n' +
					ex.getStackTraceString();
				success = false;
			}
		}
		return success;
	}
}