/**
 * @name OLSEmailValidationCalloutMock
 * @description is a callout mock to an external api at whoisxmlapi.com
 * 
 * Documentation for api found at https://emailverification.whoisxmlapi.com/bulk-api/documentation
 * 
 * @author Creed Interactive (Andrew Frederick) March 2022
 */
@IsTest
public class OLSEmailValidationCalloutMock implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {

        String requestUrl = OLSEmailValidator.credential.Request_URL__c;

        System.assert( req.getEndpoint().contains(requestUrl), 'Email Verification endpoint should contain the Custom Metadata Type OLS_api_credential__mdt\'s Request_URL__c' );
        System.assertEquals( 'POST', req.getMethod(), 'Email Verification method type should be POST' );

        
        HttpResponse response = new HttpResponse();
        response.setHeader( 'Content-Type', 'application/json' );
        response.setBody( JSON.serialize( getResponse() ) );
        response.setStatusCode( 200 );

        return response;
    }

    private OLSEmailValidator.EmailVerificationResponse getResponse(){
        OLSEmailValidator.EmailVerificationResponseResponse responseResponse = new OLSEmailValidator.EmailVerificationResponseResponse();
        responseResponse.id = 1;

        OLSEmailValidator.EmailVerificationResponse response = new OLSEmailValidator.EmailVerificationResponse();
        response.response = responseResponse;

        return response;
    }
}
