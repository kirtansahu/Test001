//object: ContentDocumentLinkTrigger_Test
// Author: Venkata Sai
// Purpose:Test Class for ContentDocumentLink trigger and ContentDocumentLinkHandler

@isTest(SeeAllData=true)
public class ContentDocumentLinkTrigger_Test {
	public static testMethod void updateFileStatus() {
		Blob beforeblob = Blob.valueOf('Unit Test Attacchment Body');
		ContentVersion cv = new ContentVersion();
		cv.Title = 'test content trigger';
		cv.PathOnClient = 'test.csv';
		cv.VersionData = beforeblob;
		insert cv;

		map<string, boolean> mapFolderNames = new Map<string, boolean>();
		List<ContentVersion__c> lstCutStg = ContentVersion__c.getall().values();
		if (!lstCutStg.Isempty()) {
			for (ContentVersion__c obj : lstCutStg) {
				mapFolderNames.put(obj.Name, obj.ExistingFile__c);
			}
		}
		ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
		system.debug('Test' + mapFolderNames);
		List<ContentWorkspace> testWorkspace = [
			SELECT Id, Name
			FROM ContentWorkspace
			WHERE Name IN :mapFolderNames.keySet()
		];

		ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc();
		newWorkspaceDoc.ContentWorkspaceId = testWorkspace[0].Id;
		newWorkspaceDoc.ContentDocumentId = testContent.ContentDocumentId;
		insert newWorkspaceDoc;
	}

	public static testMethod void documentDeleteTest() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'Analyst - Global'].Id;
		Id adprofileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
		Id inprofileId = [SELECT Id FROM Profile WHERE Name = 'Integration User'].Id;
		//Insert User
		User userRec = new User(
			LastName = 'Test User',
			Email = 'testUser@test.com',
			Username = 'sysit@test.com',
			Alias = 'test123',
			ProfileId = profileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);

		User aduserRec = new User(
			LastName = 'Admin User',
			Email = 'adminUser@test.com',
			Username = 'sysad@test.com',
			Alias = 'test12',
			ProfileId = adprofileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);

		User inuserRec = new User(
			LastName = 'Int User',
			Email = 'intUser@test.com',
			Username = 'sysint@test.com',
			Alias = 'test1',
			ProfileId = inprofileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert userRec;
		insert aduserRec;
		insert inuserRec;

		Blob beforeblob = Blob.valueOf('Unit Test Attacchment Body');
		ContentVersion cv = new ContentVersion();
		cv.Title = 'test content trigger';
		cv.PathOnClient = 'test.csv';
		cv.VersionData = beforeblob;

		System.runAs(userRec) {
			insert cv;

			ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
			ContentDocument testContentDocument = [
				SELECT Id
				FROM ContentDocument
				WHERE Id = :testContent.ContentDocumentId
			];

			try {
				delete testContentDocument;
			} catch (Exception e) {
			}
		}
	}
}