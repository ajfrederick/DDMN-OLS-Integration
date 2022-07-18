/**
 * @name OLSCronJobHelper
 * @description internally creates cron jobs for this application, the OLS integration application.
 * 
 * @author Creed Interactive (Andrew Frederick) July 2022
 */
public with sharing class OLSCronJobHelper {
  
/**
 * FIELDS
 */

    private static OLS_Cron_Job_Detail__mdt bounceReportCronJobDetail {get;set;}
    private static OLS_Cron_Job_Detail__mdt emailValidationCronJobDetail {get;set;}

    private static Boolean isDev {get;set;}

    static {

        isDev = [SELECT isSandBox FROM Organization LIMIT 1].IsSandbox;

        try {

            Map<String, OLS_Cron_Job_Detail__mdt> cronJobDetails = OLS_Cron_Job_Detail__mdt.getAll();
    
            bounceReportCronJobDetail = cronJobDetails.get('Bounce_Report');
            emailValidationCronJobDetail = cronJobDetails.get('Email_Validation');

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }
    }

/**
 * ACTION METHODS
 */

    /**
     * @name scheduleBounceBackReportJob
     * @description schedules the job to email bounce reports to selected individuals if there isn't one already.
     * @param none
     * @return none
     */
    public static void scheduleBounceBackReportJob(){
        if( getJob('OLSBounceReportJob') != null ){ return; }

        scheduleJob( bounceReportCronJobDetail.Job_Name__c, getCronExpression( bounceReportCronJobDetail ), new OLSBounceReportJob() );
    }

     /**
     * @name scheduleBounceEmailValidationJob
     * @description schedules the job to validate OLS customer emails.
     * @param none
     * @return none
     */
    public static void scheduleBounceEmailValidationJob(){
        if( getJob('OLSEmailValidation') != null ){ return; }

        scheduleJob( emailValidationCronJobDetail.Job_Name__c, getCronExpression( emailValidationCronJobDetail ), new OLSEmailValidation() );
    }

    /**
     * @name scheduleJob
     * @description schedules actual job
     * @param String jobName
     * @param String cronExpression
     * @param Schedulable schedulable
     * @return none
     */
    private static void scheduleJob( String jobName, String cronExpression, Schedulable schedulable ){

        try {

            System.schedule(jobName, cronExpression, schedulable);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

/**
 * UTILITY METHODS
 */

     /**
     * @name getCronExpression
     * @description gets cron expression from detail metadata type (e.g. every wednesday = '0 0 6 ? * WED')
     * @param Cron_Job_Detail__mdt detail
     * @return String
     */
    private static String getCronExpression( OLS_Cron_Job_Detail__mdt detail ){
        String cronExpression;

        if( isDev ){    
            cronExpression = OLSUtil.getMinutesFromNow( (Integer) detail.Minutes_From_Now__c ); 
        } else {
            cronExpression = detail.Cron_Expression__c;
        }

        return cronExpression;
    }

/**
 * QUERY METHODS
 */

    /**
     * @name getJob
     * @description get job by scheduable class to see if the job already exists
     * @param String className
     * @return none
     */
    private static AsyncApexJob getJob( String className ){
        AsyncApexJob job;

        try {

            job = [SELECT
                    Id
                        FROM AsyncApexJob
                        WHERE ApexClass.Name = :className
                        AND JobType = 'ScheduledApex'
                        AND Status != 'Aborted'
                        AND Status != 'Completed'
                        AND Status != 'Failed'
                        LIMIT 1];

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.debug();
        }

        return job;
    }
}
