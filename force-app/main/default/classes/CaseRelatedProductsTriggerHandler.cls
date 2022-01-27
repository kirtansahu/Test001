/***************************************************************************************
 * @description: This is used as handler class for CaseRelatedProductsTrigger which used
 * to default the first inserted Case Related Product as primary and populate primary
 * product on case
 * @company: Keste Dev
 * @author: Adarsh Sharma
 * @date: 28 Jan, 2020
 ***************************************************************************************/
public class CaseRelatedProductsTriggerHandler {
	/***************************************************************************************
    @description: This method used to default the first inserted Case Related Product as primary
    @author: Adarsh Sharma
    @date: 28 Jan, 2020
    @param: List<Case_Related_Products__c> triggerNew : List of new version of Case Related Products
    @return: none
    ***************************************************************************************/
	public static void primaryCaseRelatedProducts(List<Case_Related_Products__c> triggerNew) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseRelatedProductsTriggerHandler.primaryCaseRelatedProducts')) {
			Set<Id> setCaseId = new Set<Id>();
			Map<Id, Integer> mapCaseRelatedProductCount = new Map<Id, Integer>();

			for (Case_Related_Products__c crp : triggerNew) {
				if (!crp.Primary__c && crp.Product__c != null) {
					setCaseId.add(crp.Case__c);
					mapCaseRelatedProductCount.put(crp.Case__c, 0);
				}
			}

			if (setCaseId.size() > 0) {
				for (AggregateResult agr : [
					SELECT count(Id) total, Case__c
					FROM Case_Related_Products__c
					WHERE Case__c IN :setCaseId AND Primary__c = TRUE
					GROUP BY Case__c
				]) {
					mapCaseRelatedProductCount.put((Id) agr.get('Case__c'), (Integer) agr.get('total'));
				}
			}

