/**
 * @name OLSTrigger
 * @description Trigger for Contact object
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
trigger OLSTrigger on Contact (
    //before insert,
    after insert
    //before update,
    //after update,
    //before delete,
    //after delete,
    //after undelete,
){

    if( Trigger.isBefore ){

        if( Trigger.isInsert ){

        } else
        if( Trigger.isUpdate ){

        } else
        if( Trigger.isDelete ){

        }

    } else
    if( Trigger.isAfter ){

        if( Trigger.isInsert ){
            OLSTriggerHelper.afterInsert( Trigger.new );
        } else
        if( Trigger.isUpdate ){

        } else
        if( Trigger.isDelete ){

        } else
        if( Trigger.isUndelete ){

        }
    }
}