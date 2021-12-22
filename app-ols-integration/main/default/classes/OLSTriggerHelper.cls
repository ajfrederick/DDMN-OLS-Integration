/**
 * @name OLSTriggerHelper
 * @description helper for OnlineStoreCustomerTrigger.trigger and throughout the application
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public class OLSTriggerHelper {

/**
 * FIELDS
 */

    private static final String fromAddress = System.Label.OLS_Email_From_Address;

    // A list of record type developer/api names that we will use to get the recordType Ids to use below
    private static final String[] RecordTypeNames = new String[]{
        'Online_Store_Customer'
    };
    
    private static Map<String, Id> RecordTypeIdsByName = new Map<String, Id>();

    /**
     * This static block is to ensure there are no problems constructing the class when accessing the Schema describe and the 
     * getRecordTypeInfosByDeveloperName. If the record type was deleted or the name was changed then you will
     * incur an 'attempt to de-referece a null object error'.
     */
    static {
        DescribeSobjectResult describe = Contact.SObjectType.getDescribe();
        
        Map<String, Schema.RecordTypeInfo> recordTypes = describe.getRecordTypeInfosByDeveloperName();

        for( String name : RecordTypeNames ){

            if( recordTypes.containsKey( name ) ){
                RecordTypeIdsByName.put( name, recordTypes.get( name ).getRecordTypeId() );
            } else {
                RecordTypeIdsByName.put( name, null ); // this will only happen if the record type was deleted or the name was changed for the list above
            }
        }
    }
    
/**
 * TRIGGER METHODS
 */

    /**
     * @name beforeInsert
     * @description gets called in trigger before insert
     * @param Contact[] customers
     * @return none
     */
    public static void afterInsert( Contact[] newList ){
        Contact[] customers = sortOnlineStoreCustomers( newList );

        sendEmails( customers );
    }

/**
 * ACTION METHODS
 */

    /**
     * @name sendEmails
     * @description gets called in trigger after insert handles
     * @param Contact[] customers
     * @return none
     */
    public static void sendEmails( Contact[] customers ){
        ContentVersion[] versions = getContentVersions(customers);

        EmailContainerCreatorOLS containerCreator = new EmailContainerCreatorOLS();
        containerCreator.setTemplate('Online_Store_Customer_Welcome');
        
        for( ContentVersion version : versions ){
            containerCreator.addVersionId( version );
        }

        containerCreator.create(customers);

        MessageCreatorOutbound messageCreator = new MessageCreatorOutbound( containerCreator.getContainers() );
        messageCreator.setOrgWideEmailAddressId(fromAddress);
        messageCreator.create();

        // this get fired in the email app EmailMessageTrigger
        EmailMessageHelper.handlers.add( new OLSEmailMessageTriggerHandler() );

        MessageHandler handler = new MessageHandler( messageCreator );
        handler.handle();

        scheduleJob();
    }

/**
 * UTILITY METHODS
 */

    /**
     * @name sendEmails
     * @description gets Brochure PDFs for email's attachment
     * @param Contact[] customers
     * @return none
     */
    private static ContentVersion[] getContentVersions( Contact[] customers ){
        ContentVersion[] versions = new ContentVersion[]{};

        String[] brochureKeys = new String[]{};

        for( Contact customer : customers ){
            brochureKeys.add( customer.Brochure_Key__c );
        }

        try {

            versions.addAll([SELECT
                Id,
                Title,
                VersionData,
                Brochure_Key__c
                    FROM ContentVersion
                    WHERE Brochure_Key__c IN :brochureKeys]);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }

        return versions;
    }

    /**
     * @name sortOnlineStoreCustomers
     * @description sorts out Contacts that are Online Store Customers that have been delivered emails.
     * @param String name
     * @return Id
     */
    private static Contact[] sortOnlineStoreCustomers( Contact[] newList ){
        Contact[] customers = new Contact[]{};

        for( Contact customer : newList ){
            if( isNewOnlineStoreCustomer( customer ) ){
                customers.add( customer );
            }
        }

        return customers;
    }

    /**
     * @name scheduleJob
     * @description schedules the job to email bounce reports to selected individuals if there isn't one already.
     * @param none
     * @return none
     */
    private static void scheduleJob(){
        String cronJobName = 'Online Store Customer Bounce Report';

        CronJobDetail job;

        try {

            job = [SELECT
                    Id,
                    Name
                        FROM CronJobDetail
                        WHERE Name = :cronJobName
                        LIMIT 1];

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.debug();
        }

        if( job != null ) return;

        OLSBounceReportSchedulable schedulable = new OLSBounceReportSchedulable();

        // job for every Monday at 6am
        String everyWeek = '0 0 6 ? * MON';

        // FOR TESTING: job for every Day at 6am
        String everyDay = '0 0 6 * * ?';

        // FOR TESTING: job for 3 minutes from now
        String threeMinutesFromNow = getThreeMinutesFromNow();

        System.schedule(cronJobName, everyWeek, schedulable);
    }

    /**
     * @name getRecordTypeId
     * @description get RecordTypeId by name
     * @param String name
     * @return Id
     */
    public static Id getRecordTypeId( String name ){
        Id recordTypeId;
        
        try {

            recordTypeId = RecordTypeIdsByName.get( name );

            if( recordTypeId == null ){
                throw new RecordTypeException('Record Type ' + name + ' for Contacts does not exist. Or the developer is searching for this record type on the wrong Object.');
            }

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }

        return recordTypeId;
    }

    /**
     * @name isNewOnlineStoreCustomer
     * @description this checks to make sure a contact record is indeed an Online Store Customer.
     * 1) is an online store customer contact record
     * 2) and an email hasn't been sent yet.
     * @param Contact customer 
     * @return Boolean
     */
    public static Boolean isNewOnlineStoreCustomer( Contact customer ){
        return isOnlineStoreCustomer( customer ) && !customer.Email_Sent__c;
    }

    /**
     * @name isNewOnlineStoreCustomer
     * @description this checks to make sure a contact record is indeed an Online Store Customer.
     * 1) First we want to make sure the RecordType exists
     * 2) we want to make sure that the Contact record has a the Online_Store_Customer RecordTypeId
     * @param Contact customer 
     * @return Boolean
     */
    public static Boolean isOnlineStoreCustomer( Contact customer ){
        return getRecordTypeId('Online_Store_Customer') != null && customer.RecordTypeId == getRecordTypeId('Online_Store_Customer');
    }

    /**
     * @name getThreeMinutesFromNow
     * @description a cron expression fro 3 minutes from now. For Testing purposes.
     * @return String
     */
    public static String getThreeMinutesFromNow(){
        DateTime now = DateTime.now();

        Integer threeMinutesFromNow = now.minute() + 3;

        String ret = now.second() + ' ';
        ret += threeMinutesFromNow + ' ';
        ret += now.hour() + ' ';
        ret += now.day() + ' ';
        ret += now.month() + ' ';
        ret += '?';

        return ret;
    }

/**
 * CLASSES
 */

    public class RecordTypeException extends Exception {}
}
