/**
 * @name OLSCustomerBounceReportBatchable
 * @description this emails the bounce report of any Online Store Customer (contact) record and then sets the email bounced flag
 * as well as the bounce reported
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public class OLSCustomerBounceReportBatchable implements Database.Batchable<SObject> {

/**
 * FIELDS
 */

    private static final String fromAddress = System.Label.Online_Store_Reply_From_Address;
    
/**
 * INTERFACE METHODS
 */

    public Database.QueryLocator start( Database.BatchableContext context ){
        String q = 'SELECT ';
                q += 'Id, ';
                q += 'FirstName, ';
                q += 'LastName, ';
                q += 'Email, ';
                q += 'MailingAddress, ';
                q += 'CreatedDate, ';
                q += 'CAID__c, ';
                q += 'Email_Bounced__c, ';
                q += 'Bounce_Reported__c ';
                    q += 'FROM Contact ';
                    q += 'WHERE EmailBouncedDate != null ';
                    q += 'AND Bounce_Reported__c = false';

        return Database.getQueryLocator(q);
    }

    public void execute( Database.BatchableContext context, Contact[] customers ){
        Date newDate = Date.today();

        String subject = 'Online Store Customer Bounce Report';
        String body = 'Here is the bounce report for all Online Strore Customers who failed to received a brochure via email.';

        String filename = 'OLS_BouncedEmails_' + newDate.month() + '-' + newDate.day() + '-' + newDate.year() + '.xlsx';
        Blob attachmentBody = Blob.valueOf( getAttachmentBody(customers) );
    
        EmailContainer container = new EmailContainer();
        
        for( OLS_Bounce_Report_Email_Address__mdt record : OLS_Bounce_Report_Email_Address__mdt.getAll().values() ){
            container.ToAddresses.add(record.Email__c);
        }

        container.setContent( subject, body, body );
        container.setAttachment( filename, attachmentBody );

        MessageCreatorOutbound messageCreator = new MessageCreatorOutbound( new EmailContainer[]{container} );
        messageCreator.setOrgWideEmailAddressId(fromAddress);
        messageCreator.create();

        MessageHandler handler = new MessageHandler( messageCreator );
        handler.handle();

        updateCustomers( customers );
    }

    public void finish( Database.BatchableContext context ){

    }

/**
 * ACTION METHODS
 */

    private void updateCustomers( Contact[] customers ){

        for( Contact customer : customers ){
            customer.Bounce_Reported__c = true;
            customer.Email_Bounced__c = true;
        }

        try {

            update customers;

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

/**
 * UTILITY METHODS
 */

    private String getAttachmentBody( Contact[] customers ){
        String body = 'Id, Name, Email, Mailing Address, CAID, Created Date \n';

        for( Contact customer : customers ){
            body += customer.Id + ',' + customer.FirstName + ' ' + customer.LastName + ',' + customer.Email + ',' + customer.MailingAddress + ',' + customer.CAID__c + ',' + customer.CreatedDate + ' \n';
        }

        return body;
    }
}
