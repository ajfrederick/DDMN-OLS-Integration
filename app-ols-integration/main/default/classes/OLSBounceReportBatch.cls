/**
 * @name OLSBounceReportBatch
 * @description this emails the bounce report of any Online Store Customer (contact) record and then sets the email bounced flag
 * as well as the bounce reported
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public class OLSBounceReportBatch implements Database.Batchable<SObject> {

/**
 * FIELDS
 */

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
        String olsCustomer = OLSUtil.getRecordTypeId('Online_Store_Customer');

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
                    q += 'WHERE Email_Bounced__c = true ';
                    q += 'AND Bounce_Reported__c = false ';
                    q += 'AND RecordTypeId = :olsCustomer';

        return Database.getQueryLocator(q);
    }

    public void execute( Database.BatchableContext context, Contact[] customers ){
        this.customers = customers;
    }

    public void finish( Database.BatchableContext context ){

        CustomEmailTemplate template = new CustomEmailTemplate( this.customers );

        EmailParcel parcel = new EmailParcel();
        parcel.setContent( template.subject, template.body, template.body );
        parcel.setAttachment( template.filename, template.attachmentBody );

        addToAddresses( parcel );

        EmailFactoryOutbound emailFactory = new EmailFactoryOutbound( new EmailParcel[]{parcel} );
        emailFactory.build();

        EmailPost emailPost = new EmailPost( emailFactory );
        emailPost.post();

        updateCustomers();
    }

/**
 * ACTION METHODS
 */

    private void updateCustomers(){

        for( Contact customer : this.customers ){
            customer.Bounce_Reported__c = true;
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

    private void addToAddresses( EmailParcel parcel ){
        for( OLS_Bounce_Report_Email_Address__mdt record : OLS_Bounce_Report_Email_Address__mdt.getAll().values() ){
            parcel.ToAddresses.add(record.Email__c);
        }
    }

/**
 * CLASSES
 */

    public class CustomEmailTemplate {

        public String subject = 'Online Store Customer Bounce Report';
        private String body = 'Here is the bounce report for all Online Strore Customers who failed to received a brochure via email.';

        public String filename {get;set;}
        public Blob attachmentBody {get;set;}

        public Contact[] customers {get;set;}


        public CustomEmailTemplate( Contact[] customers ){
            this.customers = customers;

            setFileName();
            setAttachmentBody();
        }

        private void setFileName(){
            Date newDate = Date.today();
            filename = 'OLS_BouncedEmails_' + newDate.month() + '-' + newDate.day() + '-' + newDate.year() + '.csv';
        }

        private void setAttachmentBody(){
            attachmentBody = Blob.valueOf( getAttachmentBody() );
        }

        private String getAttachmentBody(){
            String body = 'Id, Name, Email, Mailing Address, Product Purchased, CAID, Created Date \n';
    
            for( Contact customer : this.customers ){
                body += customer.Id + ', ';
                body += customer.FirstName + ' ' + customer.LastName + ', ';
                body += customer.Email + ', ';
                body += getMailingAddress(customer) + ', ';
                body += customer.Product_Purchased__c + ', ';
                body += customer.CAID__c + ', ';
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
}
