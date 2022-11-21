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

    private Map<String, Contact[]> customersByTemplateName {
        get {
            if( customersByTemplateName == null ){
                customersByTemplateName = new Map<String, Contact[]>();
            }
            return customersByTemplateName;
        }
        set;
    }

    private Map<String, String> fromAddressesByTemplateName {
        get {
            if( fromAddressesByTemplateName == null ){
                fromAddressesByTemplateName = new Map<String, String>();
            }
            return fromAddressesByTemplateName;
        }
        set;
    }

    // Custom Metadata Type to determine what assets (e.g. Template, Org Wide Address for from adress, etc.) to use in welcom email
    private static Map<String, OLS_Welcome_Email_Setting__mdt> emaialSettingsByState = new Map<String, OLS_Welcome_Email_Setting__mdt>();

    private static String[] products = new String[]{};

    static {

        try {

            OLS_Welcome_Email_Setting__mdt[] emailSettings = OLS_Welcome_Email_Setting__mdt.getAll().values();

            for( OLS_Welcome_Email_Setting__mdt setting : emailSettings ){
                emaialSettingsByState.put( setting.Supplied_State_Acronym__c, setting );
            }

            OLS_Product_Setting__mdt[] productSettings = OLS_Product_Setting__mdt.getAll().values();

            for( OLS_Product_Setting__mdt setting : productSettings ){
                if( setting.isActive__c ){
                    products.add( setting.Product_Name__c );
                }
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

        setCustomersByTemplateName();
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
     * @name setCustomersByTemplateName
     * @description loops through all the settings by state and grabs an customers by state. Puts the customers into an Email App parcel factory then
     * extracts the parcels fromt the factory for emailing.
     * @param none
     * @return none
     */
    private void setCustomersByTemplateName(){

        try{

            for( Contact customer : customers ){

                OLS_Welcome_Email_Setting__mdt setting = emaialSettingsByState.get( customer.State_Acronym__c );

                if( setting == null ){
                    throw new TemplateException( STATE_ACRONYM_ERROR );
                }
    
                String templateName = setting.Email_Template_Name__c;
    
                // if the brochure key contains a product above. let's augment the template name to include the product and we'll name the email templates accordingly

                if( setting.Multiple_Products_Sold__c ){

                    for( String product : products ){
                        if( customer.Brochure_Key__c.containsIgnoreCase( product ) && !String.isBlank(templateName) ){
                            templateName += '_' + product;
                            break;
                        }
                    }
                } 

                if( String.isBlank(templateName) ){
                    throw new TemplateException( 'No template name found for this OLS contact in OLSEmailCore.cls: ' + JSON.serialize(customer) );
                }
                
                fromAddressesByTemplateName.put( templateName, setting.From_Address__c );

                if( customersByTemplateName.containsKey( templateName ) ){
                    customersByTemplateName.get( templateName ).add( customer );
                } else {
                    customersByTemplateName.put( templateName, new Contact[]{ customer } );
                }
            }

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler( e , customers );
            handler.handle();
        }
    }

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

        for( String templateName : customersByTemplateName.keySet() ){

            Contact[] customersToUse = customersByTemplateName.get(templateName);

            EmailParcelFactoryOLS parcelFactory = new EmailParcelFactoryOLS( customersToUse );
            parcelFactory.setTemplate( templateName );
            parcelFactory.setOrgWideEmailAddressId( fromAddressesByTemplateName.get(templateName) );
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
    public class TemplateException extends Exception {}
}
