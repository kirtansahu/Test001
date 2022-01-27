/***************************************************************************************
 * @description: This is used as controller for QuickLinkComp lightning component which
 * is used to get all category and it's related custom link based on selected location.
 * @author: Keste Dev
 * @date: 04 Sep, 2019
 ***************************************************************************************/
public class QuickLinksCompCtrl {
	/***************************************************************************************
    @description: This method used to get all category and it's related custom link based on selected location.
    @author: Keste Dev
    @date: 04 Sep, 2019
    @param: String location : selected location name
    @return: CategoryWrapper : return collection of category, custom link and collapisble section
    ***************************************************************************************/
	@AuraEnabled
	public static CategoryWrapper fetchCategoryAndCustomLinks(String location) {
		CategoryWrapper result = new CategoryWrapper();
		CategoryDetailWrapper previousCategory = null;
		if (DynamicCodeExecution.allowExecution('QuickLinksCompCtrl.fetchCategoryAndCustomLinks')) {
			for (Custom_Link__c cl : [
				SELECT
					Id,
					Location__c,
					Label__c,
					Link__c,
					Description__c,
					Category__c,
					Category__r.Label__c,
					Category__r.Collapsed__c
				FROM Custom_Link__c
				WHERE
					Location__c = :location
					AND RecordType.Name = 'Custom Link'
					AND IsActive__c = TRUE
					AND Category__r.IsActive__c = TRUE
				ORDER BY Category__r.Order__c, Order__c ASC
			]) {
				if (previousCategory == null || previousCategory.name != cl.Category__r.Label__c) {
					previousCategory = new CategoryDetailWrapper(cl.Category__r.Label__c);
					result.allCatgories.add(previousCategory);
				}
				previousCategory.links.add(cl);
				if (!cl.Category__r.Collapsed__c) {
					result.colapsedCatgories.add(cl.Category__r.Label__c);
				}
			}
		}
		return result;
	}

	/***************************************************************************************
    @description: This class used for return all category, related custom link and 
	* collapsible section name based on selected location.
    @author: Keste Dev
    @date: 04 Sep, 2019
    ***************************************************************************************/
	public class CategoryWrapper {
		@AuraEnabled
		public List<String> colapsedCatgories;
		@AuraEnabled
		public List<CategoryDetailWrapper> allCatgories;

		public CategoryWrapper() {
			colapsedCatgories = new List<String>();
			allCatgories = new List<CategoryDetailWrapper>();
		}
	}

	/***************************************************************************************
    @description: This class used for return category and it's related custom link 
    @author: Keste Dev
    @date: 04 Sep, 2019
    ***************************************************************************************/
	public class CategoryDetailWrapper {
		@AuraEnabled
		public String name;
		@AuraEnabled
		public List<Custom_Link__c> links;

		public CategoryDetailWrapper(String name) {
			this.name = name;
			this.links = new List<Custom_Link__c>();
		}
	}
}