// ===========================================================================
//  Object	: ContactInterfaceIntegration_Schedulde
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Scheduler Class to process all Modified Contacts - Sent callout to Siebel system to keep it in sync
// ===========================================================================
global class ContactInterfaceIntegration_Schedulde implements Schedulable {
	//Scedhuler's Execute Method, which executes when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if ((CommonUtilities.isGoodToExecuteBatch('ContactInterfaceIntegration_Batch')) || Test.isRunningTest()) {
			//Executing the batch
			Database.executebatch(new ContactInterfaceIntegration_Batch(), 100);
		}
	}

	/*******************************************
	@comment : This below script is used to execute this batch job hourly.
	System.schedule('Contact Siebel Sync Batch', '0 0 0/1 1/1 * ? *', new ContactInterfaceIntegration_Schedulde());
	********************************************/

	/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new ContactInterfaceIntegration_Batch(), 100);
	********************************************/
}