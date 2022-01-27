/**
 * Class: KMQueryBuilder
 * Description: Utility class for building SOQL queries.
 * This is based on FinancialForce query factory class.
 * Author: Ajinkya Hingne
 */
public class KMQueryBuilder {
	public enum SortOrder {
		ASCENDING,
		DESCENDING
	}
	public Schema.SObjectType table { get; private set; }

	@testVisible
	private Set<String> fields;
	private String conditionExpression;
	private Integer limitCount;
	private Integer offsetCount;
	private String groupByExpression;
	//private List<Ordering> order;

	private Boolean sortSelectFields = true;

	public KMQueryBuilder(String table) {
		this.table = Schema.getGlobalDescribe().get(table);
		fields = new Set<String>();
		//order = new List<Ordering>();
	}

	/*@TestVisible
    private String getFieldPath(String fieldName) {
        String tokenName;
        if(!fieldName.contains('.')) { //single field
            Schema.SObjectField token = table.getDescribe().fields.getMap().get(fieldName);
            if(token == null) {
                throw new InvalidFieldException(fieldName,this.table);
            }
            tokenName = token.getDescribe().getName();
        }
        return tokenName;
    }*/

	public KMQueryBuilder selectFields(Set<String> fields) {
		for (String fieldApiName : fields) {
			this.fields.add(fieldApiName);
		}
		return this;
	}

	public KMQueryBuilder setCondition(String conditionExpression) {
		if (this.conditionExpression == null) {
			this.conditionExpression = conditionExpression;
		} else {
			this.conditionExpression += ' AND ' + conditionExpression;
		}
		return this;
	}

	/*public KMQueryBuilder setCondition(List<String> conditions) {
        if(!conditions.isEmpty()) {
            for(String condition : conditions) {
                setCondition(condition);
            }
        }
        return this;
    }*/

	/*public Boolean isGroupable(String sObjectApiName, String fieldApiName) {

        Boolean isGroupable =
            Schema.getGlobalDescribe().get(sObjectApiName).getDescribe()
                .fields.getMap().get(fieldApiName).getDescribe().isGroupable();

        return isGroupable;
    }*/

	/*public String getCondition() {
        return this.conditionExpression;
    }*/

	public KMQueryBuilder setLimit(Integer limitCount) {
		this.limitCount = limitCount;
		return this;
	}

	/*public Integer getLimit() {
        return this.limitCount;
    }*/

	public KMQueryBuilder setOffset(Integer offsetCount) {
		this.offsetCount = offsetCount;
		return this;
	}

	/*public Integer getOffset() {
        return this.offsetCount;
    }*/

	/*public KMQueryBuilder addOrdering(Ordering o) {
        this.order.add(o);
        return this;
    }*/

	/*public KMQueryBuilder addOrdering(String fieldName, SortOrder direction){
        order.add(
            new Ordering(getFieldPath(fieldName), direction)
        );
        return this;
    }

    public KMQueryBuilder setOrdering(Ordering o) {
        this.order = new List<Ordering>{ o };
        return this;
    }

    public KMQueryBuilder setOrdering(String fieldName, SortOrder direction){
        Ordering order = new Ordering(fieldName, direction);
        return setOrdering(order);
    }*/

	/*public KMQueryBuilder setGroupBy(String fieldApi) {

        if(isGroupable(String.valueOf(table),fieldApi)) {
            if(this.groupByExpression == NULL) {
                this.groupByExpression =  fieldApi;
            }
            else{
                this.groupByExpression += ', ' + fieldApi;
            }
        }
        return this;
    }*/

	/*public List<Ordering> getOrderings() {
        return this.order;
    }*/

	public Set<String> getSelectedFields() {
		return this.fields;
	}

	/*public String toAggregateQuery(String fieldName) {
        String result = 'SELECT COUNT(' + fieldName + ') recordCount';

        result += ' FROM ' + table.getDescribe().getName();

        if(conditionExpression != null) {
            result += ' WHERE ' + conditionExpression;
        }

        if(groupByExpression != NULL) {
            result += ' GROUP BY ' + + groupByExpression;
        }

        if(order.size() > 0) {
            result += ' ORDER BY ';
            for(Ordering o : order) {
                result += o.toSOQL() + ', ';
            }
            result = result.substring(0, result.length() - 2);
        }

        if(limitCount != null) {
            result += ' LIMIT ' + limitCount;
        }

        if(offsetCount != null) {
            result += ' OFFSET ' + offsetCount;
        }

        return result;
    }*/

	public String toSOQL() {
		String result = 'SELECT ';

		if (fields.size() == 0) {
			result += 'Id';
		} else {
			List<String> fieldsToQuery = new List<String>(fields);
			if (sortSelectFields) {
				fieldsToQuery.sort();
			}

			result += String.join(fieldsToQuery, ', ');
		}
		result += ' FROM ' + table.getDescribe().getName();

		if (conditionExpression != null) {
			result += ' WHERE ' + conditionExpression;
		}

		if (groupByExpression != null) {
			result += ' GROUP BY ' + groupByExpression;
		}

		/*if(order.size() > 0) {
            result += ' ORDER BY ';
            for(Ordering o : order) {
                result += o.toSOQL() + ', ';
            }
            result = result.substring(0, result.length() - 2);
        }*/

		if (limitCount != null) {
			result += ' LIMIT ' + limitCount;
		}

		if (offsetCount != null) {
			result += ' OFFSET ' + offsetCount;
		}

		return result;
	}

	/*public class Ordering {

        private SortOrder direction;
        private boolean nullsLast;
        private String field;

        public Ordering(String fieldApiName, SortOrder direction){
            this.direction = direction;
            this.field = fieldApiName;
            this.nullsLast = true;
        }

        public String getField(){
            return this.field;
        }

        public SortOrder getDirection(){
            return direction;
        }

        public boolean isNullsLast(){
            return nullsLast;
        }

        public String toSOQL(){
            return field + ' '
                + (direction == SortOrder.ASCENDING ? 'ASC' : 'DESC')
                + (nullsLast ? ' NULLS LAST ' : ' NULLS FIRST ');
        }
    }*/

	/*public class InvalidFieldException extends Exception {
        private String fieldName;
        private Schema.SObjectType objectType;
        public InvalidFieldException(String fieldname, Schema.SObjectType objectType){
            this.objectType = objectType;
            this.fieldName = fieldName;
            this.setMessage( 'Invalid field \'' + fieldName + '\' for object \'' + objectType + '\'' );
        }
    }*/
}