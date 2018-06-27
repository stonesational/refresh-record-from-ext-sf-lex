/*------------------------------------------------------------
LC Controller to callout to an external service an update an SObject's fields at runtime
Components Using: detailsRefresher
History
<Date>       <Authors Name>     <Brief Description of Change>
25-Jun-2018  Jason Stone		   POC
------------------------------------------------------------*/
public with sharing class detailRefresher_CC {
    public detailRefresher_CC() {

    }

    /*------------------------------------------------------------
	Update the SObject's real-time fields from the SOR via callout.
    Using dynamic soql so it's a re-usable component.
    TODO: Make updateFields return an sObject instead of Account so it's generic.
    TODO: Currently mocked from a custom metadata type. Will want to replace with a callout
	@param argRecordId SF ID of the record
	@return None or Exception
	------------------------------------------------------------*/
    @AuraEnabled
    public static Account updateFields(String argRecordId){       
       try{
            Map<String,String> fieldMap = mockCallout(argRecordId);
            
            //Exit if there's no fields to update on this SObject
            if (fieldMap.isEmpty()) {
                System.debug('Exiting: No fields to update');    
                return null; 
            }

            //Build the dynamic query
            String query = 'SELECT Id, Last_Field_Refresh__c, Is_Stale__c, ';
            for (String fieldName : fieldMap.keySet()){
                query += fieldName + ', ';
            }
            query = query.substringBeforeLast(',');
            query += '  FROM ' + findObjectNameFromRecordIdPrefix(argRecordId) + 
                     '  WHERE Id = \'' + argRecordId + '\' LIMIT 1'; 
            
            System.debug('Query: '+query);
            
            SObject record = Database.query(query)[0];

            //Exit if there record was updated recently
            if( (Boolean)record.get('Is_Stale__c') == false ) {
                System.debug('Existing: Record is not stale');
                return null; 
            }
            
            //Update records with new values and now as the Last Field Refresh time
            for (String fieldName : fieldMap.keySet()){
                record.put(fieldName, fieldMap.get(fieldName));
            }
            record.put('Last_Field_Refresh__c', System.now());
            update record;
            System.debug('Record Updated');
            
            
            //return (String)record.get('phone');
            return (Account)record;

       } catch(Exception e) {
           System.debug('Error in detailRefresher_CC: '+ e.getMessage());
           throw new AuraHandledException(e.getMessage());
       }
    }


    /*------------------------------------------------------------
	POC to mock the callout to an external system. Querying test metadata for now
	@param argRecordId SF ID of the record
	@return Map of field_name (keys) and new field_value
	------------------------------------------------------------*/
    private static Map<String,String> mockCallout(String argRecordId) {
         Map<String,String> toReturn = new Map<String,String>();
        
        String sObjectName = findObjectNameFromRecordIdPrefix(argRecordId);
        Detail_Refresher_Setting__mdt[] fieldUpdates = [SELECT Field_Name__c, Field_Value__c FROM Detail_Refresher_Setting__mdt WHERE SObject_Type__c = :sObjectName];
        
        for (Detail_Refresher_Setting__mdt field : fieldUpdates) {
            toReturn.put(field.Field_Name__c, field.Field_Value__c);
        }

        return toReturn;

    }

    /*------------------------------------------------------------
	Gets the Object Type from a record ID
	@param recordIdOrPrefix SF ID of the record or just the 3 char prefix
	@return Object Type Name
	------------------------------------------------------------*/
    private static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
             
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                //System.debug('Prefix is ' + prefix);
                 
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }

}
