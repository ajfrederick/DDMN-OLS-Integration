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
     * is also later then today's date.
     * @param EmailParcel parcel
     * @return void
    **/
    private void addAttachmentToParcel( Contact obj, EmailParcel parcel ){

        try {

            if( String.isBlank( obj.Brochure_Key__c ) ){
                throw new AttachmentException('OLS Contact did not come with a Brochure Key');
            } else
            if( !attachmentsByName.containsKey( obj.Brochure_Key__c ) ){
                throw new AttachmentException('Brochure not found for the key provided for OLS Contact');
            }
            
            AttachmentData attachmentToUse;

            for( AttachmentData newAttachment : attachmentsByName.get( obj.Brochure_Key__c ) ){

                if( attachmentToUse == null || isAttachmentToUse( attachmentToUse, newAttachment, obj ) ){
                    attachmentToUse = newAttachment;
                }
            }  
            
            parcel.setAttachment( attachmentToUse.getFileName(), attachmentToUse.getBlobBody() );

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler( e, new SObject[]{obj} );
            handler.handle();
        }
    }

    /**
     * @name checkAttachments
     * @description if the new attachment coverage start date is greater or equal to the contact coverage start date && check if this is the newest possible version
     * @param EmailParcel parcel
     * @return void
    **/
    private Boolean isAttachmentToUse( AttachmentData attachmentToUse, AttachmentData newAttachment, Contact obj ){
        return newAttachment.version.Brochure_Coverage_Start_Date__c >= obj.Coverage_Start_Date__c && newAttachment.version.Brochure_Coverage_Start_Date__c >= attachmentToUse.version.Brochure_Coverage_Start_Date__c;
    }

    class AttachmentException extends Exception {}
}