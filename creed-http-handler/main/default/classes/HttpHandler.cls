/**
 * @name HttpHandler
 * @description Handles http request and parse the response while handling any errors. Must be extended with an getEnpoint() definition.
 * 
 * @author Creed Interactive (Andrew Frederick) March 2022
 */
public abstract class HttpHandler {

/**
 * FIELDS
 */

    public HttpRequest request {get;set;}
    
    public HttpResponse response {get;set;}

    public HttpParsedResponse parsedResponse {
        get {
            
            if( parsedResponse == null ){
                parsedResponse = new HttpParsedResponse();
            }
            
            return parsedResponse;
        }
        set;
    }

    private Map<String, String> params {
        get {
            
            if( params == null ){
                params = new Map<String, String>();
            }
            
            return params;
        }
        set;
    }

    private String methodType {
        get {

            if( methodType == null ){
                methodType = 'GET';
            }

            return methodType;
        }
        set;
    }

/**
 * ABSTRACT METHODS
 */

    /**
     * @name getEndpoint
     * @description this is the must define endpoint for the request
     * @param none
     * @return String
     */
    public abstract String getEndpoint();

/**
 * ACTION METHODS
 */

    /**
     * @name send
     * @description sends a request without have to externally create the request object
     * @param none
     * @return none
     */
    public void send(){
        send( new HttpRequest() );
    }

    /**
     * @name send
     * @description sends a request having externally creating the request object
     * @param HttpRequest request
     * @return none
     */
    public void send( HttpRequest request ){
        this.request = request;

        request.setEndpoint( getEndpoint() );
        request.setMethod( getMethod() );

        Http http = new Http();

        response = http.send( request );

        parseResponse();
    }

    /**
     * @name parseResponse
     * @description gets the reponse body from the HttpResponse object, checks the status and if the statusCode
     * is an error the grab the errors and the throw an exception.
     * @param none
     * @return none
     */
    private void parseResponse(){
        parsedResponse.responseBody = response.getBody();

        if( response.getStatusCode() > 299 ){
            parseErrors();
        }

        checkErrors();
    }
    
    /**
     * @name parseErrors
     * @description if there is an error statusCode create and error object and add it to the list of error objects.
     * the getErrorMessage is vitural so that sub classes can get more precise on what the message is if the developer 
     * knows the format of the response.
     * @param none
     * @return none
     */
    private void parseErrors(){
        HttpParsedResponseError error = new HttpParsedResponseError();
        error.errorMessage = getErrorMessage();
        error.statusCode = response.getStatusCode();
        error.status = response.getStatus();
        
        parsedResponse.errors.add( error );
    }

/**
 * UTILITY METHODS
 */

    /**
     * @name getMethod
     * @description returns the http request method which is defaulted above to GET
     * @param none
     * @return String
     */
    protected virtual String getMethod(){
        return methodType;
    }

    /**
     * @name setMethod
     * @description sets the method type
     * @param none
     * @return String
     */
    public void setMethod( String methodType ){
        this.methodType = methodType;
    }

    /**
     * @name setQueryParams
     * @description sets the params for a query string in an endpoint URL. These are name, value pairs.
     * @param Map<String, String> params
     * @return none
     */
    public void setQueryParams( Map<String, String> params ){
        this.params = params;
    }

    /**
     * @name getQuery
     * @description takes the params name, value params and creates a query string for an endpoint URL.
     * @param none
     * @return String
     */
    protected String getQuery(){
        String query = '?';

        Integer i = 0;

        Integer len = params.keyset().size();

        for( String name : params.keyset() ){
            String value = params.get(name);

            query += name + '=' + value;

            if( i < (len-1) ){
                query += '&';
            }

            i++;
        }

        return query;
    }

    /**
     * @name checkErrors
     * @description checks to see if the request came back with errors and if it did throws an exception.
     * @param none
     * @return String
     */
    public void checkErrors(){
        if( hasErrors() ){
            throw new HttpException( JSON.serialize( getErrors() ) );
        }
    }

    /**
     * @name hasErrors
     * @description 
     * @param none
     * @return Boolean
     */
    public Boolean hasErrors(){
        return parsedResponse.errors.size() > 0;
    }

    /**
     * @name getErrors
     * @description 
     * @param none
     * @return HttpParsedResponseError[]
     */
    public HttpParsedResponseError[] getErrors(){
        return parsedResponse.errors;
    }

    /**
     * @name getErrorMessage
     * @description this simply returns the responseBody of the HttpResponse as a default. It is encouraged that anyone extending
     * this class overrides this method to more precisely parse the error message from the response.
     * @param none
     * @return String
     */
    protected virtual String getErrorMessage(){
        return parsedResponse.responseBody;
    }

/**
 * CLASSES
 */

    class HttpException extends Exception {}
}