public with sharing class CustomLookupController {
	@AuraEnabled
	public static List<RecordsData> fetchRecords(
		String objectName,
		String filterField,
		List<String> subLabelFields,
		String searchString,
		String value,
		String criteria
	) {
		try {
			List<RecordsData> recordsDataList = new List<RecordsData>();
			String query = 'SELECT Id, ' + filterField;
			if (subLabelFields != null && subLabelFields.size() > 0) {
				query += ', ' + String.join(subLabelFields, ',');
			}
			query += ' FROM ' + objectName;
			if (String.isNotBlank(value)) {
				query += ' WHERE Id = \'' + value + '\' ';
			} else {
				query +=
					' WHERE (' +
					filterField +
					' LIKE ' +
					'\'' +
					String.escapeSingleQuotes(searchString.trim()) +
					'%\' ';
				if (subLabelFields != null && subLabelFields.size() > 0) {
					for (String fieldApiName : subLabelFields) {
						query +=
							' OR ' +
							fieldApiName +
							' LIKE ' +
							'\'' +
							String.escapeSingleQuotes(searchString.trim()) +
							'%\' ';
					}
				}
				query += ' ) ';
			}

			if (String.isNotBlank(criteria) && String.isNotEmpty(criteria)) {
				query += ' AND ' + criteria;
			}
			System.debug('==SOQL==' + query);
			query += ' LIMIT 49999';
			for (SObject s : Database.query(query)) {
				Map<String, String> mapSubLabel = new Map<String, String>();
				if (subLabelFields != null && subLabelFields.size() > 0) {
					for (String subFieldName : subLabelFields) {
						String fieldValue = '';
						if (subFieldName.contains('.')) {
							List<String> lstFieldMapping = subFieldName.split('\\.');
							fieldValue = (String) s.getSobject(lstFieldMapping[0]).get(lstFieldMapping[1]);
						} else {
							fieldValue = (String) s.get(subFieldName);
						}
						mapSubLabel.put(subFieldName, fieldValue);
					}
				}
				recordsDataList.add(new RecordsData((String) s.get(filterField), (String) s.get('id'), mapSubLabel));
			}
			return recordsDataList;
		} catch (Exception err) {
			if (String.isNotBlank(err.getMessage()) && err.getMessage().contains('error:')) {
				throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
			} else {
				throw new AuraHandledException(err.getMessage());
			}
		}
	}

	public class RecordsData {
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String value;
		@AuraEnabled
		public Map<String, String> mapSubLabel;
		public RecordsData(String label, String value) {
			this.label = label;
			this.value = value;
		}
		public RecordsData(String label, String value, Map<String, String> mapSubLabel) {
			this.label = label;
			this.value = value;
			this.mapSubLabel = mapSubLabel;
		}
	}
}