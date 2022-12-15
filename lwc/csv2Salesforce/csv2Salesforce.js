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
import { LightningElement, track, api } from 'lwc';
import saveFile from '@salesforce/apex/Csv2SalesforceController.saveFile';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class Csv2Salesforce extends LightningElement {
    
    @api sObjectType;
    @api readOnlysObject;
    cmpTitle = 'CSV Parser';
    @api recordid;
    @track data;
    @track fileName = '';
    @track UploadFile = 'Upload CSV File';
    @track showLoadingSpinner = false;
    @track isTrue = false;
    selectedRecords;
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 2000000;
    helpMessage = false;

    renderedCallback(){
        this.cmpTitle = 'CSV Parser for ' + this.sObjectType;
    }

    onChangesObjectImput(event){
        this.sObjectType = event.target.value;
    }

    handleFilesChange(event) {
        if(event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.fileName = event.target.files[0].name;

        }
    }

    handleSave() {
        if(this.filesUploaded.length > 0) {
            this.uploadHelper();
       }
       else {
           this.fileName = 'Please select a CSV file to upload';
       }
   }

    uploadHelper() {
        this.file = this.filesUploaded[0];
        if (this.file.size > this.MAX_FILE_SIZE) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Max file size exceeded',
                    message: 'Max file size is 2.0 MB',
                    variant: 'error',
                }),
            );
            return;
        }
        
        this.showLoadingSpinner = true;
        this.fileReader= new FileReader();
        this.fileReader.onloadend = (() => {
            this.fileContents = this.fileReader.result;
            this.saveToFile();
        });
        this.fileReader.readAsText(this.file);
    }

    saveToFile() {
        saveFile({ base64Data: JSON.stringify(this.fileContents), sObjectTypeString: this.sObjectType})
        .then(result => {
            this.data = result;
            this.fileName = this.fileName + ' - Uploaded Successfully';
            this.showLoadingSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!',
                    message: this.file.name + ' - Uploaded Successfully!',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            this.showLoadingSpinner = false;
            console.log(error.body);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while uploading File',
                    message: error.body.message,
                    variant: 'error',
                }),
            );
        });
    }

    openHelp(){
        this.helpMessage = true;
    }
    
    closeHelp(){
        this.helpMessage = false;
    }
}