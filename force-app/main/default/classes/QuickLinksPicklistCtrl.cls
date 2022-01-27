/***************************************************************************************
 * @description: This is used as controller for QuickLinkComp lightning component which
 * is used to show location name in lightning app builder.
 * @author: Keste Dev
 * @date: 04 Sep, 2019
 ***************************************************************************************/
global class QuickLinksPicklistCtrl extends VisualEditor.DynamicPickList {
	/***************************************************************************************
    @description: This method used to set default location name
    @author: Keste Dev
    @date: 04 Sep, 2019
    @param: none
    @return: VisualEditor.DataRow : return default location name
    ***************************************************************************************/
	global override VisualEditor.DataRow getDefaultValue() {
		VisualEditor.DataRow defaultValue = null;
		if (DynamicCodeExecution.allowExecution('QuickLinksPicklistCtrl.getDefaultValue')) {
			for (Schema.PicklistEntry picklistEntry : Custom_Link__c.Location__c.getDescribe().getPicklistValues()) {
				defaultValue = new VisualEditor.DataRow(picklistEntry.getLabel(), picklistEntry.getValue());
				break;
			}
		}
		return defaultValue;
	}

	/***************************************************************************************
    @description: This method used to get all location name from Custom Link's "Location__c" field
    @author: Keste Dev
    @date: 04 Sep, 2019
    @param: none
    @return: VisualEditor.DynamicPickListRows : return collection of location name
    ***************************************************************************************/
	global override VisualEditor.DynamicPickListRows getValues() {
		VisualEditor.DynamicPickListRows picklistValues = new VisualEditor.DynamicPickListRows();
		if (DynamicCodeExecution.allowExecution('QuickLinksPicklistCtrl.getValues')) {
			for (Schema.PicklistEntry picklistEntry : Custom_Link__c.Location__c.getDescribe().getPicklistValues()) {
				picklistValues.addRow(new VisualEditor.DataRow(picklistEntry.getLabel(), picklistEntry.getValue()));
			}
		}
		return picklistValues;
	}
}