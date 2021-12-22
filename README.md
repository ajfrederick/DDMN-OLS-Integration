# Online Store Customer Integration

Welcome! This is all the assets for an Unlocked package that exists in DDMN's Salesforce. It was authored by Andrew Frederick in December of 2021.

## What's In Here?

Apex classes for 3 packages two of which fulfill dependencies. The OLS Integration, the Creed Email App and the Creed Exception Handler.

There are also Salesforce metadata entities like custom fields, a record type, a permission set and more.

## Post-Install TODOs:

1) Assign Apex class access to Profile
2) Create or Change Org Wide Email Address and match to custom label Online_Store_Reply_From_Address and Bcc Address
3) Ensure Profile has page layout and record type permissions
4) Ensure the page layout assignment is correct for the record type
5) Take care of field level visibilty on all fields
6) Creat list view for Online Store Customer record type
7) Ensure Brochure Key is on ContentVersion Layout
8) Upload Brochure PDFs for attachments and association Brochure Keys
9) Share files with User "API Integration" User (which is the User who's username DDMN Web Apps is using to make API calls and then subsequently is the User that will "send" the email. So it needs access to the files.)
10) Register Bounce Report Email addresses as Custom Metadata Types