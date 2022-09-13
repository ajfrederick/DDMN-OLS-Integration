/**
 * @name HttpHandlerFailureMock
 * @description is a callout mock for http handler package
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
@isTest
public class HttpHandlerFailureMock implements HttpCalloutMock {
    
    public HttpResponse respond( HttpRequest req ){
        
        HttpResponse response = new HttpResponse();
        response.setHeader( 'Content-Type', 'application/json' );
        response.setBody( JSON.serialize( new TestReponse() ) );
        response.setStatus('Bad Input');
        response.setStatusCode( 400 );

        return response;
    }

    public class TestReponse {
        public String message = 'Failure!';
    }
}