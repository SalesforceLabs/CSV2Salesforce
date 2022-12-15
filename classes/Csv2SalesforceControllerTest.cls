/**
 * @description       : 
 * @author            : Jonathan Fox
 * @group             : 
 * @last modified on  : 22-06-2021
 * @last modified by  : Jonathan Fox
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   21-06-2021   Jonathan Fox   Initial Version
**/
@isTest(seeAllDAta=false)

public with sharing class Csv2SalesforceControllerTest {
    
    @isTest static void testCSVParsePass(){
        String csvString = JSON.serialize('Name,NumberOfEmployees\r\nAcme,100\r\nSalesforce,60000\r\nNTO,16');
    
        Csv2SalesforceController.saveFile(csvString, 'Account');

        List<Account> insertedAccounts = [SELECT Id, Name FROM Account];

        System.assertEquals(3, insertedAccounts.size());
    }

    @isTest static void testCSVParseNoAccessToFields(){
        String csvString = JSON.serialize('Name,NumberOfEmployees\r\nAcme,100\r\nSalesforce,60000\r\nNTO,16');
        Profile profileId = [SELECT Id from Profile WHERE Name ='Read Only' limit 1];
        User u = new User(
                            LastName = 'Test',
                            FirstName='Apex',
                            Alias = 'SFDCAT',
                            Email = 'apex.test@testclass.com',
                            Username = 'apex.test@testclass.com'+String.valueOf(math.random()*1000000),
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                        );
        insert u;

        System.runAs(u){
            try{
                Csv2SalesforceController.saveFile(csvString, 'Account');
            }
            catch(Exception e){
                System.assert(e != null);
                System.debug(e.getMessage());
                System.assertEquals(true, e.getMessage().contains('You can not create this type of record due to your profile permissions.'));
            }
            List<Account> insertedAccounts = [SELECT Id, Name FROM Account];

            System.assertEquals(0, insertedAccounts.size());
        }
    }
}