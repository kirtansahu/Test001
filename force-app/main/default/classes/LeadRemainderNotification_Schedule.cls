// ===========================================================================
//	Class	: LeadRemainderNotification_Schedule
//  Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
//  Purpose	: Scheduler Class to schedule and execute the LeadRemainderNotification_Batch
// ===========================================================================
global class LeadRemainderNotification_Schedule implements Schedulable {
	//Execute method whcih will get executed when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if (CommonUtilities.isGoodToExecuteBatch('LeadRemainderNotification_Batch') || Test.isRunningTest()) {
			Database.executebatch(new LeadRemainderNotification_Batch());
		}
	}

	/*******************************************
	@comment : This below script is used to execute this batch job hourly.
	System.schedule('Lead Remainder Notification', '0 0 8 1/1 * ? *', new LeadRemainderNotification_Schedule());
	********************************************/

	/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new LeadRemainderNotification_Batch());
	********************************************/
}