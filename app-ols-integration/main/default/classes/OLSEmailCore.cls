/**
 * @name OLSEmailCore
 * @description this is the core class that generates and sends welcome emails
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public without sharing class OLSEmailCore {

/**
 * FEILDS
 */

    private Contact[] customers {
        get {
            if( customers == null ){
                customers = new Contact[]{};
            }
            return customers;
        }
        set;
    }

    private Map<String, Contact[]> customersByStateAcronym {
        get {
            if( customersByStateAcronym == null ){
                customersByStateAcronym = new Map<String, Contact[]>();
            }
            return customersByStateAcronym;
        }
        set;
    }

    // Custom Metadata Type to determine what assets (e.g. Template, Org Wide Address for from adress, etc.) to use in welcom email
    private static Map<String, OLS_Welcome_Email_Setting__mdt> emailSettingsByState;

    static {

        emailSettingsByState = new Map<String, OLS_Welcome_Email_Setting__mdt>();

        try {

            OLS_Welcome_Email_Setting__mdt[] settings = OLS_Welcome_Email_Setting__mdt.getAll().values();

            for( OLS_Welcome_Email_Setting__mdt setting : settings ){
                emailSettingsByState.put( setting.Supplied_State_Acronym__c, setting );
            }

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }
    }

    private static final String STATE_ACRONYM_ERROR = 'There were OLS customers that were registered but no email sent. Most likely due to state acronym values not matching between WebApps and Salesforce OLS Welcome Email Settings Custom Metadata Type.';

/**
 * CONSTUCTORS
 */

    public OLSEmailCore( Contact[] customers ){
        this.customers = customers;

        for( Contact customer : customers ){

            if( customersByStateAcronym.containsKey( customer.State_Acronym__c ) ){
                customersByStateAcronym.get( customer.State_Acronym__c ).add( customer );
            } else {
                customersByStateAcronym.put( customer.State_Acronym__c, new Contact[]{ customer } );
            }
        }
    }

/**
 * ACTION METHODS
 */

    /**
     * @name sendEmails
     * @description actually sends the emails using the Creed Email App
     * @param none
     * @return none
     */
    public void sendEmails(){
        if( customers.isEmpty() ){ return; }

        try {

            EmailParcel[] parcels = getParcels();

            if( parcels.isEmpty() ){
                throw new StateAcronymException( STATE_ACRONYM_ERROR );
            }
    
            EmailFactoryOutbound emailFactory = new EmailFactoryOutbound( parcels );
            emailFactory.build();
    
            EmailPost emailPost = new EmailPost( emailFactory );
            emailPost.addTriggerHook( new OLSTriggerHook() );
            emailPost.post();

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler( e , customers );
            handler.handle();
        }
    }

/**
 * UTILITY METHODS
 */

    /**
     * @name getParcels
     * @description loops through all the settings by state and grabs an customers by state. Puts the customers into an Email App parcel factory then
     * extracts the parcels fromt the factory for emailing.
     * @param none
     * @return EmailParcel[] parcels
     */
    private EmailParcel[] getParcels(){

        ContentVersion[] versions = getContentVersions();

        EmailParcel[] parcels = new EmailParcel[]{};

        for( String stateAcronym : emailSettingsByState.keySet() ){

            // if we don't have any customers for a state set in settings then move on!
            if( !customersByStateAcronym.containsKey(stateAcronym) ){ continue; }

            OLS_Welcome_Email_Setting__mdt setting = emailSettingsByState.get(stateAcronym);

            Contact[] customersToUse = customersByStateAcronym.get(stateAcronym);

            EmailParcelFactoryOLS parcelFactory = new EmailParcelFactoryOLS( customersToUse );
            parcelFactory.setTemplate( setting.Email_Template_Name__c );
            parcelFactory.setOrgWideEmailAddressId( setting.From_Address__c );
            parcelFactory.addAttachmentsByName( versions );
            parcelFactory.build();

            parcels.addAll( parcelFactory.getParcels() );
        }

        return parcels;
    }

/**
 * QUERY METHODS
 */

    /**
     * @name getContentVersions
     * @description gets Brochure PDFs for email's attachment
     * @param none
     * @return ContentVersion[] versions
     */
    private ContentVersion[] getContentVersions(){
        ContentVersion[] versions = new ContentVersion[]{};

        String[] brochureKeys = new String[]{};

        for( Contact customer : customers ){

            if( !String.isBlank( customer.Brochure_Key__c ) ){
                brochureKeys.add( customer.Brochure_Key__c );
            }
        }

        try {

            if( brochureKeys.isEmpty() ){
                throw new BrochureKeyException('No brochure keys associated with these customer records.');
            }

            versions.addAll([SELECT
                Id,
                Title,
                PathOnClient,
                VersionData,
                Brochure_Key__c,
                Brochure_Coverage_Start_Date__c
                    FROM ContentVersion
                    WHERE Brochure_Key__c IN :brochureKeys
                    AND Brochure_Inactive__c = false]);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e, customers);
            handler.handle();
        }

        return versions;
    }

/**
 * CLASSES
 */

    public class BrochureKeyException extends Exception {}
    public class StateAcronymException extends Exception {}
}
