/**
 * @name EmailParcelFactoryOLS
 * @description Extracts Email from Online Store Customer Object
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
**/
global class EmailParcelFactoryOLS extends EmailParcelFactory {

    private static final String bccAddress = System.Label.OLS_Email_Bcc_Address;

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
            
            parcel.BccAddresses.add(bccAddress);
            parcel.template = template;
            parcel.oweAddressId = oweAddressId; // from address
            parcel.whoId = obj.Id; // since this is a contact set the whoId

            if( (!String.isBlank( obj.Brochure_Key__c )) && attachmentsByName.containsKey( obj.Brochure_Key__c ) ){
                AttachmentData[] attachments = attachmentsByName.get( obj.Brochure_Key__c );

                for( AttachmentData attachment : attachments ){
                    parcel.setAttachment( attachment.filename, attachment.blobBody );
                }                
            }

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
            addAttachmentByName( version.PathOnClient, version.VersionData, version.Brochure_Key__c );
        }
    }
}