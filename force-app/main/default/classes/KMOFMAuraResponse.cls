/**
 * Description: Class for returning response to Aura Components
 * Created By: Ajinkya Hingne
 */
public class KMOFMAuraResponse {
	@AuraEnabled
	public Boolean isSuccess;
	@AuraEnabled
	public Object data;
	@AuraEnabled
	public List<Object> dataList;

	public KMOFMAuraResponse(Boolean isSuccess, Object data) {
		this.isSuccess = isSuccess;
		this.data = data;
	}

	public KMOFMAuraResponse(Boolean isSuccess, List<Object> dataList) {
		this.isSuccess = isSuccess;
		this.dataList = dataList;
	}
}