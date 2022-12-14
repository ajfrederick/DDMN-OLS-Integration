/**
 * @name OLSBounceReportJob
 * @description this emails the bounce report of any Online Store Customer (contact) record and then sets the email bounced flag
 * as well as the bounce reported. Uses batchable for scaling.
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public class OLSBounceReportJob implements Schedulable {
    
    public void execute( System.SchedulableContext context ){
        Database.executeBatch( new OLSBounceReportBatch(), 2000 );
    }
}