// ===========================================================================
//  Object	: LayoutSection
//  Company	: Keste @ IDC
//  Author	: Adarsh Sharma
//  Purpose	: Wrapper Class to hold Layout Section Details
// ===========================================================================
public class LayoutSection {
	@AuraEnabled
	public boolean useHeader { get; set; }
	@AuraEnabled
	public string name { get; set; }
	@AuraEnabled
	public boolean allowCollapse { get; set; }
	@AuraEnabled
	public integer columns { get; set; }
	@AuraEnabled
	public List<LayoutField> layoutFields { get; set; }

	public LayoutSection(string name, boolean useHeader, integer columns, boolean allowCollapse) {
		this.name = name;
		this.useHeader = useHeader;
		this.columns = columns;
		this.allowCollapse = allowCollapse;
		this.layoutFields = new List<LayoutField>();
	}
}