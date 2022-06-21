global class HttpParsedResponse {

    global String responseBody {
        get {

            if( responseBody == null ){
                responseBody = '{}';
            }
            
            return responseBody;
        }
        set;
    }

    global HttpParsedResponseError[] errors {
        get {

            if( errors == null ){
                errors = new HttpParsedResponseError[]{};
            }

            return errors;
        }
        set;
    }
}