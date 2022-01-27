// ===========================================================================
//  Object	: selectedSizeWorkaround
// 	Company	: Keste @ IDC
// 	Purpose	: Controller Class for MassUpdate VF Page
// ===========================================================================
public with sharing class selectedSizeWorkaround {
	public ApexPages.StandardSetController setCon;

	//Standard Constructor
	public selectedSizeWorkaround(ApexPages.StandardSetController controller) {
		setCon = controller;
	}

	//Method to get the count of selected record
	public integer getMySelectedSize() {
		return setCon.getSelected().size();
	}

	//Method to get the count of all record
	public integer getMyRecordsSize() {
		return setCon.getRecords().size();
	}
}