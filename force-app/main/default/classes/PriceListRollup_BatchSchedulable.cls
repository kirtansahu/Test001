// ===========================================================================
//	Class	: PriceListRollup_BatchSchedulable
//  Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
//  Purpose	: Scheduler Class to schedule and execute the PriceListRollup_Batch
// ===========================================================================
global class PriceListRollup_BatchSchedulable implements Schedulable {
	//Execute method whcih will get executed when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if (
			(CommonUtilities.isGoodToExecuteBatch('PriceListRollup_Batch') &&
			CommonUtilities.isGoodToExecuteBatch('ParentalSetupAccountTeamCascade_Batch') &&
			CommonUtilities.isGoodToExecuteBatch('RetriggerAccountTeam_Batch')) || Test.isRunningTest()
		) {
			Database.executebatch(new PriceListRollup_Batch());
		}
	}

	/*******************************************
	@comment : This below script is used to execute this batch job hourly.
	System.schedule('PriceList Rollup Batch Job', '0 0 0/1 1/1 * ? *', new PriceListRollup_BatchSchedulable());
	********************************************/

	/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new PriceListRollup_Batch());
	********************************************/
}