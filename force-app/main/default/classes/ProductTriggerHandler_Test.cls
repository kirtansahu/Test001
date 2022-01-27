//===========================================================================
//  Object  :   ProductTriggerHandler_Test
//  Company :   Keste @IDC
//  Author  :   Jataram B
//  Purpose :   Unit Test Class for ProductTrigger and ProductTriggerHandler.
//===========================================================================
@isTest
private class ProductTriggerHandler_Test {
	// Method Name: testSetupMethod
	// Author: Abinash panigrahi
	// Description: Method to create Test Data to be used
	@isTest
	public static void testSetupMethod() {
		List<Product2> lstProduct = new List<Product2>();
		Product2 oProduct;
		oProduct = new Product2();
		oProduct.Name = 'Test';
		oProduct.Unique_Id__c = 'test1';
		lstProduct.add(oProduct);
		oProduct = new Product2();
		oProduct.Name = 'Test New';
		oProduct.Unique_Id__c = 'test2';
		lstProduct.add(oProduct);
		insert lstProduct;
		lstProduct[0].Name = 'New Test';
		update lstProduct;
	}
}