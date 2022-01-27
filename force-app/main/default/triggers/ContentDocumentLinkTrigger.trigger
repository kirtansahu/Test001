//Object  : ContentDocumentLinkTrigger
//  Author  : Venkata Sai
//  Purpose : ContentDocumentLinkTrigger functionality.
// =========================================================================
trigger ContentDocumentLinkTrigger on ContentDocumentLink(after update, after insert) {
	if (Trigger.isAfter) {
		{
			if (
				DynamicCodeExecution.allowExecution('ContentDocumentLinkHandler') &&
				!CommonUtilities.isIntegrationUser()
			)
				ContentDocumentLinkHandler.UpdateContentVerison(Trigger.new);
		}
	}
}