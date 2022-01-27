// ===========================================================================
//  Object	: CustomRollupUtility
// 	Company	: Keste @ IDC
//  Author	: Basant Kumar Verma
// 	Purpose	: Utility Class for Custom Rollup Functionality
// ===========================================================================
public class CustomRollupUtility {
	//Class level variables for the error messages
	private static final String OBJ = '{obj}';
	private static final String FLD = '{fld}';
	private static final String TYP = '{type}';
	private static final String INVALID_FIELD = OBJ + '.' + FLD + ' should be type of ' + TYP;
	private static final String FIELD_NOT_AVIALBLE = 'Unable to find field ' + FLD + ' on object ' + OBJ;
	private static final String OBJECT_NOT_AVIALBLE = 'Unable to find object ' + OBJ;
	private static final String INVALID_PARAMETERS = 'Invalid Parameters';
	private static final String CURRENCY_ISO_CODE = 'CurrencyISOCode';
	private static final String CURRENCY_DATA_TYPE = 'CURRENCY';

	//Class level variable to check the rollup field's data type
	private static Set<String> validRollupFieldType {
		get {
			if (validRollupFieldType == null) {
				validRollupFieldType = new Set<String>();
				validRollupFieldType.add(CURRENCY_DATA_TYPE);
				validRollupFieldType.add('DOUBLE');
				validRollupFieldType.add('INTEGER');
				validRollupFieldType.add('LONG');
				validRollupFieldType.add('PERCENT');
			}
			return validRollupFieldType;
		}
		set;
	}

	//Class level variable to check the refernce field's data type
	private static Set<String> validRefernceFieldType {
		get {
			if (validRefernceFieldType == null) {
				validRefernceFieldType = new Set<String>();
				validRefernceFieldType.add('REFERENCE');
			}
			return validRefernceFieldType;
		}
		set;
	}

	private static Map<String, Decimal> conversionRates {
		get {
			if (conversionRates == null) {
				conversionRates = new Map<String, Decimal>();
				for (CurrencyType ob : [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE isActive = TRUE]) {
					conversionRates.put(ob.IsoCode, ob.ConversionRate);
				}
			}
			return conversionRates;
		}
		set;
	}

	//Class level ENUM variable to define all allowed Rollup Types
	public enum ROLLUP_TYPE {
		COUNT,
		SUM,
		MIN,
		MAX
	}

	//Exception Class to throw custom error message
	public class RollupException extends Exception {
	}

	//wrapper class for Field Details, Child -> Parent
	public class RollupFieldDetails {
		public String childField;
		public String parentField;
		public ROLLUP_TYPE rollupType;
		Boolean currecnyConversionNeeded;

		// Parameter 1: childField - Child Object's field API name which need to be rolled-up,
		// 				must need to be currency/number/integer/long/double/percent type field, except when rollup type is COUNT
		// Parameter 2: parentField - Parent Object's field API name where rollup value need to be stored
		// 				must need to be currency/number/integer/long/double/percent type field
		// Parameter 3: rollupType - Defines the Rollup Type, possible values are COUNT, SUM, MIN and MAX
		public RollupFieldDetails(String childField, String parentField, ROLLUP_TYPE rollupType) {
			if (String.isNotBlank(childField) && String.isNotBlank(parentField) && rollupType != null) {
				this.childField = childField;
				this.parentField = parentField;
				this.rollupType = rollupType;
				this.currecnyConversionNeeded = false;
			} else {
				throw new RollupException(INVALID_PARAMETERS);
			}
		}
	}

