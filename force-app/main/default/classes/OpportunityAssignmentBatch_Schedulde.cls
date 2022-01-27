// ===========================================================================
//  Class	: OpportunityAssignmentBatch_Schedulde
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Scheduler Class to schedule and execute the OpportunityAssignment_Batch
// ===========================================================================
global class OpportunityAssignmentBatch_Schedulde implements Schedulable {
	//Execute method whcih will get executed when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if (CommonUtilities.isGoodToExecuteBatch('OpportunityAssignment_Batch') || Test.isRunningTest()) {
			Database.executebatch(new OpportunityAssignment_Batch(), 1);
		}
	}

	/*******************************************
    @comment : This below script is used to execute this batch job hourly.
    System.schedule('Opportunity Rule Assignment Batch Job', '0 10 0/1 1/1 * ? *', new OpportunityAssignmentBatch_Schedulde());
    ********************************************/

	/*******************************************
    @comment : This below script is used to execute this batch job immediately.
    Database.executebatch(new OpportunityAssignment_Batch(), 1);
    ********************************************/
}