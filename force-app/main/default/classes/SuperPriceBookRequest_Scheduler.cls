// ===========================================================================
//  Object	: SuperPriceBookRequest_Scheduler
// 	Company	: Keste @ IDC
//  Author	: Basant Verma
// 	Purpose	: Scheduler Class for Batch SuperPriceBookRequest_Batch Which Create/Updates
// 				the Super Price Book to have corresponding PriceBookEntry records
// ===========================================================================
global class SuperPriceBookRequest_Scheduler implements Schedulable {
	//Scedhuler's Execute Method, which executes when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if (
			(CommonUtilities.isGoodToExecuteBatch('UpdatePriceBookEntry_Batch') &&
			CommonUtilities.isGoodToExecuteBatch('SuperPriceBookRequest_Batch')) || Test.isRunningTest()
		) {
			SuperPriceBookRequest_Batch.checkRequestedRecordsAndExecute();
		}
	}

	/*******************************************
	@comment : This below script is used to execute this batch job hourly.
	System.schedule('SuperPriceBookRequestJob', '0 20 0/1 1/1 * ? *', new SuperPriceBookRequest_Scheduler());
	********************************************/

	/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	SuperPriceBookRequest_Batch.checkRequestedRecordsAndExecute();
	********************************************/
}