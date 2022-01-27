// ===========================================================================
//  Object	: UpdatePriceBookEntry_Schedule
// 	Company	: Keste @ IDC
//  Author	: Vasavi Poranki
// 	Purpose	: Scheduler Class for Batch UpdatePriceBookEntry_Batch Which Create/Updates
// 				the SFDC Native PriceBookEntry records from custom Price_Book_Entry__c records
// ===========================================================================
global class UpdatePriceBookEntry_Schedule implements Schedulable {
	//Scedhuler's Execute Method, which executes when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if (
			(CommonUtilities.isGoodToExecuteBatch('UpdatePriceBookEntry_Batch') &&
			CommonUtilities.isGoodToExecuteBatch('SuperPriceBookRequest_Batch')) || Test.isRunningTest()
		) {
			//fetch stndard pricebook record
			Id standardPriceBookId = null;
			List<Set<Id>> ListOfPriceBooksToProcess = new List<Set<Id>>();
			for (Pricebook2 oPricebook2 : [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1]) {
				standardPriceBookId = oPricebook2.Id;
			}
			if (Test.isRunningTest()) {
				standardPriceBookId = Test.getStandardPricebookId();
			}

			//fetch all Standard Active price books, and divid them in 4 lists to execute all of them parellely
			List<PriceBook2> pbList = new List<PriceBook2>([SELECT Id, Name FROM PriceBook2 WHERE isActive = TRUE]);
			Decimal perBatchPBCount = pbList.size() / 1.0;
			perBatchPBCount = Math.ceil(perBatchPBCount);
			Set<Id> pbeSet = new Set<Id>();
			ListOfPriceBooksToProcess.add(pbeSet);
			for (PriceBook2 pb : pbList) {
				if (pbeSet.size() == perBatchPBCount || Test.isRunningTest()) {
					pbeSet = new Set<Id>();
					ListOfPriceBooksToProcess.add(pbeSet);
				}
				pbeSet.add(pb.Id);
			}

			//Execute batch for all groups
			for (Set<Id> priceBooksToProcess : ListOfPriceBooksToProcess) {
				Integer batchSize = 2000;
				//Check if most recent batch have failed all the records, if so decrease the batch size and try again
				if (
					CommonUtilities.isAllRecordsFailedInRecentExecution('UpdatePriceBookEntry_Batch') ||
					Test.isRunningTest()
				) {
					batchSize = 200;
				}
				//Executing the batch
				Database.executebatch(
					new UpdatePriceBookEntry_Batch(standardPriceBookId, priceBooksToProcess),
					batchSize
				);
			}
		}
	}

	/*******************************************
	@comment : This below script is used to execute this batch job hourly.
	System.schedule('UpdatePriceBookEntryJob', '0 0 0/1 1/1 * ? *', new UpdatePriceBookEntry_Schedule());
	********************************************/

	/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new UpdatePriceBookEntry_Batch());
	********************************************/
}