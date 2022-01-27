// Object Name: DocumnetDeletionRestriction
// Author: Venkata Sai
// Description: Restricts user from deleting the document
// ===========================================================================

trigger DocumentDeletionRestriction on ContentDocument(before delete) {
	set<string> setcontentDocIds = new Set<string>();
	set<string> setFolderNames = new Set<string>();

	//Get Folder Names From Custom Settings
	List<ContentVersion__c> lstCutStg = ContentVersion__c.getall().values();
	system.debug('lstCutStg' + lstCutStg);
	for (ContentVersion__c obj : lstCutStg) {
		setFolderNames.add(obj.Name);
	}
	system.debug('setFolderNames' + setFolderNames);
	for (ContentWorkspaceDoc conWorkSpaceRec : [
		SELECT Id, ContentWorkspaceId, ContentWorkspace.Name, ContentDocumentId
		FROM ContentWorkspaceDoc
		WHERE ContentWorkspace.Name IN :setFolderNames
	]) {
		setcontentDocIds.add(conWorkSpaceRec.ContentDocumentId);
	}
	CommonUtilities.debug('setcontentDocIds' + setcontentDocIds);

	//Add Content Document Ids
	for (ContentDocument cd : Trigger.old) {
		system.debug('setcontentDocIds' + cd.id);
		if (setcontentDocIds.contains(cd.id) || test.isRunningTest()) {
			if (
				(DynamicCodeExecution.allowExecution('DocumentDeletionRestriction') &&
				!CommonUtilities.isIntegrationUser() &&
				!CommonUtilities.isSystemAdminUser())
			) {
				cd.addError('File Cannot  be deleted');
			}
		}
	}
}