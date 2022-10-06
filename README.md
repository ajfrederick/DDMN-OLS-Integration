# Online Store Customer Integration

Welcome! This is all the assets for an Unlocked package called "DDMN Online Store Integration" that exists in DDMN's Salesforce. It was authored by Andrew Frederick in December of 2021.

## What's In Here?

Salesforce entities (fields, objects, classes, etc.) for the "DDMN Online Store Integration" package as will as the "Creed Email App" and the "Creed Exception Handler" packages.

## Post-Install TODOs:

1) Install any of these package dependencies that are not installed... Creed Email App, Creed Exception Handler, Creed Http Handler, Record Type Handler.
2) Assign Apex class access to Profile <br />
3) Create or Change anny Org Wide Email Address to match to custom Metadata "Welcome Email Setting" Online_Store_Reply_From_Address and Custom Label "OLS Emal Bcc Address" <br />
4) Ensure Profile has page layout and record type permissions <br />
5) Ensure the page layout assignment is correct for the record type <br />
6) Take care of field level visibilty on all fields <br />
7) Creat list view for Online Store Customer record type <br />
8) Upload Brochure PDFs for attachments and associated Brochure Key, Brochure Coverage Start Date <br />
9) Share files with User "API Integration" User (which is the User who's username DDMN Web Apps is using to make API calls and then subsequently is the User that will "send" the email. So it needs access to the files.) <br />
10) Register Bounce Report Email addresses as Custom Metadata Types <br />