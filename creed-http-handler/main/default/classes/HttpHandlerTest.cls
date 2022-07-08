/**
 * @name HttpHandlerTest
 * @description Test Creed Http Handler
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
@isTest
public class HttpHandlerTest {
    
    @isTest
    public static void testHttpHandlerSuccess(){

        Test.setMock( HttpCalloutMock.class, new HttpHandlerSuccessMock() );

        HttpHandlerTestGet httpHandler = new HttpHandlerTestGet();
        
        Test.startTest();

            Map<String, String> params = new Map<String, String>();
            params.put('firstname', 'Andrew');

            httpHandler.setQueryParams(params);
            httpHandler.send();

        Test.stopTest();

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped( httpHandler.getReponseBody() );

        System.assertEquals('OK', httpHandler.getStatus());
        System.assertEquals(200, httpHandler.getStatusCode());
        System.assertEquals(false, httpHandler.hasErrors());
        System.assertEquals('Success!', (String) parsed.get('message'));

    }

    @isTest
    public static void testHttpHandlerFailure(){

        Test.setMock( HttpCalloutMock.class, new HttpHandlerFailureMock() );

        HttpHandlerTestPost httpHandler = new HttpHandlerTestPost();
        
        Test.startTest();

            HttpRequest request = new HttpRequest();
            request.setBody( JSON.serialize( new TestRequest() ) );

            httpHandler.send( request );

        Test.stopTest();

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped( httpHandler.getReponseBody() );

        System.assertEquals('Bad Input', httpHandler.getStatus());
        System.assertEquals(400, httpHandler.getStatusCode());
        System.assertEquals(true, httpHandler.hasErrors());
        System.assertEquals('Failure!', (String) parsed.get('message'));
    }

    public class HttpHandlerTestGet extends HttpHandler {

        public override String getEndpoint(){
            return 'www.fakeendpoint.com' + getQuery();
        }
    }

    public class HttpHandlerTestPost extends HttpHandler {

        public override String getEndpoint(){
            return 'www.fakeendpoint.com';
        }

        public override String getMethod(){
            return 'POST';
        }
    }

    public class TestRequest {
        public String message = 'Help!';
    }
}
