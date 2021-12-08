/**
 * @name EmailContainerCreatorOLS
 * @description Extracts Email from Online Store Customer Object
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
**/
global class EmailContainerCreatorOLS extends EmailContainerCreator {

    private static final String bccAddress = System.Label.OLS_Email_Bcc_Address;

/**
 * CONSTRUCTOR
**/

    global EmailContainerCreatorOLS(){

    }

/**
 * ACTION METHODS
**/ 
    
    /**
     * @name create
     * @description creates email containers from Online Store Customer object
     * @param SObject[] objs
     * @return void
    **/
    global override void create( SObject[] objs ){
        Contact[] customers = (Contact[]) objs;

        EmailContainer[] neContainers = new EmailContainer[]{};

        for( Contact obj : customers ){
            if( obj.Email == null ) continue;
            
            EmailContainer container = new EmailContainer();
    
            container.ToAddresses.add(obj.Email);
            container.BccAddresses.add(bccAddress);
            container.whoId = obj.Id; // since this is a contact set the whoId

            // this how we'll manage dynamically setting the Nebraska template
            if( obj.State_Acronym__c != 'DDNE' ){
                container.template = template;
            } else 
            if( obj.State_Acronym__c == 'DDNE' ) {
                neContainers.add( container );
            }

            if( versionIdsByTitle.containsKey( obj.Brochure_Key__c ) ){
                String[] versionIds = versionIdsByTitle.get( obj.Brochure_Key__c );

                container.setVersionIds(versionIds);
            }

            containers.add( container );
        }

        if( !neContainers.isEmpty() ){
            
            setTemplate('Online_Store_Customer_Welcome_NE');

            for( EmailContainer container : neContainers ){
                container.template = template;
            }
        }
    }

    /**
     * @name addVersionId
     * @description adds a verion id by it's name
     * @param ContentVersion version
     * @return void
    **/
    global override void addVersionId( ContentVersion version ){
        String key = version.Brochure_Key__c;

        if( versionIdsByTitle.containsKey(key) ){
            versionIdsByTitle.get(key).add(version.Id);
        } else {
            versionIdsByTitle.put(key, new String[]{version.Id});
        }
    }
}