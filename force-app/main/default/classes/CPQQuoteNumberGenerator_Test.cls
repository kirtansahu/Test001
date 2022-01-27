@isTest
public class CPQQuoteNumberGenerator_Test {
	static testMethod void unitTest() {
		List<Quote_Number_Generator__c> lstQNG = new List<Quote_Number_Generator__c>();
		lstQNG.add(
			new Quote_Number_Generator__c(Quote_Type__c = 'P;D', Latest_Quote_Number__c = 1, Max_Allowed_Number__c = 5)
		);
		lstQNG.add(
			new Quote_Number_Generator__c(
				Quote_Type__c = 'S;SAMPLE',
				Latest_Quote_Number__c = 6,
				Max_Allowed_Number__c = 10
			)
		);
		lstQNG.add(
			new Quote_Number_Generator__c(
				Quote_Type__c = 'E;F;H;AGREEMENT',
				Latest_Quote_Number__c = 11,
				Max_Allowed_Number__c = 15
			)
		);
		insert lstQNG;

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		req.requestURI = '/services/apexrest/QuoteNumberGenerator/';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf('{ "QuoteType" : "P"  }');

		RestContext.request = req;
		RestContext.response = res;

		test.startTest();
		CPQQuoteNumberGenerator.returnQuoteNumber('P');
		CPQQuoteNumberGenerator.returnQuoteNumber('D');
		CPQQuoteNumberGenerator.returnQuoteNumber('Sample');
		CPQQuoteNumberGenerator.returnQuoteNumber('S');
		CPQQuoteNumberGenerator.returnQuoteNumber('E');
		CPQQuoteNumberGenerator.returnQuoteNumber('F');
		CPQQuoteNumberGenerator.returnQuoteNumber('H');
		CPQQuoteNumberGenerator.returnQuoteNumber('AGREEMENT');
		CPQQuoteNumberGenerator.returnQuoteNumber('E');
		CPQQuoteNumberGenerator.returnQuoteNumber('');
		CPQQuoteNumberGenerator.returnQuoteNumber('A');
		CPQQuoteNumberGenerator.returnQuoteNumber('Z');
		CPQQuoteNumberGenerator.returnQuoteNumber(null);

		for (Quote_Number_Generator__c qng : [
			SELECT Id, Latest_Quote_Number__c, Max_Allowed_Number__c, Quote_Type__c
			FROM Quote_Number_Generator__c
		]) {
			if (qng.Quote_Type__c.equals('P;D')) {
				System.assert(qng.Latest_Quote_Number__c >= 3);
			} else if (qng.Quote_Type__c.equals('S;SAMPLE')) {
				System.assert(qng.Latest_Quote_Number__c >= 7);
			} else if (qng.Quote_Type__c.equals('E;F;H;AGREEMENT')) {
				System.assert(qng.Latest_Quote_Number__c >= 9);
			}
		}

		insert new Quote_Number_Generator__c(
			Quote_Type__c = 'P',
			Latest_Quote_Number__c = 21,
			Max_Allowed_Number__c = 30
		);
		CPQQuoteNumberGenerator.returnQuoteNumber('P');
		test.stopTest();
	}
}