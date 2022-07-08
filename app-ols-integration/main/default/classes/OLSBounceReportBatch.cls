/**
 * @name OLSBounceReportBatch
 * @description this emails the bounce report of any Online Store Customer (contact) record and then sets the email bounced flag
 * as well as the bounce reported
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
global class OLSBounceReportBatch implements Database.Batchable<SObject>, Database.Stateful {

/**
 * INTERFACE METHODS
 */ 

    private Contact[] customers {
        get {
            if( customers == null ){
                customers = new Contact[]{};
            }
            return customers;
        }
        set;
    }

/**
 * INTERFACE METHODS
 */
    
    global Database.QueryLocator start( Database.BatchableContext context ){
        String olsCustomer = OLSUtil.getOLSRecordTypeId();

        String q = 'SELECT ';
                q += 'Id, ';
                q += 'FirstName, ';
                q += 'LastName, ';
                q += 'Email, ';
                q += 'MailingStreet, ';
                q += 'MailingCity, ';
                q += 'MailingState, ';
                q += 'MailingPostalCode, ';
                q += 'CreatedDate, ';
                q += 'CAID__c, ';
                q += 'Product_Purchased__c ';
                    q += 'FROM Contact ';
                    q += 'WHERE Email_Validated__c = true ';
                    q += 'AND Email_Bounced__c = true ';
                    q += 'AND Bounce_Reported__c = false ';
                    q += 'AND RecordTypeId = :olsCustomer';

        return Database.getQueryLocator(q);
    }

    global void execute( Database.BatchableContext context, Contact[] scopeCustomers ){

        try {

            for( Contact customer : scopeCustomers ){
                customer.Bounce_Reported__c = true;
            }

            update scopeCustomers;

            this.customers.addAll(scopeCustomers);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

    global void finish( Database.BatchableContext context ){

        CustomEmailTemplate template = new CustomEmailTemplate( this.customers );

        EmailParcel parcel = new EmailParcel();
        parcel.setContent( template.subject, template.body, template.body );
        parcel.setAttachment( template.filename, template.attachmentBody );
        parcel.ToAddresses.addAll( getToAddresses() );

        EmailFactoryOutbound emailFactory = new EmailFactoryOutbound( new EmailParcel[]{parcel} );
        emailFactory.build();

        EmailPost emailPost = new EmailPost( emailFactory );
        emailPost.post();
    }

/**
 * UTILITY METHODS
 */

    private String[] getToAddresses(){
        String[] toAddresses = new String[]{};

        for( OLS_Bounce_Report_Email_Address__mdt record : OLS_Bounce_Report_Email_Address__mdt.getAll().values() ){
            toAddresses.add(record.Email__c);
        }

        return toAddresses;
    }

/**
 * CLASSES
 */

    global class CustomEmailTemplate {

        global String subject = 'Online Store Customer Bounce Report';
        private String body = 'Here is the bounce report for all Online Strore Customers who failed to received a brochure via email.';

        global String filename {get;set;}
        global Blob attachmentBody {get;set;}

        global Contact[] customers {get;set;}

        global CustomEmailTemplate( Contact[] customersForTemplate ){
            this.customers = customersForTemplate;

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
            mailingAddress += customer.MailingCity + ' ';
            mailingAddress += customer.MailingState + ' ';
            mailingAddress += customer.MailingPostalCode;
    
            return mailingAddress;
        }
    }
}
