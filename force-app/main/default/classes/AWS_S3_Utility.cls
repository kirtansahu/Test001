// ===========================================================================
//  Object	: AWS_S3_Utility
// 	Company	: Keste @IDC
//  Author	: Basant Kumar Verma -tttttt
// 	Purpose	: Utility Class to fetch case file from AWS S3 bucket
// ===========================================================================
public class AWS_S3_Utility implements Queueable, Database.AllowsCallouts {
	// All Class Level Variables
	private static final String STATUS_SUCCESS = 'Success';
	private static final String STATUS_ERROR = 'Error';
	private static final String STATUS_IN_PROGRESS = 'In Progress';
	private static final String APPLICATION = 'Case - Integration - AWS S3 File';
	private Set<Id> caseIds;

	// Parameterized constructor of the class
	// Author: Basant Kumar Verma
	// Description: Receive set of CaseIds for which file need to be fetched
	// Parameter: caseIds: Set of Case Ids
	public AWS_S3_Utility(Set<Id> caseIds) {
		this.caseIds = caseIds;
	}

	// Method Name: execute
	// Author: Basant Kumar Verma
	// Description: GET Call to fetch file from AWS S3 bucket
	// Parameter: QueueableContext context
	public void execute(QueueableContext context) {
		if (caseIds != null) {
			List<Case> caseList = new List<Case>();
			for (Case c : [
				SELECT
					Id,
					CaseNumber,
					Web_File_URL__c,
					Web_File_Name__c,
					Web_File_Type__c,
					Web_File_AWS_Integration_Status__c
				FROM Case
				WHERE Id IN :caseIds AND Web_File_Name__c != NULL
			]) {
				caseList.add(c);
			}

			if (caseList.size() > 0 && caseList.size() <= 10) {
				Map<Id, AWS_S3_Utility.RequestResponseWrapper> callOutMap = new Map<Id, AWS_S3_Utility.RequestResponseWrapper>();
				for (Case c : caseList) {
					callOutMap.put(c.Id, doFetchFile(c.Web_File_URL__c));
				}

				List<ContentVersion> filesToInsert = new List<ContentVersion>();
				for (Case c : caseList) {
					AWS_S3_Utility.RequestResponseWrapper wrapper = callOutMap.get(c.Id);
					if (wrapper != null && wrapper.res != null) {
						if (wrapper.res.getStatusCode() == 200) {
							c.Web_File_AWS_Integration_Status__c = STATUS_SUCCESS;

							ContentVersion cv = new ContentVersion();
							cv.ContentLocation = 'S';
							cv.FirstPublishLocationId = c.Id;
							cv.VersionData = wrapper.res.getBodyAsBlob();
							cv.Title =
								c.Web_File_Name__c + (c.Web_File_Type__c != null ? '.' + c.Web_File_Type__c : '');
							cv.PathOnClient =
								c.Web_File_Name__c + (c.Web_File_Type__c != null ? '.' + c.Web_File_Type__c : '');
							filesToInsert.add(cv);

							ExceptionHandlerController.createIntegrationException(
								'AWS_S3_Utility',
								'execute',
								APPLICATION,
								'AWS S3 file sync is Successfull.\n\n\r' + wrapper.getSummary(),
								null,
								System.today(),
								c.Web_File_Name__c,
								'Success File',
								'Success'
							);
						} else {
							c.Web_File_AWS_Integration_Status__c = STATUS_ERROR;
							ExceptionHandlerController.createIntegrationException(
								'AWS_S3_Utility',
								'execute',
								APPLICATION,
								'AWS S3 file sync is failed',
								'Error Occured whaile fetching AWS S3 file.\n\n\r' + wrapper.getSummary(),
								System.today(),
								c.Web_File_Name__c,
								wrapper.res.getBody(),
								'Error'
							);
						}
					} else {
						c.Web_File_AWS_Integration_Status__c = STATUS_ERROR;
						ExceptionHandlerController.createIntegrationException(
							'AWS_S3_Utility',
							'execute',
							APPLICATION,
							'AWS S3 file sync is failed',
							'Error Occured whaile fetching AWS S3 file. NO RESULT',
							System.today(),
							c.Web_File_Name__c,
							'NO RESULT',
							'Error'
						);
					}
				}

				CaseTriggerHandler.AWSS3CallMade = true;
				try {
					if (filesToInsert.size() > 0) {
						insert filesToInsert;
					}

					if (caseList.size() > 0) {
						update caseList;
					}
				} catch (Exception e) {
					ExceptionHandlerController.createIntegrationException(
						'AWS_S3_Utility',
						'execute',
						APPLICATION,
						'AWS S3 file sync is failed.\n' + e.getStackTraceString(),
						'Error Occured during Case update or File creation. ' + e.getMessage(),
						System.today(),
						'',
						e.getStackTraceString(),
						'Error'
					);
					for (Case c : caseList) {
						c.Web_File_AWS_Integration_Status__c = STATUS_ERROR;
					}
					update caseList;
				}
			}
		}
	}

