/**
 * @name TestEmailMessaging
 * @description this tests the application as a whole as a 'User'
 * TODO: Write unit tests
 */
@IsTest(SeeAllData = true)
public class TestEmailMessaging {
    
    @IsTest
    static void testOutboundEmail(){
        Contact contact = new Contact(
            FirstName = 'New',
            LastName = 'Contact',
            Email = 'me@test.com'
        );

        insert contact;

        Case c = new Case(
            ContactId = contact.Id
        );

        insert c;

        EmailContainer container = new EmailContainer();

        container.whatId = c.Id;
        container.ToAddresses = new String[]{'me@test.com'};
        container.CcAddresses = new String[]{'me2@test.com'};
        container.BccAddresses = new String[]{'me3@test.com'};
        container.FromAddress = 'you@test.com';
        container.setContent( 'Subject', 'HTMLBody', 'PlainTextBody' );
        container.setAttachment( 'Attachment.txt', Blob.valueOf('Attachment') );
        container.whoId = contact.Id;

        System.assertEquals(3, container.allAddresses.size());

        EmailContainer[] containers = new EmailContainer[]{container};

        // insert our attachments since we have before we set messages so SingleEmailMessage can access the ContentVersionIds
        AttachmentCreatorOutbound attachmentCreator = new AttachmentCreatorOutbound( containers );
        attachmentCreator.insertAttachments();

        // instatiate a message creator, set option, set contentversionids for attatchments and 
        // set messages which unpacks container info into Messaging.SingleEmailMessage
        MessageCreatorOutbound messageCreator = new MessageCreatorOutbound( containers );
        messageCreator.create();

        // since the EmailMessage gets created asyncronously after sending the SingleMessage
        // let's store the object in a static variable to access when the EmailMessage trigger gets
        // fired on insert. There we will do the work of creating the necessary ContentDocumentLinks
        // to link the attachment to the EmailMessage. There this variable will get set to null afterward.
        EmailMessageHelper.attachmentCreatorForTrigger = attachmentCreator;

        
        Integer numberOfEmailsSent = 0;

        Test.startTest();

            // send the emails
            MessageHandler handler = new MessageHandler( messageCreator );
            handler.handle();

            numberOfEmailsSent = Limits.getEmailInvocations();
            
        Test.stopTest();

        System.assertEquals( 1, numberOfEmailsSent );

        // asserts on outbound results
        OutboundEmailResults outboundResults = handler.getOutboundEmailResults();

        System.assertEquals( 1, outboundResults.getSuccesses().size() );
        System.assertEquals( 1, outboundResults.getSuccessesByObjId().size() );

        System.assertEquals( 0, outboundResults.getErrorMessages().size() );

        System.assertEquals( true, outboundResults.hasSuccesses() );
        System.assertEquals( false, outboundResults.hasFailures() );

        System.assertEquals( true, String.isBlank(outboundResults.failedIds) );
    }

    @IsTest
    static void testOutboundEmailWithTemplate(){

        System.runAs( new User( Id = UserInfo.getUserId() ) ){

            EmailTemplate template = new EmailTemplate(
                Name = 'Test Template',
                DeveloperName = 'Test_Template',  
                TemplateType = 'Text',
                Body = 'Body',
                Subject = 'Subject',
                FolderId = UserInfo.getUserId()
            );

            insert template;
        }

        Contact contact = new Contact(
            FirstName = 'New',
            LastName = 'Contact',
            Email = 'me@test.com'
        );

        insert contact;

        Case c = new Case(
            ContactId = contact.Id
        );

        insert c;

        EmailContainer container = new EmailContainer();

        container.whatId = c.Id;
        container.ToAddresses = new String[]{'me@test.com'};
        container.FromAddress = 'you@test.com';
        container.template = EmailMessageUtils.getTemplate('Test_Template');
        container.whoId = contact.Id;
        

        EmailContainer[] containers = new EmailContainer[]{container};

        // insert our attachments since we have before we set messages so SingleEmailMessage can access the ContentVersionIds
        AttachmentCreatorOutbound attachmentCreator = new AttachmentCreatorOutbound( containers );
        attachmentCreator.useFirstAttachmentsForAllMessages = true; // let's use this opportunity to test this feature.
        attachmentCreator.insertAttachments();

        // instatiate a message creator, set option, set contentversionids for attatchments and 
        // set messages which unpacks container info into Messaging.SingleEmailMessage
        MessageCreatorOutbound messageCreator = new MessageCreatorOutbound( containers );
        messageCreator.create();

        // since the EmailMessage gets created asyncronously after sending the SingleMessage
        // let's store the object in a static variable to access when the EmailMessage trigger gets
        // fired on insert. There we will do the work of creating the necessary ContentDocumentLinks
        // to link the attachment to the EmailMessage. There this variable will get set to null afterward.
        EmailMessageHelper.attachmentCreatorForTrigger = attachmentCreator;
        
        Integer numberOfEmailsSent = 0;

        Test.startTest();

            // send the emails
            MessageHandler handler = new MessageHandler( messageCreator );
            handler.handle();

            numberOfEmailsSent = Limits.getEmailInvocations();
            
        Test.stopTest();

        System.assertEquals( 1, numberOfEmailsSent );
    }

