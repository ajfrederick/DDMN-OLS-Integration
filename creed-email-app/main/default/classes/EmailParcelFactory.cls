/**
 * @name EmailParcelFactory
 * @description gets proper email info from object for email message. Abstract so you can define
 * the process of getting email addresses for different Objects
**/
global virtual class EmailParcelFactory {

/**
 * FIELDS
**/

    // a list of central, understandable, ubiquitis parcels for the whole email application. These get passed around and 
    // loaded up with info and then unpacked
    global EmailParcel[] parcels {
        get {
            if( parcels == null ) parcels = new EmailParcel[]{};
            return parcels;
        }
        set;
    }

    // parcels can be created from either SObjects or inboundEmails. This is the list of objs.
    global SObject[] objs {
        get {
            if( objs == null ) objs = new SObject[]{};
            return objs;
        }
        set;
    }

    // parcels can be created from either SObjects or inboundEmails. This is the list of Inbound Emails.
    global Messaging.InboundEmail[] inboundEmails {
        get {
            if( inboundEmails == null ) inboundEmails = new Messaging.InboundEmail[]{};
            return inboundEmails;
        }
        set;
    }

    // to add ContentVersions (files) to parcel that are already in the database and will be used to send an attachment
    // keyed on an explicitly named value passed into the method below
    global Map<String, String[]> versionIdsByName {
        get {
            if( versionIdsByName == null ) versionIdsByName = new Map<String, String[]>();
            return versionIdsByName;
        }
        set;
    }

    global EmailTemplate template {get;set;}

    global Id oweAddressId {get;set;}

    global Id relatedToId {get;set;}
    
/**
 * CONSTRUCTOR
**/

    global EmailParcelFactory( SObject[] objs ){
        this.objs = objs;
    }

    global EmailParcelFactory( Messaging.InboundEmail[] inboundEmails ){
        this.inboundEmails = inboundEmails;
    }

/**
 * ACTION METHODS
**/

    /**
     * @name build
     * @description creates email parcels from sObjects
     * @param none
     * @return void
    **/
    global void build(){
        build( objs );
        build( inboundEmails );
    }

    /**
     * @name build
     * @description creates email parcels from sObjects. This will be extended by sub classes. e.g. if you want a factory
     * for Cases create EmailParcelFactoryCase.cls
     * @param SObject[] objs
     * @return void
    **/
    global virtual void build( SObject[] objs ){

    }

    /**
     * @name build
     * @description creates email parcels from InboundEmails
     * @param Messaging.InboundEmail[] emails 
     * @return void
    **/
    global void build( Messaging.InboundEmail[] emails ){

        for( Messaging.InboundEmail email : emails ){
            EmailParcel parcel = new EmailParcel();

            for( String address : email.ToAddresses ){
                parcel.toAddresses.add(address);
            }

            if( email.CcAddresses != null ){

                for( String address : email.CcAddresses ){
                    parcel.ccAddresses.add(address);
                }
            }

            parcel.FromAddress = email.FromAddress;
            parcel.FromName = email.FromName;
            
            parcel.setContent(
                email.Subject, 
                email.HtmlBody, 
                email.PlainTextBody
            );

            if( email.binaryAttachments != null ){
                for( Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments ){
                    parcel.setAttachment( attachment.filename, attachment.body );
                }
            }

            if( email.textAttachments != null ){
                for( Messaging.InboundEmail.TextAttachment attachment : email.textAttachments ){
                    parcel.setAttachment( attachment.filename, attachment.body );
                }
            }

            parcel.whatId = relatedToId;
            parcel.messageId = email.messageId;
            parcel.inReplyTo = email.inReplyTo;

            parcels.add( parcel );
        }
    }

    /**
     * @name transorm
     * @description takes parcels and adds property values to them if need be
     * @param EmailParcel[] existingpParcels
     * @return void
    **/
    global virtual void transorm( EmailParcel[] existingpParcels ){

        for( EmailParcel parcel : existingpParcels ){
            parcel.template = template;
            parcel.oweAddressId = oweAddressId;
        }
    }

    /**
     * @name getParcels
     * @description returns parcels
     * @return EmailParcel[]
    **/
    global EmailParcel[] getParcels(){
        return parcels;
    }

/**
 * UTILITY METHODS
**/ 
    
    /**
     * @name hasParcels
     * @description returns true if this class has found email address
     * @return Boolean
    **/
    global Boolean hasParcels(){
        return !parcels.isEmpty();
    }

    /**
     * @name setTemplate
     * @description sets Email Template filtered by developerName
     * @param String name
     * @return void
    **/
    global void setTemplate( String name ){
        template = EmailAppUtil.getTemplate( name );
    }

    /**
     * @name setOrgWideEmailAddressId
     * @description sets Org Wide Email Address for From Address
     * @param String address
    **/
    global void setOrgWideEmailAddressId( String addressName ){
        OrgWideEmailAddress oweAddress = EmailAppUtil.getOrgWideEmailAddress( addressName );

        if( oweAddress != null ){
            oweAddressId = oweAddress.Id;
        }
    }

    /**
     * @name addVersionIdByName
     * @description adds a verion id by a particular key value
     * @param ContentVersion version
     * @return void
    **/
    global void addVersionIdByName( ContentVersion version, String key ){

        if( versionIdsByName.containsKey(key) ){
            versionIdsByName.get(key).add(version.Id);
        } else {
            versionIdsByName.put(key, new String[]{version.Id});
        }
    }

    /**
     * @name addVersionIdsByName
     * @description loops a list and adds a verion id by a particular key value this is overrideable
     * so that a sub class can name a different key
     * @param ContentVersion[] versions
     * @return void
    **/
    global virtual void addVersionIdsByName( ContentVersion[] versions ){

        for( ContentVersion version : versions ){
            addVersionIdByName( version, version.Title );
        }
    }
}
