/**
 * @name TestEmailMessageUtils
 * @description this tests EmailMessageUtils class to cover Exception paths
 */
@isTest(SeeAllData = true)
public class EmailMessageUtilsTest {

    @IsTest
    static void testEmailMessageUtils(){
    
        Integer numberOfEmailsSent = 0;
        
        Test.startTest();

            EmailMessageUtils.getOrgWideEmailAddress('');
            EmailMessageUtils.getTemplate('');

            numberOfEmailsSent = Limits.getEmailInvocations();

        Test.stopTest();
        
        System.assertEquals( 2, numberOfEmailsSent );
    }
}
