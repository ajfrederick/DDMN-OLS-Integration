/**
 * @name OLSEmailValidator
 * @description this class is an http callout to an external api at whoisxmlapi.com to verify email addresses and mark OLS Contact
 * records as bounced for a weekly bounce report.
 * 
 * Documentation for api found at https://emailverification.whoisxmlapi.com/bulk-api/documentation
 * 
 * @author Creed Interactive (Andrew Frederick) March 2022
 */
public without sharing class OLSEmailValidator {
    
/**
 * FIELDS
 */

    public Contact[] customers {get;set;}


    public Id cronJobId {get;set;}

    public Integer apexCronIndex {
        get {
            if( apexCronIndex == null ){
                apexCronIndex = 1;
            }
            return apexCronIndex;
        }
        set;
    }

    public Integer apiJobId {get;set;}

    private StatusResponse statusResponse {get;set;}


    public String[] invalidEmails {
        get {

            if( invalidEmails == null ){
                invalidEmails = new String[]{};
            }

            return invalidEmails;
        }
        set;
    }


    public static OLS_api_credential__mdt credential;

    /**
    * Static block to set credential variable
    */
    static {

        try {
            
           credential = OLS_api_credential__mdt.getInstance('Bulk_Email_Verification');

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

/**
 * CONSTRUCTORS
 */

    public OLSEmailValidator( Contact[] customers ){
        this.customers = customers;
    }

/**
 * CALLOUT METHODS
 */

    /**
     * @name validate
     * @description Makes on http request to the Email Validation api
     * @param none
     * @return none
     */
    public void validate(){
        
        try {

            EmailVerificationRequestBody requestBody = new EmailVerificationRequestBody( customers );
            EmailVerificationHttpHandler httpHandler = new EmailVerificationHttpHandler();
            httpHandler.send( getHttpRequest( JSON.serialize(requestBody) ) );

            EmailVerificationResponse response = httpHandler.getParsedResponse();

            if( response != null && response.response.id != null ){
                apiJobId = response.response.id;
            }

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }



    /**
     * @name checkStatus
     * @description Makes on http request to the Email Validation api
     * @param String id
     * @return void
     */
    public void checkStatus(){

        try {

            StatusRequestBody requestBody = new StatusRequestBody( apiJobId );
            StatusHttpHandler httpHandler = new StatusHttpHandler();
            httpHandler.send( getHttpRequest( JSON.serialize(requestBody) ) );

            statusResponse = httpHandler.getParsedResponse();

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }

    }

    /**
     * @name retrieveResults
     * @description Makes on http request to the Email Validation api
     * @param String id
     * @return none
     */
    public void retrieveResults(){

        try {

            RetrieveResultsRequestBody requestBody = new RetrieveResultsRequestBody( apiJobId );
            RetriveResultsHttpHandler httpHandler = new RetriveResultsHttpHandler();
            httpHandler.send( getHttpRequest( JSON.serialize(requestBody) ) );

            RetrieveResultsResponse response = httpHandler.getParsedResponse();

            if( response == null || response.response.isEmpty() ){ return; }

            for( RetrieveResultsResponseResponse result : response.response ){

                if( !result.isValid() ){
                    invalidEmails.add( result.emailAddress );
                }
            }

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    } 

/**
 * UTILITY METHODS
 */ 

    /**
     * @name getHttpRequest
     * @description sends http request
     * @param none 
     * @return none
     */
    private HttpRequest getHttpRequest( String requestBody ){

        HttpRequest request = new HttpRequest();
        request.setBody( requestBody );
        request.setHeader( 'Content-Type', 'application/json' );

        return request;
    }

    /**
     * @name scheduleStatusCheck
     * @description Makes on http request to the Email Validation api
     * @param StatusResponse response 
     * @return none
     */
    public void scheduleStatusCheck(){

        try {

            if( apiJobId == null ){
                throw new EmailVerificationException('Job Id from initial api request is null.');
            }

            String apexJobName = 'OLS Email Verification Status Check ' + apexCronIndex++;

            OLSEmailValidationCheckStatus statusCheck = new OLSEmailValidationCheckStatus( this );

            System.schedule( apexJobName, OLSUtil.getMinutesFromNow(5), statusCheck );

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

    /**
     * @name abortCronJob
     * @description aborts job
     * @param StatusResponse response 
     * @return none
     */
    public void abortCronJob(){
        if( cronJobId == null ){ return; }
        
        System.abortJob( cronJobId );
    }

    /**
     * @name isReady
     * @description if the job that is bulk processing the emails for invalid emails is done it will return
     * ready as an integer greater than 0
     * @param none
     * @return none
     */
    public Boolean isReady(){
        return statusResponse != null && (!statusResponse.response.isEmpty()) && statusResponse.response[0].ready > 0;
    }       

    /**
     * @name isInvalid
     * @description the final check if the address is valid or not.
     * @param none
     * @return none
     */
    public Boolean isInvalid( String email ){
        return invalidEmails.contains(email);
    }

/**
 * HTTP HANDLER CLASSES
 */

    public class EmailVerificationHttpHandler extends HttpHandler {

        public EmailVerificationHttpHandler(){
            setMethod('POST');
        }
        
        public override String getEndpoint(){
            return credential.Request_URL__c;
        }

        public EmailVerificationResponse getParsedResponse(){
            return (EmailVerificationResponse) JSON.deserialize( responseBody, EmailVerificationResponse.class );
        }
    }

    public class StatusHttpHandler extends HttpHandler {
        
        public StatusHttpHandler(){
            setMethod('POST');
        }

        public override String getEndpoint(){
            return credential.Request_URL__c + '/status';
        }

        public StatusResponse getParsedResponse(){
            return (StatusResponse) JSON.deserialize( responseBody, StatusResponse.class );
        }
    }

    public class RetriveResultsHttpHandler extends HttpHandler {
        
        public RetriveResultsHttpHandler(){
            setMethod('POST');
        }

        public override String getEndpoint(){
            return credential.Request_URL__c + '/completed';
        }

        public RetrieveResultsResponse getParsedResponse(){
            return (RetrieveResultsResponse) JSON.deserialize( responseBody, RetrieveResultsResponse.class );
        }
    }

/**
 * FORMATTED HTTP REQUEST AND RESPONSE CLASSES
 * 
 * All documentation for request and response formatting can be found at https://emailverification.whoisxmlapi.com/bulk-api/documentation
 */

    // Initial Email Verification Call
    public class EmailVerificationRequestBody {
        public String apiKey {get;set;}
        public String[] emails {get;set;}

        public EmailVerificationRequestBody( Contact[] customers ){
            this.apiKey = credential.API_Key__c;
            this.emails = new String[]{};

            for( Contact customer : customers ){
                this.emails.add( customer.Email );
            }
        }
    }

    public class EmailVerificationResponse {
        public EmailVerificationResponseResponse response {get;set;}
    }

    public class EmailVerificationResponseResponse {
        public Integer id {get;set;}
        public String[] errors {get;set;}
    }


    // API Job Status Call
    public class StatusRequestBody {
        public String apiKey {get;set;}
        public Integer[] ids {get;set;}

        public StatusRequestBody( Integer id ){
            this.apiKey = credential.API_Key__c;
            this.ids = new Integer[]{id};
        }
    }

    public class StatusResponse {
        public StatusResponseResponse[] response {get;set;}
    }

    public class StatusResponseResponse {
        public Integer ready {get;set;}
    }


    // Retrieve Invalid Results Call
    public class RetrieveResultsRequestBody {
        public String apiKey {get;set;}
        public Integer id {get;set;}

        public RetrieveResultsRequestBody( Integer id ){
            this.apiKey = credential.API_Key__c;
            this.id = id;
        }
    }

    public class RetrieveResultsResponse {
        public RetrieveResultsResponseResponse[] response {get;set;}
    }

    public class RetrieveResultsResponseResponse {

        public String emailAddress {get;set;}

        public String formatCheck {
            get {
                if( formatCheck == null ){ formatCheck = 'false'; }
                return formatCheck;
            }
            set;
        }

        public String smtpCheck {
            get {
                if( smtpCheck == null ){ smtpCheck = 'false'; }
                return smtpCheck;
            }
            set;
        }

        public String dnsCheck {
            get {
                if( dnsCheck == null ){ dnsCheck = 'false'; }
                return dnsCheck;
            }
            set;
        }

        public Boolean isValid(){
            return Boolean.valueOf(formatCheck) && Boolean.valueOf(smtpCheck) && Boolean.valueOf(dnsCheck);
        }
    }

/**
 * EXCEPTION CLASSES
 */

    public class EmailVerificationException extends Exception {}
}