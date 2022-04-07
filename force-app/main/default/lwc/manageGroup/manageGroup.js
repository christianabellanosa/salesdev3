import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchJSGroups from '@salesforce/apex/manageGroupController.fetchJsGroups';
import fetchGroupAccounts from '@salesforce/apex/manageGroupController.fetchGroupAccounts';
import searchGroupAccounts from '@salesforce/apex/manageGroupController.searchGroupAccounts';
import searchGroupAmenities from '@salesforce/apex/manageGroupController.searchGroupAmenities';
import searchGroupUser from '@salesforce/apex/manageGroupController.searchGroupUser';
import createJsGroup from '@salesforce/apex/manageGroupController.createJsGroup';


const groupcolumns = [
    { label: 'Name', fieldName: 'Name', type: 'text'},
    { label: 'Group User', fieldName: 'Group_UserName'},
    { label: 'Group Account', fieldName: 'Group_AccountName'},
    { label: 'Group Amenity', fieldName: 'Group_AmenityName'},
];

const accountcolumns = [
    { label: 'Name', fieldName: 'Name', type: 'text'},
    { label: 'JS Group', fieldName: 'JS_GroupName'},
    { label: 'Account', fieldName: 'AccountName'},
];

export default class ManageGroup extends LightningElement {
//test
    groupcolumns = groupcolumns;
    accountcolumns = accountcolumns;
    @track isGroupModalOpen = false;
    @api userId;
    @api accountId;
    @track isLoading = false;
    @track error;
    @track selectedGroupAccountName;
    //@track selectedGroupAccountId;
    @track selectedGroupAmenityName;
    //@track selectedGroupAmenityId;
    @track selectedGroupUserName;
    //@track selectedGroupUserId;
    @track isSearchLoadingGroup = false;
    @track isSearchLoadingAmenity = false;
    @track isSearchLoadingUser = false;
    @track hasRecordsGroup = true;
    @track hasRecordsAmenity = true;
    @track hasRecordsUser = true;
    @track listGroupAccounts;
    @track listGroupAmenities;
    @track listGroupUser;
    @track noResults = false;
    //@track jsGroupName;
    @track jsGroupRecord = {};
    groups = [];
    accounts = [];

    openGroupModal() {
        this.isGroupModalOpen = true;
    }
    closeGroupModal() {
        this.isGroupModalOpen = false;
    }
    submitDetails() {
        this.isModalOpen = false;
    }

    connectedCallback() {
        this.getJSGroups();
        this.getGroupAccounts();
    }

    renderedCallback() {
        const style = document.createElement('style');
        style.innerText = `body header {
            background: white;
        }
        `;
        this.template.querySelector('lightning-card').appendChild(style);


    }

    getJSGroups() {
        this.isLoading = true;
        fetchJSGroups()
            .then(data => {
                if (data) {       
                    data.forEach(group => { 
                        if(group.Group_User__c != null){
                            group.Group_UserName = group.Group_User__r.Name; 
                        } else {
                            group.Group_UserName = '';
                        }
                        if(group.Group_Account__c != null){
                            group.Group_AccountName = group.Group_Account__r.Name; 
                        } else {
                            group.Group_AccountName = '';
                        }   
                        if(group.Group_Amenity__c != null){
                            group.Group_AmenityName = group.Group_Amenity__r.Name;
                        } else {
                            group.Group_AmenityName = '';
                        }     
                    });
                }
                this.groups = data;
                console.log(this.groups);
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                console.log(' error >>> ', error);
                this.isLoading = false;
            });
    }

    getGroupAccounts() {
        this.isLoading = true;
        fetchGroupAccounts()
            .then(data => {
                if (data) {       
                    data.forEach(account => { 
                        if(account.JSGroup__c != null){
                            account.JS_GroupName = account.JS_Group__r.Name; 
                        } else {
                            account.JS_GroupName = '';
                        }
                        if(account.Account__c != null){
                            account.AccountName = account.Account__r.Name; 
                        } else {
                            account.AccountName = '';
                        }   
                    });
                }
                this.accounts = data;
                console.log(this.accounts);
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                console.log(' error >>> ', error);
                this.isLoading = false;
            });
    }

    handleNameChange(event){
        //this.jsGroupName = event.target.value;
        this.jsGroupRecord.Name = event.target.value;
    }

    get disableButton(){
        return !(this.jsGroupRecord.Name);
    }

    handleGroupAccountKeyChange(event) {
        const searchKeyString = event.target.value;
        this.isSearchLoadingGroup = true;
        // console.log('brokerSearchKey selectedBrokerCode>>> ' + searchKey);
        console.log(searchKeyString);
        this.selectedGroupAccountName = searchKeyString;
        searchGroupAccounts({ searchKey: this.selectedGroupAccountName })
            .then(data => {
                this.hasRecordsGroup = data.length == 0 ? false : true;
                this.listGroupAccounts = data;
                console.log(this.listGroupAccounts);
                // console.log(' listBrokerCodesInternal >>> ', this.listBrokerCodesInternal);
                this.error = undefined;
                this.isSearchLoadingGroup = false;
            })
            .catch(error => {
                this.error = error;
                console.log(' error >>> ', error);
                this.listGroupAccounts = undefined;
                this.isSearchLoadingGroup = false;
            });
    }

