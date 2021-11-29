#! /bin/bash

# if there is an arg then use that as perm set name

if [ -z $1 ]
then
  sfdx force:user:permset:assign --permsetname Online_Store_Customer_Integration
else
  sfdx force:user:permset:assign --permsetname $1
fi