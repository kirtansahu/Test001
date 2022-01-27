// ===========================================================================
//  Object	: LayoutField
//  Company	: Keste @ IDC
//  Author	: Adarsh Sharma
//  Purpose	: Wrapper Class to hold Layout Field
// ===========================================================================
public class LayoutField {
	@AuraEnabled
	public boolean required { get; set; }
	@AuraEnabled
	public boolean isPlaceHolder { get; set; }
	@AuraEnabled
	public boolean editableField { get; set; }
	@AuraEnabled
	public string ApiName { get; set; }
	@AuraEnabled
	public string dataType { get; set; }
	@AuraEnabled
	public string label { get; set; }

	//Constructor
	public LayoutField(
		boolean required,
		boolean isPlaceHolder,
		boolean editableField,
		string ApiName,
		String dataType,
		string label
	) {
		this.required = required;
		this.isPlaceHolder = isPlaceHolder;
		this.editableField = editableField;
		this.ApiName = ApiName;
		this.dataType = dataType;
		this.label = label;
	}
}