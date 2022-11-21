/**
 * @name OLSUtil
 * @description helper for OnlineStoreCustomerTrigger.trigger and throughout the application
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public without sharing class OLSUtil {

/**
 * FIELDS
 */

    // OLS Contact Record Type developerName
    public static final String OLS_CONTACT = 'Online_Store_Customer';

    private static final RecordTypeUtil RECORD_TYPE_UTIL = new RecordTypeUtil( new Contact() );
    
/**
 * TRIGGER METHODS
 */

    /**
     * @name afterInsert
     * @description gets called in trigger after insert
     * @param Contact[] customers
     * @return none
     */
    public static void afterInsert( Contact[] newList ){
        Contact[] customers = sortOnlineStoreCustomers( newList );

        sendEmails( customers );
    }

    /**
     * @name afterUpdate
     * @description gets called in trigger after update
     * @param Contact[] customers
     * @return none
     */
    public static void afterUpdate( Contact[] newList ){
        Contact[] customers = sortOnlineStoreCustomers( newList );

        sendEmails( customers );
    }

/**
 * ACTION METHODS
 */

    /**
     * @name sendEmails
     * @description gets called in trigger after insert handler
     * @param Contact[] customers
     * @return none
     */
    private static void sendEmails( Contact[] customers ){
        if( customers.isEmpty() ){ return; }

        OLSEmailCore emailCore = new OLSEmailCore( customers );
        emailCore.sendEmails();

        OLSCronJobHelper.scheduleBounceBackReportJob();
        OLSCronJobHelper.scheduleBounceEmailValidationJob();
    }

/**
 * UTILITY METHODS
 */

    /**
     * @name sortOnlineStoreCustomers
     * @description sorts out Contacts that are Online Store Customers that have been delivered emails.
     * @param String name
     * @return Id
     */
    private static Contact[] sortOnlineStoreCustomers( Contact[] newList ){
        Contact[] customers = new Contact[]{};

        for( Contact customer : newList ){
            if( isNewSuccessfulOnlineStoreCustomer( customer ) ){
                customers.add( customer );
            }
        }

        return customers;
    }

    /**
     * @name getRecordTypeId
     * @description get RecordTypeId by name
     * @param String name
     * @return Id
     */
    public static Id getRecordTypeId( String name ){
        return RECORD_TYPE_UTIL.getRecordTypeId(name);
    }

    /**
     * @name getOLSRecordTypeId
     * @description get RecordTypeId for OLS Contact record type name
     * @return Id
     */
    public static Id getOLSRecordTypeId(){
        return RECORD_TYPE_UTIL.getRecordTypeId( OLS_CONTACT );
    }


    /**
     * @name isNewSuccessfulOnlineStoreCustomer
     * @description this checks to make sure a contact record is indeed an Online Store Customer.
     * 1) is an online store customer contact record
     * 2) and an email hasn't been sent yet.
     * 3) and that the payment has been successful
     * @param Contact customer 
     * @return Boolean
     */
    public static Boolean isNewSuccessfulOnlineStoreCustomer( Contact customer ){
        return isOnlineStoreCustomer( customer ) && (!customer.Email_Sent__c) && customer.Payment_Successful__c;
    }

    /**
     * @name isOnlineStoreCustomer
     * @description this checks to make sure a contact record is indeed an Online Store Customer.
     * 1) First we want to make sure the RecordType exists
     * 2) we want to make sure that the Contact record has a the Online_Store_Customer RecordTypeId
     * @param Contact customer 
     * @return Boolean
     */
    public static Boolean isOnlineStoreCustomer( Contact customer ){
        Id olsContact = getOLSRecordTypeId();

        return olsContact != null && customer.RecordTypeId == olsContact;
    }

    /**
     * @name getThreeMinutesFromNow
     * @description a cron expression for 3 minutes from now. For Testing purposes.
     * @return String
     */
    public static String getThreeMinutesFromNow(){
        DateTime now = DateTime.now();

        Integer threeMinutesFromNow = now.minute() + 3;
        Integer hour = now.hour();

        if( threeMinutesFromNow >= 60 ){
            threeMinutesFromNow = threeMinutesFromNow - 60;
            hour = hour + 1;
        }

        String ret = now.second() + ' ';
        ret += threeMinutesFromNow + ' ';
        ret += hour + ' ';
        ret += now.day() + ' ';
        ret += now.month() + ' ';
        ret += '?';

        return ret;
    }

    /**
     * @name getMinutesFromNow
     * @description a cron expression which adds a certain number of minutes from now to the expression.
     * @param Integer minutesToAdd
     * @return String
     */
    public static String getMinutesFromNow( Integer minutesToAdd ){
        DateTime now = DateTime.now();

        Integer minutesFromNow = now.minute() + minutesToAdd;
        Integer hour = now.hour();

        // to manage if input is greater than an hour
        if( minutesFromNow >= 60 ){
            Integer additionalHours = Math.round( minutesFromNow/60 );

            minutesFromNow = minutesFromNow - (60 * additionalHours);

            hour = hour + additionalHours;
        }

        String ret = now.second() + ' ';
        ret += minutesFromNow + ' ';
        ret += hour + ' ';
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
