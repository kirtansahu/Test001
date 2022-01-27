// ===========================================================================
//  Object	: NewOpportunity
// 	Company	: Keste @ IDC
//  Author	: Vasavi Poranki
// 	Purpose	: Lightning Controller To Fetch All OpportunityFields Present in Layout.
// ===========================================================================
public class NewOpportunity {
	//method to build new Opportunity with efault fields
	@AuraEnabled
	public static String NewOpportunityPrefill() {
		String strJSON = '';
		Opportunity objService = new Opportunity();
		objService.Name = 'Opportunity : ';
		objService.StageName = 'New';
		//objService.Confidence__c = '10%';
		objService.closedate = system.today().adddays(15);
		strJSON += '{';
		for (Schema.FieldSetMember f : getFields()) {
			if (
				!f.getFieldPath().contains('__r') &&
				objService.get(f.getFieldPath()) != null &&
				objService.get(f.getFieldPath()) != ''
			) {
				if (String.valueOf(f.getType()) == 'BOOLEAN') {
					strJSON += '\"' + f.getFieldPath() + '\" : ' + objService.get(f.getFieldPath()) + ',';
				} else if (String.valueOf(f.getType()) == 'DATE') {
					DateTime objdt = Date.valueOf(objService.get(f.getFieldPath()));
					Date objdt1 = Date.newInstance(objdt.year(), objdt.month(), objdt.day());
					string strDt = objdt.Year() + '-' + objdt.Month() + '-' + objdt.Day();
					strJSON += '\"' + f.getFieldPath() + '\" : \"' + strDt + '\",';
				} else {
					strJSON += '\"' + f.getFieldPath() + '\" : \"' + objService.get(f.getFieldPath()) + '\",';
				}
			}
		}
		strJSON = strJSON.substring(0, strJSON.length() - 1);
		strJSON += '}';
		CommonUtilities.debug('strJSON---------->' + strJSON);
		return strJSON;
	}

	//Method to get list of all fields from Opportunity field set
	public static List<Schema.FieldSetMember> getFields() {
		return SObjectType.Opportunity.FieldSets.Opportunity_Fieldset.getFields();
	}
}