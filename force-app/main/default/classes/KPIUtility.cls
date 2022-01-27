// ===========================================================================
//  Object	: KPIUtility
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Utill Class to calculate Hours difference between Case coumns to figure out Agent KPI values.
// ===========================================================================

public class KPIUtility {
	// Method Name: calculateKPIValue
	// Author: Abinash Panigrahi
	// Description: Method to find Case Resolution Time, Agent Response Time and Case First Response Time
	// Parameter 1: caseStartDT - Represent Case Opened/ Agent Assigned Datetime
	// Parameter 2: caseEndDT - Represent Case Closed/ Email Replied Datetime
	// Parameter 3: timezoneSIDKey - Represent Queue Owner Timezone local
	// Return: Decimal
	public static Decimal calculateKPIValue(Datetime caseStartDT, Datetime caseEndDT, String timezoneSIDKey) {
		CommonUtilities.debug('Inside calculateKPIValue Method');
		CommonUtilities.debug('caseStartDT------->>>>>>>' + caseStartDT);
		CommonUtilities.debug('caseEndDT------->>>>>>>' + caseEndDT);
		CommonUtilities.debug('timezone------->>>>>>>' + timezoneSIDKey);

		//STEP 1 : Based on Queue Owner Timezone will fetch the Offset difference with GMT model
		Integer offset = Timezone.getTimeZone(timezoneSIDKey).getOffset(caseStartDT);
		CommonUtilities.debug('offset------->>>>>>>' + offset / 1000);

		//STEP 2 : Convert UTC fetched timezone to locale timezone, then round up to start of week
		Datetime convertedStart = convertIntoLocale(caseStartDT, offset);
		CommonUtilities.debug('convertedStart------->>>>>>>' + convertedStart);
		Datetime convertedEnd = convertIntoLocale(caseEndDT, offset);
		CommonUtilities.debug('convertedEnd------->>>>>>>' + convertedEnd);

		//STEP 3 : Calculate difference between two Datetime value, make sure to exclude Weekend hours
		Decimal diffHrs = totalDifferenceDateTime(convertedStart, convertedEnd);
		CommonUtilities.debug('diffHrs------->>>>>>>' + diffHrs);
		CommonUtilities.debug('Exit calculateKPIValue Method');

		//Return appropriate KPI value
		return diffHrs;
	}

	public static Datetime convertIntoLocale(Datetime fetchApexUTC, Integer offset) {
		Datetime locale = fetchApexUTC.addSeconds(offset / 1000);
		String dayOfWeek = locale.formatGMT('E');
		if (dayOfWeek == 'Sat' || dayOfWeek == 'Sun') {
			Integer weekStartDiff = dayOfWeek == 'Sat' ? 2 : dayOfWeek == 'Sun' ? 1 : 0;
			locale = locale.addDays(weekStartDiff);
			locale = locale.addHours(-locale.hourGMT()).addMinutes(-locale.minuteGMT()).addSeconds(-locale.secondGMT());
		}
		return locale;
	}

	public static Decimal totalDifferenceDateTime(Datetime startDateTime, Datetime endDateTime) {
		Long startDateTimeLong = startDateTime.getTime();
		Long endDateTimeLong = endDateTime.getTime();
		Decimal milliseconds = Decimal.valueOf(endDateTimeLong - startDateTimeLong);
		Decimal hoursDiff = milliseconds / (1000 * 60 * 60);

		Date startDate = startDateTime.dateGmt();
		Date endDate = endDateTime.dateGmt();
		Integer weeks = 0;

		for (integer i = 0; i <= startDate.daysBetween(endDate); i++) {
			Date dt = startDate + i;
			DateTime currDate = DateTime.newInstance(dt.year(), dt.month(), dt.day());
			String todayDay = currDate.format('EEEE');
			if (todayDay == 'Saturday' || todayDay == 'Sunday') {
				weeks = weeks + 1;
			}
		}

		Decimal excludeHours = Decimal.valueOf((weeks / 2) * 48);
		Decimal result = hoursDiff - excludeHours;
		return result.setScale(2);
	}
}