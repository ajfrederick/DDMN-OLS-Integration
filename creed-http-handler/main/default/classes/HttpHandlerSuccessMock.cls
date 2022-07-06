/**
 * @name HttpHandlerSuccessMock
 * @description is a callout mock for http handler package
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
@isTest
public class HttpHandlerSuccessMock implements HttpCalloutMock {
    
    public HttpResponse respond( HttpRequest req ){
        
        HttpResponse response = new HttpResponse();
        response.setHeader( 'Content-Type', 'application/json' );
        response.setBody( JSON.serialize( new TestReponse() ) );
        response.setStatus('OK');
        response.setStatusCode( 200 );

        return response;
    }

    public class TestReponse {
        public String message = 'Success!';
    }
}
