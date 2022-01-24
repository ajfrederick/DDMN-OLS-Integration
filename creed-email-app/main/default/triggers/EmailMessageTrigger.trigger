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
    for( TriggerHook hook : EmailMessageHelper.hooks ){

        if( Trigger.isBefore ){
            if( Trigger.isInsert ){
                hook.beforeInsert( Trigger.newMap );
            } else 
            if( Trigger.isUpdate ){
                hook.beforeUpdate( Trigger.oldMap, Trigger.newMap );
            } else 
            if( Trigger.isDelete ){
                hook.beforeDelete( Trigger.oldMap, Trigger.newMap );
            }
        } else 
        if( Trigger.isAfter ){
            if( Trigger.isInsert ){ 
                hook.afterInsert( Trigger.newMap );
            } else 
            if( Trigger.isUpdate ){
                hook.afterUpdate( Trigger.oldMap, Trigger.newMap );
            } else 
            if( Trigger.isDelete ){
                hook.afterDelete( Trigger.oldMap, Trigger.newMap );
            } else 
            if( Trigger.isUndelete ){
                hook.afterUndelete( Trigger.new );
            }
        }
    }

    if( Trigger.isAfter ) EmailMessageHelper.hooks.clear();
}