/**
 * @name OLSRestService
 * @description exposed rest api endpoint that is managed with a Connected App called DDMN Web Apps.
 * 
 * DDMN Web Apps access this end point with a JWT Bearer flow. This particular method is called in the Online Store when
 * an indiviual customer requests a product and their payment method has been approved.
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
@RestResource(urlMapping='/CreateOnlineStoreCustomer')
global without sharing class OLSRestService {
   
/**
 * API METHODS
 */

    /**
     * @name create
     * @description actual method that gets called when someone makes a request to the endpoint above
     * @param none
     * @return none
     */
    @HttpPost
    global static void create(){
        String requestBody = RestContext.request.requestBody.toString();

        // set payment successful param to true
        OLSRestServiceHelper helper = getClientSideCustomer( requestBody, true );

        Contact contact = upsertContact( helper );

        if( contact == null || contact.Id == null ) return;

        RestContext.response.statusCode = 201;
        RestContext.response.responseBody = Blob.valueOf( JSON.serialize( contact ) );
    }

/**
 * ACTION METHODS
 */

    /**
     * @name getClientSideCustomer
     * @description deconstructs the request JSON into typed class to be worked with in insertContact()
     * @param String requestBody
     * @param Boolean paymentSuccessful
     * @return OLSRestServiceHelper
     */
    public static OLSRestServiceHelper getClientSideCustomer( String requestBody, Boolean paymentSuccessful ){

        OLSRestServiceHelper helper;

        try {
            
            helper = new OLSRestServiceHelper( requestBody, paymentSuccessful );
            helper.parseRequest();
             
        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler( e );
            handler.addMessage('Online Store Request\'s Detail: ' + JSON.serialize( requestBody ) );
            handler.handle();

            ErrorResponse error = new ErrorResponse( 'Client Request Body is Malformed: ' + e.getMessage() );
            error.details = requestBody;

            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf( JSON.serialize( error ) );
        }

        return helper;
    }

    /**
     * @name upsertContact
     * @description inserts new Contact record or updates an old one where the payment was unnsuccessful
     * @param OLSRestServiceHelper helper
     * @return Contact
     */
    public static Contact upsertContact( OLSRestServiceHelper helper ){
        if( helper == null || helper.customer == null ) return null;

        Contact contact;

        try {
            
            contact = helper.getContact();

            if( !OLSTriggerHelper.isOnlineStoreCustomer( contact ) ){
                throw new OnlineStoreCustomerException('This Contact could not be set as an Online Store Customer Record Type.');
            }

            upsert contact;

        } catch( Exception e ){
            String JSONContact = JSON.serialize( contact );

            CreedExceptionHandler handler = new CreedExceptionHandler( e );
            handler.addMessage('Online Store Contact\'s Detail: ' + JSONContact );
            handler.handle();

            ErrorResponse error = new ErrorResponse( 'Insert Operation Failed: ' + e.getMessage() );
            error.details = JSONContact;

            RestContext.response.statusCode = 501;
            RestContext.response.responseBody = Blob.valueOf( JSON.serialize( error ) );
        }

        return contact;
    }

/**
 * CLASSES
 */

    public class ErrorResponse {
        
        public String message {get;set;}
        public String details {get;set;}

        public ErrorResponse( String m ){
            message = m;
        }
    }

    public class OnlineStoreCustomerException extends Exception {}
}
