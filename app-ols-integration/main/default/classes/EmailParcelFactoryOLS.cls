/**
 * @name EmailParcelFactoryOLS
 * @description Extracts Email from Online Store Customer Object
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
**/
global class EmailParcelFactoryOLS extends EmailParcelFactory {

    private static final String BCC_ADDRESS = System.Label.OLS_Email_Bcc_Address;

/**
 * CONSTRUCTOR
**/

    global EmailParcelFactoryOLS( SObject[] objs ){
        super(objs);
    }

/**
 * ACTION METHODS
**/ 
    
    /**
     * @name build
     * @description creates email parcels from Online Store Customer object
     * @param SObject[] objs
     * @return void
    **/
    global override void build( SObject[] objs ){
        Contact[] customers = (Contact[]) objs;

        for( Contact obj : customers ){
            if( obj.Email == null ){ continue; }
            
            EmailParcel parcel = new EmailParcel();
            
            parcel.bccAddresses.add(BCC_ADDRESS);
            parcel.template = template;
            parcel.oweAddressId = oweAddressId; // from address
            parcel.whoId = obj.Id; // since this is a contact set the whoId to avoid counting against email limits

            addAttachmentToParcel(obj, parcel);

            parcels.add( parcel );
        }
    }

    /**
     * @name addAttachmentsByName
     * @description loops a list of versions and deconstructs it into raw attachment data
     * @param ContentVersion[] versions
     * @return void
    **/
    global override void addAttachmentsByName( ContentVersion[] versions ){

        for( ContentVersion version : versions ){
            addAttachmentByName( version.Brochure_Key__c, version );
        }
    }

    /**
     * @name addAttachmentToParcel
     * @description adds an attachment to parcel. checks the coverage start date and grabs the most recent brochure IF the start date
     * is also later then the OLS Customer new policy start date.
     * @param EmailParcel parcel
     * @return void
    **/
    private void addAttachmentToParcel( Contact obj, EmailParcel parcel ){

        AttachmentData[] attachments;

        try {

            if( String.isBlank( obj.Brochure_Key__c ) ){
                throw new AttachmentException('OLS Contact did not come with a Brochure Key');
            } else
            if( !attachmentsByName.containsKey( obj.Brochure_Key__c ) ){
                throw new AttachmentException('Brochure not found for the brochure key provided for OLS Contact');
            }
            
            attachments = attachmentsByName.get( obj.Brochure_Key__c );
            
            AttachmentData currentAttachment;

            for( AttachmentData newAttachment : attachments ){
                currentAttachment = useNewAttachment( currentAttachment, newAttachment, obj );
            }

            // this is in the case where there was 1 attachment found but start date is null. This hopefully won't ever happen
            // as the start date is required on the page layout now but it's possible. Let's not have it be a show stopper.
            if( currentAttachment == null && attachments.size() == 1 ){
                currentAttachment = attachments[0];
            } else
            // if there was no attachment found because there was 0 files for the key or if there were 2 or more found but every start date was null
            if( currentAttachment == null ){
                throw new AttachmentException('No Brochure PDF found for OLS Contact email attachment. Most likely due to File\'s Brochure Coverage Start Date.');
            } 
            
            parcel.setAttachment( currentAttachment.getFileName(), currentAttachment.getBlobBody() );

        } catch( Exception e ){

            CreedExceptionHandler handler = new CreedExceptionHandler( e, new SObject[]{obj} );

            // if we have possible files for attachments let's send them in the error email.
            if( attachments != null && !attachments.isEmpty() ){

                ContentVersion[] versions = new ContentVersion[]{};

                for( AttachmentData attachment : attachments ){
                    versions.add( attachment.version );
                }

                handler.addMessage('Here are the possible attachments that were found to be used: ' + JSON.serialize(versions));
            }

            handler.handle();
        }
    }

    /**
     * @name useNewAttachment
     * @description if the new attachment coverage start date is greater or equal to the contact coverage start date && check if this is the newest possible version
     * @param EmailParcel parcel
     * @return void
    **/
    private AttachmentData useNewAttachment( AttachmentData currentAttachment, AttachmentData newAttachment, Contact obj ){
        
        // return the current attachment if there is no coverage start date for the new attachment or if it is at a future point 
        // to the new policy start date for the OLS customer
        if( newAttachment.version.Brochure_Coverage_Start_Date__c == null || newAttachment.version.Brochure_Coverage_Start_Date__c > obj.Coverage_Start_Date__c ){ 
            return currentAttachment; 
        }

        // if we made it this far set the current attachment if we don't have it yet OR if we do compare it with a possible new one
        // if the new one is newer than the old one then use the new one.
        if( currentAttachment == null || newAttachment.version.Brochure_Coverage_Start_Date__c > currentAttachment.version.Brochure_Coverage_Start_Date__c ){
            currentAttachment = newAttachment;
        }
        
        return currentAttachment;
    }

    class AttachmentException extends Exception {}
}