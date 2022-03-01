/**
 * @name OLSRestServiceHelper
 * @description this class helps parse the JSON that is delivered to the apex rest service class OnlineStoreCustomerRestService.cls
 * as well as deliver contact that is loaded with all the values from the parsed JSON.
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public without sharing class OLSRestServiceHelper {

/**
 * FIELDS
 */ 

    // this is the JSON that comes from the DDMN webapps
    public String requestBody;

    // this is marked by the apex REST service that instantiates this class. There are two entry points.
    // One for a successful payment upon enrollment and one for an unsuccessful payment.
    public Boolean paymentSuccessful;

    // this is the parsed customer object for us to extract data into a Contact object
    public ClientSideCustomer customer;

/**
 * FIELDS FOR DECONSTRUCTION
 * 
 * The following lazy loaded fields exist to hold the deconstructed data from the customer object.
 * Doing this will help avoid de-referencing a null object in the case that one of the objects from the request is missing.
 * The contact will still be created just missing some data if it is indeed missing.
 */
    private AddressData address {
        get {
            if( address == null ) address = new AddressData();
            return address;
        }
        set;
    }

    private ExistingCoverage existingCoverage {
        get {
            if( existingCoverage == null ) existingCoverage = new ExistingCoverage();
            return existingCoverage;
        }
        set;
    }

    private PaymentDetails paymentDetails {
        get {
            if( paymentDetails == null ) paymentDetails = new PaymentDetails();
            return paymentDetails;
        }
        set;
    }

    private PreEnrollment preEnrollment {
        get {
            if( preEnrollment == null ) preEnrollment = new PreEnrollment();
            return preEnrollment;
        }
        set;
    }

    private Enrollment enrollment {
        get {
            if( enrollment == null ) enrollment = new Enrollment();
            return enrollment;
        }
        set;
    }

    // let's just grab the record type id once to be referenced here
    private static final Id olsContact = OLSUtil.getOLSRecordTypeId();

/**
* CONSTRUCTOR
*/

    public OLSRestServiceHelper( String requestBody, boolean paymentSuccessful ) {
        this.requestBody = requestBody;
        this.paymentSuccessful = paymentSuccessful;
    }

