// ===========================================================================
//  Object	: 	PhoneFormatUtility
// 	Company	: 	Keste @IDC
//  Author	: 	Basant Kumar Verma
// 	Purpose	: 	Utility Class to handle all Phone Number Formating
// ===========================================================================
public class PhoneFormatUtility {
	//ALL PRIVATE ATTRIBUTES
	private static final String DEFAULT_JOIN = ' ';
	private static final String COUNTRY_CODE_KEY = '+';
	private static final String EXTENSION_KEY = 'x';
	private static final String MERGE_PHONE = '{PHONE}';
	private static final String MERGE_FORMAT = '{FORMAT}';
	private static final String UNKNOWN_ERROR = 'Unknown';
	private static final String SUCCESS = 'Phone formatting done successfully.';
	private static final String INVALID_INPUTS = 'Invalid Inputs: Both Phone and Country Name is requred for Phone Formatting.';
	private static final String COUNTRY_FORMAT_MISSING = 'Country Format is missing in configuration, please contact system admin.';
	private static final String LESS_THEN_FORMAT =
		'Digits in requested phone number [' +
		MERGE_PHONE +
		'] are less then requied digits in format [' +
		MERGE_FORMAT +
		']';
	private static final String MORE_THEN_FORMAT =
		'Digits in requested phone number [' +
		MERGE_PHONE +
		'] are more then requied digits in format [' +
		MERGE_FORMAT +
		']';
	private static final String CONUNTRY_CODE_MISSMATCH =
		'Country code in requested phone number [' +
		MERGE_PHONE +
		'] are not matched with configured Country Code [' +
		MERGE_FORMAT +
		']';

	private static Set<Integer> oneDigitCountryCodes = new Set<Integer>();
	private static Map<Integer, String> countryCodeWithNames = new Map<Integer, String>();

	//ALL PUBLIC ATTRIBUTES
	public Boolean isSuccess { get; set; }
	public String statusMessage { get; set; }
	public String rawPhone { get; set; }
	public String countryName { get; set; }
	public String countryPhoneFormat { get; set; }
	public String countryCode { get; set; }
	public String formatedPhone { get; set; }

	//START - ALL PRIVATE METHODS
	private static Map<String, Phone_Number_Format_Data_Standards__c> phoenFormatMap {
		get {
			if (phoenFormatMap == null) {
				phoenFormatMap = new Map<String, Phone_Number_Format_Data_Standards__c>();
				countryCodeWithNames = new Map<Integer, String>();
				for (Phone_Number_Format_Data_Standards__c ob : [
					SELECT Id, Name, Phone_Format__c, Mobile_Phone_Format__c, Country_Code__c
					FROM Phone_Number_Format_Data_Standards__c
					WHERE isActive__c = TRUE
				]) {
					phoenFormatMap.put(ob.Name, ob);
					countryCodeWithNames.put(Integer.valueOf(ob.Country_Code__c), ob.Name);
					if (ob.Country_Code__c < 10) {
						oneDigitCountryCodes.add(Integer.valueOf(ob.Country_Code__c));
					}
				}
			}
			return phoenFormatMap;
		}
		set;
	}
	//END - ALL PRIVATE METHODS

	//CONSTRUCTOR
	public PhoneFormatUtility(String formatConfig, String rawPhone, String countryName1) {
		doInit(formatConfig, rawPhone, countryName1, null);
	}

	public PhoneFormatUtility(String formatConfig, String rawPhone, String countryName1, String countryName2) {
		doInit(formatConfig, rawPhone, countryName1, countryName2);
	}

	private void doInit(String formatConfig, String rawPhone, String countryName1, String countryName2) {
		CommonUtilities.debug('======== rawPhone: ' + rawPhone);
		CommonUtilities.debug('======== countryName1: ' + countryName1);
		CommonUtilities.debug('======== countryName2: ' + countryName2);

		this.isSuccess = false;
		this.statusMessage = UNKNOWN_ERROR;
		if (String.isNotBlank(rawPhone)) {
			this.rawPhone = rawPhone.trim();
			/*Integer countryCodeFromPhone = fetchCountryCodeIfAvailable();
            CommonUtilities.debug('======== countryCodeFromPhone: '+countryCodeFromPhone); 
            CommonUtilities.debug('======== countryCodeWithNames: '+countryCodeWithNames);
            */

			if (phoenFormatMap != null) {
				/*if(countryCodeFromPhone != null && countryCodeWithNames.containsKey(countryCodeFromPhone)){
                    this.countryName = countryCodeWithNames.get(countryCodeFromPhone);
                }else */
				if (String.isNotBlank(countryName1) && phoenFormatMap.containsKey(countryName1)) {
					this.countryName = countryName1;
				} else if (String.isNotBlank(countryName2) && phoenFormatMap.containsKey(countryName2)) {
					this.countryName = countryName2;
				} else {
					this.countryName = null;
				}
			}

			this.formatedPhone = this.rawPhone;
			CommonUtilities.debug('======== this.countryName: ' + this.countryName);

			if (
				String.isNotBlank(this.countryName) &&
				phoenFormatMap != null &&
				phoenFormatMap.containsKey(this.countryName)
			) {
				this.countryPhoneFormat = (String) phoenFormatMap.get(this.countryName).get(formatConfig);
				this.countryCode = String.valueOf(phoenFormatMap.get(this.countryName).Country_Code__c);
			}

			if (String.isNotBlank(countryPhoneFormat)) {
				validateAndFormat();
			} else {
				this.statusMessage = COUNTRY_FORMAT_MISSING;
			}
		} else {
			this.statusMessage = INVALID_INPUTS;
		}
	}