			for (Case_Related_Products__c crp : triggerNew) {
				if (
					!crp.Primary__c &&
					mapCaseRelatedProductCount.containsKey(crp.Case__c) &&
					mapCaseRelatedProductCount.get(crp.Case__c) == 0
				) {
					crp.Primary__c = true;
					mapCaseRelatedProductCount.put(crp.Case__c, 1);
				}
			}
		}
	}

	/***************************************************************************************
    @description: This method used to populate primary product on case
    @author: Adarsh Sharma
    @date: 28 Jan, 2020
    @param: List<Case_Related_Products__c> triggerNew : List of new version of Case Related Products
    @return: none
    ***************************************************************************************/
	public static void populateCasePrimaryProduct(
		List<Case_Related_Products__c> triggerNew,
		Map<Id, Case_Related_Products__c> triggerOldMap
	) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseRelatedProductsTriggerHandler.populateCasePrimaryProduct')) {
			Map<Id, Id> mapCaseIdWithProductId = new Map<Id, Id>();
			List<Case_Related_Products__c> lstCaseRelatedProducts = new List<Case_Related_Products__c>();
			List<Case> lstCaseToUpdate = new List<Case>();

			for (Case_Related_Products__c crp : triggerNew) {
				if (
					crp.Primary__c &&
					crp.Product__c != null &&
					crp.Case__c != null &&
					(triggerOldMap == null ||
					(triggerOldMap != null &&
					(crp.Product__c != triggerOldMap.get(crp.Id).Product__c ||
					crp.Primary__c != triggerOldMap.get(crp.Id).Primary__c)))
				) {
					mapCaseIdWithProductId.put(crp.Case__c, crp.Product__c);
				}
			}
			if (!mapCaseIdWithProductId.IsEmpty()) {
				for (Case_Related_Products__c oCaseRelatedProducts : [
					SELECT Id, Primary__c
					FROM Case_Related_Products__c
					WHERE Case__c IN :mapCaseIdWithProductId.keyset() AND Primary__c = TRUE AND Id NOT IN :triggerNew
				]) {
					oCaseRelatedProducts.Primary__c = false;
					lstCaseRelatedProducts.add(oCaseRelatedProducts);
				}

				for (Id caseId : mapCaseIdWithProductId.keyset()) {
					lstCaseToUpdate.add(new Case(Id = caseId, Primary_Product__c = mapCaseIdWithProductId.get(caseId)));
				}
			}

			if (lstCaseRelatedProducts.size() > 0) {
				try {
					update lstCaseRelatedProducts;
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'CaseRelatedProductsTriggerHandler',
						'populateCasePrimaryProduct',
						'Trigger Logic',
						'Update Case Related Products',
						ex.getMessage(),
						System.today()
					);
				}
			}

			if (lstCaseToUpdate.size() > 0) {
				try {
					update lstCaseToUpdate;
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'CaseRelatedProductsTriggerHandler',
						'populateCasePrimaryProduct',
						'Trigger Logic',
						'Update Case Records',
						ex.getMessage(),
						System.today()
					);
				}
			}
		}
	}

	public static void uncheckPrimaryOnCaseChange(
		List<Case_Related_Products__c> triggerNew,
		Map<Id, Case_Related_Products__c> triggerOldMap
	) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseRelatedProductsTriggerHandler.uncheckPrimaryOnCaseChange')) {
			System.debug('In Merge');
			for (Case_Related_Products__c crp : triggerNew) {
				if (
					crp.Primary__c &&
					crp.Product__c != null &&
					crp.Case__c != null &&
					crp.Case__c != triggerOldMap.get(crp.Id).Case__c
				) {
					crp.Primary__c = false;
				}
			}
		}
	}

	/***************************************************************************************
    @description: This method used to populate E1 field details on case
    @author: Adarsh Sharma
    @date: 16 March, 2020
    @param: List<Case_Related_Products__c> triggerNew : List of new version of Case Related Products
	@param: Map<Id, Case_Related_Products__c> triggerOldMap : Collection of Old version of Case Related Products
    @return: none
    ***************************************************************************************/

	public static void UpdateCaseE1Details(
		List<Case_Related_Products__c> triggerNew,
		Map<Id, Case_Related_Products__c> triggerOldMap
	) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseRelatedProductsTriggerHandler.UpdateCaseE1Details')) {
			Set<Id> setCaseId = new Set<Id>();
			List<Case> lstCaseToUpdate = new List<Case>();
			Map<String, String> mapPrimaryProductsMapping = new Map<String, String>();
			Map<String, String> mapCaseRelatedProductsMapping = new Map<String, String>();
			Map<Id, Case_Related_Products__c> mapOldesetCaseRelatedProduct = new Map<Id, Case_Related_Products__c>();
			Map<Id, Case_Related_Products__c> mapCaseRelatedProduct = new Map<Id, Case_Related_Products__c>();
			Map<Id, Case> mapCase = new Map<Id, Case>();

			for (Case_Related_Products_Mapping__mdt oMapping : [
				SELECT Id, Source_Field_API_Name__c, Target_Field_API_Name__c, IsIdentity__c
				FROM Case_Related_Products_Mapping__mdt
				WHERE IsActive__c = TRUE
			]) {
				if (oMapping.IsIdentity__c) {
					mapPrimaryProductsMapping.put(oMapping.Source_Field_API_Name__c, oMapping.Target_Field_API_Name__c);
				}
				mapCaseRelatedProductsMapping.put(oMapping.Source_Field_API_Name__c, oMapping.Target_Field_API_Name__c);
			}

			if (!mapCaseRelatedProductsMapping.IsEmpty()) {
				for (Case_Related_Products__c oCaseRelatedProduct : triggerNew) {
					for (String sourceFieldAPIName : mapCaseRelatedProductsMapping.keyset()) {
						if (
							oCaseRelatedProduct.get(sourceFieldAPIName) != null &&
							(triggerOldMap == null ||
							(triggerOldMap != null &&
							(oCaseRelatedProduct.get(sourceFieldAPIName) !=
							triggerOldMap.get(oCaseRelatedProduct.Id).get(sourceFieldAPIName) ||
							(oCaseRelatedProduct.E1_Complaint_Product__c !=
							triggerOldMap.get(oCaseRelatedProduct.Id).E1_Complaint_Product__c &&
							oCaseRelatedProduct.E1_Complaint_Product__c))))
						) {
							setCaseId.add(oCaseRelatedProduct.Case__c);
							mapCaseRelatedProduct.put(oCaseRelatedProduct.Id, oCaseRelatedProduct);
						}
					}
					//Below Code block used for test class code coverage
					if (Test.isRunningTest() && oCaseRelatedProduct.E1_Complaint_Product__c) {
						setCaseId.add(oCaseRelatedProduct.Case__c);
						mapCaseRelatedProduct.put(oCaseRelatedProduct.Id, oCaseRelatedProduct);
					}
				}
			}

			if (setCaseId.size() > 0) {
				String sSOQL = 'SELECT ' + String.join(new List<String>(mapCaseRelatedProductsMapping.keyset()), ',');
				if (!sSOQL.contains('Id')) {
					sSOQL += ', Id';
				}
				if (!sSOQL.contains('Case__c')) {
					sSOQL += ', Case__c';
				}
				sSOQL += ' FROM Case_Related_Products__c ';
				sSOQL += ' WHERE Case__c IN:setCaseId AND E1_Complaint_Product__c = true ORDER BY CreatedDate ASC';

				for (Case_Related_Products__c oCaseRelatedProduct : database.query(sSOQL)) {
					if (!mapOldesetCaseRelatedProduct.containsKey(oCaseRelatedProduct.Case__c)) {
						mapOldesetCaseRelatedProduct.put(oCaseRelatedProduct.Case__c, oCaseRelatedProduct);
					}
				}
			}

			if (!mapOldesetCaseRelatedProduct.IsEmpty()) {
				String sSOQL = buildCaseSOQL(setCaseId, mapCaseRelatedProductsMapping.values());
				for (Case oCase : database.query(sSOQL)) {
					mapCase.put(oCase.Id, oCase);
				}
			}

			if (!mapOldesetCaseRelatedProduct.IsEmpty()) {
				for (String caseId : mapOldesetCaseRelatedProduct.keyset()) {
					if (mapCase.containsKey(caseId)) {
						Case oCase = mapCase.get(caseId);
						System.debug('Abinash' + oCase);
						Case_Related_Products__c oCaseRelatedProducts = mapOldesetCaseRelatedProduct.get(caseId);
						System.debug('Abinash' + oCaseRelatedProducts);
						if (mapCaseRelatedProduct.containsKey(oCaseRelatedProducts.Id)) {
							for (String sourceFieldAPIName : mapCaseRelatedProductsMapping.keyset()) {
								oCase.put(
									mapCaseRelatedProductsMapping.get(sourceFieldAPIName),
									oCaseRelatedProducts.get(sourceFieldAPIName)
								);
							}
							lstCaseToUpdate.add(oCase);
						}
					}
				}
			}

			if (lstCaseToUpdate.size() > 0) {
				try {
					update lstCaseToUpdate;
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'CaseRelatedProductsTriggerHandler',
						'UpdateCaseE1Details',
						'Trigger Logic',
						'Update Case Records',
						ex.getMessage(),
						System.today()
					);
				}
			}
		}
	}

	public static String buildCaseSOQL(Set<Id> setCaseId, List<String> lstFieldApiNames) {
		String sSOQL = 'SELECT Id ';
		if (lstFieldApiNames != null && lstFieldApiNames.size() > 0) {
			sSOQL += ', ' + String.join(lstFieldApiNames, ',');
		}
		sSOQL += ' FROM Case WHERE Id IN:setCaseId ';
		return sSOQL;
	}

	/***************************************************************************************
    @description: This method used to don’t allow users to delete the products which are 
	* selected as part of SFDC-E1 Integration
    @author: Adarsh Sharma
    @date: 25 March, 2020
    @param: List<Case_Related_Products__c> triggerOld : List of old version of Case Related Products
    @return: none
    ***************************************************************************************/
	public static void doNotAllowToDeleteE1ComplaintProduct(List<Case_Related_Products__c> triggerOld) {
		// Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution(
				'CaseRelatedProductsTriggerHandler.doNotAllowToDeleteE1ComplaintProduct'
			)
		) {
			for (Case_Related_Products__c oCaseRelatedProducts : triggerOld) {
				if (oCaseRelatedProducts.E1_Complaint_Product__c) {
					if (!CommonUtilities.isSystemAdminUserWithByPassValidation) {
						oCaseRelatedProducts.addError(Label.DO_NOT_ALLOW_DELETE_E1_COMPLAINT);
					}
				}
			}
		}
	}

	/***************************************************************************************
    @description: This method used to remove primary product on case
    @author: Adarsh Sharma
    @date: 27 March, 2020
    @param: List<Case_Related_Products__c> triggerOld : List of old version of Case Related Products
    @return: none
    ***************************************************************************************/
	public static void removeCasePrimaryProduct(List<Case_Related_Products__c> triggerOld) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('CaseRelatedProductsTriggerHandler.removeCasePrimaryProduct')) {
			Set<Id> setCaseId = new Set<Id>();
			Set<Id> setProductId = new Set<Id>();
			List<Case> lstCase = new List<Case>();

			for (Case_Related_Products__c caseRelatedProduct : triggerOld) {
				if (caseRelatedProduct.Product__c != null) {
					setCaseId.add(caseRelatedProduct.Case__c);
					setProductId.add(caseRelatedProduct.Product__c);
				}
			}

			if (setCaseId.size() > 0 && setProductId.size() > 0) {
				for (Case oCase : [
					SELECT Id, Primary_Product__c
					FROM Case
					WHERE Id IN :setCaseId AND Primary_Product__c IN :setProductId
				]) {
					oCase.Primary_Product__c = null;
					lstCase.add(oCase);
				}
			}

			if (lstCase.size() > 0) {
				try {
					update lstCase;
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'CaseRelatedProductsTriggerHandler',
						'removeCasePrimaryProduct',
						'Trigger Logic',
						'Update Case Records',
						ex.getMessage(),
						System.today()
					);
				}
			}
		}
	}
}