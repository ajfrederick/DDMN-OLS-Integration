/**
 * @name MessageHandler
 * @description handles inbound and outbound messages
**/
global class MessageHandler {

    private MessageCreator messageCreator {get;set;}

    private OutboundEmailResults outboundResults {get;set;}

    global static Boolean triggerEnabled {
        get {
            if( triggerEnabled == null ) triggerEnabled = false;

            return triggerEnabled;
        }
        set;
    }

/**
 * CONSTRUCTOR
**/

    global MessageHandler( MessageCreator mc ) {
        messageCreator = mc;
    }

/**
 * ACTION METHODS
**/
    /**
     * @name handle
     * @description sends outbound and recieves inbound messages
     * @return void
    **/
    global void handle(){
        triggerEnabled = true;

        if( messageCreator.hasOutboundMessages() ){
            send( messageCreator.getOutboundMessages() );
        }

        if( messageCreator.hasInboundMessages() ){
            receive( messageCreator.getInboundMessages() );
        }
    }

    /**
     * @name send
     * @description Sends messages
     * @param Messaging.SingleEmailMessage[] messages
     * @return void
    **/
    private void send( Messaging.SingleEmailMessage[] messages ){

        //Utils.EmailLimitsData limitsData = Utils.getEmailLimitsData();

        try {
            /*
            if( limitsData.totalSentToday == (limitsData.emailTotalLimit - 1) ){
                throw new EmailException( 'WARNING: This org has reached it\'s email limit of ' + limitsData.emailTotalLimit + ' and this is the final email that can be sent. After this emails will no longer be sent with the Creed email app to avoid operation failures with applications that rely on this one.');
            }
            
            if( limitsData.limitExceeded ) return;
            */
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail( messages );

            outboundResults = new OutboundEmailResults( results );
            outboundResults.setSuccesses( messages );

            if( outboundResults.hasFailures() ){
                String joinedErrorMessages = String.join( outboundResults.getErrorMessages(), '\n\n' );

                throw new EmailException( joinedErrorMessages );
            }

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

    /**
     * @name receive
     * @description inserts/receive messages
     * @return void
    **/
    private void receive( EmailMessage[] messages ){

        try {

            insert messages;

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

    /**
     * @name getOutboundEmailResults
     * @description return the results of the outbound messages to get failures
     * @return OutboundEmailResults
    **/
    global OutboundEmailResults getOutboundEmailResults(){
        return outboundResults;
    }

/**
 * CLASSES
**/

    global class EmailException extends Exception {}
}
