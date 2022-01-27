// ===========================================================================
//  Class	: ParentalSetupAccountTeamCascade_Sch
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Scheduler Class to schedule and execute the ParentalSetupAccountTeamCascade_Batch
// ===========================================================================
global class ParentalSetupAccountTeamCascade_Sch implements Schedulable {
	//Execute method whcih will get executed when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if (
			(CommonUtilities.isGoodToExecuteBatch('ParentalSetupAccountTeamCascade_Batch') &&
			CommonUtilities.isGoodToExecuteBatch('PriceListRollup_Batch') &&
			CommonUtilities.isGoodToExecuteBatch('RetriggerAccountTeam_Batch')) || Test.isRunningTest()
		) {
			Database.executebatch(new ParentalSetupAccountTeamCascade_Batch(), 20);
		}
	}

	/*******************************************
    @comment : This below script is used to execute this batch job hourly.
    System.schedule('Parental Setup Account Team Cascade Batch Job', '0 20 0/1 1/1 * ? *', new ParentalSetupAccountTeamCascade_Sch());
    ********************************************/

	/*******************************************
    @comment : This below script is used to execute this batch job immediately.
    Database.executebatch(new ParentalSetupAccountTeamCascade_Batch());
    ********************************************/
}