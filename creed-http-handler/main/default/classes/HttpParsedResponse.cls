public class HttpParsedResponse {

    public String responseBody {
        get {

            if( responseBody == null ){
                responseBody = '{}';
            }
            
            return responseBody;
        }
        set;
    }

    public HttpParsedResponseError[] errors {
        get {

            if( errors == null ){
                errors = new HttpParsedResponseError[]{};
            }

            return errors;
        }
        set;
    }
}