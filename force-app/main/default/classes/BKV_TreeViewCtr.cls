// ===========================================================================
//  Object	: BKV_TreeViewCtr
// 	Company	: Keste @IDC
//  Author	: Adarsh Sharma
// 	Purpose	:
// ===========================================================================
// 	Changes:
// ===========================================================================

public class BKV_TreeViewCtr {
	@AuraEnabled
	public static List<TreeHirarchy> buildTreeHirarchy() {
		List<TreeHirarchy> thList = new List<TreeHirarchy>();
		Map<Id, TreeHirarchy> thMap = new Map<Id, TreeHirarchy>();
		TreeHirarchy unmatched = new TreeHirarchy('UNMATCHED', 'UNMATCHED', new List<TreeHirarchy>());
		for (UserRole ur : [SELECT Id, Name, ParentRoleId FROM UserRole ORDER BY ParentRoleId, Name NULLS FIRST]) {
			TreeHirarchy node = new TreeHirarchy(ur.Name, ur.Id, new List<TreeHirarchy>());
			thMap.put(ur.Id, node);
			if (ur.ParentRoleId == null) {
				thList.add(node);
			} else if (thMap.containsKey(ur.ParentRoleId)) {
				thMap.get(ur.ParentRoleId).childNodes.add(node);
			} else {
				if (thList.size() == 1) {
					thList.add(unmatched);
				}
				unmatched.childNodes.add(node);
			}
		}
		return thList;
	}

	@AuraEnabled
	public static Boolean deleteRole(Id userRoleId) {
		delete [SELECT Id FROM UserRole WHERE Id = :userRoleId];
		return true;
	}

	public class TreeHirarchy {
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String value;
		@AuraEnabled
		public List<TreeHirarchy> childNodes;
		@AuraEnabled
		public Boolean isExpanded;

		public TreeHirarchy(String label, String value, List<TreeHirarchy> childNodes) {
			this.label = label;
			this.value = value;
			this.childNodes = childNodes;
			this.isExpanded = true;
		}

		public TreeHirarchy(String label, String value, List<TreeHirarchy> childNodes, Boolean isExpanded) {
			this.label = label;
			this.value = value;
			this.childNodes = childNodes;
			this.isExpanded = isExpanded;
		}
	}
}