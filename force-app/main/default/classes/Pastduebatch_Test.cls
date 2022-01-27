@isTest
private class Pastduebatch_Test {
	static testMethod void testmethod1() {
		Contact c1 = new contact();
		c1.firstname = 'Test1';
		c1.lastname = 'Contact1';

		insert c1;
		Account testAccount1 = new Account();
		testAccount1.Name = 'TrylerTest1';
		testAccount1.Unique_Id__c = '123456';
		insert testAccount1;

		list<opportunity> oplist = new List<opportunity>();
		for (integer i = 0; i < 200; i++) {
			opportunity op = new opportunity();
			op.AccountID = testAccount1.ID;
			op.name = 'name' + i;
			op.Primary_Contact__c = c1.id;
			op.past_Due_Triggered__c = false;
			op.StageName = 'Relating';
			op.CloseDate = Date.today().addDays(-1);
			oplist.add(op);
		}
		insert oplist;
		/* test.startTest();
        If(Test.isRunningTest()){
   PastdueBatchable bch=new PastdueBatchable();
      ID jobID = Database.executeBatch(bch,200);
      System.abortJob(jobID);
}else{
     PastdueBatchable bch1=new PastdueBatchable();
      Database.executeBatch(bch1);
}
        //PastdueBatchable bth=new PastdueBatchable();
       // database.executeBatch(bth);
        test.stopTest();*/
	}
	static testMethod void schedulerTest() {
		Contact c2 = new contact();
		c2.firstname = 'Test2';
		c2.lastname = 'Contact2';
		insert c2;
		Account testAccount2 = new Account();
		testAccount2.Name = 'TrylerTest2';
		testAccount2.Unique_Id__c = '654321';
		insert testAccount2;
		String CRON_EXP = '0 1 0 * * ?';

		// Create your test data
		Opportunity Opp = new Opportunity();
		Opp.name = 'test';
		Opp.Primary_Contact__c = c2.Id;
		Opp.AccountID = testAccount2.ID;

		Opp.past_Due_Triggered__c = false;
		Opp.StageName = 'Relating';
		Opp.CloseDate = Date.today().addDays(-1);

		insert Opp;

		Test.startTest();

		String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new PastdueSchedule());
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(CRON_EXP, ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);

		Test.stopTest();
		// Add assert here to validate result
		//
	}
}