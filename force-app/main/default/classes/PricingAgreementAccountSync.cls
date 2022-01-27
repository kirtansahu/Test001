/**
 * @description  : Sync Operation to keep Account Quote Junction object records in check based on Pricing Agreements
 * @author       : Abinash Panigrahi
 * @group        : Keste LLC
 * @created on   : 11-26-2020
 **/

public class PricingAgreementAccountSync {
	/**
	 * @description After adding ship-tos/sgns in CPQ to a Quote, user will
	 * click on Save to sync the header to salesforce. The list of Ship-Tos/SGNs
	 * that were added to the Quote in CPQ will be available as a list of comma
	 * separated values in a text field on the Quote header
	 * @author Abinash Panigrahi | 11-26-2020
	 **/
	public static void processChanges(
		BigMachines__Quote__c objNew,
		BigMachines__Quote__c objOld
	) {
		Id quoteId = objNew.Id;
		String selectedShipTos = objNew.Selected_Ship_To_s__c;
		String selectedSGNs = objNew.Selected_SGN_s__c;

		List<String> allowedAgreements = new List<String>{ 'E', 'F', 'H' };
		if (!allowedAgreements.contains(objNew.BigMachines_Quote_Type__c)) {
			return;
		}

		if (
			(objOld == null &&
			(objNew.Selected_SGN_s__c != null ||
			objNew.Selected_Ship_To_s__c != null)) ||
			(objOld != null &&
			(objNew.Selected_SGN_s__c != objOld.Selected_SGN_s__c ||
			objNew.Selected_Ship_To_s__c != objOld.Selected_Ship_To_s__c))
		) {
			syncAccountQuotes(quoteId, selectedShipTos, selectedSGNs);
		}
	}

	/**
	 * @description What we then need to do is to parse those comma separated
	 * values and create them as association records in this junction object,
	 * i.e. we need to link that Quote to all those accounts via the junction
	 * object. And we need to do this as a sync operation i.e. if any account
	 * was removed from that quote, it needs to be deleted from the junction object.
	 * @author Abinash Panigrahi | 11-26-2020
	 **/
	@future
	public static void syncAccountQuotes(
		Id quoteId,
		String selectedShipTos,
		String selectedSGNs
	) {
		Set<String> accountNumbers = new Set<String>();

		if (selectedShipTos != null) {
			accountNumbers.addAll(selectedShipTos.split(','));
		}
		/* if (selectedSGNs != null) {
			accountNumbers.addAll(selectedSGNs.split(','));
		} */

		List<Account_Quote__c> toBeDeletedRecs = new List<Account_Quote__c>();
		for (Account_Quote__c junctionRecord : [
			SELECT Id, Account_Number__c, AccountId__c
			FROM Account_Quote__c
			WHERE QuoteId__c = :quoteId AND Account_Number__c != NULL
		]) {
			if (!accountNumbers.contains(junctionRecord.Account_Number__c)) {
				toBeDeletedRecs.add(junctionRecord);
			} else {
				accountNumbers.remove(junctionRecord.Account_Number__c);
			}
		}

		List<Account_Quote__c> toBeInsertedRecs = new List<Account_Quote__c>();
		for (Account acc : [
			SELECT Id, ERP_Account_Id__c
			FROM Account
			WHERE ERP_Account_Id__c IN :accountNumbers
		]) {
			toBeInsertedRecs.add(
				new Account_Quote__c(
					QuoteId__c = quoteId,
					AccountId__c = acc.Id,
                    Unique_Id__c = quoteId + '_' + acc.Id
				)
			);
		}

		try {
			if (toBeDeletedRecs.size() > 0) {
				// Database.delete(toBeDeletedRecs, false);
                delete toBeDeletedRecs;
			}

			if (toBeInsertedRecs.size() > 0) {
				// Database.insert(toBeInsertedRecs, false);
                insert toBeInsertedRecs;
			}
		} catch (Exception ex) {
			ExceptionHandlerController.createException(
				'PricingAgreementAccountSync',
				'syncAccountQuotes',
				'Future Logic',
				'Insert & Delete Account Quotes',
				ex.getMessage(),
				System.today()
			);
		}
	}

	public static void deleteRecords(
		BigMachines__Quote__c objNew,
		BigMachines__Quote__c objOld
	) {
		if (
			objNew.BigMachines__Status__c == 'Deleted' &&
			objNew.BigMachines__Status__c != objOld.BigMachines__Status__c
		) {
			syncArchivedQuotes(objNew.Id);
		}
	}

	@future
	public static void syncArchivedQuotes(Id quoteId) {
		List<Account_Quote__c> relatedAccs = [
			SELECT Id
			FROM Account_Quote__c
			WHERE QuoteId__c = :quoteId
		];
		if (relatedAccs.size() > 0) {
			delete relatedAccs;
		}
		delete new BigMachines__Quote__c(Id = quoteId);
	}
}