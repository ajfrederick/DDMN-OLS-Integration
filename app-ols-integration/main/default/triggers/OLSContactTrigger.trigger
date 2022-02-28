/**
 * @name OLSTrigger
 * @description Trigger for Contact object for Online Store Integration
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
trigger OLSContactTrigger on Contact (
    after insert,
    after update
){
    if( Trigger.isAfter ){
        if( Trigger.isInsert ){
            OLSUtil.afterInsert( Trigger.new );
        } 
        else
        if( Trigger.isUpdate ){
            OLSUtil.afterUpdate( Trigger.new );
        } 
    }
}