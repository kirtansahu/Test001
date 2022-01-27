public class CASContactExtract {
	public static string sCASPrimeId;
	public static string sSurveyId;
	public void GenerateExtract(List<String> CASPrimeIdList) {
		try {
			Decimal SamplePercent;
			Decimal SampleRecordCount;
			String SampleSizeType;
			//string sCASPrimeId;
			string sSurveyID;
			string sDivName;
			string sFuncSite;
			string sBusUnit;
			string sLanguage;
			string sFuncCountry;
			string sIncludeHeader;
			string sFileFormat;

			Integer lastDays = 0;
			Integer WeeksAgoFrom = 0;
			Integer WeeksAgoTo = 0;

			String sLeadProductType;

			Decimal conversionrate;
			string sAccountName = '';
			string sAccountIndustry = '';
			string sAccountNumber = '';
			string sConFirstName = '';
			string sConLastName = '';
			String sOptyName = '';
			string sManagerName = '';
			string sRegion = '';
			string sEmail = '';
			string sPhone = '';
			string sCreatedBy = '';
			string sRecordId = '';
			string sOptySKUStr = '';
			string sOptyNumber = '';
			string sOptySKUDescriptionStr = '';
			string sOptyCurrencyCode = '';
			Decimal sOptyConvertedvalue = 0;
			string sfrequency = '';
			string subject = '';
			String sEventEndDt_USFormat = '';
			Datetime sEventEndDate;
			string sTransactionType = '';
			string sAccountId = '';
			string sMailingStreet = '';
			string sMailingCity = '';
			string sMailingState = '';
			string sMailingPostalCode = '';
			string sMailingCountry = '';
			string sStatus = '';
			string sType = '';
			string sOwnerName = '';
			string sOwnerId = '';
			string sSalesRepFstName = '';
			String sSalesRepLastName = '';
			string sSalesRepRole = '';
			string sSalesRepName = '';
			string sEventId = '';
			string sBrand = 'Thermo Scientific';
			string sLetterUploadVar1 = '';
			string sLetterUploadVar2 = '';
			string sLetterUploadVar3 = '';
			string sProductFamily = '';
			string sUploadVar1 = '';
			string sUploadVar2 = '';
			string sUploadVar3 = '';
			string sUploadVar4 = '';
			String sUploadVar5 = '';
			string sUploadVar6 = '';
			string sUploadVar7 = '';
			string sQuoteThrough = '';
			string sProductsOfInterest = '';
			String sSellingTeam = '';
			String sCASFileName = '';
			string finalstr = '';
			string psvheader = '';
			string csvheader = '';
			string header = '';
			string recordString = '';
			string filename = '';
			String sDay;
			String sMonth;
			String sYear;
			Integer TotalCount = 0;
			Integer FinalSize = 0;
			string emailTo = '';
			string senderDisplayName = '';
			string emailSubject = '';
			string ManagerName = '';
			string sEmployeeNumber = '';
			string sPlatform;
			string sSubPlatform;
			string sBusinessUnitLabel;
            string sPO;
            string sProductLine;

			string sCaseNumber;
			string sAgentFirstName;
			string sAgentLastName;
			string sAgentName;
			string sAccountCountry;

			Set<Id> CASPrimeIdSet = new Set<Id>();
			for (String cprime : CASPrimeIdList) {
				CASPrimeIdSet.add(cprime);
			}
			///////////////////////////get the job params from the CAS record///////////////////
			List<CAS_Prime__c> casList = [
				SELECT
					ID,
					Name,
					Survey_ID__c,
					Division_name__c,
					B_U_Name__c,
					Functional_Site__c,
					Functional_Country__c,
					Survey_Object_Type__c,
					Language__c,
					Include_Header__c,
					File_Format__c,
					Sample_Size__c,
					Report_run__c,
					Sample_Record_Count__c,
					Sample_Size_Type__c
				FROM CAS_Prime__c
				WHERE ID IN :CASPrimeIdSet
				LIMIT 20
			];
			system.debug('Number of CAS records found ' + casList.size());
			if (casList.size() > 0) {
				for (CAS_Prime__c cas : casList) {
					SamplePercent = cas.Sample_Size__c;
					SampleRecordCount = cas.Sample_Record_Count__c;
					SampleSizeType = cas.Sample_Size_Type__c;
					sSurveyID = cas.Survey_ID__c;
					sDivName = cas.Division_name__c;
					sFuncSite = cas.Functional_Site__c;
					sBusUnit = cas.B_U_Name__c;
					sLanguage = cas.Language__c;
					sCASFileName = cas.Name;
					sCASPrimeId = cas.Id;
					sfrequency = cas.Report_run__c;
					sFuncCountry = cas.Functional_Country__c;
					sIncludeHeader = cas.Include_Header__c;
					sFileFormat = cas.File_Format__c;
					sTransactionType = cas.Survey_Object_Type__c;
				} //for
			} //if
			system.debug('CAS Prime Id is ' + sCASPrimeId);
			system.debug('Division  is ' + sDivName);
			system.debug('Business Unit  is ' + sBusUnit);
			system.debug('Functional Site is ' + sFuncSite);
			system.debug('Frequency  is ' + sFrequency);
			system.debug('Sample Size Type  is ' + SampleSizeType);
			system.debug('Transaction Type  is ' + sTransactionType);
			if ('Daily'.equals(sfrequency)) {
				lastDays = 1; //last 1 day's data
			} else if ('Weekly'.equals(sfrequency)) {
				lastDays = 7; //last 7 days' data
			} else if ('Monthly'.equals(sfrequency)) {
				lastDays = 30; //last 30 days' data
			}

			///////////////////////////////////////////////////////////////////////
			if (sTransactionType == 'Opportunity') {
				Set<Id> contactIds = new Set<Id>();
				Set<Id> userIds = new Set<Id>();
				Set<Id> accountIds = new Set<Id>();
				Set<Id> optyIds = new Set<Id>();
				Set<String> ManagerNameSet = new Set<String>();
				Set<String> SalesRepNameSet = new Set<String>();
				String sQuery;
				String sQuery1;
				String sQuery2;

				Map<string, string> DedupCASMap = new Map<string, string>();
				List<Opportunity> CASOpty;

				Map<string, decimal> queriedcurrencies = new Map<string, decimal>();
				List<CurrencyType> cList = [SELECT ISOCode, ConversionRate FROM CurrencyType WHERE IsActive = TRUE];
				for (CurrencyType c : cList) {
					queriedcurrencies.put(c.ISOCode, c.ConversionRate);
				}

				List<OpportunityFieldHistory> OptyhistoryList = Database.Query(
					'Select Id, CreatedById,OpportunityId, CreatedDate, Field, NewValue, OldValue from OpportunityFieldHistory Where CreatedDate=LAST_N_DAYS:' +
					lastDays +
					' AND Field = \'StageName\''
				);
				Integer count = 0;
				Set<Id> QualifiedOptySet = new Set<Id>();
				for (OpportunityFieldHistory optyhistory : OptyhistoryList) {
					if (sFuncSite == 'LSG - BID Inside Sales') {
						if (
							optyhistory.NewValue == 'New' ||
							optyhistory.NewValue == 'Qualified' ||
							optyhistory.NewValue == 'Evaluating' ||
							optyhistory.NewValue == 'Negotiating Commitment' ||
							optyhistory.NewValue == 'Started Buying Process'
						) {
							QualifiedOptySet.add(optyhistory.OpportunityId);
							count = count + 1;
						}
					} else {
						if (optyhistory.NewValue == 'Qualified') {
							QualifiedOptySet.add(optyhistory.OpportunityId);
							count = count + 1;
						}
					}
				}
				system.debug('No of qualified Optys in history is ' + QualifiedOptySet.size());

				if (sFuncSite == 'LSG - BID Inside Sales') {
					List<CAS_Sales_Setting__mdt> CAS_SalesManagerList = [
						SELECT ID, Sales_Manager_Name__c
						FROM CAS_Sales_Setting__mdt
						WHERE MasterLabel = 'CAS Sales Manager%' AND Division_Name__c = 'BID' AND Region__c = 'NA'
					];
					for (CAS_Sales_Setting__mdt casSalesManager : CAS_SalesManagerList) {
						ManagerNameSet.add(casSalesManager.Sales_Manager_Name__c);
					}
					List<CAS_Sales_Setting__mdt> CAS_SalesRepList = [
						SELECT ID, Sales_Rep_Name__c
						FROM CAS_Sales_Setting__mdt
						WHERE MasterLabel LIKE 'CAS Sales Rep%' AND Division_Name__c = 'BID' AND Region__c = 'NA'
					];
					for (CAS_Sales_Setting__mdt casSalesRep : CAS_SalesRepList) {
						SalesRepNameSet.add(casSalesRep.Sales_Rep_Name__c);
					}

					//construct the query
					sQuery = 'Select Id,CreatedDate,Name,Opportunity_Number__c,CurrencyIsoCode,Amount,StageName,AccountId,Account.Name,Account.Industry,Owner.Id,Owner.Name,CloseDate,CreatedBy.Name from Opportunity where (Status__c=\'Accepted\' AND  Opportunity_Source__c=\'Sales Created\' AND  OwnerId !=\'\' AND Account.Name!=\'\' AND (NOT Account.Name LIKE \'%NO ACCOUNT LINK%\') AND (NOT Account.Name LIKE \'%UNKNOWN%\') AND (Owner.Manager.Name IN';
					sQuery = sQuery + ': ManagerNameSet OR Owner.Name IN'; //check sales managers
					sQuery = sQuery + ':SalesRepNameSet ))'; //check sales reps
					sQuery =
						sQuery +
						' AND ((StageName =\'Qualified\' AND CreatedDate =LAST_N_DAYS:' +
						lastDays +
						') OR ID IN';
					sQuery = sQuery + ': QualifiedOptySet )'; //check if exists in qualified opty set

					CASOpty = Database.query(sQuery);

					//   CASOpty=Database.query('Select Id,CreatedDate,Name,Opportunity_Number__c,CurrencyIsoCode,Amount,StageName,AccountId,Account.Name,Account.Industry,Owner.Id,Owner.Name,CloseDate,CreatedBy.Name from Opportunity where Status__c=\'Accepted\' AND CreatedDate =LAST_N_DAYS:' +lastDays+ ' AND Opportunity_Source__c=\'Sales Created\' AND  StageName =\'Qualified\' AND OwnerId !=\'\' AND Account.Name!=\'\' AND (NOT Account.Name LIKE \'%NO ACCOUNT LINK%\') AND (NOT Account.Name LIKE \'%UNKNOWN%\') AND Owner.Manager.Name IN:'+ManagerNameSet+'');
				} else {
					sQuery = 'Select Id,CreatedDate,Name,Opportunity_Number__c,CurrencyIsoCode,Amount,StageName,AccountId,Account.Name,Account.Industry,Owner.Id,Owner.Name,CloseDate,CreatedBy.Name from Opportunity where (Status__c=\'Accepted\'  AND Opportunity_Source__c=\'Sales Created\'  AND OwnerId !=\'\' AND Account.Name!=\'\' AND (NOT Account.Name LIKE \'%NO ACCOUNT LINK%\') AND (NOT Account.Name LIKE \'%UNKNOWN%\')) ';
					sQuery =
						sQuery +
						' AND ((StageName =\'Qualified\' AND CreatedDate =LAST_N_DAYS:' +
						lastDays +
						') OR ID IN';
					sQuery = sQuery + ': QualifiedOptySet )'; //check if exists in qualified opty set

					CASOpty = Database.query(sQuery);
					// CASOpty=Database.query('Select Id,CreatedDate,Name,Opportunity_Number__c,CurrencyIsoCode,Amount,StageName,AccountId,Account.Name,Account.Industry,Owner.Id,Owner.Name,CloseDate,CreatedBy.Name from Opportunity where Status__c=\'Accepted\' AND CreatedDate =LAST_N_DAYS:' +lastDays+ ' AND Opportunity_Source__c=\'Sales Created\' AND  StageName =\'Qualified\' AND OwnerId !=\'\' AND Account.Name!=\'\' AND (NOT Account.Name LIKE \'%NO ACCOUNT LINK%\') AND (NOT Account.Name LIKE \'%UNKNOWN%\') LIMIT 1000');
				}

				system.debug('No of Optys found is ' + CASOpty.size());
				for (Opportunity opty : CASOpty) {
					accountIds.Add(opty.AccountId); //gather the account ids and opty ids associated to the event set
					optyIds.add(opty.Id);
				}
				List<OpportunityContactRole> contacts = [
					SELECT
						Id,
						OpportunityId,
						Contact.FirstName,
						Contact.LastName,
						Contact.Email,
						Contact.Phone,
						Contact.MailingStreet,
						Contact.MailingCity,
						Contact.MailingState,
						Contact.MailingPostalCode,
						Contact.MailingCountry
					FROM OpportunityContactRole
					WHERE
						Contact.Email != ''
						AND (NOT Contact.Email LIKE '%@lifetech.com%')
						AND (NOT Contact.Email LIKE '%@invitrogen.com%')
						AND (NOT Contact.Email LIKE '%@appliedbiosystems.com%')
						AND (NOT Contact.Email LIKE '%@thermofisher.com%')
						AND (NOT Contact.Email LIKE '%@affymetrix.com%')
						AND (NOT Contact.Email LIKE '%UNKNOWN%')
						AND Contact.Email != '?'
						AND (NOT Contact.MailingCountry LIKE '%UNKNOWN%')
						AND Contact.MailingCountry != '?'
						AND Contact.MailingCountry != ''
						AND (NOT Contact.FirstName LIKE '%UNKNOWN%')
						AND (NOT Contact.LastName LIKE '%UNKNOWN%')
						AND OpportunityId IN :optyIds
				]; //get the set of all contacts associated to the optys above
				Map<string, OpportunityContactRole> conMap = new Map<string, OpportunityContactRole>();

				for (OpportunityContactRole con : contacts) {
					conMap.put(con.OpportunityID, con);
				}
				for (Opportunity opty : CASOpty) {
					userIds.Add(opty.OwnerId);
				}
				List<User> userList;
				if (sFuncSite == 'LSG - EMEA') {
					userList = [
						SELECT ID, UserRole.Name, FirstName, LastName, Name, Manager.Name, Organization__c
						FROM User
						WHERE ID IN :userIds AND Profile.Name = 'Account Manager' AND Organization__c IN ('EMEA')
					];
				} else if (sFuncSite == 'LSG - APJ') {
					userList = [
						SELECT ID, UserRole.Name, FirstName, LastName, Name, Manager.Name, Organization__c
						FROM User
						WHERE
							ID IN :userIds
							AND Profile.Name = 'Account Manager'
							AND Organization__c IN ('AP', 'AP-GWI')
					];
				} else if (sFuncSite == 'LSG - BID Inside Sales') {
					// system.debug('Querying for NA BID Users');
					userList = [
						SELECT ID, UserRole.Name, FirstName, LastName, Name, Manager.Name, Organization__c
						FROM User
						WHERE
							ID IN :userIds
							AND Profile.Name = 'Account Manager'
							AND Organization__c IN ('NA')
							AND Manager.Name IN :ManagerNameSet
					];
				} else
					return;

				Map<string, User> uMap = new Map<string, User>();
				for (User usr : userList) {
					uMap.put(usr.ID, usr);
				}

				List<OpportunityLineItem> oliList = [
					SELECT OpportunityId, Quantity, ListPrice, Product2.Name, SKU_Name__c, Product2.Family
					FROM OpportunityLineItem
					WHERE OpportunityId IN :optyIds
				];

				List<Opportunity_Product_Line__c> oProdLineList = [
					SELECT ID, Name, Opportunity__c
					FROM Opportunity_Product_Line__c
					WHERE Opportunity__c IN :optyIds
				];

				system.debug('Begin building file extract');
				for (Opportunity opty : CASOpty) {
					OpportunityContactRole c = conMap.get(opty.Id); //for each opty fetch the contact that was associated to the event from the contact set above
					User u = uMap.get(opty.OwnerId);
					// OpportunityLineItem oi=oliMap.get(opty.Id);

					if (c != null && u != null) {
						system.debug('Processing Opportunity ' + opty.Id);
						sEventEndDate = opty.CreatedDate;
						sEventEndDt_USFormat = '';
						if (sEventEndDate != null) {
							sDay = string.valueOf(sEventEndDate.day());
							sMonth = string.valueOf(sEventEndDate.month());
							sYear = string.valueOf(sEventEndDate.year());
							sEventEndDt_USFormat = sMonth + '/' + sDay + '/' + sYear;
						}
						sOptyName = opty.Name;
						sAccountName = opty.Account.Name;
						sAccountIndustry = opty.Account.Industry;
						//sRecordId=opty.Id;
						sRecordId = opty.Opportunity_Number__c;
						sConFirstName = c.Contact.FirstName;
						sConLastName = c.Contact.LastName;
						sEmail = c.Contact.Email;
						sPhone = c.Contact.Phone;

						sCreatedBy = opty.CreatedBy.Name;
						sMailingStreet = c.Contact.MailingStreet;
						sMailingCity = c.Contact.MailingCity;
						sMailingState = c.Contact.MailingState;
						sMailingPostalCode = c.Contact.MailingPostalCode;
						sMailingCountry = c.Contact.MailingCountry;
						sSalesRepFstName = u.FirstName;
						sSalesRepLastName = u.LastName;
						sSalesRepName = u.Name;
						sSalesRepRole = u.UserRole.Name;
						sManagerName = u.Manager.Name;
						sRegion = u.Organization__c;
						sOptyNumber = opty.Opportunity_Number__c;
						sOptyCurrencyCode = opty.CurrencyIsoCode;

						if (sAccountName == null)
							sAccountName = '';
						else {
							sAccountName = sAccountName.replace('\r\n', ' ');
							sAccountName = sAccountName.replace('\n', ' ');
							sAccountName = sAccountName.replace('\r', ' ');
						}
						if (sAccountName.indexOf(',') != -1)
							sAccountName = '\"' + sAccountName + '\"';
						if (sConLastName.indexOf(',') != -1)
							sConLastName = '\"' + sConLastName + '\"';
						if (sPhone == null)
							sPhone = '';

						if (sMailingStreet == null || sMailingStreet == '')
							sMailingStreet = '';
						else {
							if (sMailingStreet.indexOf(',') != -1)
								sMailingStreet.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sMailingStreet = '\"' + sMailingStreet + '\"';
							sMailingStreet = sMailingStreet.replace('\r\n', ' ');
							sMailingStreet = sMailingStreet.replace('\n', ' ');
							sMailingStreet = sMailingStreet.replace('\r', ' ');
						}

						if (sMailingCity == null || sMailingCity == '')
							sMailingCity = '';
						else {
							if (sMailingCity.indexOf(',') != -1)
								sMailingCity.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sMailingCity = '\"' + sMailingCity + '\"';
							sMailingCity = sMailingCity.replace('\r\n', ' ');
							sMailingCity = sMailingCity.replace('\n', ' ');
							sMailingCity = sMailingCity.replace('\r', ' ');
						}

						if (sMailingState == null || sMailingState == '')
							sMailingState = '';
						else {
							if (sMailingState.indexOf(',') != -1)
								sMailingState.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sMailingState = '\"' + sMailingState + '\"';
							sMailingState = sMailingState.replace('\r\n', ' ');
							sMailingState = sMailingState.replace('\n', ' ');
							sMailingState = sMailingState.replace('\r', ' ');
						}
						if (sMailingPostalCode == null || sMailingPostalCode == '')
							sMailingPostalCode = '';
						else {
							if (sMailingPostalCode.indexOf(',') != -1)
								sMailingPostalCode.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sMailingPostalCode = '\"' + sMailingPostalCode + '\"';
							sMailingPostalCode = sMailingPostalCode.replace('\r\n', ' ');
							sMailingPostalCode = sMailingPostalCode.replace('\n', ' ');
							sMailingPostalCode = sMailingPostalCode.replace('\r', ' ');
						}
						if (sMailingCountry == null || sMailingCountry == '')
							sMailingCountry = '';
						else {
							if (sMailingCountry.indexOf(',') != -1) {
								//if there is any newline character  or comma within the street address replace it with tab
								sMailingCountry = '\"' + sMailingCountry + '\"';
								sMailingCountry = sMailingCountry.replace('\r\n', ' ');
								sMailingCountry = sMailingCountry.replace('\n', ' ');
								sMailingCountry = sMailingCountry.replace('\r', ' ');
                                
							}
						}
						if (sMailingCity == null)
							sMailingCity = '';
						if (sMailingState == null)
							sMailingState = '';
						if (sMailingPostalCode == null)
							sMailingPostalCode = '';
						if (sMailingCountry == null)
							sMailingCountry = '';
						if (sAccountIndustry == null)
							sAccountIndustry = '';
						sBrand = 'Life Sciences Solutions No Product Question';
						sLetterUploadVar1 = 'Sales Rep Name: ' + sSalesRepName;
						sLetterUploadVar2 = '';
						sLetterUploadVar3 = '';
						//if(sLetterUploadVar3.indexOf(',')!=-1) sLetterUploadVar3='\"'+sLetterUploadVar3+'\"';
						//if(sManagerName!='')
						// sUploadVar1= sManagerName;
						/////////////////////////////////////////////////////////////

						List<OpportunityLineItem> oiListSortInput = new List<OpportunityLineItem>();
						for (OpportunityLineItem oi : oliList) {
							if (oi.OpportunityId == opty.Id)
								oiListSortInput.add(oi);
						}
						//Bubble sort for sorting opportunity products based on price and picking the most expensive one
						Integer n = oiListSortInput.size();
						if (n > 0) {
							sObject temp = new OpportunityLineItem();
							for (Integer i = 0; i < n; i++) {
								for (Integer j = 1; j < (n - i); j++) {
									if (
										(Decimal) oiListSortInput[j - 1].get('ListPrice') <
										(Decimal) oiListSortInput[j].get('ListPrice')
									) {
										temp = oiListSortInput[j - 1];
										oiListSortInput[j - 1] = (OpportunityLineItem) oiListSortInput[j];
										oiListSortInput[j] = (OpportunityLineItem) temp;
									}
								}
							}

							sUploadVar2 = string.valueOf(oiListSortInput[0].get('SKU_Name__c'));
						} else {
							List<Opportunity_Product_Line__c> oProdLineListSortInput = new List<Opportunity_Product_Line__c>();
							for (Opportunity_Product_Line__c opLineitem : oProdLineList) {
								if (opLineitem.Opportunity__c == opty.Id)
									oProdLineListSortInput.add(opLineitem);
							}
							if (oProdLineListSortInput.size() > 0)
								sUploadVar3 = string.valueOf(oProdLineListSortInput[0].get('Name'));
						}

						////////////////////////////////////////////

						sUploadVar4 = '';
						if (sRegion != '')
							sUploadVar5 = sRegion;
						sUploadVar6 = sOptyNumber;
						sUploadVar7 = '';
						if (sLanguage == null)
							sLanguage = 'English';

						if (sUploadVar2 == null || sUploadVar2 == '')
							sUploadVar2 = '';
						else {
							if (sUploadVar2.indexOf(',') != -1)
								sUploadVar2.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sUploadVar2 = '\"' + sUploadVar2 + '\"';
							sUploadVar2 = sUploadVar2.replace('\r\n', ' ');
							sUploadVar2 = sUploadVar2.replace('\n', ' ');
							sUploadVar2 = sUploadVar2.replace('\r', ' ');
						}

						recordString =
							sDivName +
							',' +
							sBusUnit +
							',' +
							sFuncSite +
							',' +
							sSurveyID +
							',' +
							sAccountName +
							',' +
							sAccountNumber +
							',' +
							sConFirstName +
							',' +
							sConLastName +
							',' +
							sMailingStreet +
							',' +
							sMailingCity +
							',' +
							sMailingState +
							',' +
							sMailingPostalCode +
							',' +
							sMailingCountry +
							',' +
							sPhone +
							',' +
							sEmail +
							',' +
							sLanguage +
							',' +
							sEventEndDt_USFormat +
							',' +
							sSalesRepName +
							',' +
							',' +
							',' +
							sRecordId +
							',' +
							',' +
							',' +
							sBrand +
							',' +
							sLetterUploadVar1 +
							',' +
							sLetterUploadVar2 +
							',' +
							sLetterUploadVar3 +
							',' +
							sUploadVar1 +
							',' +
							sUploadVar2 +
							',' +
							sUploadVar3 +
							',' +
							sUploadVar4 +
							',' +
							sUploadVar5 +
							',' +
							sUploadVar6 +
							',' +
							sUploadVar7 +
							'\n';
						DedupCASMap.put(sEmail, recordString);
						//finalstr= finalstr + recordString; //append to the previous record
					} //if c!=null

					sEventEndDt_USFormat = '';
					sAccountName = '';
					sConFirstName = '';
					sConLastName = '';
					sEmail = '';
					sPhone = '';
					sCreatedBy = '';
					sSalesRepFstName = '';
					sSalesRepLastName = '';
					sSalesRepRole = '';
					sProductFamily = '';
					sMailingStreet = '';
					sMailingCity = '';
					sMailingState = '';
					sMailingPostalCode = '';
					sMailingCountry = '';
					sSalesRepFstName = '';
					sSalesRepLastName = '';
					sSalesRepName = '';
					sRegion = '';
					sOptyNumber = '';
					sManagerName = '';
					sLanguage = '';
					sPlatform = '';
					sSubPlatform = '';
					sBusinessUnitLabel = '';
					sSalesRepRole = '';
					sAccountIndustry = '';
					sLetterUploadVar1 = '';
					sLetterUploadVar2 = '';
					sLetterUploadVar3 = '';
					sUploadVar1 = '';
					sUploadVar2 = '';
					sUploadVar3 = '';
					sUploadVar4 = '';
					sUploadVar5 = '';
					sUploadVar6 = '';
					sUploadVar7 = '';
				} //end of loop for(Opportunity opty:CASOpty)

				//remove any duplicates
				if (DedupCASMap.size() > 0) {
					for (String dedupkeystr : DedupCASMap.keyset()) {
						finalstr = finalstr + DedupCASMap.get(dedupkeystr); //append to the previous record
					}
				}
				//end of duplicate removal
			} //end  if(sTransactionType=='Opportunity')
			///////////////////////////////////////////////////////////////////////////////////////////

			////////////////////////////start Cases////////////////////////////////////////////////
			if (sSurveyId == 'TSUP1' && sTransactionType == 'Case') {
				Set<Id> contactIds = new Set<Id>();
				Set<Id> userIds = new Set<Id>();
				Set<Id> accountIds = new Set<Id>();
				Set<Id> optyIds = new Set<Id>();
				Set<Id> caseIds = new Set<Id>();
				Set<Id> ProductIds = new Set<Id>();
				Map<Id, Id> caseIDProductIDMap = new Map<Id, Id>();
				Map<string, string> DedupCASMap = new Map<string, string>();
				List<Case> CASCase;
				if ('Daily'.equals(sfrequency)) {
					if (sFuncSite == 'LSG - GSD')
						CASCase = Database.Query(
							'Select Id,CaseNumber,Origin,CreatedDate,OwnerId,Owner.Name,AccountId,ContactId,ClosedDate,CreatedBy.Name,Subject,Primary_Product__c from Case where ClosedDate =LAST_N_DAYS:' +
							lastDays +
							' AND Status= \'Closed\' AND Sub_Status__c=\'Resolved\' AND Area__c IN (\'Human Identity\',\'Rapid HIT\') AND RecordType.Name =\'Tech Support\' AND CaseNumber!=\'\' AND Origin!=\'Chat\' AND (NOT Subject LIKE \'%Concierge%\')'
						);
					else
						CASCase = Database.Query(
							'Select Id,CaseNumber,Origin,CreatedDate,OwnerId,Owner.Name,AccountId,ContactId,ClosedDate,CreatedBy.Name,Subject,Primary_Product__c from Case where ClosedDate =LAST_N_DAYS:' +
							lastDays +
							' AND Status= \'Closed\' AND Sub_Status__c=\'Resolved\' AND Area__c != \'Human Identity\' AND Area__c !=\'Rapid HIT\' AND RecordType.Name =\'Tech Support\' AND CaseNumber!=\'\' AND Origin!=\'Chat\' AND (NOT Subject LIKE \'%Concierge%\')'
						);
				}
				/*  if ('Hourly'.equals(sfrequency))  
                  {
                       if(sFuncSite=='LSG - GSD')
                        CASCase=Database.Query('Select Id,CaseNumber,Origin,CreatedDate,OwnerId,Owner.Name,AccountId,ContactId,ClosedDate,CreatedBy.Name,Subject from Case where ClosedDate = TODAY AND HOUR_IN_DAY(ClosedDate) > 1 AND Status= \'Closed\' AND Sub_Status__c=\'Resolved\' AND Area__c IN (\'Human Identity\',\'Rapid HIT\') AND RecordType.Name =\'Tech Support\' AND CaseNumber!=\'\' AND Origin!=\'Chat\' AND (NOT Subject LIKE \'%Concierge%\')'); 
                   	   else
                        CASCase=Database.Query('Select Id,CaseNumber,Origin,CreatedDate,OwnerId,Owner.Name,AccountId,ContactId,ClosedDate,CreatedBy.Name,Subject from Case where ClosedDate = TODAY AND HOUR_IN_DAY(ClosedDate) > 1 AND Status= \'Closed\' AND Sub_Status__c=\'Resolved\' AND Area__c != \'Human Identity\' AND Area__c !=\'Rapid HIT\' AND RecordType.Name =\'Tech Support\' AND CaseNumber!=\'\' AND Origin!=\'Chat\' AND (NOT Subject LIKE \'%Concierge%\')');                    
                
                  }*/
				system.debug('Number of Cases found: ' + CASCase.size());
				for (Case caseRecord : CASCase) {
					accountIds.Add(caseRecord.AccountId);
					contactIds.Add(caseRecord.ContactId); //gather the contact ids and user ids associated to the event set
					userIds.add(caseRecord.OwnerId);
					caseIDProductIDMap.put(caseRecord.Id, caseRecord.Primary_Product__c);
					ProductIds.add(caseRecord.Primary_Product__c);
					// caseIds.add(caseRecord.Id);
				}
				List<Contact> contacts = [
					SELECT
						Id,
						FirstName,
						LastName,
						Email,
						Phone,
						MobilePhone,
						Account_Number__c,
						Account_Name__c,
						X7UP_Account_Country__c,
						MailingStreet,
						MailingCity,
						MailingState,
						MailingPostalCode,
						MailingCountry
					FROM Contact
					WHERE
						Email_Opt_In__c = TRUE
						AND Account_Name__c != ''
						AND Account_Name__c != '?'
						AND Account_Name__c != 'UNKNOWN'
						AND Account_Name__c != 'NO ACCOUNT LINK'
						AND FirstName != 'Unknown'
						AND LastName != 'Unknown'
						AND Email != ''
						AND (NOT Email LIKE '%UNKNOWN%')
						AND (NOT Email LIKE '%?%')
						AND (NOT Email LIKE '%@LIFETECH%')
						AND (NOT Email LIKE '%@INVITROGEN%')
						AND (NOT Email LIKE '%@APPLIEDBIOSYSTEMS%')
						AND (NOT Email LIKE '%@THERMOFISHER%')
						AND (NOT Email LIKE '%thermofisher%')
						AND ID IN :contactIds
				]; //get the set of all contacts associated to the Cases above

				Map<string, Contact> conMap = new Map<string, Contact>();

				for (Contact con : contacts) {
					conMap.put(con.Id, con);
				}
				system.debug('Number of Contacts found: ' + conMap.size());

				List<User> userList;
				if (sFuncSite == 'LSG - APJ')
					userList = [
						SELECT ID, UserRole.Name, FirstName, LastName, Name, Organization__c, EmployeeNumber
						FROM User
						WHERE Organization__c IN ('AP', 'AP-GWI', 'JP') AND ID IN :userIds
					];

				if (sFuncSite == 'LSG - EMEA')
					userList = [
						SELECT ID, UserRole.Name, FirstName, LastName, Name, Organization__c, EmployeeNumber
						FROM User
						WHERE Organization__c IN ('EMEA') AND ID IN :userIds
					];

				if (sFuncSite == 'LSG - N.A.')
					userList = [
						SELECT ID, UserRole.Name, FirstName, LastName, Name, Organization__c, EmployeeNumber
						FROM User
						WHERE Organization__c IN ('NA') AND ID IN :userIds
					];

				if (sFuncSite == 'LSG - GC')
					userList = [
						SELECT ID, UserRole.Name, FirstName, LastName, Name, Organization__c, EmployeeNumber
						FROM User
						WHERE Organization__c IN ('GC') AND ID IN :userIds
					];

				if (sFuncSite == 'LSG - GSD')
					userList = [
						SELECT ID, UserRole.Name, FirstName, LastName, Name, Organization__c, EmployeeNumber
						FROM User
						WHERE ID IN :userIds
					];

				system.debug('Number of Users found: ' + userList.size());

				Map<string, User> uMap = new Map<string, User>();
				for (User usr : userList) {
					uMap.put(usr.ID, usr);
				}

				Map<Id, Product2> caseProductRecordMap = new Map<Id, Product2>();

				/*    List<Case_Related_Products__c> caseProdList=[select Id,Case__c,Product__c from Case_Related_Products__c where Case__c IN: caseIds AND Primary__c=true];
               for(Case_Related_Products__c caseProduct: caseProdList)
               {
                   ProductIds.add(caseProduct.Product__c);
                   caseIDProductIDMap.put(caseProduct.Case__c,caseProduct.Product__c);
               }*/

				//get the primary products details
				List<Product2> productList = [
					SELECT ID, Name, Product_Line_Label__c, Platform__c, Sub_Platform__c, Business_Unit_Label__c
					FROM Product2
					WHERE ID IN :ProductIds
				];

				for (
					Product2 caseProd : productList //for each case id fetch the details of its primary product
				) {
					caseProductRecordMap.put(caseProd.Id, caseProd); //create a map of Case primary Product Id and product record
				}
				for (Case caseRecord : CASCase) {
					Contact c = conMap.get(caseRecord.ContactId); //for each Case fetch the contact that was associated to the Case from the contact set above
					User u = uMap.get(caseRecord.OwnerId);
					Product2 p = caseProductRecordMap.get(caseRecord.Primary_Product__c);

					if (c != null && u != null) {
						sEventEndDate = caseRecord.ClosedDate;
						sEventEndDt_USFormat = '';
						if (sEventEndDate != null) {
							sDay = string.valueOf(sEventEndDate.day());
							sMonth = string.valueOf(sEventEndDate.month());
							sYear = string.valueOf(sEventEndDate.year());
							sEventEndDt_USFormat = sMonth + '/' + sDay + '/' + sYear;
						}
						sAccountName = c.Account_Name__c;
						sAccountNumber = c.Account_Number__c;
                        if(p!=null)
                            sPO=p.Name;
						sRecordId = caseRecord.CaseNumber;
						sConFirstName = c.FirstName;
						sConLastName = c.LastName;
						sEmail = c.Email;
						if (c.Phone != '')
							sPhone = c.Phone;
						else if (c.MobilePhone != '')
							sPhone = c.MobilePhone;
						else
							sPhone = '';

						sCreatedBy = caseRecord.CreatedBy.Name;
						sMailingStreet = c.MailingStreet;
						sMailingCity = c.MailingCity;
						sMailingState = c.MailingState;
						sMailingPostalCode = c.MailingPostalCode;
						sMailingCountry = c.MailingCountry;
						sAgentFirstName = u.FirstName;
						sAgentLastName = u.LastName;
						sAgentName = u.Name;
						sRegion = u.Organization__c;
						sEmployeeNumber = u.EmployeeNumber;
						if (
							p != null //if a product is associated to the case
						) {
							sProductsOfInterest = p.Product_Line_Label__c;
							sPlatform = p.Platform__c;
							sSubPlatform = p.Sub_Platform__c;
							sBusinessUnitLabel = p.Business_Unit_Label__c;
						}
						if (sProductsOfInterest == null || sProductsOfInterest == '')
							sProductsOfInterest = '';
						else {
							if (sProductsOfInterest.indexOf(',') != -1)
								sProductsOfInterest.replace(',', ' ');

							//if there is any newline character  or comma  replace it with tab
							sProductsOfInterest = '\"' + sProductsOfInterest + '\"';
							sProductsOfInterest = sProductsOfInterest.replace('\r\n', ' ');
							sProductsOfInterest = sProductsOfInterest.replace('\n', ' ');
							sProductsOfInterest = sProductsOfInterest.replace('\r', ' ');
						}
						if (sBusinessUnitLabel == null || sBusinessUnitLabel == '')
							sBusinessUnitLabel = '';
						else {
							if (sBusinessUnitLabel.indexOf(',') != -1)
								sBusinessUnitLabel.replace(',', ' ');

							//if there is any newline character  or comma  replace it with tab
							sBusinessUnitLabel = '\"' + sBusinessUnitLabel + '\"';
							sBusinessUnitLabel = sBusinessUnitLabel.replace('\r\n', ' ');
							sBusinessUnitLabel = sBusinessUnitLabel.replace('\n', ' ');
							sBusinessUnitLabel = sBusinessUnitLabel.replace('\r', ' ');
						}
                       //  sProductLine=sBusinessUnitLabel;  //temporarily removing this until the invalid PL issue is figured out. will be uploaded to LUV5 instead
						if (sAccountName == null)
							sAccountName = '';
						else {
							sAccountName = sAccountName.replace('\r\n', ' ');
							sAccountName = sAccountName.replace('\n', ' ');
							sAccountName = sAccountName.replace('\r', ' ');
						}
						if (sAccountName.indexOf(',') != -1)
							sAccountName = '\"' + sAccountName + '\"';
						if (sConFirstName.indexOf(',') != -1)
							sConFirstName = '\"' + sConFirstName + '\"';
						if (sConLastName.indexOf(',') != -1)
							sConLastName = '\"' + sConLastName + '\"';
						if (sPhone == null)
							sPhone = '';

						if (sMailingStreet == null || sMailingStreet == '')
							sMailingStreet = '';
						else {
							if (sMailingStreet.indexOf(',') != -1)
								sMailingStreet.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sMailingStreet = '\"' + sMailingStreet + '\"';
							sMailingStreet = sMailingStreet.replace('\r\n', ' ');
							sMailingStreet = sMailingStreet.replace('\n', ' ');
							sMailingStreet = sMailingStreet.replace('\r', ' ');
						}

						if (sMailingCity == null || sMailingCity == '')
							sMailingCity = '';
						else {
							if (sMailingCity.indexOf(',') != -1)
								sMailingCity.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sMailingCity = '\"' + sMailingCity + '\"';
							sMailingCity = sMailingCity.replace('\r\n', ' ');
							sMailingCity = sMailingCity.replace('\n', ' ');
							sMailingCity = sMailingCity.replace('\r', ' ');
						}

						if (sMailingState == null || sMailingState == '')
							sMailingState = '';
						else {
							if (sMailingState.indexOf(',') != -1)
								sMailingState.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sMailingState = '\"' + sMailingState + '\"';
							sMailingState = sMailingState.replace('\r\n', ' ');
							sMailingState = sMailingState.replace('\n', ' ');
							sMailingState = sMailingState.replace('\r', ' ');
						}
						if (sMailingPostalCode == null || sMailingPostalCode == '')
							sMailingPostalCode = '';
						else {
							if (sMailingPostalCode.indexOf(',') != -1)
								sMailingPostalCode.replace(',', ' ');

							//if there is any newline character  or comma within the street address replace it with tab
							sMailingPostalCode = '\"' + sMailingPostalCode + '\"';
							sMailingPostalCode = sMailingPostalCode.replace('\r\n', ' ');
							sMailingPostalCode = sMailingPostalCode.replace('\n', ' ');
							sMailingPostalCode = sMailingPostalCode.replace('\r', ' ');
						}

						if (sMailingCity == null)
							sMailingCity = '';
						if (sMailingState == null)
							sMailingState = '';
						if (sMailingPostalCode == null)
							sMailingPostalCode = '';
						if (sMailingCountry == null)
							sMailingCountry = '';

						sBrand = 'Life Sciences Solutions No Product Question';

						//////////////////derive survey language based on Contact's Account's Country///
						sAccountCountry = c.X7UP_Account_Country__c;
						List<CAS_Country_Language__mdt> countryCodeList = [
							SELECT ID, Country_Code__c, Language__c
							FROM CAS_Country_Language__mdt
							WHERE MasterLabel = :sAccountCountry
						];

						// get the language from custom metadata type
						for (CAS_Country_Language__mdt cntry : countryCodeList) {
							sLanguage = cntry.Language__c;
						}

						if (sLanguage == null || sLanguage == '')
							sLanguage = 'English';
						///////////////////////end language///////////////////////////////////////////////

						//////////////////////////////////////////////////
						sLetterUploadVar1 = 'Case: ' + sRecordId;
						sLetterUploadVar2 = 'Technical Support Scientist: ' + sAgentFirstName + ' ' + sAgentLastName;
						sLetterUploadVar3 = caseRecord.Subject;

						if (sLetterUploadVar3 != null) {
							if (sLetterUploadVar3.indexOf(',') != -1)
								sLetterUploadVar3 = sLetterUploadVar3.replace(',', ' ');
						} else
							sLetterUploadVar3 = '';
						/////////////////////////////////////////////////////////////

						sUploadVar1 = caseRecord.Origin;
						sUploadVar2 = sEventEndDt_USFormat;
						sUploadVar3 = sProductsOfInterest; //product description
						sUploadVar4 = caseRecord.Owner.Name;
                        sUploadVar5= sBusinessUnitLabel;
						sUploadVar6 = sSubPlatform;
						sUploadVar7 = sPlatform;

						 if(sUploadVar5==null || sUploadVar5=='')
                 							sUploadVar5='';
                                      else  { 
           									 if(sUploadVar5.indexOf(',')!=-1) sUploadVar5.replace(',',' ');
											  
											  //if there is any newline character  or comma within the street address replace it with tab
                                         		sUploadVar5='\"'+sUploadVar5+'\"';
												sUploadVar5=sUploadVar5.replace('\r\n',' ');
												sUploadVar5=sUploadVar5.replace('\n',' ');
												sUploadVar5=sUploadVar5.replace('\r',' ');
                                      }

						if ((sMailingCountry == '' || sMailingCountry == null) && sAccountCountry != '')
							sMailingCountry = sAccountCountry;
						
                       

						if (sMailingCountry == null || sMailingCountry == '')
							sMailingCountry = '';
						else {
							if (sMailingCountry.indexOf(',') != -1) {
								//if there is any newline character  or comma within the street address replace it with tab
								sMailingCountry = '\"' + sMailingCountry + '\"';
								sMailingCountry = sMailingCountry.replace('\r\n', ' ');
								sMailingCountry = sMailingCountry.replace('\n', ' ');
								sMailingCountry = sMailingCountry.replace('\r', ' ');
                                
                                 if (sMailingCountry.indexOf('Korea') != -1) 
                                 {
                                        sMailingCountry = 'Korea, Republic of';
                                        sLanguage = 'Korean';
								 }
							}
						}
						if (sRegion == 'EMEA') {
							sAgentName = sEmployeeNumber;
							sLetterUploadVar2 = '';
							sUploadVar4 = sEmployeeNumber;
						}

						recordString =
							sDivName +
							',' +
							sBusUnit +
							',' +
							sFuncSite +
							',' +
							sSurveyID +
							',' +
							sAccountName +
							',' +
							sAccountNumber +
							',' +
							sConFirstName +
							',' +
							sConLastName +
							',' +
							sMailingStreet +
							',' +
							sMailingCity +
							',' +
							sMailingState +
							',' +
							sMailingPostalCode +
							',' +
							sMailingCountry +
							',' +
							sPhone +
							',' +
							sEmail +
							',' +
							sLanguage +
							',' +
							sEventEndDt_USFormat +
							',' +
							sAgentName +
							',' +
							sProductLine +
							',' +
                            sPO +
							',' +
							sRecordId +
							',' +
							',' +
							',' +
							sBrand +
							',' +
							sLetterUploadVar1 +
							',' +
							sLetterUploadVar2 +
							',' +
							sLetterUploadVar3 +
							',' +
							sUploadVar1 +
							',' +
							sUploadVar2 +
							',' +
							sUploadVar3 +
							',' +
							sUploadVar4 +
							',' +
							sUploadVar5 +
							',' +
							sUploadVar6 +
							',' +
							sUploadVar7 +
							'\n';
						DedupCASMap.put(sEmail, recordString);
						//finalstr= finalstr + recordString; //append to the previous record
					} else
						//if c!=null
						system.debug('Case Record not found');
					sEventEndDt_USFormat = '';
					sAccountName = '';
					sConFirstName = '';
					sConLastName = '';
					sEmail = '';
                    sPO='';
					sPhone = '';
					sCreatedBy = '';
					sSalesRepFstName = '';
					sSalesRepLastName = '';
					sSalesRepRole = '';
					sProductFamily = '';
					sMailingStreet = '';
					sMailingCity = '';
					sMailingState = '';
					sMailingPostalCode = '';
					sMailingCountry = '';
					sSalesRepFstName = '';
					sSalesRepLastName = '';
					sSalesRepName = '';
					sRegion = '';
					sOptyNumber = '';
					sManagerName = '';
					sLanguage = '';
					sEmployeeNumber = '';
					sPlatform = '';
					sSubPlatform = '';
					sBusinessUnitLabel = '';
                    sProductLine='';
					sAgentName = '';
					sProductsOfInterest = '';
					sSalesRepRole = '';
					sAccountIndustry = '';
					sLetterUploadVar1 = '';
					sLetterUploadVar2 = '';
					sLetterUploadVar3 = '';
					sUploadVar1 = '';
					sUploadVar2 = '';
					sUploadVar3 = '';
					sUploadVar4 = '';
					sUploadVar5 = '';
					sUploadVar6 = '';
					sUploadVar7 = '';
				} //end of loop for(Case casRecord:CASCase)

				//remove any duplicates
				if (DedupCASMap.size() > 0) {
					for (String dedupkeystr : DedupCASMap.keyset()) {
						finalstr = finalstr + DedupCASMap.get(dedupkeystr); //append to the previous record
					}
				}
				//end of duplicate removal
			} //if(sTransactionType=='Case')

			/////////////////////////////end Cases///////////////////////////////////////////////////

			/////apply sample size on the final output based on the sampe size type specified on the cas record//////////////////////
			if (SamplePercent == null)
				SamplePercent = 100;

			if (SampleSizeType == 'Percent') {
				String[] EventList = finalstr.split('\n');
				TotalCount = EventList.size();
				Decimal temp = (SamplePercent / 100) * TotalCount;
				FinalSize = Integer.valueOf(temp.round(System.RoundingMode.UP));

				string tempstr = '';
				for (Integer i = 0; i < FinalSize; i++) {
					tempstr = tempstr + EventList.get(i) + '\n';
				}
				finalstr = tempstr;
			}
			if (SampleSizeType == 'Record Count') {
				String[] EventList = finalstr.split('\n');
				TotalCount = EventList.size();

				if (TotalCount < Integer.valueOf(SampleRecordCount))
					FinalSize = TotalCount;
				else
					FinalSize = Integer.valueOf(SampleRecordCount);

				string tempstr = '';
				for (Integer i = 0; i < FinalSize; i++) {
					tempstr = tempstr + EventList.get(i) + '\n';
				}
				finalstr = tempstr;
			}

			////////////////////////////////////////////////////////////////
			/////////////////////////////////wrap up////////////////////////////////////////////////////////////////

			DateTime currentDay = System.today();
			String currentDayStr = string.valueOf(currentDay);
			if (sIncludeHeader == 'Yes') {
				if (sFileFormat == 'PSV') {
					psvheader =
						'Division|Business Unit|Functional Site|Survey ID|Company Name|Account|First Name|Last Name|Address|City|State or Province|Zip or Postal Code|Country|Phone Number|Email|Language|Event Date|Name/ID of Employee|Product Line|PO|Transaction ID/Ticket ID #|Sales Won?|Loaner/Product Type|Brand|Letter Upload 1/Product Description|Letter Upload 2|Letter Upload 3|Upload Variable 1|Upload Variable 2|Upload Variable 3|Upload Variable 4|Upload Variable 5|Upload Variable 6|Upload Variable 7' +
						'\n';
					finalstr = psvheader + finalstr;
					filename =
						sTransactionType +
						'_' +
						sFuncSite +
						'_' +
						sDivName +
						'_' +
						sSurveyID +
						'_' +
						'CAS' +
						'_' +
						currentDayStr +
						'.psv';
				}
				if (sFileFormat == 'CSV') {
					csvheader =
						'Division,Business Unit,Functional Site,Survey ID,Company Name,Account,First Name,Last Name,Address,City,State or Province,Zip or Postal Code,Country,Phone Number,Email,Language,Event Date,Name/ID of Employee,Product Line,PO,Transaction ID/Ticket ID #,Sales Won?,Loaner/Product Type,Brand,Letter Upload 1/Product Description,Letter Upload 2,Letter Upload 3,Upload Variable 1,Upload Variable 2,Upload Variable 3,Upload Variable 4,Upload Variable 5,Upload Variable 6,Upload Variable 7' +
						'\n';
					finalstr = csvheader + finalstr;
					filename =
						sTransactionType +
						'_' +
						sFuncSite +
						'_' +
						sDivName +
						'_' +
						sSurveyID +
						'_' +
						'CAS' +
						'_' +
						currentDayStr +
						'.csv';
				}
			} else {
				if (sFileFormat == 'PSV') {
					filename =
						sTransactionType +
						'_' +
						sFuncSite +
						'_' +
						sDivName +
						'_' +
						sSurveyID +
						'_' +
						'CAS' +
						'_' +
						currentDayStr +
						'.psv';
				}
				if (sFileFormat == 'CSV') {
					filename =
						sTransactionType +
						'_' +
						sFuncSite +
						'_' +
						sDivName +
						'_' +
						sSurveyID +
						'_' +
						'CAS' +
						'_' +
						currentDayStr +
						'.csv';
				}
			}
			////////////////////////////////////////////////////////////////////
			if (finalstr != '') {
				Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
				Blob csvBlob = Blob.valueOf('\uFEFF' + finalstr);

				csvAttc.setFileName(filename);
				csvAttc.setBody(csvBlob);

				String[] emailAddresses = new List<String>{};
				List<CAS_Setting__mdt> CAS_EmailList = [
					SELECT ID, Email_Address__c, Email_Subject__c, Sender_Display_Name__c
					FROM CAS_Setting__mdt
					WHERE MasterLabel = 'CAS Email'
				];
				for (CAS_Setting__mdt casEmail : CAS_EmailList) {
					if (casEmail.Email_Address__c != null)
						emailAddresses.add(casEmail.Email_Address__c);
					emailSubject = casEmail.Email_Subject__c;
					senderDisplayName = casEmail.Sender_Display_Name__c;
				}

				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				mail.setToAddresses(emailAddresses);

				mail.setSenderDisplayName(senderDisplayName);
				mail.setSubject(emailSubject);
				mail.setPlainTextBody(
					'CAS extract file attached. Division=' +
					sDivName +
					' \n Business Unit= ' +
					sBusUnit
				);
				mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ csvAttc });
				//  listmail.add(mail);
				// }
				Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
				//    Messaging.sendEmail(mail);

				//////////////////////////////////////////////

				//attach the file as an attachment to the corresponding CAS Prime record
				CAS_Prime__c casprime = [SELECT id, name FROM CAS_Prime__c WHERE id = :sCASPrimeId]; //attach the extract as an attachment to the CAS prime record
				if (casprime != null) {
					Attachment attCASFile = new Attachment();
					attCASFile.parentId = casprime.id;
					attCASFile.ContentType = 'text/plain';
					attCASFile.name = filename;
					attCASFile.body = Blob.valueOf('\uFEFF' + finalstr);
					if (finalstr.length() > 1)
						insert attCASFile;
				}
			} //if(finalstr !='')
		} catch (Exception e) {
			//try
			string errEmailTo = '';
			string senderDisplayName = '';
			string errEmailSubject = '';
			String[] errToAddresses = new List<String>{};
			List<CAS_Setting__mdt> CAS_EmailList = [
				SELECT ID, Email_Address__c, Error_Subject__c, Sender_Display_Name__c
				FROM CAS_Setting__mdt
				WHERE MasterLabel = 'CAS Email'
			];
			for (CAS_Setting__mdt casEmail : CAS_EmailList) {
				if (casEmail.Email_Address__c != null)
					errToAddresses.add(casEmail.Email_Address__c);
				errEmailSubject = casEmail.Error_Subject__c;
				senderDisplayName = casEmail.Sender_Display_Name__c;
			}

			List<Messaging.SingleEmailMessage> Listmail = new List<Messaging.SingleEmailMessage>();
			for (String recipients : errToAddresses) {
				Messaging.SingleEmailMessage errmail = new Messaging.SingleEmailMessage();
				errmail.setToAddresses(errToAddresses);
				errmail.setSenderDisplayName(senderDisplayName);
				errmail.setSubject(errEmailSubject);
				errmail.setPlainTextBody(
					'Error in Apex job for CASPrime ID: ' +
					sCASPrimeId +
					' , ' +
					'SurveyID: ' +
					sSurveyID +
					' ERROR LINE#:' +
					e.getLineNumber() +
					' ERROR CAUSE: ' +
					e.getCause() +
					' ERROR MESSAGE: ' +
					e.getMessage()
				);
				Listmail.add(errmail);
			}
			// Messaging.sendEmail(new Messaging.SingleEmailMessage[] {errmail});
			if (!Test.isRunningTest())
				Messaging.sendEmail(Listmail);
		} finally {
			//catch
		}
	} //generate extract
} //end class