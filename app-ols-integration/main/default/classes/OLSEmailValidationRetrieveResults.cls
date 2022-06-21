/**
 * @name OLSEmailValidationCheckOLSEmailValidationRetrieveResultsStatus
 * @description this class is a queueable class which makes a call out to whoisxmlapi.com to check the status of a bulk email verification job.
 * 
 * @author Creed Interactive (Andrew Frederick) June 2022
 */
public without sharing class OLSEmailValidationRetrieveResults implements Queueable, Database.AllowsCallouts {
    
/**
 * FIELDS
 */

    private OLSEmailValidator validator {get;set;}

/**
 * CONSTUCTOR
 */

    public OLSEmailValidationRetrieveResults( OLSEmailValidator validator ) {
        this.validator = validator;
    }

/**
 * INTERFACE METHODS
 */

    /**
     * @name execute
     * @description required by interface. This makes the callouts to check the status. If the job is not ready then we cancel the scheduled apex job that
     * queued this queueuable and schedule another job. If the job is finished then the third and final callout is made to retrieve the results. Then
     * we update the OLS contact records
     * @param System.QueueableContext context
     * @return none
     */
    public void execute( System.QueueableContext context ){
        validator.checkStatus();

        if( !validator.isReady() ){

            validator.abortCronJob();
            validator.scheduleStatusCheck();
            
        } else {

            validator.retrieveResults();
            validator.abortCronJob();

            updateCustomers();
        }
    }

/**
 * ACTION METHODS
 */

    /**
     * @name updateCustomers
     * @description This actual updates the OLS customers record to indicate that it has been indeed validated and if the email
     * is invalid then mark that the initial welcome email was bounced.
     * @param Contact customers
     * @param Boolean isValid
     * @return none
     */
    private void updateCustomers(){

        for( Contact customer : validator.customers ){

            customer.Email_Validated__c = true;
        
            if( validator.isInvalid( customer.Email ) ){
                customer.Email_Bounced__c = true;
            }

        }

        try {

            update validator.customers;

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

}
