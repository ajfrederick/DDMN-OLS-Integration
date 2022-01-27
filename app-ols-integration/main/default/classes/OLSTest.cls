/**
 * @name OLSTest
 * @description Test class for Online Store Customer Package
 */
@IsTest
public with sharing class OLSTest {
    
    @IsTest
    public static void testApexRestServiceMN(){
        ContentVersion version = createContentVersion();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        OLSRestServiceHelper.ClientSideCustomer customer = getClientSideCustomer('MN');
        
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
                                WHERE CAID__c = :customer.preEnrollment.caid];

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

        OLSRestServiceHelper.ClientSideCustomer customer = getClientSideCustomer('NE');
        
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
                                WHERE CAID__c = :customer.preEnrollment.caid];

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

        OLSRestServiceHelper.ClientSideCustomer customer = getClientSideCustomer('MN');
        
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
                                WHERE CAID__c = :customer.preEnrollment.caid];

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
    public static void testTriggerHelper(){
        EmailMessageHelper.hooks.add(new OLSTriggerHook());

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
    public static void testBatch(){
        Database.executeBatch( new OLSBounceReportBatchable() );
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
        paymentDetails.paymentType = 'CC';
        paymentDetails.customerId = 'customerId1';
        paymentDetails.transactionId = 'tranId1';
        paymentDetails.transactionDate = '11/12/20';
        paymentDetails.paymentAuthNumber = '12345';
        paymentDetails.bankAccountType = 'Checking';
        paymentDetails.paymentFrequency = 'Monthly';
        paymentDetails.callingApplication = 'webappsui';
        paymentDetails.paymentErrorMessage = 'none';

        OLSRestServiceHelper.PreEnrollment preEnrollment = new OLSRestServiceHelper.PreEnrollment();
        preEnrollment.status = 'good';
        preEnrollment.stateAcronym = stateAcronym;
        preEnrollment.preEnrollmentId = 'id543';
        preEnrollment.caid = 'caid98432';

        OLSRestServiceHelper.Enrollment enrollment = new OLSRestServiceHelper.Enrollment();
        enrollment.status = 'good';
        enrollment.enrollmentId = 'id1';

        OLSRestServiceHelper.ExistingCoverage existingCoverage = new OLSRestServiceHelper.ExistingCoverage();
        existingCoverage.carrier = 'BCBS';
        existingCoverage.policyNumber = 'policy111222';
        existingCoverage.effectiveDate = '2016-12-29';
        existingCoverage.endDate = '2021-09-02';
        existingCoverage.waitingPeriodWaiverEligible = 'true';
        existingCoverage.daysSinceEndOfPriorCoverage = '23 days';
        existingCoverage.lengthOfPriorCoverage = '18 days';

        OLSRestServiceHelper.ClientSideCustomer customer = new OLSRestServiceHelper.ClientSideCustomer();
        customer.firstName = 'Crazy New Test';
        customer.lastName = 'Customer';
        customer.email = 'me@test.com';
        customer.address = address;
        customer.phone = '222-234-5487';
        customer.accessCode = 'testcode';
        customer.existingCoverage = existingCoverage;
        customer.amount = '$87.33';
        customer.product = 'Test Product';
        customer.brochureKey = 'Test_Brochure_Key';
        customer.brochureUrl = 'www.Test_Brochure_URL.io';
        customer.preEnrollment = preEnrollment;
        customer.postBackUrl = 'www.postback.io';
        customer.paymentDetails = paymentDetails;
        customer.enrollment = enrollment;
        
        return customer;
    }   
}
