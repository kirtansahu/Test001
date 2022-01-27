/********************************************************************************************************
 * Object	: CustomLeadPathCompCtrl
 * Company	: Keste @ IDC
 * Author	: Adarsh Sharma
 * Purpose	: Controller class for the Custom Lead Path Lightning Component
 ********************************************************************************************************/
public class CustomLeadPathCompCtrl {
	/***************************************************************************************
    @Description: Method to fetch lead record through lead record id
    @Author: Adarsh Sharma
    @Param: Id leadId : Lead Record Id
    @Return: Lead : fetched Lead Record
    ***************************************************************************************/
	@AuraEnabled
	public static Lead fetchLeadRecord(Id leadId) {
		return LeadConvertUtilities.fetchLeadRecordDetails(leadId);
	}

	/***************************************************************************************
    @Description: Method to fetch all Lead Status Picklist Values
    @Author: Adarsh Sharma
    @Param: none
    @Return: List<LeadStatusWrapper> : List of all Status values
    ***************************************************************************************/
	@AuraEnabled
	public static List<LeadStatusWrapper> fetchLeadStatusValues() {
		List<LeadStatusWrapper> lstLeadStatusWrapper = new List<LeadStatusWrapper>();
		if (DynamicCodeExecution.allowExecution('CustomLeadPathCompCtrl.fetchLeadStatusValues')) {
			for (Schema.PicklistEntry picklistEntry : Lead.Status.getDescribe().getPicklistValues()) {
				lstLeadStatusWrapper.add(
					new LeadStatusWrapper(picklistEntry.getLabel(), picklistEntry.getValue(), null)
				);
			}
		}
		return lstLeadStatusWrapper;
	}

	/***************************************************************************************
    @Description: Method to Update Lead object record
    @Author: Adarsh Sharma
    @Param: Lead leadOb : Lead Object record to be updated
    @Return: Lead : Updated lead object record
    ***************************************************************************************/
	@AuraEnabled
	public static Lead updateLeadRecord(Lead leadObj) {
		try {
			if (DynamicCodeExecution.allowExecution('CustomLeadPathCompCtrl.updateLeadRecord')) {
				update leadObj;
			}
			return leadObj;
		} catch (DMLException dmlex) {
			throw new AuraHandledException(dmlex.getDMLMessage(0));
		} catch (exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/***************************************************************************************
    @Description: Method to Lead record
    @Author: Adarsh Sharma
    @Param: Lead leadOb : Lead Object record to be converted
    @Return: Id : returns the converted Opportunity Id
    ***************************************************************************************/
	@AuraEnabled
	public static Id convertLeadIntoOpportunity(Lead oLead) {
		return LeadConvertUtilities.convertLead(oLead);
	}

	/***************************************************************************************
    @Description: Method to fetch the dependent Pick List Values
    @Author: Adarsh Sharma
    @Param: String objTypeName : sObject API Name whos fields need to be used
	@Param: String contrfieldApiName : API Name of the controling field
	@Param: String depfieldApiName : API Name of the dependent field
	@Param: String contrFldValue : Value of the Controling field
    @Return: List<SelectOption> : List of valid dependent picklist values
    ***************************************************************************************/
	@AuraEnabled
	public static List<SelectOption> fetchDependentPickListValue(
		String objTypeName,
		string contrfieldApiName,
		string depfieldApiName,
		string contrFldValue
	) {
		Map<String, List<SelectOption>> objResults = new Map<String, List<SelectOption>>();
		List<SelectOption> lstDependentPicklistValues = new List<SelectOption>();
		lstDependentPicklistValues.add(new SelectOption('', '-None-'));

		if (DynamicCodeExecution.allowExecution('CustomLeadPathCompCtrl.fetchDependentPickListValue')) {
			String controllingField = contrfieldApiName.toLowerCase();
			String dependentField = depfieldApiName.toLowerCase();
			Schema.SObjectType objType = Schema.getGlobalDescribe().get(objTypeName);
			Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
			Schema.SObjectField theField = objFieldMap.get(dependentField);
			Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
			List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
			List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
			List<String> controllingValues = new List<String>();
			for (Schema.PicklistEntry ple : contrEntries) {
				String label = ple.getLabel();
				objResults.put(label, new List<SelectOption>());
				controllingValues.add(label);
			}
			for (PicklistEntryWrapper plew : depEntries) {
				String label = plew.label;
				String validForBits = base64ToBits(plew.validFor);
				for (Integer i = 0; i < validForBits.length(); i++) {
					String bit = validForBits.mid(i, 1);
					if (bit == '1') {
						objResults.get(controllingValues.get(i)).add(new SelectOption(label, label));
					}
				}
			}
			if (objResults.containsKey(contrFldValue)) {
				lstDependentPicklistValues.addAll(objResults.get(contrFldValue));
			}
		}
		return lstDependentPicklistValues;
	}

	/***************************************************************************************
    @Description: Private method to convert decimal number to Binary string, used to fetch the dependent picklist
    @Author: Adarsh Sharma
    @Param: Integer val: Decimal number to be converyed
    @Return: String: Converted binary string value
    ***************************************************************************************/
	private static String decimalToBinary(Integer val) {
		String bits = '';
		while (val > 0) {
			Integer remainder = Math.mod(val, 2);
			val = Integer.valueOf(Math.floor(val / 2));
			bits = String.valueOf(remainder) + bits;
		}
		return bits;
	}

	/***************************************************************************************
    @Description: Private method to convert base64 string to Bits String, used to fetch the dependent picklist
    @Author: Adarsh Sharma
    @Param: String validFor: Base64 String to be converted
    @Return: String: Converted Bits string
    ***************************************************************************************/
	private static String base64ToBits(String validFor) {
		if (String.isEmpty(validFor))
			return '';

		String validForBits = '';

		for (Integer i = 0; i < validFor.length(); i++) {
			String thisChar = validFor.mid(i, 1);
			Integer val = base64Chars.indexOf(thisChar);
			String bits = decimalToBinary(val).leftPad(6, '0');
			validForBits += bits;
		}

		return validForBits;
	}

	private static final String base64Chars =
		'' +
		'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
		'abcdefghijklmnopqrstuvwxyz' +
		'0123456789+/';

	/***************************************************************************************
    @Description: Private method to convert List of Schema.PicklistEntry to List of PicklistEntryWrapper
    @Author: Adarsh Sharma
    @Param: List<Schema.PicklistEntry> PLEs: list of Schema.PicklistEntry
    @Return: List,PicklistEntryWrapper>: List of PicklistEntryWrapper
    ***************************************************************************************/
	private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
		return (List<PicklistEntryWrapper>) JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
	}

	//Wrapper class for Pick list values
	public class PicklistEntryWrapper {
		public String active { get; set; }
		public String defaultValue { get; set; }
		public String label { get; set; }
		public String value { get; set; }
		public String validFor { get; set; }
		public string validForName { get; set; }
		public PicklistEntryWrapper() {
		}
	}

	//Wrapper class for Select Options
	public class SelectOption {
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String value;

		public SelectOption(String value, String label) {
			this.value = value;
			this.label = label;
		}
	}

	//Wrapper class for Lead Status
	public class LeadStatusWrapper {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }
		@AuraEnabled
		public String status { get; set; }

		public LeadStatusWrapper(String slabel, String sValue, String sStatus) {
			this.label = slabel;
			this.value = sValue;
			this.status = sStatus;
		}
	}
}