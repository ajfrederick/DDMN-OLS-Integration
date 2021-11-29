trigger EmailMessageTrigger on EmailMessage ( 
    before insert, 
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    
    // trigger functionality for inside the email application
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
            EmailMessageHelper.updateContentDocumentLinks(Trigger.new);
            EmailMessageRelationHelper.updateRelationIds(Trigger.new);
        } else 
        if( Trigger.isUpdate ){

        } else
        if( Trigger.isDelete ){

        } else 
        if( Trigger.isUndelete ){

        }  
    }
    
    // this is so someone can add trigger functionality oustide the email app
    for( EmailMessageTriggerHandler handler : EmailMessageHelper.handlers ){

        if( Trigger.isBefore ){
            if( Trigger.isInsert ){
                handler.beforeInsert( Trigger.newMap );
            } else 
            if( Trigger.isUpdate ){
                handler.beforeUpdate( Trigger.oldMap, Trigger.newMap );
            } else 
            if( Trigger.isDelete ){
                handler.beforeDelete( Trigger.oldMap, Trigger.newMap );
            }
        } else 
        if( Trigger.isAfter ){
            if( Trigger.isInsert ){ 
                handler.afterInsert( Trigger.newMap );
            } else 
            if( Trigger.isUpdate ){
                handler.afterUpdate( Trigger.oldMap, Trigger.newMap );
            } else 
            if( Trigger.isDelete ){
                handler.afterDelete( Trigger.oldMap, Trigger.newMap );
            } else 
            if( Trigger.isUndelete ){
                handler.afterUndelete( Trigger.new );
            }
        }
    }

    if( Trigger.isAfter ) EmailMessageHelper.handlers.clear();
}