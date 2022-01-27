/****************************************************************************************************
 * Author Name   : Abinash Panigrahi
 * Class Name    : TerritoryRule_Batch  
 * Created Date  : 29th June 2020
 * Description   : To Setup Object Rule based on Dynamic Condition Items and then assosiated with Territory  
 * Test Class    : TerritoryRuleBatch_Test
****************************************************************************************************
	@comment : This below script is used to execute this batch job immediately.
    Database.executebatch(new TerritoryRule_Batch(), 1);
    @note : Always execute batch job with Batch size equal to 1
****************************************************************************************************/

global class TerritoryRule_Batch implements Database.Batchable<sObject>, Database.Stateful {
	//Class Level Variables
	global Id MAIN_TERRITORY_MODEL;
	global String RULE_OBJECT_TYPE;
	global Integer MAXIMUM_NUMBER_CONDITION;
	global String MAIN_TERRITORY_MODEL_NAME;

	//Instance to be reused in all Batch Iteration
	global List<Territory_Rule__c> ALL_RECORDS = new List<Territory_Rule__c>();
	global Map<String, String> SCHEMA_FIELD_MAPPPING = new Map<String, String>();
	global Map<String, String> OPERATORS_MAPPPING = new Map<String, String>();
	global List<Apex_Log__c> APEX_LOGS = new List<Apex_Log__c>();

	//Custom Exception
	public virtual class CustomException extends Exception {
	}

	//Overide Default Constructor 
	global TerritoryRule_Batch() {
		//Get Custom Metadata Config data -- 'Parent Territory Node'
		//Assumption: Only One Org-Specific record should exist
		Parent_Territory_Node__mdt config = [
			SELECT Id, Territory_Model_Name__c, Rule_Object_Type__c, Maximum_Number_Rule_Condition__c
			FROM Parent_Territory_Node__mdt
			LIMIT 1
		];

		//Fetch Territory Model Record ID & Rule Object Name
		//Consideration: Make sure to populate placeholder value with Name or Label(not DeveloperName)
		MAIN_TERRITORY_MODEL = [SELECT Id FROM Territory2Model WHERE Name = :config.Territory_Model_Name__c LIMIT 1].Id;
		RULE_OBJECT_TYPE = config.Rule_Object_Type__c;
		MAXIMUM_NUMBER_CONDITION = (Integer) config.Maximum_Number_Rule_Condition__c;
		MAIN_TERRITORY_MODEL_NAME = config.Territory_Model_Name__c;

		//Describe Rule Object Fields Label & API Name using Schema Class
		//Use Case: Need to use for Mapping Business provided condition to System defined one
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Map<String, Schema.SObjectField> fieldMap = schemaMap.get(RULE_OBJECT_TYPE).getDescribe().fields.getMap();
		for (Schema.SObjectField sfield : fieldMap.Values()) {
			Schema.Describefieldresult dfield = sfield.getDescribe();
			SCHEMA_FIELD_MAPPPING.put(dfield.getLabel().toLowerCase(), dfield.getname());
		}

		//Make the Operator Value transition from UI to API Name
		//Use Case: Business will provide the values as per what they see on UI
		Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
			.get('ObjectTerritory2AssignmentRuleItem')
			.getDescribe()
			.fields.getMap()
			.get('Operation')
			.getDescribe();
		for (Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues()) {
			OPERATORS_MAPPPING.put(pickListVal.getLabel().toLowerCase(), pickListVal.getValue());
		}

		//Debug Logs for reference
		System.debug('config------------' + config);
		System.debug('MAIN_TERRITORY_MODEL------------' + MAIN_TERRITORY_MODEL);
		System.debug('RULE_OBJECT_TYPE------------' + RULE_OBJECT_TYPE);
		System.debug('SCHEMA_FIELD_MAPPPING------------' + SCHEMA_FIELD_MAPPPING);
		System.debug('OPERATORS_MAPPPING------------' + OPERATORS_MAPPPING);
	}

	//Batch's Start method to query all eligible Territory Hierarchy Stagging Object records
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String conditionFields = ' ';
		for (Integer i = 1; i <= MAXIMUM_NUMBER_CONDITION; i++) {
			conditionFields += 'Condition' + i + '_Field__c, ';
			conditionFields += 'Condition' + i + '_Operator__c, ';
			conditionFields += 'Condition' + i + '_Value__c, ';
			if (i == MAXIMUM_NUMBER_CONDITION) {
				conditionFields = conditionFields.removeEnd(', ');
			}
		}

		String soql = 'SELECT Id, Name, Assigned_Territories__c, Filter_Criteria__c, Rule_Name__c, ';
		soql += 'IsActive__c, Is_Batch_Processed__c, Rule_Id__c ,';
		soql += conditionFields + ' FROM Territory_Rule__c WHERE IsActive__c = true AND ';
		soql += 'Is_Batch_Processed__c = false AND Territory_Model_Name__c =: MAIN_TERRITORY_MODEL_NAME';
		System.debug('soql------------' + soql);

		return Database.getQueryLocator(soql);
	}

	//Batch's Execute method to execute and process the scoped records
	global void execute(Database.BatchableContext BC, list<Territory_Rule__c> records) {
		//Debug Logs for reference
		System.debug('records------------' + records);
		System.debug('records.size()------------' + records.size());

		//Always Process Single Stagging Records -- Do set Batch Size during execution
		if (records.size() > 1) {
			return;
		} else {
			//Instantiate Stagging Records
			Territory_Rule__c obj = records[0];

			//Debug Logs for reference
			System.debug('obj------------' + obj);

			//Cretae Database Image for Rollback
			Savepoint sp = Database.setSavepoint();

			/******** STEP 1 : Clear Up Backend table if any Assignment Rule already exist  *********/

			//Check if Existing Territory Assignment Rule exist or not
			if (obj.Rule_Id__c != null && String.valueOf(obj.Rule_Id__c).length() == 18) {
				//Fetch all assigned Territories to given Assignment Rule
				List<RuleTerritory2Association> terrRelated = [
					SELECT Id
					FROM RuleTerritory2Association
					WHERE RuleId = :obj.Rule_Id__c AND Territory2.Territory2ModelId = :MAIN_TERRITORY_MODEL
				];

				//Delete Territory and Assignment Rule Relation
				if (terrRelated.size() > 0) {
					//Exception Handling
					try {
						delete terrRelated;
					} catch (System.DmlException err) {
						//Create Apex Log
						createExceptionLogs(terrRelated, 'Delete Territory and Assignment Rule Relation', err, sp, obj);
						return;
					}
				}

				//Debug Logs for reference
				System.debug('terrRelated------------' + terrRelated);
				System.debug('terrRelated.size()------------' + terrRelated.size());

				//Check if Provided Assignment Rule exist in System
				ObjectTerritory2AssignmentRule ruleHeader = [
					SELECT Id
					FROM ObjectTerritory2AssignmentRule
					WHERE Id = :obj.Rule_Id__c AND Territory2ModelId = :MAIN_TERRITORY_MODEL
					LIMIT 1
				];

				//Delete Assignment Rule Header
				if (ruleHeader != null) {
					//Exception Handling
					try {
						delete ruleHeader;
					} catch (System.DmlException err) {
						//Create Apex Log
						List<ObjectTerritory2AssignmentRule> recordlst = new List<ObjectTerritory2AssignmentRule>();
						recordlst.add(ruleHeader);
						createExceptionLogs(recordlst, 'Delete Assignment Rule Header', err, sp, obj);
						return;
					}
				}

				//Debug Logs for reference
				System.debug('ruleHeader------------' + ruleHeader);

				//Nullify Value to clear old reference
				obj.Rule_Id__c = null;
			}

			/******** STEP 2 : Create Territory Assignment Rule Header info  *********/

			//Prepare Rule to be Inserted
			ObjectTerritory2AssignmentRule ruleHeaderInfo = new ObjectTerritory2AssignmentRule();

			ruleHeaderInfo.MasterLabel = obj.Rule_Name__c;
			ruleHeaderInfo.ObjectType = RULE_OBJECT_TYPE;
			ruleHeaderInfo.Territory2ModelId = MAIN_TERRITORY_MODEL;
			ruleHeaderInfo.IsActive = true;

			//Generate Random Number to have Unique Developer Name
			ruleHeaderInfo.DeveloperName =
				'X_' +
				obj.Rule_Name__c.replaceAll('[^a-zA-Z0-9\\s]', '').replaceAll(' ', '') +
				'_' +
				String.valueOf(Integer.valueof((Math.random() * 10000)));

			//Debug Logs for reference
			System.debug('ruleHeaderInfo------------' + ruleHeaderInfo);

			//Insert Assignment Rule records
			if (ruleHeaderInfo != null) {
				//Exception Handling
				try {
					insert ruleHeaderInfo;
				} catch (System.DmlException err) {
					//Create Apex Log
					List<ObjectTerritory2AssignmentRule> recordlst = new List<ObjectTerritory2AssignmentRule>();
					recordlst.add(ruleHeaderInfo);
					createExceptionLogs(recordlst, 'Insert Assignment Rule', err, sp, obj);
					return;
				}
			}

			//Debug Logs for reference
			System.debug('ruleHeaderInfo.Id------------' + ruleHeaderInfo.Id);

			/******** STEP 3 : Insert Object Territory Assignment Rule Condition Item records  *********/

			//Prepare list of Rule Items to be Inserted
			List<ObjectTerritory2AssignmentRuleItem> ruleConditionInfo = new List<ObjectTerritory2AssignmentRuleItem>();

			//Check all Condition Statements individually
			for (Integer i = 1; i <= MAXIMUM_NUMBER_CONDITION; i++) {
				//Prepare Custom Field API Name
				String conditionField = 'Condition' + i + '_Field__c';
				String conditionOperator = 'Condition' + i + '_Operator__c';
				String conditionValue = 'Condition' + i + '_Value__c';

				//Null Value Check
				if (
					obj.get(conditionField) != null &&
					obj.get(conditionOperator) != null &&
					obj.get(conditionValue) != null
				) {
					ObjectTerritory2AssignmentRuleItem rule = new ObjectTerritory2AssignmentRuleItem();
					String fieldName = (String) obj.get(conditionField);
					String operatorName = (String) obj.get(conditionOperator);
					String valueName = (String) obj.get(conditionValue);

					if (SCHEMA_FIELD_MAPPPING.containsKey(fieldName.toLowerCase())) {
						rule.Field = RULE_OBJECT_TYPE + '.' + SCHEMA_FIELD_MAPPPING.get(fieldName.toLowerCase());
					}

					if (OPERATORS_MAPPPING.containsKey(operatorName.toLowerCase())) {
						rule.Operation = OPERATORS_MAPPPING.get(operatorName.toLowerCase());
					}

					if (valueName.length() < 1000) {
						rule.Value = valueName;
					}

					//Relate Rule Item to Header
					rule.RuleId = ruleHeaderInfo.Id;
					//Define Order -- Will be used in Boolean Filter
					rule.SortOrder = i;

					//Debug Logs for reference
					System.debug('rule.Field------------' + rule.Field);
					System.debug('rule.Operation------------' + rule.Operation);
					System.debug('rule.Value------------' + rule.Value);

					//Add instance to List
					ruleConditionInfo.add(rule);
				}
			}

			//Debug Logs for reference
			System.debug('ruleConditionInfo------------' + ruleConditionInfo);

			//Insert Assignment Rule Item records
			if (ruleConditionInfo.size() > 0) {
				//Exception Handling
				try {
					insert ruleConditionInfo;
				} catch (System.DmlException err) {
					//Create Apex Log
					createExceptionLogs(ruleConditionInfo, 'Insert Assignment Rule Items', err, sp, obj);
					return;
				}
			}

			/******** STEP 4 : Set Filter Boolean Condition  *********/

			//Check if Filter Criteria Condition provided or else skip execution
			if (obj.Filter_Criteria__c != null) {
				//Create Instance of updated record
				ObjectTerritory2AssignmentRule ruleHeaderFilter = new ObjectTerritory2AssignmentRule();
				ruleHeaderFilter.Id = ruleHeaderInfo.Id;
				ruleHeaderFilter.BooleanFilter = obj.Filter_Criteria__c;

				//Debug Logs for reference
				System.debug('ruleHeaderFilter------------' + ruleHeaderFilter);

				//Insert Assignment Rule Item records
				if (ruleHeaderFilter != null) {
					//Exception Handling
					try {
						update ruleHeaderFilter;
					} catch (System.DmlException err) {
						//Create Apex Log
						List<ObjectTerritory2AssignmentRule> recordlst = new List<ObjectTerritory2AssignmentRule>();
						recordlst.add(ruleHeaderFilter);
						createExceptionLogs(recordlst, 'Update Assignment Rule', err, sp, obj);
						return;
					}
				}
			}

			/******** STEP 5 : Establish Relationship between Territory and Assignment Rule *********/

			//Check if Assigned Territory is provided by Business or not
			if (obj.Assigned_Territories__c != null && ruleHeaderInfo.Id != null) {
				//Store Relationship value
				Map<String, Id> territoryIdMap = new Map<String, Id>();
				for (String str : String.valueOf(obj.Assigned_Territories__c).split(',')) {
					if (str != null) {
						territoryIdMap.put(str, null);
					}
				}

				//Fetch Territory node Record Ids
				for (Territory2 terr : [
					SELECT Id, Name
					FROM Territory2
					WHERE Name IN :territoryIdMap.keySet() AND Territory2ModelId = :MAIN_TERRITORY_MODEL
				]) {
					territoryIdMap.put(terr.Name, terr.Id);
				}

				//Debug Logs for reference
				System.debug('territoryIdMap------------' + territoryIdMap);

				//Prepare list of records to be Inserted
				List<RuleTerritory2Association> assosiationRec = new List<RuleTerritory2Association>();
				for (String terr : territoryIdMap.keySet()) {
					RuleTerritory2Association objrec = new RuleTerritory2Association();
					objrec.RuleId = ruleHeaderInfo.Id;
					objrec.Territory2Id = territoryIdMap.get(terr);
					//Add instance to List
					assosiationRec.add(objrec);
				}

				//Debug Logs for reference
				System.debug('assosiationRec------------' + assosiationRec);

				//Insert Assignment Rule Item records
				if (assosiationRec.size() > 0) {
					//Exception Handling
					try {
						insert assosiationRec;
					} catch (System.DmlException err) {
						//Create Apex Log
						createExceptionLogs(assosiationRec, 'Insert Assignment Rule Assosiation', err, sp, obj);
						return;
					}
				}
			}

			/******** STEP 6 : Mark all picked up Stagging Object records as Batch Processed *********/

			ALL_RECORDS.add(
				new Territory_Rule__c(
					Id = obj.Id,
					Is_Batch_Processed__c = true,
					Rule_Id__c = ruleHeaderInfo.Id,
					Error_Message__c = ''
				)
			);
		}
	}

	//Batch Class's Finish method
	global void finish(Database.BatchableContext BC) {
		//Debug Logs for reference
		System.debug('ALL_RECORDS------------' + ALL_RECORDS);
		System.debug('APEX_LOGS------------' + APEX_LOGS);

		//Update Stagging Object records
		if (ALL_RECORDS.size() > 0) {
			//Exception Handling
			try {
				update ALL_RECORDS;
			} catch (Exception err) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'TerritoryRule_Batch',
					'execute',
					'Batch Logic',
					'Update Territory Rules Stage',
					err.getMessage(),
					System.today()
				);
			}
		}

		//Capture Error Logs and Post
		if (APEX_LOGS.size() > 0) {
			insert APEX_LOGS;
		}
	}

	//Capture Error Message in full discrete info -- stamp to Apex_Log__c
	//Comment and Uncomment code line based on level of Error logs needed
	public void createExceptionLogs(
		List<SObject> lstRecords,
		String objective,
		System.DmlException err,
		Savepoint sp,
		Territory_Rule__c obj
	) {
		//Prepare Meaningful Error Message
		String linebreak = '\n**************************************\n';
		String genericErrorMessage = '';
		String specificErrorMessage = '';

		for (Integer i = 0; i < err.getNumDml(); i++) {
			specificErrorMessage += linebreak + 'DISPALY ERROR MESSAGE: ' + String.valueOf(err.getDmlMessage(i));
			specificErrorMessage += linebreak + 'DISPALY RECORD: ' + String.valueOf(lstRecords.get(err.getDmlIndex(i)));
		}

		// Maximum Character Limit -- Strip out execessive characters
		if (specificErrorMessage.length() > 30000) {
			specificErrorMessage = specificErrorMessage.substring(0, 30000);
		}

		genericErrorMessage += linebreak + 'DISPALY ERROR MESSAGE: ' + String.valueOf(err.getMessage());
		genericErrorMessage += linebreak + 'DISPALY # FAILED ROWS : ' + String.valueOf(err.getNumDml());
		genericErrorMessage += linebreak + 'DISPALY STACK TRACE: ' + String.valueOf(err.getStackTraceString());

		//Add record to custom Apex Log object for capturing
		APEX_LOGS.add(
			new Apex_Log__c(
				Location__c = 'TerritoryRule_Batch',
				Method_name__c = 'execute',
				Application_Name__c = 'Batch Logic',
				Log_Comments__c = objective,
				Integration_Request__c = genericErrorMessage,
				Integration_Response__c = specificErrorMessage,
				Fixed_Date__c = System.today()
			)
		);

		//Update Stagging Table record with Error Message for Business View
		ALL_RECORDS.add(
			new Territory_Rule__c(
				Id = obj.Id,
				Is_Batch_Processed__c = false,
				Error_Message__c = specificErrorMessage + genericErrorMessage
			)
		);

		//Database Rollback to previous Saved Image
		Database.rollback(sp);

		//Throw Exception for Error Visibility
		throw new CustomException('Data Issue Encountered');
	}
}