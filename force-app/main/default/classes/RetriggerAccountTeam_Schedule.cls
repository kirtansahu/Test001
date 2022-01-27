// ===========================================================================
//  Object	: RetriggerAccountTeam_Schedule
// 	Company	: Keste @ IDC
//  Author	: Basant Kumar Verma
// 	Purpose	: Scheduler Class for Batch RetriggerAccountTeam_Batch Which process
// 	Custom Account Team records and create the standard Accoun Team Members
// ===========================================================================
global class RetriggerAccountTeam_Schedule implements Schedulable {
	//Scedhuler's Execute Method, which executes when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if (
			(CommonUtilities.isGoodToExecuteBatch('RetriggerAccountTeam_Batch') &&
			CommonUtilities.isGoodToExecuteBatch('ParentalSetupAccountTeamCascade_Batch') &&
			CommonUtilities.isGoodToExecuteBatch('PriceListRollup_Batch')) || Test.isRunningTest()
		) {
			//Executing the batch
			Database.executebatch(new RetriggerAccountTeam_Batch(), 10);
		}
	}

	/*******************************************
	@comment : This below script is used to execute this batch job hourly.
	System.schedule('Retrigger Account Team', '0 40 0/1 1/1 * ? *', new RetriggerAccountTeam_Schedule());
	********************************************/

	/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new RetriggerAccountTeam_Batch());
	********************************************/
}