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


        public HttpResponse response {get;set;}
    
        public String responseBody {
            get {
                
                if( responseBody == null ){
                    responseBody = '{}';
                }
                
                return responseBody;
            }
            set;
        }

        private Integer statusCode {get;set;}

        private String status {get;set;}
    
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
            responseBody = response.getBody();
            status = response.getStatus();
            statusCode = response.getStatusCode();
    
            if( hasErrors() ){

                if( !Test.isRunningTest() ) {
                    throw new HttpException( JSON.serialize( getError() ) );
                } else {
                    getError();
                }
            }
        }
        
        /**
         * @name getError
         * @description if there is an error statusCode create and error object.
         * the getErrorMessage is vitural so that sub classes can get more precise on what the message is if the developer 
         * knows the format of the response.
         * @param none
         * @return none
         */
        private HttpError getError(){
            HttpError error = new HttpError();
            error.message = getErrorMessage();
            error.statusCode = statusCode;
            error.status = status;

            return error;
        }
    
    /**
     * UTILITY METHODS
     */ 

        /**
         * @name getReponseBody
         * @description returns the body of the reponse
         * @param none
         * @return String
         */
        public virtual String getReponseBody(){
            return responseBody;
        }
    
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
        public String getQuery(){
            String query = '?';
    
            Integer i = 0;
    
            Integer len = params.keyset().size();
    
            for( String name : params.keyset() ){
                String value = params.get(name);
    
                query += name + '=' + EncodingUtil.urlEncode( value, 'UTF-8');
    
                if( i < (len-1) ){
                    query += '&';
                }
    
                i++;
            }
    
            return query;
        }

        /**
         * @name getStatus
         * @description 
         * @param none
         * @return String
         */
        public String getStatus(){
            return status;
        }
    
        /**
         * @name getStatusCode
         * @description 
         * @param none
         * @return Integer
         */
        public Integer getStatusCode(){
            return statusCode;
        }
    
        /**
         * @name hasErrors
         * @description 
         * @param none
         * @return Boolean
         */
        public Boolean hasErrors(){
            return statusCode > 299 ;
        }
    
        /**
         * @name getErrorMessage
         * @description this simply returns the responseBody of the HttpResponse as a default. It is encouraged that anyone extending
         * this class overrides this method to more precisely parse the error message from the response.
         * @param none
         * @return String
         */
        protected virtual String getErrorMessage(){
            return responseBody;
        }
    
    /**
     * CLASSES
     */

        class HttpError {
            String message {get;set;}
            String status {get;set;}
            Integer statusCode {get;set;}
        }
    
        class HttpException extends Exception {}
    }