// Method Name: UpdateContentVersion
// Author: Venkata Sai
// Description: Method to Update status of file if it is uploaded to only 'Bulk package price upload' library
// ===========================================================================

public class ContentDocumentLinkHandler {
	public static void UpdateContentVerison(List<ContentDocumentLink> lstCntLinks) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('ContentDocumentLinkHandler.UpdateContentVerison')) {
			CommonUtilities.debug('Inside UpdateContentVerison method');
			CommonUtilities.debug('lstCntLinks------->>>>>>>' + lstCntLinks);
			set<string> setConDocIds = new Set<string>();
			List<contentversion> lstconversion = new List<contentversion>();
			List<ContentWorkspaceDoc> lstConWorkSpaceDoc = new List<ContentWorkspaceDoc>();
			map<string, Boolean> mapFolderNames = new Map<string, Boolean>();
			map<string, Boolean> mapContDocIds = new Map<string, Boolean>();

			List<ContentVersion__c> lstCutStg = ContentVersion__c.getall().values();
			if (!lstCutStg.Isempty()) {
				for (ContentVersion__c obj : lstCutStg) {
					mapFolderNames.put(obj.Name, obj.ExistingFile__c);
				}
			}

			for (ContentDocumentLink obj : lstCntLinks) {
				setConDocIds.add(obj.ContentDocumentId);
			}

			if (!mapFolderNames.isEmpty() && !setConDocIds.isEmpty()) {
				lstConWorkSpaceDoc = [
					SELECT Id, ContentWorkspaceId, ContentWorkspace.Name, ContentDocumentId
					FROM ContentWorkspaceDoc
					WHERE ContentDocumentId IN :setConDocIds AND ContentWorkspace.Name IN :mapFolderNames.keySet()
				];
			}
			CommonUtilities.debug('lstConWorkSpaceDoc------->>>>>>>' + lstConWorkSpaceDoc);
			if (!lstConWorkSpaceDoc.isEmpty()) {
				for (ContentWorkspaceDoc objConWoksp : lstConWorkSpaceDoc) {
					if (!mapContDocIds.containsKey(objConWoksp.ContentDocumentId)) {
						mapContDocIds.put(
							objConWoksp.ContentDocumentId,
							mapFolderNames.get(objConWoksp.ContentWorkspace.Name)
						);
					}
				}
			}

			if (!lstConWorkSpaceDoc.isEmpty()) {
				lstconversion = [
					SELECT Id, ContentDocumentId, Package_Upload_Status__c, File_Format__c, FileType
					FROM ContentVersion
					WHERE ContentDocumentId IN :mapContDocIds.keySet()
				];
			}
			CommonUtilities.debug('lstconversion------->>>>>>>' + lstconversion);

			if (!lstconversion.isEmpty()) {
				for (contentversion obj : lstconversion) {
					if (obj.FileType == 'CSV') {
						obj.Package_Upload_Status__c = System.label.StatusUpdate;

						if (mapContDocIds.containsKey(obj.ContentDocumentId)) {
							if (mapContDocIds.get(obj.ContentDocumentId)) {
								obj.File_Format__c = System.label.BulkPackagePriceUploadFileFormat;
							} else {
								obj.File_Format__c = System.label.BulkPackagePriceUploadNewFileFormat;
							}
						}
					}
				}
				update lstconversion;
			}
			CommonUtilities.debug('File Status' + lstconversion);
			CommonUtilities.debug('UpdateContentVerison');
		}
	}
}