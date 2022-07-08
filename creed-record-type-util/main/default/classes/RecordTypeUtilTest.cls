@IsTest
public class RecordTypeUtilTest {
    
    @IsTest
    public static void testRecordTypeUtil(){
        RecordTypeUtil recordTypeUtil = new RecordTypeUtil( new Account() );

        Id masterAccountRecordTypeId = Schema.Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('Master').getRecordTypeId();

        System.assertEquals( masterAccountRecordTypeId, recordTypeUtil.getRecordTypeId('Master') );
        System.assertEquals( 1, recordTypeUtil.getAllRecordTypeIds().size() );

        System.assertEquals( 'Master', recordTypeUtil.getRecordTypeName(masterAccountRecordTypeId) );
        System.assertEquals( 1, recordTypeUtil.getAllRecordTypeNames().size() );
    }
}