	// Method Name: doFetchFile
	// Author: Basant Kumar Verma
	// Description: Do the actual call out and fetch teh file
	// Parameter: File Name - Just need file name as Bucket will be same for all files
	// Return: RequestResponseWrapper - Wrapper Class for Request and Response for Callout
	private static RequestResponseWrapper doFetchFile(String fileName) {
		HTTPResponse res = new HTTPResponse();
		String method = 'GET';
		//String endpointURL = Label.AWS_S3_ENDPOINT+handleEncoding(fileName);
		String endpointURL = Label.AWS_S3_ENDPOINT + fileName;

		Http http = new Http();
		HttpRequest req = new HttpRequest();

		req.setMethod(method);
		req.setEndpoint(endpointURL);
		try {
			res = http.send(req);
		} catch (Exception e) {
			res.setStatus('EXCEPTION');
			res.setStatusCode(999);
			res.setBody(
				'endpointURL: ' +
				endpointURL +
				'\n\n\r' +
				'Message: ' +
				e.getMessage() +
				'\n\n\r' +
				'Stack Trace: ' +
				e.getStackTraceString()
			);
		}
		return new RequestResponseWrapper(req, res);
	}

	// Method Name: fetchFileFromURLs
	// Author: Basant Kumar Verma
	// Description: Utility method to do bulk handling
	// Parameter: Set of Case Record Ids
	// Return: none
	public static void fetchFileFromURLs(Set<Id> setOfRecordIds) {
		if (setOfRecordIds.size() > 0) {
			List<Case> caseToUpdate = new List<Case>();
			List<Set<Id>> listOfIdSets = new List<Set<Id>>();
			Set<Id> tempSetOfIds = new Set<Id>();
			for (Id recordId : setOfRecordIds) {
				caseToUpdate.add(new Case(Id = recordId, Web_File_AWS_Integration_Status__c = STATUS_IN_PROGRESS));
				if (tempSetOfIds.size() == 0) {
					listOfIdSets.add(tempSetOfIds);
				}
				tempSetOfIds.add(recordId);
				if (tempSetOfIds.size() == 10) {
					tempSetOfIds = new Set<Id>();
				}
			}

			update caseToUpdate;
			for (Set<Id> recordIdSet : listOfIdSets) {
				AWS_S3_Utility utilityOb = new AWS_S3_Utility(recordIdSet);
				//Asynchronous Callout
				System.enqueueJob(utilityOb);
			}
		}
	}

	// Wrapper Class to Hold both Request and Response Objects so we can have better Apex Log
	public class RequestResponseWrapper {
		public HttpRequest req { get; set; }
		public HTTPResponse res { get; set; }

		public RequestResponseWrapper(HttpRequest req, HTTPResponse res) {
			this.req = req;
			this.res = res;
		}

		public String getSummary() {
			String summary = '';
			if (req != null) {
				summary += 'Request-Method: ' + req.getMethod() + '\n\rRequest-Enpoint: ' + req.getEndpoint();
			} else {
				summary += 'NO REQUEST INFORMATION FOUND';
			}
			if (res != null) {
				summary +=
					'\n\n\rResponse-Status: ' +
					res.getStatus() +
					'\n\rResponse-StatusCode: ' +
					res.getStatusCode();
			} else {
				summary += '\n\n\rNO RESPONSE INFORMATION FOUND';
			}
			return summary;
		}
	}

	// Method to handle the URL Encoding for the FileName ONLY, not for the folder and subfolder names
	/*public static String handleEncoding(String fileName){
        Integer lastIndex = fileName.lastIndexOf('/');
        String leftStr = '', rightStr = '';
        if(lastIndex > 0){
            leftStr = filename.substring(0,lastIndex+1);
            rightStr = filename.substring(lastIndex+1);
        }else{
            rightStr = filename;
        }
        rightStr = EncodingUtil.urlEncode(rightStr, 'UTF-8').replaceAll('\\+','%20');
        
        fileName = leftStr+rightStr;
        return fileName;
    }*/
}
