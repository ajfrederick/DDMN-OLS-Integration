/**
 * @name OLSEmailValidationCheckStatus
 * @description this class is queues a queueable class which makes a call out to whoisxmlapi.com to check the status of a bulk email verification job.
 * 
 * @author Creed Interactive (Andrew Frederick) June 2022
 */
public without sharing class OLSEmailValidationCheckStatus implements Schedulable {

/**
 * FIELDS
 */

    private OLSEmailValidator validator {get;set;}

/**
 * CONSTUCTOR
 */

    public OLSEmailValidationCheckStatus( OLSEmailValidator validator ) {
        this.validator = validator;
    }

/**
 * INTERFACE METHOD
 */

    /**
     * @name execute
     * @description required by interface. This makes queues a queueable job which allows asyncronous callouts. Schudelable classes cannot make http callouts.
     * @param System.SchedulableContext context
     * @return none
     */
    public void execute( System.SchedulableContext context ){
        validator.cronJobId = context.getTriggerId();

        OLSEmailValidationRetrieveResults resultsRetriever = new OLSEmailValidationRetrieveResults( validator );

        System.enqueueJob(resultsRetriever);
    }
}