	// Method Name: doRollup
	// Author: Basant Kumar Verma
	// Description: Core method to perfrom the rollup action
	// Parameter 1: childObject - Child Object's API name which need to be rolled-up,
	// Parameter 2: relationshipField - Child object's relationship field name, must need to be a reference type field
	// Parameter 3: parentObject - Parent Object's API name where need to be rolled-up,
	// Parameter 4: fieldDetails - List of wrapper class containing Child Field, Parent Field and Rollup Type
	// Parameter 5: newList - New List of all sObjects
	// Parameter 6: oldMap - Old map of all sObjects
	// Return: Null
	public static void doRollup(
		String childObject,
		String relationshipField,
		String parentObject,
		List<RollupFieldDetails> fieldDetails,
		List<sObject> newList,
		Map<Id, sObject> oldMap
	) {
		try {
			// Only process if the NewList or OldMap is not null and empty
			if (
				String.isNotBlank(childObject) &&
				String.isNotBlank(relationshipField) &&
				String.isNotBlank(parentObject) &&
				fieldDetails != null &&
				!fieldDetails.isEmpty() &&
				((newList != null && !newList.isEmpty()) || (oldMap != null && !oldMap.isEmpty()))
			) {
				//Handle the delete scenario
				if (newList == null || newList.isEmpty()) {
					newList = oldMap.values();
					oldMap = null;
				}

				Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

				if (gd.containsKey(childObject)) {
					if (gd.containsKey(parentObject)) {
						Schema.DescribeSObjectResult dr = gd.get(childObject).getDescribe();
						Map<String, Schema.SObjectField> flds = dr.fields.getMap();

						Schema.DescribeSObjectResult pdr = gd.get(parentObject).getDescribe();
						Map<String, Schema.SObjectField> pflds = pdr.fields.getMap();

						Boolean isMultiCurrencyEnabled = false;
						if (flds.containsKey(CURRENCY_ISO_CODE) && pflds.containsKey(CURRENCY_ISO_CODE)) {
							isMultiCurrencyEnabled = true;
						}

						//Run the validations for all fields
						for (RollupFieldDetails ob : fieldDetails) {
							//Validate child object's rollup field's existance and data type
							if (flds.containsKey(ob.childField)) {
								String childFieldDataType = String.valueOf(
										flds.get(ob.childField).getDescribe().getType()
									)
									.toUpperCase();
								if (
									ob.rollupType != ROLLUP_TYPE.COUNT &&
									!validRollupFieldType.contains(childFieldDataType)
								) {
									throw new RollupException(
										INVALID_FIELD.replace(OBJ, childObject)
											.replace(FLD, ob.childField)
											.replace(TYP, String.valueOf(validRollupFieldType))
									);
								} else if (isMultiCurrencyEnabled && childFieldDataType == CURRENCY_DATA_TYPE) {
									ob.currecnyConversionNeeded = true;
								}
							} else {
								throw new RollupException(
									FIELD_NOT_AVIALBLE.replace(OBJ, childObject)
										.replace(FLD, ob.childField)
										.replace(TYP, String.valueOf(validRollupFieldType))
								);
							}

							//Validate parent object's refernce field's existance and data type
							if (pflds.containsKey(ob.parentField)) {
								String parentFieldDataType = String.valueOf(
										pflds.get(ob.parentField).getDescribe().getType()
									)
									.toUpperCase();
								if (!validRollupFieldType.contains(parentFieldDataType)) {
									throw new RollupException(
										INVALID_FIELD.replace(OBJ, parentObject)
											.replace(FLD, ob.parentField)
											.replace(TYP, String.valueOf(validRollupFieldType))
									);
								}
							} else {
								throw new RollupException(
									FIELD_NOT_AVIALBLE.replace(OBJ, parentObject)
										.replace(FLD, ob.parentField)
										.replace(TYP, String.valueOf(validRollupFieldType))
								);
							}
						}

						//Validate child object's refernce field's existance and data type.
						if (flds.containsKey(relationshipField)) {
							Schema.DescribeFieldResult fdr = flds.get(relationshipField).getDescribe();
							String referenceFieldDataType = String.valueOf(fdr.getType()).toUpperCase();
							if (!validRefernceFieldType.contains(referenceFieldDataType)) {
								throw new RollupException(
									INVALID_FIELD.replace(OBJ, childObject)
										.replace(FLD, relationshipField)
										.replace(TYP, String.valueOf(validRefernceFieldType))
								);
							}
						} else {
							throw new RollupException(
								FIELD_NOT_AVIALBLE.replace(OBJ, childObject)
									.replace(FLD, relationshipField)
									.replace(TYP, String.valueOf(validRefernceFieldType))
							);
						}

						//Collect set of all distinct parent record Ids
						Set<String> parentIds = new Set<String>();
						for (sObject ob : newList) {
							Id obId = (Id) ob.get('Id');
							if (ob.get(relationshipField) != null) {
								Id rfld = (Id) ob.get(relationshipField);
								if (!parentIds.contains(rfld)) {
									if (oldMap == null) {
										parentIds.add(rfld);
									} else {
										for (RollupFieldDetails fld : fieldDetails) {
											if (
												String.valueOf(ob.get(fld.childField)) !=
												String.valueOf(oldMap.get(obId).get(fld.childField))
											) {
												parentIds.add(rfld);
												break;
											}
										}
									}
								}
							}

							if (
								oldMap != null &&
								oldMap.get(obId).get(relationshipField) != null &&
								oldMap.get(obId).get(relationshipField) != ob.get(relationshipField)
							) {
								Id rfld = (Id) oldMap.get(obId).get(relationshipField);
								if (!parentIds.contains(rfld)) {
									parentIds.add(rfld);
								}
							}
						}

						if (parentIds != null && !parentIds.isEmpty()) {
							//Fetch All Parent records
							Map<Id, sObject> parentRecordsToUpdate = new Map<Id, sObject>();
							String parentSOQL = 'SELECT Id, ' + (isMultiCurrencyEnabled ? CURRENCY_ISO_CODE : '');
							for (RollupFieldDetails fld : fieldDetails) {
								parentSOQL += ', ' + fld.parentField;
							}
							parentSOQL += ' FROM ' + parentObject + ' WHERE Id IN :parentIds';
							for (sObject ob : Database.query(parentSOQL)) {
								for (RollupFieldDetails fld : fieldDetails) {
									ob.put(fld.parentField, 0);
								}
								parentRecordsToUpdate.put((Id) ob.get('Id'), ob);
							}

							//Run Aggregate SOQL to get the rollup value
							String aggregateSOQL = 'SELECT ' + relationshipField + ' relFld';
							for (RollupFieldDetails fld : fieldDetails) {
								aggregateSOQL += ', ' + fld.rollupType + '(' + fld.childField + ') ' + fld.childField;
							}
							aggregateSOQL += ' FROM ' + childObject + ' WHERE ' + relationshipField + ' IN :parentIds';
							aggregateSOQL += ' GROUP BY ' + relationshipField;
							for (AggregateResult agr : Database.query(aggregateSOQL)) {
								Id parentId = (Id) agr.get('relFld');
								if (parentRecordsToUpdate.containsKey(parentId)) {
									for (RollupFieldDetails fld : fieldDetails) {
										Decimal agrResult = (Decimal) agr.get(fld.childField);
										if (agrResult == null) {
											agrResult = 0;
										}
										if (fld.currecnyConversionNeeded) {
											String parentCurrencyISOCode = String.valueOf(
												parentRecordsToUpdate.get(parentId).get(CURRENCY_ISO_CODE)
											);
											if (conversionRates.containsKey(parentCurrencyISOCode)) {
												agrResult = agrResult * conversionRates.get(parentCurrencyISOCode);
											}
										}
										parentRecordsToUpdate.get(parentId).put(fld.parentField, agrResult);
									}
								}
							}

							//Perform the update on the parent records to update the Rollup Field
							if (!parentRecordsToUpdate.isEmpty()) {
								update parentRecordsToUpdate.values();
							}
						}
					} else {
						throw new RollupException(OBJECT_NOT_AVIALBLE.replace(OBJ, parentObject));
					}
				} else {
					throw new RollupException(OBJECT_NOT_AVIALBLE.replace(OBJ, childObject));
				}
			} else {
				throw new RollupException(INVALID_PARAMETERS);
			}
		} catch (Exception e) {
			ExceptionHandlerController.createException(
				'CustomRollupUtility',
				'doRollup',
				'Exception occured while doing custom rollup for ' +
				childObject +
				' to ' +
				parentObject,
				'Child object: ' +
				childObject +
				'\nReference field: ' +
				relationshipField +
				'\nParent object: ' +
				parentObject +
				'\n\nField Details: ' +
				JSON.serializePretty(fieldDetails) +
				'\n\nNew List:\n' +
				JSON.serializePretty(newList) +
				'\n\nOld Map:\n' +
				JSON.serializePretty(oldMap),
				e.getMessage() +
				'\n' +
				e.getStackTraceString(),
				System.today()
			);
		}
	}
}