	//METHOD TO DO ALL VALIDATION AND PHONE FORMATTING
	/*private Integer fetchCountryCodeIfAvailable(){
        Integer countryCodeFromPhone = null;
        if(!String.isBlank(rawPhone)){
            if(rawPhone.startsWith(COUNTRY_CODE_KEY)){
                Integer codeDigit1, codeDigit2;
                for(String str : rawPhone.split('')){
                    if(str.isNumeric()){
                        if(codeDigit1 == null){
                            codeDigit1 = Integer.valueOf(str);
                        }else{
                            codeDigit2 = Integer.valueOf(str);
                            break;
                        }
                    }
                }
                
                if(codeDigit1 != null && codeDigit2 != null){
                    if(oneDigitCountryCodes != null && oneDigitCountryCodes.contains(codeDigit1)){
                        countryCodeFromPhone = codeDigit1;
                    }else{
                        countryCodeFromPhone = codeDigit1*10+codeDigit2;
                    }
                }
            }
        }
        return countryCodeFromPhone;
    }*/

	//METHOD TO DO ALL VALIDATION AND PHONE FORMATTING
	private void validateAndFormat() {
		formatedPhone = rawPhone;
		List<String> phoneArr = new List<String>();
		List<String> phoneFormatArr = countryPhoneFormat.split('');
		Integer index = 0, requiredNumeric = 0;

		//Identifying total number of numeric fields in format
		for (Integer i = 0; i < phoneFormatArr.size(); i++) {
			if (phoneFormatArr[i].isNumeric()) {
				requiredNumeric++;
			}
		}

		//Identifying total number of numeric fields in provided phone
		String extensionDetails = '';
		Boolean isExtensionDetected = false, isWithCountryCode = false;

		//FILTER ALL NUMERIC DIGITS ONLY
		for (String str : rawPhone.split('')) {
			if (!isExtensionDetected && str.isNumeric()) {
				phoneArr.add(str);
			} else if (str.trim().equalsIgnoreCase(EXTENSION_KEY)) {
				isExtensionDetected = true;
			} else if (isExtensionDetected) {
				extensionDetails += str;
			}
		}

		//START - All Validations
		//Check if Country Code Is Provided
		if (rawPhone.startsWith(COUNTRY_CODE_KEY)) {
			isWithCountryCode = true;
			List<String> configuredCountryCodeArr = countryCode.split('');
			Boolean isError = false;
			if (configuredCountryCodeArr.size() <= phoneArr.size()) {
				for (Integer i = 0; i < configuredCountryCodeArr.size(); i++) {
					if (phoneArr[i] != configuredCountryCodeArr[i]) {
						statusMessage = CONUNTRY_CODE_MISSMATCH.replace(MERGE_PHONE, rawPhone)
							.replace(MERGE_FORMAT, countryCode);
						isError = true;
						break;
					}
				}

				if (!isError) {
					for (Integer i = 0; i < configuredCountryCodeArr.size(); i++) {
						phoneArr.remove(0);
					}
				}
			} else {
				statusMessage = CONUNTRY_CODE_MISSMATCH.replace(MERGE_PHONE, rawPhone)
					.replace(MERGE_FORMAT, countryCode);
				isError = true;
			}
		}

		//CHECK FOR NUMBER OF DIGITS PROVIDED VS REQUIRED
		if (statusMessage == UNKNOWN_ERROR && phoneArr.size() < requiredNumeric) {
			statusMessage = LESS_THEN_FORMAT.replace(MERGE_PHONE, rawPhone).replace(MERGE_FORMAT, countryPhoneFormat);
		} else if (statusMessage == UNKNOWN_ERROR && phoneArr.size() > requiredNumeric) {
			statusMessage = MORE_THEN_FORMAT.replace(MERGE_PHONE, rawPhone).replace(MERGE_FORMAT, countryPhoneFormat);
		}
		//END - All Validations

		//PERFORM FORMATING ONLY AND ONLY IF THE NUMERIC DIGITS MATCHES
		if (phoneArr.size() == requiredNumeric && statusMessage == UNKNOWN_ERROR) {
			for (Integer i = 0; i < phoneFormatArr.size(); i++) {
				if (phoneFormatArr[i].isNumeric()) {
					phoneFormatArr[i] = phoneArr[index];
					index++;
				}
			}
			//CORE PHONE FORMATTING
			formatedPhone = String.join(phoneFormatArr, '');

			//APPENDING EXTENTION
			if (isExtensionDetected) {
				formatedPhone += DEFAULT_JOIN + EXTENSION_KEY + extensionDetails;
			}

			//APPENDING COUNTRY CODE
			if (isWithCountryCode) {
				formatedPhone = COUNTRY_CODE_KEY + countryCode + DEFAULT_JOIN + formatedPhone;
			}
			isSuccess = true;
			statusMessage = SUCCESS;
		}
	}
}