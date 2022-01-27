global class gl_CustomContactLookupController {
	public List<Contact> contact_results { get; set; } // search results
	public List<Contact> contact_results1 { get; set; } // search results for FirstName
	public List<Contact> contact_results2 { get; set; } // search results for LastName
	public List<Contact> contact_results3 { get; set; } // search results for Email

	//public List<Account> account_results {get;set;} // search results

	public string searchString { get; set; } // search keyword, set either by invoking page or via URI
	public string firstName { get; set; } // set by invoking page
	public string lastName { get; set; } // set by invoking page
	public string email { get; set; } // set by invoking page
	public string phoneNumber { get; set; }

	public static string ixnId { get; set; } // interaction id, set via URI

	public gl_CustomContactLookupController() {
		// get the current search string
		searchString = System.currentPageReference().getParameters().get('lksrch');
		ixnId = System.currentPageReference().getParameters().get('ixnId');
		system.debug('*** CustomContactLookupController ixnId ' + ixnId);
		system.debug('*** CustomContactLookupController search for ' + searchString);

		if (searchString != '' && searchString != null) {
			runSearch();
		}
	}

	// performs the keyword search
	global PageReference search() {
		system.debug('*** search');
		runSearch();
		return null;
	}

	// prepare the query and issue the search command
	private void runSearch() {
		system.debug('*** runSearch');
		performSearch(searchString);
	}

	public void updateContactResults(Map<Id, Contact> contactMap, List<Contact> resultObjects) {
		for (Contact resultObj : resultObjects) {
			contactMap.put(resultObj.Id, resultObj);
		}
	}

	// run the search and save the records found.
	private void performSearch(string searchString) {
		system.debug('*** performSearch for ' + searchString);

		List<List<SObject>> objs = null;
		contact_results = new List<Contact>();
		contact_results1 = null;
		contact_results2 = null;
		contact_results3 = null;
		Integer listSize = 0;
		//Fix for contact duplicate issue
		Map<Id, Contact> contactMap = new Map<Id, Contact>();

		system.debug('*** phoneNumber = ' + phoneNumber);
		system.debug('*** firstName = ' + firstName);
		system.debug('*** lastName = ' + lastName);
		system.debug('*** email = ' + email);

		if (searchString != null && searchString != '') {
			system.debug('*** performSearch for before replace all');
			searchString = searchString.replaceAll('MyAmpersand', '\\&');
			searchString = searchString.replaceAll('SingleQuote', '\\\'');
			system.debug('*** performSearch for searchString after modification: ' + searchString);
			List<Contact> test = (List<Contact>) System.JSON.deserialize(searchString, List<Contact>.class);
			//Fix for contact duplicate issue
			//contact_results.addAll((List<Contact>) test);
			updateContactResults(contactMap, (List<Contact>) test);
			/* 
            objs = [find :searchString in phone fields returning Contact(Account.Name, Account.BillingPostalCode, Id, 
                    Name, FirstName, LastName, 
                    MailingStreet, 
                    EMail, 
                    Phone, MobilePhone, HomePhone, AssistantPhone, OtherPhone)];
            listSize = objs.size();
            system.debug('*** contact listSize = ' + listSize);
            List<Contact> contacts = null;
            if (!objs.isEmpty()) {
                contact_results.addAll((List<Contact>) objs[0]);
            }
            */
		}
		system.debug('*** contact_results from searchString = ' + contact_results);

		try {
			if (phoneNumber != null && phoneNumber != '') {
				objs = [
					FIND :phoneNumber
					IN PHONE FIELDS
					RETURNING
						Contact(
							Account.Name,
							Account.BillingPostalCode,
							Id,
							Name,
							FirstName,
							LastName,
							MailingStreet,
							EMail,
							Phone,
							MobilePhone,
							HomePhone,
							AssistantPhone,
							OtherPhone,
							LastModifiedDate
							ORDER BY LastModifiedDate DESC
							LIMIT 100)
				];
				listSize = objs.size();
				system.debug('*** contact listSize = ' + listSize);
				system.debug('*** objs = ' + objs);
				system.debug('*** contact objs[0] = ' + objs[0]);
				if (!objs.isEmpty()) {
					//Fix for contact duplicate issue
					//contact_results.addAll((List<Contact>) objs[0]);
					updateContactResults(contactMap, (List<Contact>) objs[0]);

					//contact_results=addUniqueSobjects(contact_results,objs[0]);
				}
			}

			if (firstName != null && firstName != '') {
				string term = '%' + firstName + '%';
				system.debug('*** contact search term = ' + term);
				/*List<Contact> contact_results1 = [select  Account.Name, Account.BillingPostalCode, Id, 
                        Name, FirstName, LastName, 
                        MailingStreet, 
                        EMail,
                        Phone, MobilePhone, HomePhone, AssistantPhone, OtherPhone 
                        from contact where FirstName like :term];
                system.debug('*** contact listSize1 = ' + contact_results1.size());
                system.debug('*** contact_results1 = ' + contact_results1);
                contact_results.addAll(contact_results1);*/

				objs = [
					FIND :firstName
					IN NAME FIELDS
					RETURNING
						Contact(
							Account.Name,
							Account.BillingPostalCode,
							Id,
							Name,
							FirstName,
							LastName,
							MailingStreet,
							EMail,
							Phone,
							MobilePhone,
							HomePhone,
							AssistantPhone,
							OtherPhone,
							LastModifiedDate
							WHERE firstName LIKE :term
							ORDER BY LastModifiedDate DESC
							LIMIT 100)
				];
				listSize = objs.size();
				system.debug('*** contact listSize1 = ' + listSize);
				system.debug('*** objs = ' + objs);
				system.debug('*** contact objs[0] = ' + objs[0]);
				if (!objs.isEmpty()) {
					//Fix for contact duplicate issue
					//contact_results.addAll((List<Contact>) objs[0]);
					updateContactResults(contactMap, (List<Contact>) objs[0]);
					//contact_results=addUniqueSobjects(contact_results,objs[0]);
				}
			}

			if (lastName != null && lastName != '') {
				string term1 = '%' + lastName + '%';
				system.debug('*** contact search last name term = ' + term1);
				/*List<Contact> contact_results2 = [select Account.Name, Account.BillingPostalCode, Id, 
                        Name, FirstName, LastName, 
                        MailingStreet, 
                        EMail,
                        Phone, MobilePhone, HomePhone, AssistantPhone, OtherPhone 
                        from contact where LastName like :term];
                system.debug('*** contact listSize2 = ' + contact_results2.size());
                system.debug('*** contact_results2 = ' + contact_results2);
                contact_results.addAll(contact_results2);*/

				objs = [
					FIND :lastName
					IN NAME FIELDS
					RETURNING
						Contact(
							Account.Name,
							Account.BillingPostalCode,
							Id,
							Name,
							FirstName,
							LastName,
							MailingStreet,
							EMail,
							Phone,
							MobilePhone,
							HomePhone,
							AssistantPhone,
							OtherPhone,
							LastModifiedDate
							WHERE LastName LIKE :term1
							ORDER BY LastModifiedDate DESC
							LIMIT 100)
				];
				listSize = objs.size();
				system.debug('*** contact listSize2 = ' + listSize);
				system.debug('*** objs = ' + objs);
				system.debug('*** contact objs[0] = ' + objs[0]);
				if (!objs.isEmpty()) {
					//Fix for contact duplicate issue
					//contact_results.addAll((List<Contact>) objs[0]);
					updateContactResults(contactMap, (List<Contact>) objs[0]);
					//contact_results=addUniqueSobjects(contact_results,objs[0]);
				}
			}

			if (email != null && email != '') {
				//string term2 = '%' + email + '%';
				//Fix for email search issue - searches email starts with search term -- EASFP-24
				string term2 = email + '*';
				system.debug('*** contact search email term = ' + term2);
				/*List<Contact> contact_results3 = [select Account.Name, Account.BillingPostalCode, Id, 
                        Name, FirstName, LastName, 
                        MailingStreet, 
                        EMail,
                        Phone, MobilePhone, HomePhone, AssistantPhone, OtherPhone 
                        from contact where Email like :term];
                system.debug('*** contact listSize3 = ' + contact_results3.size());
                system.debug('*** contact_results3 = ' + contact_results3);
                contact_results.addAll(contact_results3);*/
				objs = [
					FIND :term2
					IN EMAIL FIELDS
					RETURNING
						Contact(
							Account.Name,
							Account.BillingPostalCode,
							Id,
							Name,
							FirstName,
							LastName,
							MailingStreet,
							EMail,
							Phone,
							MobilePhone,
							HomePhone,
							AssistantPhone,
							OtherPhone,
							LastModifiedDate
							ORDER BY LastModifiedDate DESC
							LIMIT 100)
				];
				listSize = objs.size();
				system.debug('*** contact listSize3 = ' + listSize);
				system.debug('*** objs = ' + objs);
				system.debug('*** contact objs[0] = ' + objs[0]);
				if (!objs.isEmpty()) {
					//Fix for contact duplicate issue
					//contact_results.addAll((List<Contact>) objs[0]);
					updateContactResults(contactMap, (List<Contact>) objs[0]);
					//contact_results=addUniqueSobjects(contact_results,objs[0]);
				}
			}
			system.debug('*** TOTAL contact_results= ' + contact_results);

			// Use custom sorting
			if (contactMap.size() != 0) {
				//contact_results.addAll(contactMap.values());
				// Set<Contact> myset = new Set<Contact>();
				List<gl_ContactWrapper> myresult = new List<gl_ContactWrapper>();
				// //this removes the duplicates since list is not allowed dups
				// myset.addAll(contact_results);
				for (Contact c : contactMap.values()) {
					myresult.add(new gl_ContactWrapper(c));
				}
				myresult.sort();

				contact_results.clear();
				Integer count = 0;
				for (gl_ContactWrapper gl_c : myresult) {
					count = count + 1;
					if (count <= 100) {
						contact_results.add(gl_c.getContact());
					}
				}
			}
		} catch (Exception e) {
			system.debug('*** ERROR = ' + e);
		}
	}

	// used by the visualforce page to send the link to the right dom element
	public string getFormTag() {
		return System.currentPageReference().getParameters().get('frm');
	}

	// used by the visualforce page to send the link to the right dom element for the text box
	public string getTextBox() {
		return System.currentPageReference().getParameters().get('txt');
	}
}