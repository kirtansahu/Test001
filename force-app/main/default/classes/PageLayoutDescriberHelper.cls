/********************************************************************************************************
 * Object	: PageLayoutDescriberHelper
 * Company	: Keste @ IDC
 * Author	: Adarsh Sharma
 * Purpose	: Utility class for get Page Layout fields and sections
 ********************************************************************************************************/
public class PageLayoutDescriberHelper {
	/***************************************************************************************
    @Description: Method to get Page Layout Section and fields using Rest API
    @Author: Adarsh Sharma
    @Param 1: Id recordTypeId : current object RecordType Id
    @Param 2: string objectType : current object type
    @Return: List<LayoutSection> : collection Page layout section and fields
    ***************************************************************************************/
	public static List<LayoutSection> describeSectionWithFields(Id recordTypeId, string objectType) {
		List<LayoutSection> layoutSections = new List<LayoutSection>();

		//make callout and get response body
		String body = GetLayoutSchema(recordTypeId, objectType);
		Map<String, Object> mapPageLayoutDetails = (Map<String, Object>) JSON.deserializeUntyped(body);
		if (mapPageLayoutDetails.containsKey('editLayoutSections')) {
			List<object> targetLayout = (List<object>) mapPageLayoutDetails.get('editLayoutSections');

			for (object sectionObject : targetLayout) {
				Map<String, object> section = (Map<String, object>) sectionObject;
				LayoutSection layoutSectionObj = new LayoutSection(
					(String) section.get('heading'),
					(boolean) section.get('useHeading'),
					(integer) section.get('columns'),
					(boolean) section.get('useCollapsibleSection')
				);
				layoutSections.add(layoutSectionObj);

				List<object> layoutRows = (List<object>) section.get('layoutRows');
				for (Object itemObject : layoutRows) {
					Map<String, object> item = (Map<String, object>) itemObject;
					List<object> layoutItem = (List<object>) item.get('layoutItems');
					boolean priorFieldLayoutAdded = true;
					for (object fieldItemObject : layoutItem) {
						Map<string, object> fields = (Map<string, object>) fieldItemObject;
						List<object> layoutComponents = (List<object>) fields.get('layoutComponents');
						string apiName = '';
						string fieldType = '';
						string label = null;
						for (Object layoutComponent : layoutComponents) {
							Map<string, object> componentMap = (Map<string, object>) layoutComponent;
							if (componentMap.containsKey('value')) {
								apiName = (string) componentMap.get('value');
							}

							if (componentMap.containsKey('type')) {
								fieldType = (string) componentMap.get('type');
							}

							if (componentMap.containsKey('label')) {
								label = (string) componentMap.get('label');
							}
						}
						boolean placeholderF = (boolean) fields.get('placeholder');
						boolean isEditable = (boolean) fields.get('editable');
						boolean required = (boolean) fields.get('required');
						if (label == null && fields.containsKey('label')) {
							label = (string) fields.get('label');
						}

						if ((apiName != '' && fieldType == 'Field') || (placeholderF)) {
							if (layoutSectionObj.Name != '' || layoutSections.size() == 1) {
								layoutSectionObj.layoutFields.add(
									new LayoutField(required, placeholderF, isEditable, apiName, fieldType, label)
								);
							} else if (layoutSections.size() - 2 >= 0) {
								layoutSections.get(layoutSections.size() - 2)
									.layoutFields.add(
										new LayoutField(required, placeholderF, isEditable, apiName, fieldType, label)
									);
							}
							priorFieldLayoutAdded = true;
						} else
							priorFieldLayoutAdded = false;
					}
				}
				if (layoutSections.get(layoutSections.size() - 1).layoutFields.size() <= 0) {
					layoutSections.remove(layoutSections.size() - 1);
				}
			}
		}
		return layoutSections;
	}

	/***************************************************************************************
    @Description: Method to get layout schema for sObject using Rest API
    @Author: Adarsh Sharma
    @Param 1: id recordTypeId : current object RecordType Id
    @Param 2: string objectType : current object type
    @Return: string : return json response
    ***************************************************************************************/
	public static string GetLayoutSchema(id recordTypeId, string objectType) {
		String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
		string endpoint = baseUrl + '/services/data/v29.0/sobjects/' + objectType + '/describe/layouts/' + recordtypeid;
		HttpResponse resp = null;
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(endpoint);
		req.setHeader('Authorization', 'Bearer ' + fetchUserSessionId());
		Http client = new Http();
		resp = client.send(req);
		return resp.getBody();
	}

	/***************************************************************************************
    @Description: Method to fetch session Id
    @Author: Adarsh Sharma
    @Param: none
    @Return: Id : current session Id
    ***************************************************************************************/
	public static String fetchUserSessionId() {
		String sessionId = '';
		PageReference reportPage = Page.GetSessionIdVF;
		String vfContent;
		if (!Test.isRunningTest()) {
			vfContent = reportPage.getContent().toString();
		} else {
			vfContent = 'Start_Of_Session_Id' + UserInfo.getSessionId() + 'End_Of_Session_Id';
		}
		Integer startP = vfContent.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
			endP = vfContent.indexOf('End_Of_Session_Id');
		sessionId = vfContent.substring(startP, endP);
		return sessionId;
	}

	/***************************************************************************************
    @Description: Method to fetch default record type Id
    @Author: Adarsh Sharma
    @Param: SObject obj : current object record
    @Return: Id : default recordtype Id
    ***************************************************************************************/
	public static Id getDefaultRecordType(SObject obj) {
		Schema.DescribeSObjectResult describeResult = obj.getsObjectType().getDescribe();
		List<Schema.RecordTypeInfo> rtInfos = describeResult.getRecordTypeInfos();
		for (Schema.RecordTypeInfo rtInfo : rtInfos) {
			if (rtInfo.DefaultRecordTypeMapping) {
				return rtInfo.getRecordTypeId();
			}
		}
		return null;
	}
}