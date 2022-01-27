// ===========================================================================
//  Object	: CloneOpportunityController
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Lightning Component Controller to Clone Opportunity.
// ===========================================================================
public class CloneOpportunityController {
	// Method Name: getOpportunityRecord
	// Author: Adarsh Sharma
	// Description: Method which will return Opportunity record details
	// Parameter 1: Id recordId - Opportunity record which needs to be cloned
	// Return: Opportunity - Current opportunity record
	@AuraEnabled
	public static Opportunity getOpportunityRecord(Id recordId) {
		Opportunity opp = new Opportunity();
		String sSOQL = CommonUtilities.prepareQuery('Opportunity', null, false) + ' WHERE Id = \'' + recordId + '\'';
		for (Opportunity sourceOpp : Database.query(sSOQL)) {
			opp = sourceOpp;
			opp.Siebel_Row_Id__c = null;
			opp.OwnerId = null;
		}
		return opp;
	}

	// Method Name: fetchPageLayoutFieldsAndSection
	// Author: Adarsh Sharma
	// Description: Method which will used to get all fields and sections from page layout
	// Parameter 1: Opportunity opp - Current Opportunity record which needs to be cloned
	// Return: List<LayoutSection> - Collection of layout section and fields
	@AuraEnabled
	public static List<LayoutSection> fetchPageLayoutFieldsAndSection(Opportunity opp) {
		try {
			List<LayoutSection> lstLayoutSection = new List<LayoutSection>();
			Id describeRecordTypeId = PageLayoutDescriberHelper.getDefaultRecordType(opp);
			lstLayoutSection = PageLayoutDescriberHelper.describeSectionWithFields(describeRecordTypeId, 'Opportunity');
			return lstLayoutSection;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	// Method Name: getOpportunityChildRecordInformation
	// Author: Adarsh Sharma
	// Description: Method which will return Opportunity child record details
	// Parameter 1: Id recordId - Opportunity record which needs to be cloned
	// Return: OpportunityChildCountWrapper - Current opportunity child records details
	@AuraEnabled
	public static OpportunityChildCountWrapper getOpportunityChildRecordInformation(Id recordId) {
		OpportunityChildCountWrapper oppChildCountWrapperObj = new OpportunityChildCountWrapper();
		for (OpportunityLineItem oppLineItemObj : [
			SELECT Id
			FROM OpportunityLineItem
			WHERE OpportunityId = :recordId
			LIMIT 1
		]) {
			oppChildCountWrapperObj.hasOpportunityProduct = true;
		}
		for (Opportunity_Product_Line__c oppProductLineobj : [
			SELECT Id
			FROM Opportunity_Product_Line__c
			WHERE Opportunity__c = :recordId
			LIMIT 1
		]) {
			oppChildCountWrapperObj.hasOpporunityProductLine = true;
		}
		for (OpportunityTeamMember oppTeamMemberobj : [
			SELECT Id
			FROM OpportunityTeamMember
			WHERE OpportunityId = :recordId
			LIMIT 1
		]) {
			oppChildCountWrapperObj.hasOpportunityTeamMember = true;
		}
		return oppChildCountWrapperObj;
	}

	// Method Name: cloneOpportunityAndReturnCloneRecordId
	// Description: Method which will clone an opportunity
	// Parameter 1: opp - Opportunity record which needs to be cloned
	// Parameter 2: sourceOppRecordId - Id of the source opportunity, we had to pass it expicitly
	//                                  since it's not coming in the opp param which has page-layout field values
	// Return: String - Clone opportunity record Id
	@AuraEnabled
	public static String cloneOpportunityAndReturnCloneRecordId(Opportunity opp, String sourceOppRecordId) {
		try {
			String cloneOppId;
			opp.OwnerId = UserInfo.getUserId();
			Set<String> setAutoNumberFields = new Set<String>();
			Set<String> lstPopulatedFields = opp.getPopulatedFieldsAsMap().keySet();
			Map<String, Schema.SObjectField> mapOpportunityFields = Schema.SObjectType.Opportunity.fields.getMap();

			//Check for the required fields for the opportunity sObject
			// if they are not the part of the populated fields then add them in query explicitly
			List<String> lstOpportunityFields = new List<String>();
			for (String fieldName : mapOpportunityFields.keySet()) {
				Schema.DescribeFieldResult desribeResult = mapOpportunityFields.get(fieldName).getDescribe();

				// Check if field is required and not was populated from the page-layout
				if (
					((desribeResult.isCreateable() && !desribeResult.isNillable()) ||
					(desribeResult.isAccessible() && !desribeResult.isUpdateable())) &&
					!desribeResult.isAutoNumber() &&
					!desribeResult.isExternalID() &&
					!desribeResult.isDefaultedOnCreate() &&
					!lstPopulatedFields.contains(fieldName.toLowerCase())
				) {
					lstOpportunityFields.add(fieldName.toLowerCase());
				}
				if (desribeResult.isAutoNumber()) {
					setAutoNumberFields.add(fieldName.toLowerCase());
				}
			}

			if (!lstOpportunityFields.contains('currencyisocode')) {
				lstOpportunityFields.add('currencyisocode');
			}

			// Construct dynamic query from the fetched fields
			String queryForOpp =
				'SELECT ' +
				String.join(lstOpportunityFields, ', ') +
				' FROM Opportunity WHERE Id = \'' +
				sourceOppRecordId +
				'\'';
			Opportunity sourceOpp = Database.query(queryForOpp);

			// Deep clone the opportunity
			Opportunity clonedOpp = sourceOpp.clone(false, true, false, false);

			//Pouplate cloned opportunity fields from the record passed in the method parameter
			// Get all the values in fieldName and value map
			Map<String, Object> oppFieldsToValue = opp.getPopulatedFieldsAsMap();
			for (String fieldApiName : oppFieldsToValue.keySet()) {
				if (fieldApiName != 'Id' && !setAutoNumberFields.contains(fieldApiName.toLowerCase())) {
					clonedOpp.put(fieldApiName, oppFieldsToValue.get(fieldApiName));
				}
			}

			// Insert the cloned opportunity record
			if (Schema.SObjectType.Opportunity.isCreateable()) {
				insert clonedOpp;
				cloneOppId = clonedOpp.Id;
			}
			return cloneOppId;
		} catch (DMLException dmlex) {
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'cloneOpportunity',
				'Lightning Controller',
				'Clone Opportunity Logic',
				dmlex.getDMLMessage(0),
				System.today()
			);
			throw new AuraHandledException(dmlex.getDMLMessage(0));
		} catch (Exception e) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'cloneOpportunity',
				'Lightning Controller',
				'Clone Opportunity Logic',
				e.getMessage(),
				System.today()
			);
			throw new AuraHandledException(e.getMessage());
		}
	}

	// Method Name: getOpportunityProducts
	// Description: Method which will fetch all opportunity line item record in json format
	// Parameter 1: cloneOppId - Cloned Opportunity record Id
	// Parameter 2: sourceOppRecordId - Id of the source opportunity, we had to pass it expicitly
	//                                  since it's not coming in the opp param which has page-layout field values
	// Return: String - Collection of opportunity line item in json format
	@AuraEnabled
	public static String getOpportunityProducts(Id sourceOppRecordId, Id cloneOppId) {
		try {
			// Again, will query the opportunity line item fields
			Map<String, Clone_Opportunity_Setting__mdt> mapOpportunityProductFields = new Map<String, Clone_Opportunity_Setting__mdt>();
			Map<String, Schema.SObjectField> mapOpportunityProductDescribedFields = Schema.SObjectType.OpportunityLineItem.fields.getMap();
			List<Column> lstColumns = new List<Column>();

			//Check if there are any fields which are provided in the custom metadata
			// and use them instead of hard-coded fields
			Boolean isFieldsConfigured = false;
			for (Clone_Opportunity_Setting__mdt cos : CloneOpportunityController.getSetting()) {
				if (mapOpportunityProductDescribedFields.containsKey(cos.MasterLabel)) {
					Schema.DescribeFieldResult desribeResult = mapOpportunityProductDescribedFields.get(cos.MasterLabel)
						.getDescribe();
					if (desribeResult.isCreateable()) {
						mapOpportunityProductFields.put(cos.MasterLabel, cos);
					}
					isFieldsConfigured = true;
				}
			}

			// Compulsary fields on the layout
			// User doesn't have ability to remove them however they can make these fields non-editable
			if (mapOpportunityProductFields.containsKey('Product2Id')) {
				Clone_Opportunity_Setting__mdt setting = mapOpportunityProductFields.get('Product2Id');
				lstColumns.add(
					new Column(
						'Product',
						'Product2.Name',
						'text',
						setting.Editable__c,
						setting.Sortable__c,
						setting.Required__c
					)
				);
			} else {
				lstColumns.add(new Column('Product', 'Product2.Name', 'text', false, false, true));
			}

			if (mapOpportunityProductFields.containsKey('Quantity')) {
				Clone_Opportunity_Setting__mdt setting = mapOpportunityProductFields.get('Quantity');
				lstColumns.add(
					new Column(
						'Quantity',
						'Quantity',
						'number',
						setting.Editable__c,
						setting.Sortable__c,
						setting.Required__c
					)
				);
			} else {
				lstColumns.add(new Column('Quantity', 'Quantity', 'number', true, false, true));
			}

			if (mapOpportunityProductFields.containsKey('UnitPrice')) {
				Clone_Opportunity_Setting__mdt setting = mapOpportunityProductFields.get('UnitPrice');
				lstColumns.add(
					new Column(
						'Sales Price',
						'UnitPrice',
						'currency',
						setting.Editable__c,
						setting.Sortable__c,
						setting.Required__c
					)
				);
			} else {
				lstColumns.add(new Column('Sales Price', 'UnitPrice', 'currency', true, false, true));
			}
			if (mapOpportunityProductFields.containsKey('ServiceDate')) {
				Clone_Opportunity_Setting__mdt setting = mapOpportunityProductFields.get('ServiceDate');
				lstColumns.add(
					new Column(
						'Service Date',
						'ServiceDate',
						'date-local',
						setting.Editable__c,
						setting.Sortable__c,
						setting.Required__c
					)
				);
			} else {
				lstColumns.add(new Column('Date', 'ServiceDate', 'date-local', true, false, false));
			}
			if (mapOpportunityProductFields.containsKey('HasQuantitySchedule')) {
				Clone_Opportunity_Setting__mdt setting = mapOpportunityProductFields.get('HasQuantitySchedule');
				lstColumns.add(
					new Column(
						'Has Quantity Schedule',
						'HasQuantitySchedule',
						'boolean',
						setting.Editable__c,
						setting.Sortable__c,
						setting.Required__c
					)
				);
			} else {
				lstColumns.add(
					new Column('Has Quantity Schedule', 'HasQuantitySchedule', 'boolean', false, false, false)
				);
			}
			if (!isFieldsConfigured) {
				lstColumns.add(new Column('Line Description', 'Description', 'text', true, false, false));
			} else {
				for (String fieldName : mapOpportunityProductFields.keySet()) {
					if (mapOpportunityProductDescribedFields.containsKey(fieldName)) {
						Schema.DescribeFieldResult desribeResult = mapOpportunityProductDescribedFields.get(fieldName)
							.getDescribe();
						if (desribeResult.isCreateable()) {
							lstColumns.add(new Column(desribeResult, mapOpportunityProductFields.get(fieldName)));
						}
					}
				}
			}

			List<String> fieldsInQuery = new List<String>();
			for (Column c : lstColumns) {
				if (!fieldsInQuery.contains(c.fieldName.toLowerCase())) {
					fieldsInQuery.add(c.fieldName.toLowerCase());
				}
			}
			// Construct dynamic query from the fetched fields
			String queryForOppLineItem =
				'SELECT ' +
				String.join(fieldsInQuery, ', ') +
				' FROM OpportunityLineItem WHERE OpportunityId = \'' +
				sourceOppRecordId +
				'\'';

			List<OpportunityLineItem> sourceOppLineItems = Database.query(queryForOppLineItem);

			String dataColumnJson =
				'{ "clonedOppId": "' +
				cloneOppId +
				'", "columns": ' +
				JSON.serialize(lstColumns) +
				', "data":' +
				JSON.serialize(sourceOppLineItems) +
				'}';
			return dataColumnJson;
		} catch (DMLException dmlex) {
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'getOpportunityProducts',
				'Lightning Controller',
				'Get Opportunity Product Logic',
				dmlex.getDMLMessage(0),
				System.today()
			);
			throw new AuraHandledException(dmlex.getDMLMessage(0));
		} catch (Exception e) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'getOpportunityProducts',
				'Lightning Controller',
				'Get Opportunity Product Logic',
				e.getMessage(),
				System.today()
			);
			throw new AuraHandledException(e.getMessage());
		}
	}

	// Method Name: getOpportunityProductLine
	// Description: Method which will fetch all opportunity product line item record in json format
	// Parameter 1: cloneOppId - Cloned Opportunity record Id
	// Parameter 2: sourceOppRecordId - Id of the source opportunity, we had to pass it expicitly
	//                                  since it's not coming in the opp param which has page-layout field values
	// Return: String - Collection of opportunity product line item line item in json format
	@AuraEnabled
	public static String getOpportunityProductLine(Id sourceOppRecordId, Id cloneOppId) {
		try {
			Map<String, Schema.SObjectField> mapOpportunityProductLineDescribedFields = Schema.SObjectType.Opportunity_Product_Line__c.fields.getMap();
			List<Column> lstColumns = new List<Column>();

			lstColumns.add(new Column('Opportunity', 'Opportunity__c', 'text', false, false, true));
			lstColumns.add(new Column('Product Line', 'Product_Line__c', 'text', false, false, true));

			for (String fieldName : mapOpportunityProductLineDescribedFields.keyset()) {
				Schema.DescribeFieldResult desribeResult = mapOpportunityProductLineDescribedFields.get(fieldName)
					.getDescribe();
				if (
					desribeResult.isCreateable() &&
					desribeResult.getName() != 'Opportunity__c' &&
					desribeResult.getName() != 'Product_Line__c'
				) {
					lstColumns.add(
						new Column(
							desribeResult.getLabel(),
							desribeResult.getName(),
							String.valueOf(desribeResult.getType()).toLowerCase(),
							desribeResult.isUpdateable(),
							desribeResult.isSortable(),
							false
						)
					);
				}
			}

			List<String> fieldsInQuery = new List<String>();
			for (Column c : lstColumns) {
				if (!fieldsInQuery.contains(c.fieldName.toLowerCase())) {
					fieldsInQuery.add(c.fieldName.toLowerCase());
				}
			}

			fieldsInQuery.add('Opportunity__r.Name');
			fieldsInQuery.add('Product_Line__r.Name');

			// Construct dynamic query from the fetched fields
			String queryForOppProductLine =
				'SELECT ' +
				String.join(fieldsInQuery, ', ') +
				' FROM Opportunity_Product_Line__c WHERE Opportunity__c = \'' +
				sourceOppRecordId +
				'\'';

			List<Opportunity_Product_Line__c> sourceOppProductLines = Database.query(queryForOppProductLine);

			String dataColumnJson =
				'{ "clonedOppId": "' +
				cloneOppId +
				'", "columns": ' +
				JSON.serialize(lstColumns) +
				', "data":' +
				JSON.serialize(sourceOppProductLines) +
				'}';

			return dataColumnJson;
		} catch (DMLException dmlex) {
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'getOpportunityProductLine',
				'Lightning Controller',
				'Clone Opportunity Product Line Logic',
				dmlex.getDMLMessage(0),
				System.today()
			);
			throw new AuraHandledException(dmlex.getDMLMessage(0));
		} catch (Exception e) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'getOpportunityProductLine',
				'Lightning Controller',
				'Clone Opportunity Product Line Logic',
				e.getMessage(),
				System.today()
			);
			throw new AuraHandledException(e.getMessage());
		}
	}

	// Method Name: getOpportunityProductLine
	// Author: Adarsh Sharma
	// Description: Method which will fetch all opportunity team member record in json format
	// Parameter 1: cloneOppId - Cloned Opportunity record Id
	// Parameter 2: sourceOppRecordId - Id of the source opportunity, we had to pass it expicitly
	//                                  since it's not coming in the opp param which has page-layout field values
	// Return: String - Collection of opportunity team member in json format
	@AuraEnabled
	public static String getOpportunityTeamMembers(Id sourceOppRecordId, Id cloneOppId) {
		try {
			Map<String, Schema.SObjectField> mapOpportunityTeamMemberDescribedFields = Schema.SObjectType.OpportunityTeamMember.fields.getMap();
			List<Column> lstColumns = new List<Column>();

			lstColumns.add(new Column('Opportunity', 'OpportunityId', 'text', false, false, true));
			lstColumns.add(new Column('User', 'UserId', 'text', false, false, true));

			for (String fieldName : mapOpportunityTeamMemberDescribedFields.keyset()) {
				Schema.DescribeFieldResult desribeResult = mapOpportunityTeamMemberDescribedFields.get(fieldName)
					.getDescribe();
				if (
					desribeResult.isCreateable() &&
					desribeResult.getName() != 'OpportunityId' &&
					desribeResult.getName() != 'UserId'
				) {
					lstColumns.add(
						new Column(
							desribeResult.getLabel(),
							desribeResult.getName(),
							String.valueOf(desribeResult.getType()).toLowerCase(),
							desribeResult.isUpdateable(),
							desribeResult.isSortable(),
							false
						)
					);
				}
			}

			List<String> fieldsInQuery = new List<String>();
			for (Column c : lstColumns) {
				if (!fieldsInQuery.contains(c.fieldName.toLowerCase())) {
					fieldsInQuery.add(c.fieldName.toLowerCase());
				}
			}

			fieldsInQuery.add('Opportunity.Name');
			fieldsInQuery.add('User.Name');

			// Construct dynamic query from the fetched fields
			String queryForOppTeamMember =
				'SELECT ' +
				String.join(fieldsInQuery, ', ') +
				' FROM OpportunityTeamMember WHERE OpportunityId = \'' +
				sourceOppRecordId +
				'\'';

			List<OpportunityTeamMember> sourceOppTeamMembers = Database.query(queryForOppTeamMember);

			String dataColumnJson =
				'{ "clonedOppId": "' +
				cloneOppId +
				'", "columns": ' +
				JSON.serialize(lstColumns) +
				', "data":' +
				JSON.serialize(sourceOppTeamMembers) +
				'}';

			return dataColumnJson;
		} catch (DMLException dmlex) {
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'getOpportunityTeamMembers',
				'Lightning Controller',
				'Clone Opportunity Opportunity Team Member Logic',
				dmlex.getDMLMessage(0),
				System.today()
			);
			throw new AuraHandledException(dmlex.getDMLMessage(0));
		} catch (Exception e) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'getOpportunityTeamMembers',
				'Lightning Controller',
				'Clone Opportunity Opportunity Team Member Logic',
				e.getMessage(),
				System.today()
			);
			throw new AuraHandledException(e.getMessage());
		}
	}

	// Method Name: cloneOpportunityAndReturnProducts
	// Author: Abinash panigrahi
	// Description: Method which will clone an opportunity with it's products, product line and opportunity team member
	// Parameter 1 : sourceOppRecordId - Record id of the source opportunity
	// Parameter 2 : clonedOppRecordId - Id of the target opportunity record
	// Parameter 3 : lstSourceLineItemIds - Id of line items from the source opportunity
	// Parameter 4 : lstLineItemsChanges - List of OpportunityLineItem object which has updated values
	// Parameter 5 : lstProdLineItemsChanges - List of Opportunity_Product_Line__c object which has updated values
	// Parameter 6 : lstSourceOppTeamMemberIds - Id of Opportunity Team Member from Source Opportunity
	// Parameter 7 : lstOpportunityTeamMemberChanges - List of Opportunity Team Member object which has updated values
	// Return: Id of Cloned Opportunity record
	@AuraEnabled
	public static Id cloneOpportunityLineItems(
		Id sourceOppRecordId,
		Id clonedOppRecordId,
		List<Id> lstSourceLineItemIds,
		List<OpportunityLineItem> lstLineItemsChanges,
		List<Id> lstSourceProdLineItemIds,
		List<Opportunity_Product_Line__c> lstProdLineItemsChanges,
		List<Id> lstSourceOppTeamMemberIds,
		List<OpportunityTeamMember> lstOpportunityTeamMemberChanges
	) {
		try {
			// Query opportunity line items from the source opportunity and
			// use the fields which has been configured at custom metadata level
			List<String> lstFieldsInQuery = new List<String>{
				'product2id',
				'quantity',
				'pricebookentryid',
				'unitprice'
			};

			// Check the custom metadata level if fields are provided there
			Map<String, Clone_Opportunity_Setting__mdt> mapOpportunityProductFields = new Map<String, Clone_Opportunity_Setting__mdt>();
			Map<String, Schema.SObjectField> mapOpportunityProductDescribedFields = Schema.SObjectType.OpportunityLineItem.fields.getMap();

			Boolean isFieldsConfigured = false;
			for (Clone_Opportunity_Setting__mdt cos : CloneOpportunityController.getSetting()) {
				if (mapOpportunityProductDescribedFields.containsKey(cos.MasterLabel.toLowerCase())) {
					Schema.DescribeFieldResult desribeResult = mapOpportunityProductDescribedFields.get(
							cos.MasterLabel.toLowerCase()
						)
						.getDescribe();
					if (
						desribeResult.isCreateable() &&
						!desribeResult.isExternalID() &&
						(cos.Cloneable__c || cos.Editable__c)
					) {
						mapOpportunityProductFields.put(cos.MasterLabel.toLowerCase(), cos);
					}
					isFieldsConfigured = true;
				}
			}
			//If no fields are not configured then use the hard-coded fields
			if (!isFieldsConfigured) {
				for (String fieldName : mapOpportunityProductDescribedFields.keySet()) {
					Schema.DescribeFieldResult desribeResult = mapOpportunityProductDescribedFields.get(fieldName)
						.getDescribe();
					// Add to the query field list
					if (
						desribeResult.isCreateable() &&
						!lstFieldsInQuery.contains(fieldName.toLowerCase()) &&
						fieldName.toLowerCase() != 'totalprice' &&
						!desribeResult.isExternalID()
					) {
						lstFieldsInQuery.add(fieldName.toLowerCase());
					}
				}
			} else {
				for (String fieldName : mapOpportunityProductFields.keySet()) {
					if (!lstFieldsInQuery.contains(fieldName)) {
						if (fieldName != 'totalprice') {
							lstFieldsInQuery.add(fieldName);
						}
					}
				}
				if (!(lstFieldsInQuery.contains('unitprice') || lstFieldsInQuery.contains('totalprice'))) {
					lstFieldsInQuery.add('unitprice');
				}
			}
			//Check for the required fields on opportunity line item object
			// if they are not the part of the lstFieldsInQuery then add them in query explicitly
			for (String fieldName : mapOpportunityProductDescribedFields.keySet()) {
				Schema.DescribeFieldResult desribeResult = mapOpportunityProductDescribedFields.get(fieldName)
					.getDescribe();
				if (
					desribeResult.isCreateable() &&
					!desribeResult.isExternalID() &&
					fieldName.toLowerCase() != 'totalprice' &&
					(!desribeResult.isDefaultedOnCreate() || desribeResult.isUpdateable()) &&
					!lstFieldsInQuery.contains(fieldName.toLowerCase())
				) {
					// Add to the query field list
					lstFieldsInQuery.add(fieldName.toLowerCase());
				}
			}

			Map<Id, OpportunityLineItem> mapUpdatedOppLineItems = new Map<Id, OpportunityLineItem>();
			if (lstLineItemsChanges != null) {
				mapUpdatedOppLineItems.putAll(lstLineItemsChanges);
			}

			//Query all the opportunity line items from the query
			// Construct dynamic query from the fetched fields
			String queryForOppLineItem =
				'SELECT ' +
				String.join(lstFieldsInQuery, ', ') +
				' FROM OpportunityLineItem WHERE Id IN :lstSourceLineItemIds';
			List<OpportunityLineItem> lstSourceOppLineItems = Database.query(queryForOppLineItem);

			List<OpportunityLineItem> lstClonedOpportunityLineItems = new List<OpportunityLineItem>();

			if (lstSourceOppLineItems != null && lstSourceOppLineItems.size() > 0) {
				//Update source opp line items with updated values
				for (OpportunityLineItem sourceOli : lstSourceOppLineItems) {
					//OpportunityLineItem clonedOppLineItem = sourceOli.clone( false, true, false, false );
					OpportunityLineItem clonedOppLineItem = new OpportunityLineItem(
						OpportunityId = clonedOppRecordId,
						Product2Id = sourceOli.Product2Id,
						Quantity = sourceOli.Quantity,
						ServiceDate = sourceOli.ServiceDate,
						UnitPrice = sourceOli.UnitPrice
					);
					//clonedOppLineItem.OpportunityId = clonedOppRecordId;
					if (mapUpdatedOppLineItems.containsKey(sourceOli.Id)) {
						//Find the populated values on the sObject
						Map<String, Object> mapFieldsToValue = mapUpdatedOppLineItems.get(sourceOli.Id)
							.getPopulatedFieldsAsMap();
						for (String fieldName : mapFieldsToValue.keySet()) {
							if (fieldName != 'Id') {
								clonedOppLineItem.put(fieldName, mapFieldsToValue.get(fieldName));
							}
						}
					}
					//Adding to the list
					lstClonedOpportunityLineItems.add(clonedOppLineItem);
				}
			}

			//Clone Opportunity Product Line Items
			Map<String, Schema.SObjectField> mapOpportunityProductLineItemDescribedFields = Schema.SObjectType.Opportunity_Product_Line__c.fields.getMap();
			List<String> lstProdLineFieldsInQuery = new List<String>();

			for (String fieldName : mapOpportunityProductLineItemDescribedFields.keySet()) {
				Schema.DescribeFieldResult desribeResult = mapOpportunityProductLineItemDescribedFields.get(fieldName)
					.getDescribe();
				if (
					desribeResult.isCreateable() &&
					!desribeResult.isExternalID() &&
					(!desribeResult.isDefaultedOnCreate() || desribeResult.isUpdateable()) &&
					!lstProdLineFieldsInQuery.contains(fieldName.toLowerCase())
				) {
					// Add to the query field list
					lstProdLineFieldsInQuery.add(fieldName.toLowerCase());
				}
			}

			String queryForOppProdLineItem =
				'SELECT ' +
				String.join(lstProdLineFieldsInQuery, ', ') +
				' FROM Opportunity_Product_Line__c WHERE Id IN :lstSourceProdLineItemIds';
			List<Opportunity_Product_Line__c> lstSourceOppProdLineItems = Database.query(queryForOppProdLineItem);

			List<Opportunity_Product_Line__c> lstClonedOpportunityProdLineItems = new List<Opportunity_Product_Line__c>();

			Map<Id, Opportunity_Product_Line__c> mapUpdatedOppProdLineItems = new Map<Id, Opportunity_Product_Line__c>();
			if (lstProdLineItemsChanges != null) {
				mapUpdatedOppProdLineItems.putAll(lstProdLineItemsChanges);
			}

			if (lstSourceOppProdLineItems != null && lstSourceOppProdLineItems.size() > 0) {
				for (Opportunity_Product_Line__c sourceOli : lstSourceOppProdLineItems) {
					Opportunity_Product_Line__c clonedOppLineItem = sourceOli.clone(false, true, false, false);
					clonedOppLineItem.Opportunity__c = clonedOppRecordId;
					if (mapUpdatedOppProdLineItems.containsKey(sourceOli.Id)) {
						Map<String, Object> mapFieldsToValue = mapUpdatedOppProdLineItems.get(sourceOli.Id)
							.getPopulatedFieldsAsMap();
						for (String fieldName : mapFieldsToValue.keySet()) {
							if (fieldName != 'Id') {
								clonedOppLineItem.put(fieldName, mapFieldsToValue.get(fieldName));
							}
						}
					}
					lstClonedOpportunityProdLineItems.add(clonedOppLineItem);
				}
			}

			//Clone Opportunity Team Member
			Map<String, Schema.SObjectField> mapOppTeamMemberDescribedFields = Schema.SObjectType.OpportunityTeamMember.fields.getMap();
			List<String> lstOppTeamMemberFieldsInQuery = new List<String>();

			for (String fieldName : mapOppTeamMemberDescribedFields.keySet()) {
				Schema.DescribeFieldResult desribeResult = mapOppTeamMemberDescribedFields.get(fieldName).getDescribe();
				if (
					desribeResult.isCreateable() &&
					!desribeResult.isExternalID() &&
					fieldName.toLowerCase() != 'isprimary__c' &&
					(!desribeResult.isDefaultedOnCreate() || desribeResult.isUpdateable()) &&
					!lstOppTeamMemberFieldsInQuery.contains(fieldName.toLowerCase())
				) {
					// Add to the query field list
					lstOppTeamMemberFieldsInQuery.add(fieldName.toLowerCase());
				}
			}

			Set<Id> setExcludeUserId = new Set<Id>{ UserInfo.getUserId() };
			String queryForOppTeamMember =
				'SELECT ' +
				String.join(lstOppTeamMemberFieldsInQuery, ', ') +
				' FROM OpportunityTeamMember WHERE Id IN :lstSourceOppTeamMemberIds AND UserId Not IN:setExcludeUserId ';
			List<OpportunityTeamMember> lstSourceOppTeamMember = Database.query(queryForOppTeamMember);
			List<OpportunityTeamMember> lstClonedOppTeamMembers = new List<OpportunityTeamMember>();

			Map<Id, OpportunityTeamMember> mapUpdatedOppTeamMember = new Map<Id, OpportunityTeamMember>();
			if (lstOpportunityTeamMemberChanges != null) {
				mapUpdatedOppTeamMember.putAll(lstOpportunityTeamMemberChanges);
			}
			if (lstSourceOppTeamMember != null && lstSourceOppTeamMember.size() > 0) {
				for (OpportunityTeamMember sourceOTM : lstSourceOppTeamMember) {
					OpportunityTeamMember clonedOppTeamMember = sourceOTM.clone(false, true, false, false);
					clonedOppTeamMember.OpportunityId = clonedOppRecordId;
					if (mapUpdatedOppTeamMember.containsKey(sourceOTM.Id)) {
						Map<String, Object> mapFieldsToValue = mapUpdatedOppTeamMember.get(sourceOTM.Id)
							.getPopulatedFieldsAsMap();
						for (String fieldName : mapFieldsToValue.keySet()) {
							if (fieldName != 'Id') {
								clonedOppTeamMember.put(fieldName, mapFieldsToValue.get(fieldName));
							}
						}
					}
					lstClonedOppTeamMembers.add(clonedOppTeamMember);
				}
			}

			if (lstClonedOpportunityProdLineItems.size() > 0) {
				insert lstClonedOpportunityProdLineItems;
			}

			if (lstClonedOpportunityLineItems.size() > 0) {
				insert lstClonedOpportunityLineItems;
			}

			if (lstClonedOppTeamMembers.size() > 0) {
				insert lstClonedOppTeamMembers;
			}

			return clonedOppRecordId;
		} catch (DMLException dmlex) {
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'cloneOpportunityLineItems',
				'Lightning Controller',
				'Clone Opportunity Logic',
				dmlex.getDMLMessage(0),
				System.today()
			);
			throw new AuraHandledException(dmlex.getDMLMessage(0));
		} catch (Exception e) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'CloneOpportunityController',
				'cloneOpportunityLineItems',
				'Lightning Controller',
				'Clone Opportunity Logic',
				e.getMessage(),
				System.today()
			);
			throw new AuraHandledException(e.getMessage());
		}
	}

	// Method Name: getColumnType
	// Author: Abinash panigrahi
	// Description: This method is returning the allowed types for the column
	//              Lightning data table supported types are being retuned based on the Schema.DisplayType enum
	// Parameter 1: fieldType
	// Return: String - columnLightning data table supported types
	public static String getColumnType(Schema.DisplayType fieldType) {
		String columnType = 'text';
		switch on fieldType {
			when STRING, PICKLIST, TEXTAREA, MULTIPICKLIST {
				columnType = 'text';
			}
			when DOUBLE, LONG, INTEGER {
				columnType = 'number';
			}
			when DATE, DATETIME {
				columnType = 'date';
			}
			when ADDRESS {
				columnType = 'location';
			}
			when else {
				columnType = String.valueOf(fieldType).toLowerCase();
			}
		}
		return columnType;
	}

	public static List<Clone_Opportunity_Setting__mdt> getSetting() {
		if (!Test.isRunningTest()) {
			return [
				SELECT MasterLabel, Cloneable__c, Editable__c, Sortable__c, Required__c
				FROM Clone_Opportunity_Setting__mdt
			];
		} else {
			String jsonData =
				'[{"MasterLabel": "UnitPrice", "Cloneable__c": true, "Editable__c": true, "Required__c": true, "Sortable__c": false }, ' +
				' {"MasterLabel": "Quantity", "Cloneable__c": true, "Editable__c": true, "Required__c": true, "Sortable__c": false }, ' +
				' {"MasterLabel": "Product2Id", "Cloneable__c": true, "Editable__c": true, "Required__c": true, "Sortable__c": false }, ' +
				' {"MasterLabel": "Description", "Cloneable__c": false, "Editable__c": true, "Required__c": false, "Sortable__c": false } ' +
				']';
			List<Clone_Opportunity_Setting__mdt> lstSetting = (List<Clone_Opportunity_Setting__mdt>) JSON.deserialize(
				jsonData,
				List<Clone_Opportunity_Setting__mdt>.class
			);
			return lstSetting;
		}
	}

	//Wrapper class for generating the JSON for Lightning:dataTable columns
	public class Column {
		String label;
		String fieldName;
		String type;
		Boolean editable;
		Boolean sortable;
		Boolean required;
		Map<String, String> cellAttributes;

		public Column(Schema.DescribeFieldResult field, Clone_Opportunity_Setting__mdt setting) {
			this.label = field.getLabel();
			this.fieldName = field.getName();
			this.type = getColumnType(field.getType());
			this.editable = setting.Editable__c;
			this.sortable = setting.Sortable__c;
			this.required = setting.Required__c;
			this.cellAttributes = new Map<String, String>{ 'alignment' => 'left' };
		}
		public Column(
			String label,
			String fieldName,
			String type,
			Boolean editable,
			Boolean sortable,
			Boolean required
		) {
			this.label = required ? '*' + label : label;
			this.fieldName = fieldName;
			this.type = type;
			this.editable = editable;
			this.sortable = sortable;
			this.required = required;
			this.cellAttributes = new Map<String, String>{ 'alignment' => 'left' };
		}
	}

	public class OpportunityChildCountWrapper {
		@AuraEnabled
		public boolean hasOpportunityProduct;
		@AuraEnabled
		public boolean hasOpporunityProductLine;
		@AuraEnabled
		public boolean hasOpportunityTeamMember;

		public OpportunityChildCountWrapper() {
			hasOpportunityProduct = false;
			hasOpporunityProductLine = false;
			hasOpportunityTeamMember = false;
		}
	}
}