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

            if( obj.Brochure_Key__c != null && versionIdsByName.containsKey( obj.Brochure_Key__c ) ){
                String[] versionIds = versionIdsByName.get( obj.Brochure_Key__c );

                parcel.setVersionIds(versionIds);
            }

            parcels.add( parcel );
        }
    }

    /**
     * @name addVersionIdsByName
     * @description loops a list and adds a verion id by a particular key value this is overrideable
     * so that a sub class can name a different key
     * @param ContentVersion[] versions
     * @return void
    **/
    global override void addVersionIdsByName( ContentVersion[] versions ){

        for( ContentVersion version : versions ){
            addVersionIdByName( version, version.Brochure_Key__c );
        }
    }
}