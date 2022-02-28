/**
 * @name OLSTriggerHook
 * @description handler that is accessed in the EmailApp EmailAppTrigger
 * 
 * Updates a Contact record that is an Online Store Customer to indicate that an email was sent and/or bounced after
 * an email was sent.
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public class OLSTriggerHook implements TriggerHook {

/**
 * CONSTRUCTOR
 */

    public OLSTriggerHook(){

    }
 
/**
 * INTERFACE METHODS
 */

    public void beforeInsert( Map<Id, EmailMessage> newMap ){

    }

    public void beforeUpdate( Map<Id, EmailMessage> oldMap, Map<Id, EmailMessage> newMap ){

    }

    public void beforeDelete( Map<Id, EmailMessage> oldMap, Map<Id, EmailMessage> newMap ){

    }

    public void afterInsert( Map<Id, EmailMessage> newMap ){
        updateCustomer( newMap );
    }

    public void afterUpdate( Map<Id, EmailMessage> oldMap, Map<Id, EmailMessage> newMap ){

    }

    public void afterDelete( Map<Id, EmailMessage> oldMap, Map<Id, EmailMessage> newMap ){

    }

    public void afterUndelete( EmailMessage[] undeletedList ){

    }

/**
 * ACTION METHODS
 */

    /**
     * @name updateCustomers
     * @description updates the online store customers with an email sent if an email was indeed sent
     * @param Map<Id, EmailMessage> newMap 
     * @return none
     */
    private void updateCustomer( Map<Id, EmailMessage> newMap ){
        Set<Id> customerIds = getCustomerIds( newMap.keyset() );
        Contact[] customers = getCustomers( customerIds );

        for( Contact customer : customers ){
            customer.Email_Sent__c = true;
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

    /**
     * @name getCustomers
     * @description gets customer records
     * @param Map<Id, EmailMessage> newMap 
     * @return Contact[]
     */
    private Contact[] getCustomers( Set<Id> customerIds ){
        Contact[] customers = new Contact[]{};

        try {

            Id rtId = OLSUtil.getRecordTypeId('Online_Store_Customer');

            customers.addAll([SELECT
                                Id,
                                Email_Sent__c,
                                EmailBouncedDate
                                    FROM Contact
                                    WHERE Id IN :customerIds
                                    AND RecordTypeId = :rtId]);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.debug();
        }

        return customers;
    }

    /**
     * @name getCustomerIds
     * @description gets the customer IDs by traversing the EmailMessageRelation object
     * @param Set<Id> messageIds
     * @return Set<Id>
     */
    public Set<Id> getCustomerIds( Set<Id> messageIds ){
        Set<Id> customerIds = new Set<Id>();

        EmailMessageRelation[] relations = new EmailMessageRelation[]{};

        try {

            relations.addAll([SELECT
                                Id,
                                RelationId
                                    FROM EmailMessageRelation
                                    WHERE EmailMessageId IN :messageIds]);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.debug();
        }

        for( EmailMessageRelation relation : relations ){
            customerIds.add( relation.RelationId );
        }

        return customerIds;
    } 
}
