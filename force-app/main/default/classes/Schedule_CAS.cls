global class Schedule_CAS implements System.Schedulable {
	global String sfreq;
	global String sCASName;
	global String sCASPrimeId;

	//public static List<String> CASJob_Params=new List<String>();
	global Schedule_CAS() {
	}
	global Schedule_CAS(List<String> CASJob_Params) {
		this.sfreq = CASJob_Params.get(0); //1
		this.sCASPrimeId = CASJob_Params.get(1); //8
		this.sCASName = CASJob_Params.get(2); //8

		//System.debug('sSurveyCode '+sSurveyCode);
	}

	global void execute(SchedulableContext SC) {
		runExtract();
	}
	public void runExtract() {
		CASContactExtract casBatch = new CASContactExtract();
		List<string> CASPrimeId = new List<string>();
		CASPrimeId.add(sCASPrimeId);
		casBatch.GenerateExtract(CASPrimeId);
	}
	// public static void scheduleThis(String Frequency,String SurveyID,String DName,String FSite,String BUnit,String CName)
	public static void scheduleThis(List<String> CAS_Params) {
		try {
			String cronExp;
			String sfrequency = CAS_Params.get(0);
			String sJobName = CAS_Params.get(2);

			if ('Daily'.equals(sfrequency)) {
				cronExp = '0 0 11 1/1 * ? *'; //every day 8 AM
			} else if ('Weekly'.equals(sfrequency)) {
				// cronExp = '0 0 8 ? * MON *'; //every sunday 8 AM
				cronExp = '0 0 11 ? * MON *'; //every Monday 04:00 AM
			} else if ('Monthly'.equals(sfrequency)) {
				cronExp = '0 0 11 ? 1/1 MON#1 *'; //first monday of every month
			} else if ('Yearly'.equals(sfrequency)) {
				cronExp = '0 0 17 31 12 ? *'; //
			}
			System.assertNotEquals(null, cronExp, 'Please pass a value for frequency.');

			System.schedule(sJobName, cronExp, new Schedule_CAS(CAS_Params));
		} catch (Exception e) {
			//try
			string errEmailTo = '';
			string senderDisplayName = '';
			string errEmailSubject = '';
			String[] errToAddresses = new List<String>{};
			List<CAS_Setting__mdt> CAS_EmailList = [
				SELECT ID, Email_Address__c, Error_Subject__c, Sender_Display_Name__c
				FROM CAS_Setting__mdt
				WHERE MasterLabel = 'CAS Email'
			];
			for (CAS_Setting__mdt casEmail : CAS_EmailList) {
				if (casEmail.Email_Address__c != null)
					errToAddresses.add(casEmail.Email_Address__c);
				errEmailSubject = casEmail.Error_Subject__c;
				senderDisplayName = casEmail.Sender_Display_Name__c;
			}

			List<Messaging.SingleEmailMessage> Listmail = new List<Messaging.SingleEmailMessage>();
			for (String recipients : errToAddresses) {
				Messaging.SingleEmailMessage errmail = new Messaging.SingleEmailMessage();
				errmail.setToAddresses(errToAddresses);
				errmail.setSenderDisplayName(senderDisplayName);
				errmail.setSubject(errEmailSubject);
				errmail.setPlainTextBody(
					'Error in job Scheduler ERROR LINE#:' +
					e.getLineNumber() +
					' ERROR CAUSE: ' +
					e.getCause() +
					' ERROR MESSAGE: ' +
					e.getMessage()
				);
				Listmail.add(errmail);
			}
			// Messaging.sendEmail(new Messaging.SingleEmailMessage[] {errmail});
			Messaging.sendEmail(Listmail);
		} //catch
	}
}