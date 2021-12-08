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
        OLSRestServiceHelper helper = getClientSideCustomer( RestContext.request.requestBody.toString() );

        Contact newContact = insertContact( helper );

        if( newContact != null && newContact.Id != null ){
            RestContext.response.statusCode = 201;
            RestContext.response.responseBody = Blob.valueOf( JSON.serialize( newContact ) );
        }
    }

/**
 * ACTION METHODS
 */

    /**
     * @name insertContact
     * @description deconstructs the request JSON into typed class to be worked with in insertContact()
     * @param none
     * @return none
     */
    private static OLSRestServiceHelper getClientSideCustomer( String requestBody ){

        OLSRestServiceHelper helper;

        try {
            
            helper = new OLSRestServiceHelper( requestBody );
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
     * @name insertContact
     * @description inserts actual Contact record
     * @param none
     * @return none
     */
    private static Contact insertContact( OLSRestServiceHelper helper ){
        if( helper == null || helper.customer == null ) return null;

        Contact newContact;

        try {
            
            newContact = helper.getNewContact();

            if( !OnlineStoreCustomerHelper.isOnlineStoreCustomer( newContact ) ){
                throw new OnlineStoreCustomerException('This Contact could not be set as an Online Store Customer Record Type.');
            }

            insert newContact;

        } catch( Exception e ){
            String JSONContact = JSON.serialize( newContact );

            CreedExceptionHandler handler = new CreedExceptionHandler( e );
            handler.addMessage('Online Store Contact\'s Detail: ' + JSONContact );
            handler.handle();

            ErrorResponse error = new ErrorResponse( 'Insert Operation Failed: ' + e.getMessage() );
            error.details = JSONContact;

            RestContext.response.statusCode = 501;
            RestContext.response.responseBody = Blob.valueOf( JSON.serialize( error ) );
        }

        return newContact;
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
