trigger TF_CASPrimeActiveFlagUpdate on CAS_Prime__c(after update) {
	if (Trigger.isUpdate) {
		try {
			Boolean sNewValue;
			Boolean sOldValue;
			String sCASName;

			for (CAS_Prime__c cpnew : Trigger.new) {
				sNewValue = cpnew.Active__c;
				sCASName = cpnew.name;
			}
			for (CAS_Prime__c cpold : Trigger.old) {
				sOldValue = cpold.Active__c;
			}
			if (sNewValue != sOldValue && sNewValue == false) {
				CronTrigger job = [
					SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType
					FROM CronTrigger
					WHERE CronJobDetail.Name = :sCASName
				];
				if (
					job.Id != null //if scheduled jobjob exists
				)
					System.abortJob(job.Id); //then abort the job
			}
			if (
				sNewValue != sOldValue &&
				sNewValue == true //create a new scheduled job if user has checked the active flag on an existing CAS Prime record
			) {
				for (CAS_Prime__c c : Trigger.new) {
					//gather input parameters from the CAS object

					String Frequency = c.Report_run__c;

					String CASName = c.Name;

					String CASPrimeId = c.Id;
					String FuncCountry = c.Functional_Country__c;
					List<String> CAS_Params = new List<String>();

					CAS_Params.add(Frequency); //0
					CAS_Params.add(CASPrimeId); //1
					CAS_Params.add(CASName); //2

					//pass the parameters to the schedulable class
					if (Frequency == 'Daily' || Frequency == 'Weekly' || Frequency == 'Monthly') {
						Schedule_CAS.scheduleThis(CAS_Params);
					} else {
						IllegalArgumentException e = new IllegalArgumentException();
						e.setMessage('Insufficient arguments in CAS trigger: TF_CASPrimeTrigger!');
						throw e;
					}
				}
			} //if
		} catch (Exception e) {
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
					'Error in Trigger ERROR LINE#:' +
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
	} //if
} //trigger