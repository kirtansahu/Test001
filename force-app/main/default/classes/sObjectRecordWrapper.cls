// ===========================================================================
//  Object	: sObjectRecordWrapper
// 	Company	: Keste @ IDC
//  Author	: Adarsh Sharma
// 	Purpose	: Wrapper Class used in Sieble Sycn Resources to hold generic record
// ===========================================================================
public class sObjectRecordWrapper {
	public String strExternalId;
	public String strRelatedId;
	public String strObjectName;
	public String strRelatedName;
	public String strRelatedType;

	//Parameterized Constructor
	public sObjectRecordWrapper(String sExternalId, String sRealtedId, String sObjectName, String sRelatedName) {
		this.strExternalId = sExternalId;
		this.strRelatedId = sRealtedId;
		this.strObjectName = sObjectName;
		this.strRelatedName = sRelatedName;
	}

	//Parameterized Constructor
	public sObjectRecordWrapper(
		String sExternalId,
		String sRealtedId,
		String sObjectName,
		String sRelatedName,
		String sRelatedType
	) {
		this.strExternalId = sExternalId;
		this.strRelatedId = sRealtedId;
		this.strObjectName = sObjectName;
		this.strRelatedName = sRelatedName;
		this.strRelatedType = sRelatedType;
	}
}