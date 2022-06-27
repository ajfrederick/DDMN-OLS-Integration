/**
 * @name OLSEmailValidation
 * @description this class is an http callout to an external api at whoisxmlapi.com to verify email addresses and mark OLS Contact
 * records as bounced for a weekly bounce report.
 * 
 * @author Creed Interactive (Andrew Frederick) March 2022
 */
global without sharing class OLSEmailValidation implements Schedulable {

/**
 * INTERFACE METHODS
 */

    /**
     * @name execute
     * @description required by interface. This calls validate. The reason for this structure is http callouts are not allowed
     * in apex job execute methods. They need to be called from a future method when called from a job.
     * @param System.SchedulableContext context
     * @return none
     */
    global void execute( System.SchedulableContext context ){
        validate();
    }

/**
 * FUTURE METHODS
 */

    /**
     * @name validate
     * @description This is an async method which calls validate on OLSEmailValidator instance. This makes an initial bulk email verification call which
     * starts a job at external api. Then scheduleStatusCheck() schedules another apex job using class OLSEmailValidationCheckStatus to check on the status of the job. 
     * If the job is finished then that job makes another callout to retrieve the results using the OLSEmailValidator instance.
     * @param none
     * @return none
     */
    @future(callout=true)
    private static void validate(){
        Contact[] customers = getCustomers();

        if( customers.isEmpty() ){ return; }

        OLSEmailValidator validator = new OLSEmailValidator(customers);
        validator.validate();
        validator.scheduleStatusCheck();
    }

/**
 * QUERY METHODS
 */

    /**
     * @name getCustomers
     * @description Gets an OLS Customers since future methods only allow primitave data types and we were only able to 
     * pass it the Id of the customers record.
     * @param Id 
     * @return none
     */
    private static Contact[] getCustomers(){
        Contact[] customers = new Contact[]{};

        try {
            
            customers.addAll([SELECT
                        Id,
                        Email
                            FROM Contact
                            WHERE RecordTypeId = :OLSUtil.getOLSRecordTypeId()
                            AND Email_Validated__c = false
                            LIMIT 5000]);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }

        return customers;
    }
}