/**
* ACTION METHODS
*/     

    /**
     * @name parseRequest
     * @description parses the JSON sent in the request to the OnlineStoreCustomerRestService.cls
     * @return void
     */
    public void parseRequest(){

        if( paymentSuccessful ){
            parseRequestSuccessful();
        } else {
            parseRequestUnsuccessful();
        }
    }

    /**
     * @name parseRequestSuccessful
     * @description parses the JSON sent in the request to the OnlineStoreCustomerRestService.cls
     * @return void
     */
    public void parseRequestSuccessful(){
        customer = (ClientSideCustomer) JSON.deserialize( requestBody, ClientSideCustomer.class );
        
        this.address = customer.address;
        this.existingCoverage = customer.existingCoverage;
        this.paymentDetails = customer.paymentDetails;
        this.preEnrollment = customer.preEnrollment;
        this.enrollment = customer.enrollment;
    }

    /**
     * @name parseRequest
     * @description parses the JSON sent in the request to the OnlineStoreCustomerRestService.cls
     * @return void
     */
    public void parseRequestUnsuccessful(){
        customer = (ClientSideCustomer) JSON.deserialize( requestBody, ClientSideCustomer.class );

        this.address = customer.address;
        this.existingCoverage = customer.existingCoverage;
        this.paymentDetails = customer.paymentDetails;
        this.preEnrollment = customer.preEnrollment;
        this.enrollment = customer.enrollment;
    }

    /**
     * @name getContact
     * @description gets Instance of contact (Online Store Customer) for insert
     * @return Contact
     */
    public Contact getContact(){
        Contact contact;

        if( paymentSuccessful ){
            contact = getContactSuccessful();
        } else {
            contact = getContactUnsuccessful();
        }

        return contact;
    }

    /**
     * @name getContactSuccessful
     * @description gets Instance of contact (Online Store Customer) for insert when payment was successful
     * @return Contact
     */
    public Contact getContactSuccessful(){
        Contact contact = getBaseContact();

        contact.Payment_Successful__c = paymentSuccessful;
        contact.CAID__c = preEnrollment.caid;
        contact.Initial_Payment_Amount__c = getAmount();
        contact.Brochure_Key__c = customer.brochureKey;
        contact.Brochure_URL__c = customer.brochureUrl;
        contact.Customer_Id__c = paymentDetails.customerId;
        contact.Payment_Type__c = paymentDetails.paymentType;
        contact.Payment_Frequency__c = paymentDetails.paymentFrequency;

        Contact oldContact = queryContact();

        if( oldContact != null ){
            contact.Id = oldContact.Id;
        }
        
        return contact;
    }

    /**
     * @name getContact
     * @description gets Instance of contact (Online Store Customer) for insert when the payment from OLS was unnsuccessful
     * @return Contact
     */
    public Contact getContactUnsuccessful(){
        Contact contact = getBaseContact();

        contact.Payment_Successful__c = paymentSuccessful;

        return contact;
    }

    /**
     * @name getBaseContact
     * @description both contacts will be formatted as such
     * @return Contact
     */
    public Contact getBaseContact(){
        return new Contact(
            RecordTypeId = olsContact,
            FirstName = customer.firstName,
            LastName = customer.lastName,
            Email = customer.email,
            Phone = customer.phone,
            MailingStreet = getStreet(),
            MailingCity = address.city,
            MailingState = address.state,
            MailingPostalCode = address.zip,
            Product_Purchased__c = customer.product,
            CAID__c = preEnrollment.caid,
            State_Acronym__c = preEnrollment.stateAcronym,
            Current_Carrier__c = existingCoverage.carrier,
            Effective_Date__c = getEffectiveDate(),
            End_Date__c = getEndDate(),
            Policy_Number__c = existingCoverage.policyNumber,
            Eligible_For_Waiting_Period_Waiver__c = getWaiverEligibility(),
            Days_Since_End_Of_Prior_Coverage__c = getDaysSinceEndOfPriorCoverage(),
            Length_Of_Prior_Coverage__c = getLengthOfPriorCoverage()
        );
    }

    /**
     * @name queryContact
     * @description check to see if an Online Store Customer already exists from an unsuccessful payment
     * We want to filter on these criteria...
     * 1) The emails and names match
     * 2) Payment was indeed unsuccessful before
     * 3) That it is indeed an online store customer
     * 4) that the CAID__c is not null as just one more check to enusre we only get an online store customer
     * @return Contact
     */
    public Contact queryContact(){
        Contact[] contacts = new Contact[]{};

        try {

            contacts.addAll([SELECT
                                Id,
                                FirstName,
                                LastName,
                                Email,
                                RecordTypeId,
                                CAID__c
                                    FROM Contact
                                    WHERE Email = :customer.email
                                    AND FirstName = :customer.firstName
                                    AND LastName = :customer.lastName
                                    AND Payment_Successful__c = false
                                    AND RecordTypeId = :olsContact
                                    AND CAID__c != null]);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.debug();
        }

        if( contacts.isEmpty() ) return null;

        return contacts[0];
    }

    /**
     * @name getStreet
     * @description gets street address
     * @return String
     */
    private String getStreet(){
        String street = '';

        if( !String.isBlank(address.addressLine2) ){
            street = address.addressLine1 + ' ' + address.addressLine2;
        } else {
            street = address.addressLine1;
        }

        return street;
    }

    /**
     * @name getAmount
     * @description gets payment amount
     * @return Decimal
     */
    private Decimal getAmount(){
        String amount = customer.amount != null ? customer.amount.replace('$','') : '0';

        return isDecimal(amount) ? Decimal.valueOf(amount) : null;
    }

    /**
     * @name isDecimal
     * @description this is to avoid errors if the amount from the JSON is malformed
     * @param String amount
     * @return Boolean
     */
    private Boolean isDecimal( String amount ){
        String isDecimalRegEx = '^[+-]?([0-9]+\\.?[0-9]*|\\.[0-9]+)$';

        Pattern decimalPattern = Pattern.compile( isDecimalRegEx );

        Matcher decimalMatcher = decimalPattern.matcher( amount );

        return decimalMatcher.matches();
    }

    /**
     * @name getDaysSinceEndOfPriorCoverage
     * @description gets integer from string for this field
     * @param none
     * @return Integer
     */
    private Integer getDaysSinceEndOfPriorCoverage(){
        String numberString = existingCoverage.daysSinceEndOfPriorCoverage != null ? existingCoverage.daysSinceEndOfPriorCoverage.replaceAll('[^\\d.]', '') : '0';

        return isInteger(numberString) ? Integer.valueOf(numberString) : null;
    }

    /**
     * @name getLengthOfPriorCoverage
     * @description gets integer from string for this field
     * @param none
     * @return Integer
     */
    private Integer getLengthOfPriorCoverage(){
        String numberString = existingCoverage.lengthOfPriorCoverage != null ? existingCoverage.lengthOfPriorCoverage.replaceAll('[^\\d.]', '') : '0';

        return isInteger(numberString) ? Integer.valueOf(numberString) : null;
    }

    /**
     * @name isInteger
     * @description this is to avoid errors if the daysSinceEndOfPriorCoverage from the JSON is malformed
     * @param String int
     * @return Boolean
     */
    private Boolean isInteger( String numberString ){
        String isIntRegEx = '^[-+]?\\d+$';

        Pattern intPattern = Pattern.compile( isIntRegEx );

        Matcher intMatcher = intPattern.matcher( numberString );

        return intMatcher.matches();
    }

    /**
     * @name getEffectiveDate
     * @description returns formatted effective date
     * @return Date
     */
    private Date getEffectiveDate(){
        return getDate( existingCoverage.effectiveDate );
    }

    /**
     * @name getEndDate
     * @description returns formatted end date
     * @return Date
     */
    private Date getEndDate(){
        return getDate( existingCoverage.endDate );
    }

    /**
     * @name getDate
     * @description this is to avoid errors if the date string from the JSON is malformed
     * @param String date
     * @return Date
     */
    private Date getDate( String dateString ){
        Date newDate;

        if( String.isBlank(dateString) ) return newDate;

        try {

            newDate = Date.valueOf(dateString);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.debug();
        }

        return newDate;
    }

    /**
     * @name getWaiverEligibility
     * @description checks the string and returns boolean value
     * @param none
     * @return Boolean
     */
    private Boolean getWaiverEligibility(){
        return existingCoverage.waitingPeriodWaiverEligible == 'true' ? true : false;
    }