    toggleResultGroup(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainerGroup');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch (whichEvent) {
            case 'searchInputFieldGroup':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    handleSelectedGroupAccount(event){   
        this.jsGroupRecord.Group_Account__c = event.target.getAttribute('data-recid');
        //this.selectedGroupAccountId = event.target.getAttribute('data-recid'); // get selected record's Broker code 
        this.selectedGroupAccountName = event.target.getAttribute('data-recname');
        //this.selectedGroupAccountId = event.target.getAttribute('data-recid');
        //console.log('handle Selected Record >> '+this.selectedBrokerCode);
        this.template.querySelector('.lookupInputContainerGroup').classList.remove('slds-is-open');
    }

    handleGroupAmenityKeyChange(event) {
        const searchKeyString = event.target.value;
        this.isSearchLoadingAmenity = true;
        // console.log('brokerSearchKey selectedBrokerCode>>> ' + searchKey);
        console.log(searchKeyString);
        this.selectedGroupAmenityName = searchKeyString;
        searchGroupAmenities({ searchKey: this.selectedGroupAmenityName })
            .then(data => {
                this.hasRecordsAmenity = data.length == 0 ? false : true;
                this.listGroupAmenities = data;
                console.log(this.listGroupAmenities);
                // console.log(' listBrokerCodesInternal >>> ', this.listBrokerCodesInternal);
                this.error = undefined;
                this.isSearchLoadingAmenity = false;
            })
            .catch(error => {
                this.error = error;
                console.log(' error >>> ', error);
                this.listGroupAmenity = undefined;
                this.isSearchLoadingAmenity = false;
            });
    }

    toggleResultAmenity(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainerAmenity');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch (whichEvent) {
            case 'searchInputFieldAmenity':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    handleSelectedGroupAmenity(event){
        this.jsGroupRecord.Group_Amenity__c = event.target.getAttribute('data-recid');   
        //this.selectedGroupAmenityId = event.target.getAttribute('data-recid'); // get selected record's Broker code 
        this.selectedGroupAmenityName = event.target.getAttribute('data-recname');
        //this.selectedGroupAccountId = event.target.getAttribute('data-recid');
        //console.log('handle Selected Record >> '+this.selectedBrokerCode);
        this.template.querySelector('.lookupInputContainerAmenity').classList.remove('slds-is-open');
    }

    handleGroupUserKeyChange(event) {
        const searchKeyString = event.target.value;
        this.isSearchLoadingUser = true;
        // console.log('brokerSearchKey selectedBrokerCode>>> ' + searchKey);
        console.log(searchKeyString);
        this.selectedGroupUserName = searchKeyString;
        searchGroupUser({ searchKey: this.selectedGroupUserName })
            .then(data => {
                this.hasRecordsUser = data.length == 0 ? false : true;
                this.listGroupUser = data;
                console.log(this.listGroupUser);
                // console.log(' listBrokerCodesInternal >>> ', this.listBrokerCodesInternal);
                this.error = undefined;
                this.isSearchLoadingUser = false;
            })
            .catch(error => {
                this.error = error;
                console.log(' error >>> ', error);
                this.listGroupAmenity = undefined;
                this.isSearchLoadingUser = false;
            });
    }

    toggleResultUser(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainerUser');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch (whichEvent) {
            case 'searchInputFieldUser':
                clsList.add('slds-is-open');
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    handleSelectedGroupUser(event){   
        this.jsGroupRecord.Group_User__c = event.target.getAttribute('data-recid');
        //this.selectedGroupUserId = event.target.getAttribute('data-recid'); // get selected record's Broker code 
        this.selectedGroupUserName = event.target.getAttribute('data-recname');
        //this.selectedGroupAccountId = event.target.getAttribute('data-recid');
        //console.log('handle Selected Record >> '+this.selectedBrokerCode);
        this.template.querySelector('.lookupInputContainerUser').classList.remove('slds-is-open');
    }

    handleSaveJSGroup(){
         this.isLoading = true;
         createJsGroup({ jsGroup: this.jsGroupRecord })
            .then(data => {
                this.error = undefined;
                this.closeGroupModal();
                this.showSuccessToast();
                this.isLoading = false;
                this.jsGroupRecord = {};
                this.getJSGroups();
            })
            .catch(error => {
                this.error = error;
                console.log(' error >>> ', error);
                this.isLoading = false;
            });
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Record has been saved successfully.',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}