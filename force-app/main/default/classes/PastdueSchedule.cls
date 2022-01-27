// ===========================================================================
//  Object  : PastdueSchedule
//  Author  : Vijay Rayala
//  Purpose : Scheduler Class for PastdueBatchable Which process
//  Flag Pastduetriggered Flag Pastdue opportunities
// ===========================================================================

global class PastdueSchedule implements Schedulable {
	//Scedhuler's Execute Method, which executes when scheduled time occures
	global void execute(SchedulableContext scMain) {
		PastdueBatchable clsBatchIt = new PastdueBatchable();
		ID idBatch = Database.executeBatch(clsBatchIt, 200);
	}
	/*******************************************
    @comment : This below script is used to execute this batch job Daily at 12:01 AM.
    PastdueSchedule clsCRON = new PastdueSchedule();
    System.Schedule('PastDue Opportunities batch at 00:01 AM Daily', '0 1 0 * * ?', clsCRON);
    ********************************************/

	/*******************************************
    @comment : This below script is used to execute this batch job immediately.
     Database.executebatch(new PastdueBatchable());
    ********************************************/
}