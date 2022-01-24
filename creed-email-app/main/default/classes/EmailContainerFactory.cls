/**
 * @name EmailContainerFactory
 * @description gets proper email info from object for email message. Abstract so you can define
 * the process of getting email addresses for different Objects
**/
global virtual class EmailContainerFactory {

/**
 * FIELDS
**/

    // a list of central, understandable, ubiquitis containers for the whole email application. These get passed around and 
    // loaded up with info and then unpacked
    global EmailContainer[] containers {
        get {
            if( containers == null ) containers = new EmailContainer[]{};
            return containers;
        }
        set;
    }

    // containers can be created from either SObjects or inboundEmails. This is the list of objs.
    global SObject[] objs {
        get {
            if( objs == null ) objs = new SObject[]{};
            return objs;
        }
        set;
    }

    // containers can be created from either SObjects or inboundEmails. This is the list of Inbound Emails.
    global Messaging.InboundEmail[] inboundEmails {
        get {
            if( inboundEmails == null ) inboundEmails = new Messaging.InboundEmail[]{};
            return inboundEmails;
        }
        set;
    }

    // to add ContentVersions (files) to container that are already in the database and will be used to send an attachment
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

    global EmailContainerFactory( SObject[] objs ){
        this.objs = objs;
    }

    global EmailContainerFactory( Messaging.InboundEmail[] inboundEmails ){
        this.inboundEmails = inboundEmails;
    }

/**
 * ACTION METHODS
**/

    /**
     * @name build
     * @description creates email containers from sObjects
     * @param none
     * @return void
    **/
    global void build(){
        build( objs );
        build( inboundEmails );
    }

    /**
     * @name build
     * @description creates email containers from sObjects. This will be extended by sub classes. e.g. if you want a factory
     * for Cases create EmailContainerFactoryCase.cls
     * @param SObject[] objs
     * @return void
    **/
    global virtual void build( SObject[] objs ){

    }

    /**
     * @name build
     * @description creates email containers from InboundEmails
     * @param Messaging.InboundEmail[] emails 
     * @return void
    **/
    global void build( Messaging.InboundEmail[] emails ){

        for( Messaging.InboundEmail email : emails ){
            EmailContainer container = new EmailContainer();

            for( String address : email.ToAddresses ){
                container.toAddresses.add(address);
            }

            if( email.CcAddresses != null ){

                for( String address : email.CcAddresses ){
                    container.ccAddresses.add(address);
                }
            }

            container.FromAddress = email.FromAddress;
            container.FromName = email.FromName;
            
            container.setContent(
                email.Subject, 
                email.HtmlBody, 
                email.PlainTextBody
            );

            if( email.binaryAttachments != null ){
                for( Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments ){
                    container.setAttachment( attachment.filename, attachment.body );
                }
            }

            if( email.textAttachments != null ){
                for( Messaging.InboundEmail.TextAttachment attachment : email.textAttachments ){
                    container.setAttachment( attachment.filename, attachment.body );
                }
            }

            container.whatId = relatedToId;
            container.messageId = email.messageId;
            container.inReplyTo = email.inReplyTo;

            containers.add( container );
        }
    }

    /**
     * @name transorm
     * @description takes containers and adds property values to them if need be
     * @param EmailContainer[] existingContainers
     * @return void
    **/
    global virtual void transorm( EmailContainer[] existingContainers ){

        for( EmailContainer container : existingContainers ){
            container.template = template;
            container.oweAddressId = oweAddressId;
        }
    }

    /**
     * @name getContainers
     * @description returns containers
     * @return EmailContainer[]
    **/
    global EmailContainer[] getContainers(){
        return containers;
    }

/**
 * UTILITY METHODS
**/ 
    
    /**
     * @name hasContainers
     * @description returns true if this class has found email address
     * @return Boolean
    **/
    global Boolean hasContainers(){
        return !containers.isEmpty();
    }

    /**
     * @name setTemplate
     * @description sets Email Template filtered by developerName
     * @param String name
     * @return void
    **/
    global void setTemplate( String name ){
        template = EmailUtils.getTemplate( name );
    }

    /**
     * @name setOrgWideEmailAddressId
     * @description sets Org Wide Email Address for From Address
     * @param String address
    **/
    global void setOrgWideEmailAddressId( String addressName ){
        OrgWideEmailAddress oweAddress = EmailUtils.getOrgWideEmailAddress( addressName );

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
