/**
 * @name OLSTestApp
 * @description Test class for Online Store Customer Package
 * 
 * @author Andrew Frederick (Creed Interactive) October 2021
 */
@IsTest
public with sharing class OLSTestApp {
    
    @IsTest
    public static void testApexRestServiceMN(){
        ContentVersion version = createContentVersion();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        OLSRestServiceHelper.ClientSideCustomer customer = getClientSideCustomer('ddmn_core');
        
        req.requestURI = 'services/apexrest/creedint/CreateOnlineStoreCustomer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( JSON.serialize(customer) );

        RestContext.request = req;
        RestContext.response = res;

        Integer numberOfEmailsSent = 0;

        Test.startTest();

            OLSRestService.create();

            numberOfEmailsSent = Limits.getEmailInvocations();

        Test.stopTest();
        
        // System.assertEquals( 1, numberOfEmailsSent );

        Contact[] contacts = [SELECT 
                            Id, 
                            FirstName,
                            Email
                                FROM Contact
                                WHERE Email = :customer.email];

        System.assertEquals( 1, contacts.size() );

        Contact contact = contacts[0];

        System.assertEquals( contact.Email, customer.email );
        System.assertEquals( contact.FirstName, customer.firstName );
    }

    @IsTest
    public static void testApexRestServiceNE(){
        ContentVersion version = createContentVersion();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        OLSRestServiceHelper.ClientSideCustomer customer = getClientSideCustomer('ddne_core');
        
        req.requestURI = 'services/apexrest/creedint/CreateOnlineStoreCustomer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( JSON.serialize(customer) );

        RestContext.request = req;
        RestContext.response = res;

        Integer numberOfEmailsSent = 0;

        Test.startTest();

            OLSRestService.create();

            numberOfEmailsSent = Limits.getEmailInvocations();

        Test.stopTest();
        
        // System.assertEquals( 1, numberOfEmailsSent );

        Contact[] contacts = [SELECT 
                            Id, 
                            FirstName,
                            Email
                                FROM Contact
                                WHERE Email = :customer.email];

        System.assertEquals( 1, contacts.size() );

        Contact contact = contacts[0];

        System.assertEquals( contact.Email, customer.email );
        System.assertEquals( contact.FirstName, customer.firstName );
    }

    @IsTest
    public static void testApexRestServiceUnsuccessful(){
        ContentVersion version = createContentVersion();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        OLSRestServiceHelper.ClientSideCustomer customer = getClientSideCustomer('ddmn_core');
        
        req.requestURI = 'services/apexrest/creedint/CreateOnlineStoreCustomerUnsuccessful';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( JSON.serialize(customer) );

        RestContext.request = req;
        RestContext.response = res;

        Integer numberOfEmailsSent = 0;

        Test.startTest();

            OLSRestService.create();

            numberOfEmailsSent = Limits.getEmailInvocations();

        Test.stopTest();
        
        // System.assertEquals( 1, numberOfEmailsSent );

        Contact[] contacts = [SELECT 
                            Id, 
                            FirstName,
                            Email
                                FROM Contact
                                WHERE Email = :customer.email];

        System.assertEquals( 1, contacts.size() );

        Contact contact = contacts[0];

        System.assertEquals( contact.Email, customer.email );
        System.assertEquals( contact.FirstName, customer.firstName );
    }

    @IsTest
    public static void testBadRequest(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'services/apexrest/creedint/CreateOnlineStoreCustomer';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( 'bad request' );

        RestContext.request = req;
        RestContext.response = res;

        Integer numberOfEmailsSent = 0;

        Test.startTest();

            OLSRestService.create();

            numberOfEmailsSent = Limits.getEmailInvocations();

        Test.stopTest();

        System.assertEquals( 1, numberOfEmailsSent );

        Contact[] contacts = [SELECT 
                            Id, 
                            FirstName,
                            Email
                                FROM Contact];

        System.assertEquals( 0, contacts.size() );
    }

    @IsTest
    public static void testTrigger(){
        EmailMessageUtil.hooks.add(new OLSTriggerHook());

        Contact contact = new Contact(
            FirstName = 'new',
            LastName = 'customer',
            email = 'me@test.com'
        );

        insert contact;

        // This is a little hacky but we cannot unfortunately create an EmailMessage without a case 
        // though it's possible when sending a message using the Messaging namespace. 
        Case c = new Case(
            ContactId = contact.Id
        );

        insert c;

        EmailMessage message = new EmailMessage(
            ToAddress = 'me@test.com',
            FromAddress = 'you@test.com',
            Subject = 'Subject',
            HtmlBody = 'Body',
            ParentId = c.Id
        );

        insert message;

        contact = [SELECT Id, Email_Sent__c FROM Contact WHERE Id = :contact.Id];

        // System.assertEquals( true, contact.Email_Sent__c );
    }

    @IsTest
    public static void testEmailValidation(){

        Contact contact = new Contact(
            FirstName = 'New Customer',
            LastName = 'Bad Email',
            email = 'noemail@noemail.com',
            RecordTypeId = OLSUtil.getOLSRecordTypeId()
        );

        insert contact;


       

        Test.startTest();

            OLSEmailValidator validator = new OLSEmailValidator( new Contact[]{ contact } );

            // Check Initial Callout that creates the job on the other end of the callout
            Test.setMock( HttpCalloutMock.class, new OLSEmailValidationCalloutMock() );
            validator.validate();

            // Check Status Check on Job
            Test.setMock( HttpCalloutMock.class, new OLSValidationStatusCheckCalloutMock() );
            validator.checkStatus();

            // Check retrieving results. This is the final call which gets any invalid emails from api
            Test.setMock( HttpCalloutMock.class, new OLSValidationRetrieveResultsCalloutMock() );
            validator.retrieveResults();

        Test.stopTest();


        System.assertEquals( 1, validator.apiJobId );
        System.assertEquals( true, validator.isReady() );
        System.assertEquals( true, !validator.invalidEmails.isEmpty() );
    }

    @IsTest
    public static void testEmailValidationInitialJob(){

        Contact contact = new Contact(
            FirstName = 'New Customer',
            LastName = 'Bad Email',
            email = 'noemail@noemail.com',
            RecordTypeId = OLSUtil.getOLSRecordTypeId()
        );

        insert contact;


        Test.startTest();

            // Check Status Check on Job
            Test.setMock( HttpCalloutMock.class, new OLSEmailValidationCalloutMock() );
            System.schedule( 'Test Shell Cron Job', OLSUtil.getMinutesFromNow(1), new OLSEmailValidation() );

        Test.stopTest();

    }

    @IsTest
    public static void testEmailValidationStatusCheckCronJob(){

        Contact contact = new Contact(
            FirstName = 'New Customer',
            LastName = 'Bad Email',
            email = 'noemail@noemail.com',
            RecordTypeId = OLSUtil.getOLSRecordTypeId()
        );

        insert contact;


        Test.startTest();

            OLSEmailValidator validator = new OLSEmailValidator( new Contact[]{ contact } );

            // Check Initial Callout that creates the job on the other end of the callout
            Test.setMock( HttpCalloutMock.class, new OLSEmailValidationCalloutMock() );
            validator.validate();
            
            // Check Status Check on Job
            Test.setMock( HttpCalloutMock.class, new OLSValidationStatusCheckCalloutMock() );
            validator.scheduleStatusCheck();

        Test.stopTest();

        //System.assertNotEquals( null, validator.cronJobId );
        //System.assertEquals( true, validator.isReady() );

        System.assertEquals( 1, validator.apiJobId );
    }

    @IsTest
    public static void testBatch(){
        Database.executeBatch( new OLSBounceReportBatch() );
    }

    private static ContentVersion createContentVersion(){
        ContentVersion version = new ContentVersion(
            Title = 'Brochure',
            PathOnClient = 'Brochure.txt',
            VersionData = Blob.valueOf('This is a brochure'),
            ContentLocation = 'S',
            Brochure_Key__c = 'Test_Brochure_Key'
        );

        insert version;

        return version;
    }

    private static OLSRestServiceHelper.ClientSideCustomer getClientSideCustomer( String stateAcronym ){
       
        OLSRestServiceHelper.AddressData address = new OLSRestServiceHelper.AddressData();
        address.addressLine1 = '3 Do Street';
        address.addressLine2 = 'Unit 1';
        address.city = 'Springfield';
        address.state = 'MN';
        address.zip = '55302';

        OLSRestServiceHelper.PaymentDetails paymentDetails = new OLSRestServiceHelper.PaymentDetails();
        paymentDetails.paymentSuccessful = 'true';
        paymentDetails.paymentSuccessful2 = null;
        paymentDetails.paymentType = 'CC';
        paymentDetails.customerId = 'CC123';
        paymentDetails.customerId2 = null;
        paymentDetails.transactionId = '';
        paymentDetails.transactionDate = '9/30/2022';
        paymentDetails.paymentAuthNumber = '';
        paymentDetails.bankAccountType = '';
        paymentDetails.paymentFrequency = 'Monthly';
        paymentDetails.callingApplication = 'roosevelt-shopping-ui';
        paymentDetails.paymentErrorMessage = '';

        OLSRestServiceHelper.PlanDetails planDetails = new OLSRestServiceHelper.PlanDetails();
        planDetails.marketingName = 'Elite 1000';
        planDetails.generatedName = 'ND Plan Elite 1000 Dental Only';
        planDetails.brochureUrl = 'https://www.deltadentalmn.org/library/2022_DDND_Elite1000.pdf';
        planDetails.amount = '$35.50';
        planDetails.paymentFrequency = 'Monthly';
        planDetails.productId = '1332';
        planDetails.clientId = '3550';
        planDetails.subClientId = '1500';
        planDetails.productKey = 'DDND-INDI-ELITE1';
        planDetails.productEffectiveDate = '01/01/2022';
        planDetails.accessCode = '6659';

        OLSRestServiceHelper.PreEnrollment preEnrollment = new OLSRestServiceHelper.PreEnrollment();
        preEnrollment.customerId = 'CC937859238';
        preEnrollment.preEnrollmentId = '1900293';
        preEnrollment.preEnrollProductId = '1332';
        preEnrollment.merchantOid = '';
        preEnrollment.encPreEnrollmentMemberId = '';
        preEnrollment.auditUsername = '';
        preEnrollment.auditApplicationName = '';
        preEnrollment.hash = '';
        preEnrollment.timeStamp = '';
        preEnrollment.formattedDate = '';
        preEnrollment.applicationName = stateAcronym;
        preEnrollment.planDetails = planDetails;

        OLSRestServiceHelper.Enrollment enrollment = new OLSRestServiceHelper.Enrollment();
        enrollment.status = 'good';
        enrollment.enrollmentId = 'id1';

        OLSRestServiceHelper.ExistingCoverage existingCoverage = new OLSRestServiceHelper.ExistingCoverage();
        existingCoverage.carrier = 'BCBS';
        existingCoverage.policyNumber = 'policy111222';
        existingCoverage.effectiveDate = '12/29/2016';
        existingCoverage.endDate = '12/30/2022';
        existingCoverage.waitingPeriodWaiverEligible = 'true';
        existingCoverage.daysSinceEndOfPriorCoverage = '23 days';
        existingCoverage.lengthOfPriorCoverage = '18 days';

        OLSRestServiceHelper.ClientSideCustomer customer = new OLSRestServiceHelper.ClientSideCustomer();
        customer.agentNumber = 'X45TrL11';
        customer.firstName = 'Jabber';
        customer.lastName = 'Testing';
        customer.email = 'example@gmail.com';
        customer.ssn = '199674643';
        customer.phone = '6124038141';
        customer.dateOfBirth = '03/05/1996';
        customer.gender = 'M';
        customer.coverageType = 'myself';
        customer.address = address;
        customer.newPolicyStartDate = '11/01/2022';
        customer.existingCoverage = existingCoverage;
        customer.preEnrollment = preEnrollment;
        customer.paymentDetails = paymentDetails;
        customer.enrollment = enrollment;

        return customer;
    }   
}
