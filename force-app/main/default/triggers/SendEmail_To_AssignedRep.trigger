trigger SendEmail_To_AssignedRep on Support_Request__c(after insert, before update) {
	for (Support_Request__c SupportRquest : Trigger.new) {
		List<User> Users = new List<User>();
		// Retrieve Assigned To email from user object
		if (Trigger.isInsert && SupportRquest.Assigned_To__c != null) {
			Users = [
				SELECT Id, firstName, lastName, Name, Email
				FROM User
				WHERE Name = :SupportRquest.Assigned_To__c
				LIMIT 1
			];
		} else if (
			Trigger.isUpdate && Trigger.oldMap.get(SupportRquest.Id).Assigned_To__c != SupportRquest.Assigned_To__c
		) {
			Users = [
				SELECT Id, firstName, lastName, Name, Email
				FROM User
				WHERE Name = :SupportRquest.Assigned_To__c
				LIMIT 1
			];
		}

		// Send email to Assigned To rep
		for (User AssignedRep : Users) {
			if (AssignedRep.Email != null) {
				EmailTemplate templateId = [
					SELECT id
					FROM EmailTemplate
					WHERE name = 'Support Request Notification : Assigned To Person'
				];

				String tempId = templateId.Id;
				String userId = AssignedRep.Id;
				String whatId = SupportRquest.Id;

				Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(tempId, userId, whatId);

				String emailSubject = email.getSubject();
				String emailTextBody = email.getPlainTextBody();

				email.setTargetObjectId(AssignedRep.Id);
				email.setSubject(emailSubject);
				email.setPlainTextBody(emailTextBody);
				email.saveAsActivity = false;
				Messaging.SendEmailResult[] results = Messaging.sendEmail(
					new List<Messaging.SingleEmailMessage>{ email }
				);

				if (results[0].success) {
					System.debug('The email was sent successfully.');
				} else {
					System.debug('The email failed to send: ' + results[0].errors[0].message);
				}
			}
		}
	}
}