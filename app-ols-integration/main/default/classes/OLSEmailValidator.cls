/**
 * @name OLSEmailValidator
 * @description this class is an http callout to an external api at whoisxmlapi.com to verify email addresses and mark OLS Contact
 * records as bounced for a weekly bounce report.
 * 
 * Documentation for api found at https://emailverification.whoisxmlapi.com/api/documentation/making-requests
 * 
 * @author Creed Interactive (Andrew Frederick) March 2022
 */
public without sharing class OLSEmailValidator {
    
/**
 * FIELDS
 */

    public String emailAddress {get;set;}

    public Map<String, String> params {
        get {
            
            if( params == null ){
                params = new Map<String, String>();
            }
            
            return params;
        }
        set;
    }

    public EmailValidationResponse response {
        get {

            if( response == null ){
                response = new EmailValidationResponse();
            }

            return response;
        }
        set;
    }

    public EmailValidationHttpHandler httpHandler {
        get {

            if( httpHandler == null ){
                httpHandler = new EmailValidationHttpHandler();
            }

            return httpHandler;
        }
        set;
    }

    private static ols_api_credential__mdt credential;

    /**
    * Static block to set credential variable
    */
    static {

        try {
            
            credential = ols_api_credential__mdt.getInstance('Email_Validation_Credentials');

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

/**
 * CONSTRUCTORS
 */

    public OLSEmailValidator( String emailAddress ){
        this.emailAddress = emailAddress;
        
        params.put( 'apiKey', credential.API_Key__c );
    }

/**
 * ACTION METHODS
 */

    /**
     * @name validate
     * @description Makes on http request to the Email Validation api
     * @param none
     * @return none
     */
    public void validate(){
        
        try {
        
            if( !apiHasCredits() ){
                throw new EmailValidationException('Email Validation API has no credit.');
            }
    
            params.put( 'emailAddress', emailAddress );

            httpHandler.setQueryParams( params );
            httpHandler.send();

            response = httpHandler.getParsedResponse();

            System.debug( httpHandler.parsedResponse.responseBody );

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

    /**
     * @name validate
     * @description Checks to ensure we have enough credit on our balance. As of 3/1/2022 we have a free account which
     * has 1000 requests per month rolling. We want to make sure to not do anything if cannot due to are request limit.
     * @param none
     * @return none
     */
    public Boolean apiHasCredits(){
        BalanceCheckHttpHandler ccHttpHandler = new BalanceCheckHttpHandler();

        BalanceCheckResponse ccResponse;

        try {

            ccHttpHandler.setQueryParams( params );
            ccHttpHandler.send();

            ccResponse = ccHttpHandler.getParsedResponse();
            
        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }

        if( ccResponse == null ){
            return false;
        }

        return ccResponse.hasCredits();
    }

/**
 * UTILITY METHODS
 */

    /**
     * @name isValid
     * @description the final check if the address is valid or not.
     * @param none
     * @return none
     */
    public Boolean isValid(){
        return response.isValid();
    }

/**
 * HTTP HANDLER CLASSES
 */

    public class EmailValidationHttpHandler extends HttpHandler {
        
        public override String getEndpoint(){
            return credential.Endpoint_URL__c + getQuery();
        }

        public EmailValidationResponse getParsedResponse(){
            return (EmailValidationResponse) JSON.deserialize( parsedResponse.responseBody, EmailValidationResponse.class );
        }
    }

    public class BalanceCheckHttpHandler extends HttpHandler {
        
        public override String getEndpoint(){
            return credential.Balance_Check_URL__c + getQuery();
        }

        public BalanceCheckResponse getParsedResponse(){
            return (BalanceCheckResponse) JSON.deserialize( parsedResponse.responseBody, BalanceCheckResponse.class );
        }
    }

/**
 * FORMATTED RESPONSE CLASSES
 */

    public class EmailValidationResponse {

        public String formatCheck {
            get {
    
                if( formatCheck == null ){
                    formatCheck = '';
                }
    
                return formatCheck;
            }
            set;
        }

        public String smtpCheck {
            get {

                if( smtpCheck == null ){
                    smtpCheck = '';
                }

                return smtpCheck;
            }
            set;
        }

        public String dnsCheck {
            get {
    
                if( dnsCheck == null ){
                    dnsCheck = '';
                }
    
                return dnsCheck;
            }
            set;
        }

        public Boolean isValid(){
            return Boolean.valueOf( formatCheck ) && Boolean.valueOf( smtpCheck ) && Boolean.valueOf( dnsCheck );
        }
    }

    public class BalanceCheckResponse {
        public APIProduct[] data {get;set;}

        public Boolean hasCredits(){
            Boolean hasCredits = true;

            for( APIProduct product : data ){

                // Email Verification API product_id is 7 according to the reponse as of 3/1/2022
                // for more info go here https://emailverification.whoisxmlapi.com/api/documentation/account-balance-information
                if( product.product_id == 7 ){
                    hasCredits = product.credits > 0;
                    break;
                }
            }

            return hasCredits;
        }
    }

    public class APIProduct {
        public Integer product_id {get;set;}
        public Integer credits {get;set;}
    }

/**
 * EXCEPTION CLASSES
 */

    public class EmailValidationException extends Exception {}
}