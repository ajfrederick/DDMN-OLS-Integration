/**
 * @name RecordTypeUtil
 * @description util to aid in getting record type ids with decent error handling
 */
global without sharing class RecordTypeUtil {

/**
 * FIELDS
 */
    
    private SObject obj {get;set;}

    private Map<String, Id> recordTypeIdsByName = new Map<String, Id>();

    private Map<Id, String> recordTypeNamesById = new Map<Id, String>();

/**
 * CONSTRUCTOR
 */
 
    global RecordTypeUtil( SObject obj ){
        this.obj = obj;

        setRecordTypeIds();
    }

/**
 * ACTION METHODS
 */

    /**
     * @name setRecordTypeIds
     * @description gets the all the possible record types for an SObject then sets the one's we want
     * @param SObject obj
     * @return none
     */
    private void setRecordTypeIds(){
        DescribeSobjectResult describe = obj.getSObjectType().getDescribe();
        
        Map<String, Schema.RecordTypeInfo> recordTypes = describe.getRecordTypeInfosByDeveloperName();

        for( String name : recordTypes.keyset() ){

            recordTypeIdsByName.put( name, recordTypes.get( name ).getRecordTypeId() );

            recordTypeNamesById.put( recordTypes.get( name ).getRecordTypeId(), name );
        }
    }

    /**
     * @name getRecordTypeId
     * @description get RecordTypeId by name
     * @param String name
     * @return Id
     */
    global Id getRecordTypeId( String name ){
        Id recordTypeId;
        
        try {

            recordTypeId = recordTypeIdsByName.containsKey( name ) ? recordTypeIdsByName.get( name ) : null;

            if( recordTypeId == null && !Test.isRunningTest() ){
                throw new RecordTypeException('Record Type ' + name + ' does not exist or the developer is searching for this record type on the wrong Object.');
            }

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }

        return recordTypeId;
    }

    /**
     * @name getRecordTypeId
     * @description gets RecordTypeIds
     * @param none
     * @return Id[]
     */
    global Id[] getAllRecordTypeIds(){
        return recordTypeIdsByName.values();
    }

    /**
     * @name getRecordTypeId
     * @description get RecordTypeId by name
     * @param Id recordTypeId
     * @return String
     */
    global String getRecordTypeName( Id recordTypeId ){
        String recordTypeName;
        
        try {

            recordTypeName = recordTypeNamesById.containsKey( recordTypeId ) ? recordTypeNamesById.get( recordTypeId ) : null;

            if( recordTypeName == null ){
                throw new RecordTypeException('Record Type for Id ' + recordTypeId + ' does not exist or the developer is searching for this record type on the wrong Object.');
            }

        } catch( Exception e ){
            creedint.CreedExceptionHandler handler = new creedint.CreedExceptionHandler(e);
            handler.handle();
        }

        return recordTypeName;
    }

    /**
     * @name getAllRecordTypeNames
     * @description get RecordType DeveloperNames
     * @param none
     * @return String[]
     */
    global String[] getAllRecordTypeNames(){
        return recordTypeNamesById.values();
    }

/**
 * CLASSES
 */

    global class RecordTypeException extends Exception {}
}