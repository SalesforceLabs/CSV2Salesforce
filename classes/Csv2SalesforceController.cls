/**
 * @description       : 
 * @author            : Jonathan Fox
 * @group             : 
 * @last modified on  : 22-07-2021
 * @last modified by  : Jonathan Fox
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   21-06-2021   Jonathan Fox   Initial Version
**/
public with sharing class Csv2SalesforceController{
    public class CSVParserException extends Exception{}
    
    @AuraEnabled
    public static void saveFile(String base64Data, String sObjectTypeString) {
        
        /* Call global describe to get the map of string to token. */
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
    
        /* Get the token for the sobject based on the type. */
        Schema.SObjectType schemaSObjectType = globalDescribeMap.get(sObjectTypeString);

        /* Instantiate a List of the type  of sobject from the token. */
        String listType = 'List<' + schemaSObjectType + '>';
        List<SObject> listOfRecordstoInsert = (List<SObject>)Type.forName(listType).newInstance();

        /* Deserialise the data from CSV (from LWC). */
        String data = JSON.deserializeUntyped(base64Data).toString();
        
        List<String> listCSVLines = data.split('\r\n');
        
        // split the first list element [0] by , for column headers - THEY MUST BE IN API NAME
        List<String> columnHeader = listCSVLines[0].split(',');

        Map<Integer,Map<String,String>> rowIndexToDataMap = new Map<Integer,Map<String,String>>();

        // For each row, starting after the header/fieldApi row
        for(Integer rowIndex = 1; rowIndex < listCSVLines.size(); rowIndex++){

            //Create a map of header/fieldApi : data in that cell on that row
            Map<String,String> columnHeaderToDataMap = new Map<String,String>();

            // Split the row, by comma to get the values for each column on that row
            List<String> rowData = listCSVLines[rowIndex].split(',');
            
            // If the column headers has the same amount of elements as the data values:
            // i.e 10 column headers & 10 elements of data - incl. null, they are going to be in sync
            if(columnHeader.size() == rowData.size()){

                //Get the first element of each and add them to a map, itterate until end of both lists
                for(Integer columnHeaderIndex = 0; columnHeaderIndex < columnHeader.size(); columnHeaderIndex++){

                    //FieldApi : Data
                    //FieldApi : Data
                    
                    columnHeaderToDataMap.put(columnHeader[columnHeaderIndex], rowData[columnHeaderIndex]);
                }
            }

            //CSV Line 1 : { FieldApi : Data }
            //CSV Line 2 : { FieldApi : Data }
            rowIndexToDataMap.put(rowIndex, columnHeaderToDataMap);
        }

        //Itterate over the map to get each row of the CSV
        // Each row => FieldAPI : Data
        for(Integer rowNumberKey : rowIndexToDataMap.keySet()){

            Boolean isObjectCreateable = schemaSObjectType.getDescribe().isCreateable();
            Sobject instanceSObject = schemaSObjectType.newSobject(); 
            if (!isObjectCreateable) {
                throw new CSVParserException('You can not create this type of record due to your profile permissions.');
            }
            
            //Get the FieldAPI and Data out
            Map<String,String> headerToDataMap = rowIndexToDataMap.get(rowNumberKey);

            //Itterate over the FieldAPI names
            for(String fieldAPIKey : headerToDataMap.keySet()){

                //Get sObjectField for creating the instance of the sObject.field
                Map<String, Schema.SObjectField> fieldMap = schemaSObjectType.getDescribe().fields.getMap();

                try{
                    Schema.DisplayType fielddataTypeCheck = fieldMap.get(fieldAPIKey).getDescribe().getType();
                }catch(Exception e){
                    throw new CSVParserException('The field - ' + fieldAPIKey + ' - does not exist on this object OR there was a spelling mistake in the object/field API name.');
                }
        
                if(fieldMap.get(fieldAPIKey).getDescribe().isCreateable() == false){
                    throw new CSVParserException('You can not access field - ' + fieldAPIKey);
                }

                Schema.DisplayType fielddataType = fieldMap.get(fieldAPIKey).getDescribe().getType();
                
                switch on fielddataType {
                    when String{
                        instanceSObject.put(fieldAPIKey, (String)headerToDataMap.get(fieldAPIKey));
                    }
                    when TextArea{
                        instanceSObject.put(fieldAPIKey, (String)headerToDataMap.get(fieldAPIKey));
                    }
                    when Picklist{
                        instanceSObject.put(fieldAPIKey, (String)headerToDataMap.get(fieldAPIKey));
                    }
                    when Reference{
                        instanceSObject.put(fieldAPIKey, (String)headerToDataMap.get(fieldAPIKey));
                    }
                    when Phone{
                        instanceSObject.put(fieldAPIKey, (String)headerToDataMap.get(fieldAPIKey));
                    }
                    when Email{
                        instanceSObject.put(fieldAPIKey, (String)headerToDataMap.get(fieldAPIKey));
                    }
                    when URL{
                        instanceSObject.put(fieldAPIKey, (String)headerToDataMap.get(fieldAPIKey));
                    }
                    when Currency{
                        instanceSObject.put(fieldAPIKey, Decimal.valueOf(headerToDataMap.get(fieldAPIKey)));
                    }
                    when Double{
                        instanceSObject.put(fieldAPIKey, Decimal.valueOf(headerToDataMap.get(fieldAPIKey)));
                    }
                    when Integer{
                        instanceSObject.put(fieldAPIKey, Integer.valueOf(headerToDataMap.get(fieldAPIKey)));
                    }
                    when Boolean{
                        instanceSObject.put(fieldAPIKey, Boolean.valueOf(headerToDataMap.get(fieldAPIKey)));
                    } 
                    when Date{
                        instanceSObject.put(fieldAPIKey, Date.valueOf(headerToDataMap.get(fieldAPIKey)));
                    } 
                    when DateTime{
                        instanceSObject.put(fieldAPIKey, DateTime.valueOf(headerToDataMap.get(fieldAPIKey)));
                    } 
                    when else {
                        throw new CSVParserException('Can not find the data type for field - ' + fieldAPIKey);
                    }
                }
            }
                // Add to list for insert
                listOfRecordstoInsert.add(instanceSObject);
        }
        try{
            Database.SaveResult[] srList = Database.insert(listOfRecordstoInsert, true);
            createSuccessCSV(srList, sObjectTypeString);
        }catch (Exception e){
           throw new CSVParserException('Error inserting records (Current setting is \'All or Nothing\'). Please click the ? for more guidance - ' + e.getMessage());
        }
    }

    public static void createSuccessCSV(Database.SaveResult[] srList, String sObjectTypeString){
        /* Call global describe to get the map of string to token. */
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
    
        /* Get the token for the sobject based on the type. */
        Schema.SObjectType schemaSObjectType = globalDescribeMap.get(sObjectTypeString);

        /* Instantiate a List of the type  of sobject from the token. */
        String listType = 'List<' + schemaSObjectType + '>';
        List<SObject> listOfInsertedRecords = (List<SObject>)Type.forName(listType).newInstance();

        List<String> listOfRecordIds = new List<String>();

        for(Database.SaveResult sr : srList){
            listOfRecordIds.add(sr.getId());
        }

        String queryString = 'SELECT Id, Name FROM ' + sObjectTypeString + ' WHERE Id IN :listOfRecordIds';
        listOfInsertedRecords = Database.query(queryString);

        String header = 'Record Id, Name \n';
        String finalstr = header;

        for(sObject obj: listOfInsertedRecords) {
            String recordString = obj.Id + ',';
            recordString += (String)obj.get('Name');
            recordString += '\n';
            finalstr += recordString;
        }

        String runningUserEmail = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()].Email;
        
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalstr);
        string csvname= 'InsertedRecords.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = new list<string> {runningUserEmail};
        String subject ='Inserted Records - Salesforce';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody('Attached are the records you just inserted with their newly assigned IDs.');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
}