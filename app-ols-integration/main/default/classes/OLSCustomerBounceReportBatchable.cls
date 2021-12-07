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

    private Contact[] customers {
        get {
            if( customers == null ) customers = new Contact[]{};
            return customers;
        }
        set;
    }
    
/**
 * INTERFACE METHODS
 */

    public Database.QueryLocator start( Database.BatchableContext context ){
        String olsCustomer = OnlineStoreCustomerHelper.getRecordTypeId('Online_Store_Customer');

        String q = 'SELECT ';
                q += 'Id, ';
                q += 'FirstName, ';
                q += 'LastName, ';
                q += 'Email, ';
                q += 'MailingAddress, ';
                q += 'CreatedDate, ';
                q += 'CAID__c, ';
                q += 'Email_Bounced__c, ';
                q += 'Bounce_Reported__c, ';
                q += 'Product_Purchased__c ';
                    q += 'FROM Contact ';
                    q += 'WHERE EmailBouncedDate != null ';
                    q += 'AND Bounce_Reported__c = false ';
                    q += 'AND RecordTypeId = ' + olsCustomer;

        return Database.getQueryLocator(q);
    }

    public void execute( Database.BatchableContext context, Contact[] customers ){
        this.customers = customers;
    }

    public void finish( Database.BatchableContext context ){
        Date newDate = Date.today();

        String subject = 'Online Store Customer Bounce Report';
        String body = 'Here is the bounce report for all Online Strore Customers who failed to received a brochure via email.';

        String filename = 'OLS_BouncedEmails_' + newDate.month() + '-' + newDate.day() + '-' + newDate.year() + '.xlsx';
        Blob attachmentBody = Blob.valueOf( getAttachmentBody() );
    
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

System.debug('messages ... ' + messageCreator.getOutboundMessages());
System.debug('customers ... ' + customers);

        updateCustomers();
    }

/**
 * ACTION METHODS
 */

    private void updateCustomers(){

        for( Contact customer : this.customers ){
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

    private String getAttachmentBody(){
        String body = 'Id, Name, Email, Mailing Address, Product Purchased, CAID, Created Date \n';

        for( Contact customer : this.customers ){
            body += customer.Id + ',';
            body += customer.FirstName + ' ' + customer.LastName + ',';
            body += customer.Email + ',';
            body += getMailingAddress(customer) + ',';
            body += customer.Product_Purchased__c + ',';
            body += customer.CAID__c + ',';
            body += customer.CreatedDate + ' \n';
        }

        return body;
    }

    private String getMailingAddress( Contact customer ){
        String mailingAddress = customer.MailingStreet + ' ';
        mailingAddress += customer.MailingCity + ', ';
        mailingAddress += customer.MailingState + ' ';
        mailingAddress += customer.MailingPostalCode;

        return mailingAddress;
    }
}
