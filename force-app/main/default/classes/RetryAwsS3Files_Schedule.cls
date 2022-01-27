// ===========================================================================
//  Object	: RetryAwsS3Files_Schedule
// 	Company	: Keste @ IDC
//  Author	: Basant Kumar Verma
// 	Purpose	: Scheduler Class for Batch RetryAwsS3Files_Batch Which process
// 	All AWS S3 files from Case
// ===========================================================================
global class RetryAwsS3Files_Schedule implements Schedulable {
	//Scedhuler's Execute Method, which executes when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if ((CommonUtilities.isGoodToExecuteBatch('RetryAwsS3Files_Batch')) || Test.isRunningTest()) {
			//Executing the batch
			Database.executebatch(new RetryAwsS3Files_Batch());
		}
	}

	/*******************************************
	@comment : This below script is used to execute this batch job hourly.
	System.schedule('RetryAwsS3Files', '0 15 0/1 1/1 * ? *', new RetryAwsS3Files_Schedule());
	********************************************/

	/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new RetryAwsS3Files_Batch(), 10);
	********************************************/
}