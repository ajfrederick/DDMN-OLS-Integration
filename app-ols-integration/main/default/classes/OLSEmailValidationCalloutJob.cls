/**
 * @name OLSEmailValidationCalloutJob
 * @description this class is an http callout to an external api at whoisxmlapi.com to verify email addresses and mark OLS Contact
 * records as bounced for a weekly bounce report.
 * 
 * @author Creed Interactive (Andrew Frederick) March 2022
 */
public without sharing class OLSEmailValidationCalloutJob implements Schedulable {
    
/**
 * FIELDS
 */

    private Id customerId {get;set;}

/**
 * CONSTRUCTERS
 */

    public OLSEmailValidationCalloutJob( Id customerId ){
        this.customerId = customerId;
    }

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
    public void execute( System.SchedulableContext context ){
        validate( customerId, context.getTriggerId() );
    }

/**
 * FUTURE METHODS
 */

    /**
     * @name validate
     * @description This is an async method which actually makes the http callout to validate the email. Future methods must be static
     * and can only take primitive data types. It also aborts the job that called it as the job has finished and it needs
     * to be removed from the queue otherwise it stays in the queue.
     * @param Id customerId
     * @param Id cronId
     * @return none
     */
    @future(callout=true)
    private static void validate( Id customerId, Id cronId ){
        Contact customer = getCustomer(customerId);

        if( customer == null ){
            System.abortJob(cronId);
            return;
        }

        OLSEmailValidator validator = new OLSEmailValidator(customer.Email);
        validator.validate();

        updateCustomer( customer, validator.isValid() );

        System.abortJob(cronId);
    }

/**
 * ACTION METHODS
 */

    /**
     * @name updateCustomer
     * @description This actual updates the OLS customer record to indicate that it has been indeed validated and if the email
     * is invalid then mark that the initial welcome email was bounced.
     * @param Contact customer
     * @param Boolean isValid
     * @return none
     */
    private static void updateCustomer( Contact customer, Boolean isValid ){

        try {

            customer.Email_Validated__c = true;
        
            if( !isValid ){
                customer.Email_Bounced__c = true;
            }

            update customer;

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

/**
 * QUERY METHODS
 */

    /**
     * @name getCustomer
     * @description Gets an OLS Customer since future methods only allow primitave data types and we were only able to 
     * pass it the Id of the customer record.
     * @param Id customerId
     * @return none
     */
    private static Contact getCustomer( Id customerId ){
        Contact customer;

        try {
            
            customer = [SELECT
                        Id,
                        Email
                            FROM Contact
                            WHERE Id = :customerId];

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }

        return customer;
    }

/**
 * EXCEPTION CLASSES
 */

    public class EmailValidationException extends Exception {}
}