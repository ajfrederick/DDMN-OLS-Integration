/**
 * @name TestEmailUtils
 * @description this tests EmailUtils class to cover Exception paths
 */
@isTest(SeeAllData = true)
public class EmailUtilsTest {

    @IsTest
    static void testEmailUtils(){
    
        Integer numberOfEmailsSent = 0;
        
        Test.startTest();

            EmailUtils.getOrgWideEmailAddress('');
            EmailUtils.getTemplate('');

            numberOfEmailsSent = Limits.getEmailInvocations();

        Test.stopTest();
        
        System.assertEquals( 2, numberOfEmailsSent );
    }
}
