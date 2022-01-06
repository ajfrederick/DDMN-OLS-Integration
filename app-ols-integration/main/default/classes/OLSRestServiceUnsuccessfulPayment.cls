/**
 * @name OLSRestServiceUnsuccessfulPayment
 * @description exposed rest api endpoint that is managed with a Connected App called DDMN Web Apps.
 * 
 * DDMN Web Apps access this end point with a JWT Bearer flow. This particular method is called in the Online Store when
 * an indiviual customer requests a product and their payment method has been approved.
 * 
 * for OLS registrants when their payment is unsucccessful.
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
@RestResource(urlMapping='/CreateOnlineStoreCustomerUnsuccessfulPayment')
global without sharing class OLSRestServiceUnsuccessfulPayment {
   
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
        
        // set payment successful param to false
        OLSRestServiceHelper helper = OLSRestService.getClientSideCustomer( requestBody, false );

        Contact newContact = OLSRestService.upsertContact( helper );

        if( newContact == null || newContact.Id == null ) return;

        RestContext.response.statusCode = 201;
        RestContext.response.responseBody = Blob.valueOf( JSON.serialize( newContact ) );
    }
}