    @IsTest
    static void testInboundEmail(){
        Case c = new Case();

        insert c;
        
        // Create new inbound email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@from.com';
        email.ToAddresses  = new String[]{'test@to.com'};
        email.subject = 'Subject';
        email.HtmlBody = 'Body';
        email.PlainTextBody = 'Body';
        email.messageId = 'messageId';

        // Create an attachment for the email
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = Blob.valueOf('Attachment');
        attachment.filename = 'attachment.txt';

        // Set the attachement on the email
        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[]{attachment};


        EmailContainerCreator containerCreator = new EmailContainerCreator();
        containerCreator.relatedToId = c.Id;
        containerCreator.create( new Messaging.InboundEmail[]{ email } );

        // instatiate a message creator then set messages
        MessageCreatorInbound messageCreator = new MessageCreatorInbound( containerCreator.getContainers() );
        messageCreator.create();

        // recieve the emails
        MessageHandler handler = new MessageHandler( messageCreator );
        handler.handle();

        // insert our attachments since we have EmailMessage
        AttachmentCreatorInbound attachmentCreator = new AttachmentCreatorInbound(  containerCreator.getContainers() );
        attachmentCreator.insertAttachments();
        attachmentCreator.insertContentDocumentLinks( messageCreator.getInboundMessages() );

        EmailMessage message = [SELECT Id, ParentId FROM EmailMessage][0];

        System.assertEquals( c.Id, message.ParentId );
    }
    
    @IsTest
    static void testContainerCreator(){
        ContentVersion version = new ContentVersion(
            Title = 'Title',
            PathOnClient = 'FileName.txt',
            VersionData = Blob.valueOf('body'),
            ContentLocation = 'S'
        );

        insert version;

        EmailContainerCreator containerCreator = new EmailContainerCreator();
        containerCreator.addVersionId(version);

        System.assertEquals( 1, containerCreator.versionIdsByTitle.get(version.Title).size() );
        System.assertEquals( version.Id, containerCreator.versionIdsByTitle.get(version.Title)[0] );
        System.assertEquals( false, containerCreator.hasContainers() );
        System.assertEquals( 0, containerCreator.getContainers().size() );
    }

    @IsTest
    static void testUtils(){
        String csvContentType = EmailMessageUtils.contentTypes.get('csv');

        System.assertEquals('text/csv', csvContentType);
    }

    @IsTest
    static void testTrigger(){
        Case c = new Case();

        insert c;

        TestExternalTriggerHandlers handler = new TestExternalTriggerHandlers();

        // ADD handler to trigger and insert
        EmailMessageHelper.handlers.add( handler );

        EmailMessage message = new EmailMessage(
            ToAddress = 'me@test.com',
            FromAddress = 'you@test.com',
            Subject = 'Subject',
            HtmlBody = 'Body',
            ParentId = c.Id
        );

        insert message;

        System.assertEquals( true, handler.inserted );


        // ADD handler to trigger and update
        EmailMessageHelper.handlers.add( handler );

        message.Subject = 'Subject Update';
        update message;

        System.assertEquals( true, handler.updated );


        // ADD handler to trigger and delete
        EmailMessageHelper.handlers.add( handler );

        delete message;

        System.assertEquals( true, handler.deleted );


        // ADD handler to trigger and undelete
        EmailMessageHelper.handlers.add( handler );

        undelete message;

        System.assertEquals( true, handler.undeleted );
    }

    class TestExternalTriggerHandlers implements EmailMessageTriggerHandler {

        public Boolean inserted {get;set;}
        public Boolean updated {get;set;}
        public Boolean deleted {get;set;}
        public Boolean undeleted {get;set;}

        public void beforeInsert( Map<Id, EmailMessage> newMap ){

        }

        public void beforeUpdate( Map<Id, EmailMessage> oldMap, Map<Id, EmailMessage> newMap ){
            
        }

        public void beforeDelete( Map<Id, EmailMessage> oldMap, Map<Id, EmailMessage> newMap ){
            
        }

        public void afterInsert( Map<Id, EmailMessage> newMap ){
            inserted = true;
        }

        public void afterUpdate( Map<Id, EmailMessage> oldMap, Map<Id, EmailMessage> newMap ){
            updated = true;
        }

        public void afterDelete( Map<Id, EmailMessage> oldMap, Map<Id, EmailMessage> newMap ){
            deleted = true;
        }

        public void afterUndelete( EmailMessage[] undeletedList ){
            undeleted = true;
        }
    }
}