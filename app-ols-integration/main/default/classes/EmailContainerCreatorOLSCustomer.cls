/**
 * @name EmailContainerCreatorOLSCustomer
 * @description Extracts Email from Online Store Customer Object
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
**/
public class EmailContainerCreatorOLSCustomer extends EmailContainerCreator {

/**
 * CONSTRUCTOR
**/

    public EmailContainerCreatorOLSCustomer(){

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
    public override void create( SObject[] objs ){
        Contact[] customers = (Contact[]) objs;

        for( Contact obj : customers ){
            if( obj.Email == null ) continue;
            
            EmailContainer container = new EmailContainer();
    
            container.ToAddresses.add(obj.Email);
            container.whoId = obj.Id; // since this is a contact set the whoId
            container.template = template;

            if( versionIdsByTitle.containsKey( obj.Brochure_Key__c ) ){
                String[] versionIds = versionIdsByTitle.get( obj.Brochure_Key__c );

                container.setVersionIds(versionIds);
            }

            containers.add( container );
        }
    }
}