/**
* CLASSES
*/

    // These are the exact formats we are expecting for a customer object from the DDMN WebApps Online Store
    
    public class ClientSideCustomer {
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String email {get;set;}
        public AddressData address {get;set;}
        public String phone {get;set;}
        public String accessCode {get;set;}
        public ExistingCoverage existingCoverage {get;set;}
        public String amount {get;set;}
        public String product {get;set;}
        public String brochureKey {get;set;}
        public String brochureUrl {get;set;}
        public PreEnrollment preEnrollment {get;set;}
        public String postBackUrl {get;set;}
        public PaymentDetails paymentDetails {get;set;}
        public Enrollment enrollment {get;set;}
    }

    public class AddressData {
        public String addressLine1 {get;set;}
        public String addressLine2 {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String zip {get;set;}
    }

    public class ExistingCoverage {
        public String carrier {get;set;}
        public String effectiveDate {get;set;}
        public String endDate {get;set;}
        public String policyNumber {get;set;}
        public String waitingPeriodWaiverEligible {get;set;}
        public String daysSinceEndOfPriorCoverage {get;set;}
        public String lengthOfPriorCoverage {get;set;}
    }

    public class PaymentDetails {
        public String paymentSuccessful {get;set;}
        public String paymentType {get;set;}
        public String customerId {get;set;}
        public String transactionId {get;set;}
        public String transactionDate {get;set;}
        public String paymentAuthNumber {get;set;}
        public String bankAccountType {get;set;}
        public String paymentFrequency {get;set;}
        public String callingApplication {get;set;}
        public String paymentErrorMessage {get;set;}
    }

    public class PreEnrollment {
        public String status {get;set;}
        public String stateAcronym {get;set;}
        public String preEnrollmentId {get;set;}
        public String caid {get;set;}
    }

    public class Enrollment {
        public String status {get;set;}
        public String enrollmentId {get;set;}
    }
}
