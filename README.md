# Online Store Customer Integration

Welcome! This is all the assets for an Unlocked package called "DDMN Online Store Integration" that exists in DDMN's Salesforce. It was authored by Andrew Frederick in December of 2021.

## What's In Here?

Salesforce entities (fields, objects, classes, etc.) for the "DDMN Online Store Integration" package as will as the "Creed Email App" and the "Creed Exception Handler" packages.

## Post-Install TODOs:

1) Assign Apex class access to Profile <br />
2) Create or Change Org Wide Email Address and match to custom label Online_Store_Reply_From_Address and Bcc Address <br />
3) Ensure Profile has page layout and record type permissions <br />
4) Ensure the page layout assignment is correct for the record type <br />
5) Take care of field level visibilty on all fields <br />
6) Creat list view for Online Store Customer record type <br />
7) Ensure Brochure Key is on ContentVersion Layout <br />
8) Upload Brochure PDFs for attachments and association Brochure Keys <br />
9) Ensure Brochure Key field is on Contect Version layout <br />
9) Share files with User "API Integration" User (which is the User who's username DDMN Web Apps is using to make API calls and then subsequently is the User that will "send" the email. So it needs access to the files.) <br />
10) Register Bounce Report Email addresses as Custom Metadata Types <br />