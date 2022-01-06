/**
 * @name OLSTrigger
 * @description Trigger for Contact object for Online Store Integration
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
trigger OLSTrigger on Contact (
    after insert,
    after update
){
    if( Trigger.isAfter ){
        if( Trigger.isInsert ){
            OLSTriggerHelper.afterInsert( Trigger.new );
        } 
        else
        if( Trigger.isUpdate ){
            OLSTriggerHelper.afterUpdate( Trigger.new );
        } 
    }
}