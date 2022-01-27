public without sharing class KMUserDetailTabCtrl {
	@AuraEnabled
	public static User getUserDetails() {
		return [
			SELECT
				Id,
				Name,
				FirstName,
				LastName,
				Email,
				Phone,
				Title,
				LanguageLocaleKey,
				PO_Ref_Number__c,
				Order_Form_State__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];
	}

	@AuraEnabled
	public static void saveUserDetails(User userData) {
		update userData;
	}
}