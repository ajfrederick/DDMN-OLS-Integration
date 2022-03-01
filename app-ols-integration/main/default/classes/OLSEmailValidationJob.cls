/**
 * @name OLSEmailValidationParentJob
 * @description this class is an http callout to an external api at whoisxmlapi.com to verify email addresses and mark OLS Contact
 * records as bounced for a weekly bounce report.
 * 
 * @author Creed Interactive (Andrew Frederick) March 2022
 */
public without sharing class OLSEmailValidationJob implements Schedulable {

/**
 * FIELDS
 */

    private DateTime oneMinuteFromNow {get;set;} 

/**
 * INTERFACE METHODS
 */

    /**
     * @name execute
     * @description required by interface. This gets a list of OLS customers and then creates some apex jobs scheduled for 1 minute
     * from now all scheduled 1 second apart. This is to well avoid hitting the email verification api limitations of less then 10 calls per second.
     * 
     * This job is scheduled every night at 1am.
     * 
     * @param System.SchedulableContext context
     * @return none
     */
    public void execute( System.SchedulableContext context ){
        oneMinuteFromNow = DateTime.now().addMinutes( 1 );

        Contact[] customers = getUnvalidatedOLSCustomers();

        System.debug(customers);

        Integer len = customers.size();

        for( Integer i = 0; i < len; i++ ){
            Contact customer = customers[i];

            String cronName = customer.Email + ' Email Validation Callout';

            String cronExpression = getCronExpression( i );
            
            OLSEmailValidationCalloutJob validator = new OLSEmailValidationCalloutJob( customer.Id );

            System.schedule( cronName, cronExpression, validator );
        }
    }

/**
 * UTILITY METHODS
 */

    /**
     * @name getCronExpression
     * @description a cron expression for 1 minute and 1 second with a separater of 1 more second from now.
     * @return String
     */
    private String getCronExpression( Integer interation ){
        oneMinuteFromNow.addSeconds( 1 * interation );

        String cronExpression = oneMinuteFromNow.second() + ' ';
        cronExpression += oneMinuteFromNow.minute() + ' ';
        cronExpression += oneMinuteFromNow.hour() + ' ';
        cronExpression += oneMinuteFromNow.day() + ' ';
        cronExpression += oneMinuteFromNow.month() + ' ';
        cronExpression += '?';

        return cronExpression;
    }

/**
 * QUERY METHODS
 */
    
    /**
     * @name getUnvalidatedOLSCustomers
     * @description this is a list of OLS customers that have not had their emails validated. There will only be 35 at a time to avoid
     * hitting the limit of only 100 concurrent apex jobs allowed to be scheduled.
     * @return Contact[]
     */
    private Contact[] getUnvalidatedOLSCustomers(){
        
        Contact[] customers = new Contact[]{};

        Id olsContact = OLSUtil.getOLSRecordTypeId();

        try {

            customers.addAll([SELECT
                                Id,
                                Email
                                    FROM Contact
                                    WHERE RecordTypeId = :olsContact
                                    AND Email_Validated__c = false
                                    AND Email != null
                                    LIMIT 35]);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.debug();
        }

        return customers;
    }
}