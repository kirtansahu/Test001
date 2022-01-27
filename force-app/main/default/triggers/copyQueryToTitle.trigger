trigger copyQueryToTitle on Knowledge__kav(before insert, before update) {
	for (Knowledge__kav kb : Trigger.new) {
		string recordtypename = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosById()
			.get(kb.recordtypeid)
			.getname();
		string StrQuestion;
		if (kb.Title == 'NA' && recordtypename == 'Public FAQs') {
			if (kb.Question__c.length() >= 250) {
				kb.Title = kb.Question__c.substring(0, 250);
			} else {
				kb.Title = kb.Question__c;
			}
		}
		if (kb.UrlName == 'NA' && recordtypename == 'Public FAQs') {
			//kb.UrlName=kb.Question__c.replaceAll( '\\s+', '-');
			if (kb.Question__c.length() >= 250) {
				StrQuestion = kb.Question__c.substring(0, 250);
				kb.UrlName = StrQuestion.replaceAll('\\s+', '-').replace('?', '');
			} else {
				kb.UrlName = kb.Question__c.replaceAll('\\s+', '-').replace('?', '');
			}
		}
		if (kb.UrlName == 'NA' && recordtypename == 'Private(Internal)') {
			kb.UrlName = kb.Title.replaceAll('\\s+', '-').replace('?', '');
		}
	}
}