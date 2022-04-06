global without sharing class Sip_AmenityController {

    private static String className = 'Sip_AmenityController';
    private static String contextUser = UserInfo.getName();
    public static Boolean isDiscountApplied = false;
    public static Decimal discountedPrice = 0.00;
    public static String qualifiedLevelOnFeb = '';
    public static String promoCodeApplied = null; //Shivani added User Story 473452
    global static Logger log = Logger.getLogger();
    //2020 Security issue fix
    public static Boolean isSkipCheckInCommitTravelCertsTransaction = false;
    public static Map<Decimal, String> nominationLevelWithCodeMap = new Map<Decimal, String>{
        0 => 'MP',
        1 => '1S',
        2 => '1G',
        3 => '1P',
        4 => '1K',
        5 => 'GS'
    };

    public static Map<String, String> premierCodeWithPrdCodeMap = new Map<String, String>{
        'MP' => 'MP',
        'SL' => '1S',
        'GL' => '1G',
        'PL' => '1P',
        '1K' => '1K',
        'GS' => 'GS'
    };

    global Sip_AmenityController(Sip_CommonController controller) {

    }

    //Added by natic 20170529, Send confirmation for user
    @RemoteAction
    global static void sendEmail(String userId, String refNo) {
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return;
        //2020 Security issue fix
        } else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.sendEmail', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, '');
            return;
        }else{
        //End
            List<SIP_Transactions_line_item__c> items = [SELECT SIP_Banking_Audit__c, RecordTypeId,
                                                                SIP_Email_Address__c, SIP_MP_Number__c
                                                         FROM   SIP_Transactions_line_item__c
                                                         WHERE  SIP_Banking_Audit__r.Name = :refNo LIMIT 1];

            if (items != null && items.size() > 0) {

                String emailTemplateName = '';

                if (items[0].RecordTypeId == Sip_RecordTypeId.BEVERAGE_COUPONS_TRANSITEM) {
                    emailTemplateName = 'Beverage Coupons Confirmation Email';
                } else if (items[0].RecordTypeId == Sip_RecordTypeId.BONUS_MILES_TRANSITEM) {
                    emailTemplateName = 'Bonus Miles Confirmation Email';
                } else if (items[0].RecordTypeId == Sip_RecordTypeId.SALES_NOMINATIONS_TRANSITEM) {
                    emailTemplateName = 'Sales Nominations Confirmation Email';
                } else if (items[0].RecordTypeId == Sip_RecordTypeId.TRAVEL_CERTIFICATES_TRANSITEM) {
                    emailTemplateName = 'Travel Certificates Confirmation Email';
                } else if (items[0].RecordTypeId == Sip_RecordTypeId.UCM_TRANSITEM) {
                    emailTemplateName = 'UCM Confirmation Email';
                } else if (items[0].RecordTypeId == Sip_RecordTypeId.UPGRADES_TRANSITEM) {
                    emailTemplateName = 'Upgrades Confirmation Email';
                } else if (items[0].RecordTypeId == Sip_RecordTypeId.UCOTP_TRANSITEM &&
                        items[0].SIP_Email_Address__c != null) {
                    emailTemplateName = 'UCOTPE Confirmation Email';
                } else if (items[0].RecordTypeId == Sip_RecordTypeId.UCOTP_TRANSITEM &&
                        String.isNotBlank(items[0].SIP_MP_Number__c)) {
                    emailTemplateName = 'UCOTPMP Confirmation Email';
                } else if (items[0].RecordTypeId == Sip_RecordTypeId.ANNUALNOMINATIONPROGRAM_TRANSITEM ) {
                    emailTemplateName = 'Annual Nomination Confirmation Email';
                } else if(items[0].RecordTypeId == Sip_RecordTypeId.SUBSCRIPTION_WITH_TRANS_ITEM_ID.get(Label.Sip_Amenity_Baggage_Subscriptions)){//For baggage Subscription
                    emailTemplateName = 'Baggage Subscription Confirmation Email';
                } else if(items[0].RecordTypeId == Sip_RecordTypeId.SUBSCRIPTION_WITH_TRANS_ITEM_ID.get(Label.Sip_Amenity_Economy_Plus_Subscriptions)){//For Economy Plus Subscription
                    emailTemplateName = 'Economy Plus Subscription Confirmation Email';
                } else if(items[0].RecordTypeId == Sip_RecordTypeId.SUBSCRIPTION_WITH_TRANS_ITEM_ID.get(Label.Sip_Amenity_United_WIFI_Subscriptions)){// For United WIFI Subscription
                    emailTemplateName = 'United WIFI Subscription Confirmation Email';
                }
                System.debug('emailTemplateName ::'+emailTemplateName);
                EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Name = :emailTemplateName];

                Sip_EmailAlert emailAlert = new Sip_EmailAlert(items[0].SIP_Banking_Audit__c, et.Id);
                emailAlert.setReceivers(Id.valueOf(userId));
                //20190208 set org-wide email as sender
                // emailAlert.setOrgWideEmailId ('0D236000000PQBl'); // 2019-12-10 TCG create a label for this Id
                emailAlert.setOrgWideEmailId(Label.Sip_Org_Wide_Email_Id);
                emailAlert.send();
            }
        }
    }

    //Added by natic 20170520, All Traveller Services begin
    @RemoteAction
    global static List<Sip_RemotingResultAbstract> getCategoriesByAccountId(String accId) {
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        //2020 Security issue fix
        } else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(accId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getCategoriesByAccountId', 'Sip_SessionCacheManager', 'validateAmenityAcountId', '', accId);
            return null;
        }else{
        //End
            return Sip_RecordLocator.getCategoriesByAccountId(accId);
        }
    }

    @RemoteAction
    global static Sip_RemotingResultAbstract getPNRInfo(String recordLocator, String recordLocatorSource, String accId, String userId, String callerAccId) {
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
    //20210413 rwern TFS 484380: only internal user should call this method
        if (!Sip_RemoteSecurityUtil.isInternalUser('getPNRInfo')) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getPNRInfo', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, accId);
            return null;
        } else if (!Test.isRunningTest() && (!sessionObj.validateAmenityAcountId(accId))) {
            Sip_SessionCacheManager.insertGEHError(className + '.getPNRInfo', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, accId);
            return null;
        }else{
        //End
            // System.debug(LoggingLevel.INFO, '***Peter Log Sip_AmenityController userId: ' + userId);
            HttpResponse response = Sip_RecordLocator.getPNRStringForAllTraverl(recordLocator, recordLocatorSource, '', userId);
            Sip_RecordLocator rl = Sip_RecordLocator.getRecordLocatorByHttpResp(response);
            rl.processingServiceStatus(userId);
            rl.processingPNRForATS(accId, userId, callerAccId);
            //E+
            rl.processingTravelers();
            rl.processingSegments();
            rl.removeInactiveSegment();
            rl.createDisclaimerMessage();
            rl.proceedTicketsForAllTravellersService();
            rl.getAgentName();
            log.flush();
            return rl.getViewModel();
        }
    }

    @RemoteAction
    global static Sip_TransactionEntity.TransactionInfo confirmAllTravelerServices(Sip_RecordLocator.RecordLocatorViewModel recordLocatorVM, String userId,
                                                                                    String payerId, String beneficiaryId, String callerId, String productCode,
                                                                                    String comment, String callerFirstName, String callerLastName, String remarks) {
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.confirmAllTravelerServices', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
            return null;
        } else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(payerId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.confirmAllTravelerServices', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
            return null;
        }else{
        //End
            Sip_RecordLocator rl = new Sip_RecordLocator();
            rl.setRecordLocatorByVM(recordLocatorVM);
            log.flush();
            return rl.confirmAllTravelerServices(userId, payerId, beneficiaryId, callerId, productCode, comment, callerFirstName, callerLastName, remarks);
        }
    }

    @RemoteAction
    global static Sip_RemotingResultAbstract sendRemarks(Sip_RecordLocator.RecordLocatorViewModel recordLocatorVM ,
                                                        String userId, String waiverCode, String productCode, String remarks) {
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.sendRemarks', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, '');
            return null;
        }else{
        //End
            Sip_RecordLocator rl = new Sip_RecordLocator();
            rl.setRecordLocatorByVM(recordLocatorVM);
            return rl.sendRemarks(userId, waiverCode, productCode, remarks);
        }
    }
    //Hamed PW
    @RemoteAction
    global static Sip_RemotingResultAbstract sendRemarksPW(Sip_RecordLocator.RecordLocatorViewModel recordLocatorVM ,
            String userId, String waiverCode, String productCode, String remarks, String newAgencyPNRConfirmWaiver, String newPNRConfirmWaiver) {
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.sendRemarksPW', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, '');
            return null;
        }else{
        //End
            Sip_RecordLocator rl = new Sip_RecordLocator();
            rl.setRecordLocatorByVM(recordLocatorVM);
            return rl.sendRemarksPW(userId, waiverCode, productCode, remarks, newAgencyPNRConfirmWaiver, newPNRConfirmWaiver);
        }
    }

    //All Traveller services end

    //20170628 Add userId
    @RemoteAction
    global static Sip_RemotingResultAbstract retrievePremierQualification (Sip_PremierQualification.CM_PremierQualificationRequestBody requestBody, String userId) {
        String methodName = 'retrievePremierQualification';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.retrievePremierQualification', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, '');
            return null;
        }else{
        //End
            try {
                //20170628 userInfo and userManagement 
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);

                String amentityPremierRequestBodyInJson = JSON.serialize(requestBody);
                Sip_HttpUtil.CalloutInfoWrapper premierQualificationCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                premierQualificationCalloutInfo.requestBodyInJson = amentityPremierRequestBodyInJson;
                premierQualificationCalloutInfo.integrationType = 'GetUCBQualDetails'; 
                premierQualificationCalloutInfo.oauthType = 'SIP OAuth';
                premierQualificationCalloutInfo.headers = null;
                premierQualificationCalloutInfo.logInformation = 'Get Premier Qualification';
                premierQualificationCalloutInfo.actionDescription = 'Get Premier Qualification';
                premierQualificationCalloutInfo.logMessage = '';
                premierQualificationCalloutInfo.serviceName = 'Premier Qualification';
                premierQualificationCalloutInfo.serviceMethod = 'Premier Qualification';
                premierQualificationCalloutInfo.contextClass = className;
                premierQualificationCalloutInfo.contextMethod = methodName;
                premierQualificationCalloutInfo.milesPlusNumber = requestBody.MileagePlusNumber;
                Sip_HttpUtil h = new Sip_HttpUtil (premierQualificationCalloutInfo);
                HTTPResponse htttpRes = h.callout();
                String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                //Mock Logic            
                Sip_PremierQualification obj = new Sip_PremierQualification();
                if (resAfterHttpValidation.equals(Label.Sip_Common_Error)) {
                    String errorMsg = Label.Sip_Common_Error;
                    obj.vPremierQualification.success = false;
                    obj.vPremierQualification.messages.add(errorMsg);
                    log.flush();
                    return obj.vPremierQualification;
                }
                obj.parsepremierQualificationInfo(resAfterHttpValidation);
                obj.validateLastNameAndMemberId(requestBody);
                obj.checkVictimAccount();
                obj.populateVPremierQualification();
                obj.checkCloseAccount ();
                obj.checkDeceasedMember();
                obj.checkPVAAccount();
                obj.checkCharityAccount();
                obj.checkCUB();
                obj.checkSUB();
                obj.checkTestAccount(requestBody);
                // obj.checkBadAddress();
                //20170629 add userInfo and user management 
                obj.validateQualRes(userInfoModel, userManagementInfo);
                obj.vPremierQualification.success = obj.success;
                obj.vPremierQualification.messages = obj.messages;
                //20211001 Moin Task 7080:: Update the merchOfferRecordId attribute with the record id 
                if(obj.success && (requestBody.ServiceContext == Label.Sip_Amenity_Baggage_Subscriptions
                    || requestBody.ServiceContext == Label.Sip_Amenity_Economy_Plus_Subscriptions
                    || requestBody.ServiceContext == Label.Sip_Amenity_Club_Membership_Subscriptions
                    || requestBody.ServiceContext == Label.Sip_Amenity_United_WIFI_Subscriptions)){
                    String currentPremierStatus;
                    //START :: Moin :: Get Current Status based on the Premier Level received in PremierQualification response and Cariier Code as 'UA' maintined in custom label
                    // Get Current Status value from 'SIP_Tier_Level_Information_Table__c=>Tier Level Information' custom setting 
                    if(obj.vPremierQualification.CurrentPremierLevel != null){
                        //Status code from PremierQualification Response
                        String stausCode = String.valueOf(obj.vPremierQualification.CurrentPremierLevel);
                        List<SIP_Tier_Level_Information_Table__c> tierLevel = [Select Id,SIP_Tier_Level_Description__c   
                                                                            FROM SIP_Tier_Level_Information_Table__c
                                                                            WHERE SIP_FQTV_Elite_Status_Code__c =: stausCode
                                                                            AND  SIP_FQTV_Carrier_Code__c =: Label.SIP_FQTV_Carrier_Code
                                                                            LIMIT 1];
                        if(tierLevel != null && tierLevel.size() > 0){
                            currentPremierStatus = tierLevel[0].SIP_Tier_Level_Description__c;
                        } 
                    }//END
                    SIP_Merch_Offers__c merchOffer = new SIP_Merch_Offers__c();
                    merchOffer.Customer_ID__c = obj.vPremierQualification.MileagePlusNumber;
                    //TASK 18509:: Moin::Encode First Name on Merch Offer Object                  
                    merchOffer.First_Name__c = EncodingUtil.base64Encode(Blob.valueOf(obj.vPremierQualification.FirstName));
                    //TASK 18509:: Moin::Encode SurName on Merch Offer Object                  
                    merchOffer.Surname__c = EncodingUtil.base64Encode(Blob.valueOf(obj.vPremierQualification.LastName));    
                    merchOffer.Current_Premier_Status__c = currentPremierStatus;        
                    insert merchOffer;
                    Sip_PremierQualification.VM_PremierQualification obj1 = new Sip_PremierQualification.VM_PremierQualification();
                    obj1.success = true;
                    obj1.merchOfferRecordId = merchOffer.Id;                    
                    return obj1;
                }
                //Shivani PII Qual quick fix
                if(!obj.success){
                    Sip_PremierQualification.VM_PremierQualification obj1 = new Sip_PremierQualification.VM_PremierQualification();
                    obj1.success = false;
                    obj1.messages.addAll(obj.messages);
                    return obj1;
                }
                log.flush();
                // System.debug(LoggingLevel.INFO, '*** : Premier Qulification' + Json.serialize(obj.vPremierQualification));
                return obj.vPremierQualification;
            } catch (Exception ex) {
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_PremierQualification.VM_PremierQualification obj = new Sip_PremierQualification.VM_PremierQualification();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return obj;
            }
        }
    }

    //Shivani REQ-0823 - New method to get whole response data for Min Guaranteed Level
    @RemoteAction
    global static Sip_RemotingResultAbstract retrievePremierQualificationForNomination (Sip_PremierQualification.CM_PremierQualificationRequestBody requestBody, String userId) {
        String methodName = 'retrievePremierQualificationForNomination';
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.retrievePremierQualificationForNomination', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, '');
            return null;
        }else{
            try {
                //20170628 userInfo and userManagement 
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);

                String amentityPremierRequestBodyInJson = JSON.serialize(requestBody);
                Sip_HttpUtil.CalloutInfoWrapper premierQualificationCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                premierQualificationCalloutInfo.requestBodyInJson = amentityPremierRequestBodyInJson;
                premierQualificationCalloutInfo.integrationType = 'GetUCBQualDetails'; 
                premierQualificationCalloutInfo.oauthType = 'SIP OAuth';
                premierQualificationCalloutInfo.headers = null;
                premierQualificationCalloutInfo.logInformation = 'Get Premier Qualification';
                premierQualificationCalloutInfo.actionDescription = 'Get Premier Qualification';
                premierQualificationCalloutInfo.logMessage = '';
                premierQualificationCalloutInfo.serviceName = ''; //TBD
                premierQualificationCalloutInfo.serviceMethod = ''; //TBD
                premierQualificationCalloutInfo.contextClass = className;
                premierQualificationCalloutInfo.contextMethod = methodName;
                premierQualificationCalloutInfo.milesPlusNumber = requestBody.MileagePlusNumber;
                Sip_HttpUtil h = new Sip_HttpUtil (premierQualificationCalloutInfo);
                HTTPResponse htttpRes = h.callout();
                String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                //Mock Logic            
                Sip_PremierQualification obj = new Sip_PremierQualification();
                if (resAfterHttpValidation.equals(Label.Sip_Common_Error)) {
                    String errorMsg = Label.Sip_Common_Error;
                    obj.vPremierQualification.success = false;
                    obj.vPremierQualification.messages.add(errorMsg);
                    log.flush();
                    return obj.vPremierQualification;
                }
                obj.parsepremierQualificationInfo(resAfterHttpValidation);
                obj.validateLastNameAndMemberId(requestBody);
                obj.checkVictimAccount();
                obj.populateVPremierQualification();
                obj.checkCloseAccount ();
                obj.checkDeceasedMember();
                obj.checkPVAAccount();
                obj.checkCharityAccount();
                obj.checkCUB();
                obj.checkSUB();
                obj.checkTestAccount(requestBody);
                // obj.checkBadAddress();
                //20170629 add userInfo and user management 
                obj.validateQualRes(userInfoModel, userManagementInfo);
                obj.vPremierQualification.success = obj.success;
                obj.vPremierQualification.messages = obj.messages;            
                log.flush();
                System.debug(LoggingLevel.INFO, '*** : Premier Qulification' + Json.serialize(obj.vPremierQualification));
                //2020 Security issue fix
                Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
                sessionObj.putMPWithCurrentLevel(obj.vPremierQualification.MileagePlusNumber, nominationLevelWithCodeMap.get(obj.vPremierQualification.CurrentPremierLevel));
                sessionObj.putMPWithQualifiedLevel(obj.vPremierQualification.MileagePlusNumber, obj.cPremierQaulification.Qualification.PremierLevel);
                sessionObj.putMPWithCustomerIdFromRetrievePremier(obj.vPremierQualification.MileagePlusNumber, obj.vPremierQualification.CustomerId);
                obj.vPremierQualification.CustomerId = null;
                obj.cPremierQaulification.CustomerId = null;
                //Shivani PII Qual quick fix
                if(!obj.success){
                    Sip_PremierQualification.VM_PremierQualification obj1 = new Sip_PremierQualification.VM_PremierQualification();
                    obj1.success = false;
                    obj1.messages.addAll(obj.messages);
                    return obj1;
                }
                //Shivani REQ-0823- Returning whole service response.
                return obj;
            } catch (Exception ex) {
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_PremierQualification.VM_PremierQualification obj = new Sip_PremierQualification.VM_PremierQualification();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return obj;
            }
        }
    }

    //To be uploaded Subscription
    @RemoteAction
    global static Sip_RemotingResultAbstract retrieveSubscription (Sip_PremierQualification.VM_PremierQualification premierQual, String accountId, String amenityType, String userId) {
        String methodName = 'retrieveSubscription';
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();

        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.retrieveSubscription', 'Sip_RemoteSecurityUtil', 'isValidUserId', userId, accountId);
            return null;
        } else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(accountId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.retrieveSubscription', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, accountId);
            return null;
        }else{
        //End
            try {
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);


                Sip_Subscription.GetSubscriptionServiceRequestBody requestBodyOfGetSubscriptionService = new Sip_Subscription.GetSubscriptionServiceRequestBody();
                requestBodyOfGetSubscriptionService.Requester.Requestor.ChannelName = Sip_CommonConstant.CHANNELNAMEFORSUBSERVER;
                requestBodyOfGetSubscriptionService.Requester.Requestor.ChannelID = Sip_CommonConstant.CHANNELIDFORSUBSERVER;
                requestBodyOfGetSubscriptionService.Requester.Requestor.LanguageCode = Sip_CommonConstant.LANGUAGECODEFORSUBSERVER;
                requestBodyOfGetSubscriptionService.Filter.Statuses.add(Sip_CommonConstant.STATUSESCODEFORSUBSERVER);
                requestBodyOfGetSubscriptionService.Filter.ProductCode = Sip_CommonConstant.PRODUCTCODEFORSUBSERVER;
                requestBodyOfGetSubscriptionService.LoyaltyProgramMemberID = premierQual.MileagePlusNumber;
                String requestBodyInJson = JSON.serialize(requestBodyOfGetSubscriptionService);

                Sip_HttpUtil.CalloutInfoWrapper subsCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                subsCalloutInfo.requestBodyInJson = requestBodyInJson;
                subsCalloutInfo.integrationType = 'getSubscription';
                subsCalloutInfo.oauthType = 'SIP OAuth';
                subsCalloutInfo.headers = null;
                subsCalloutInfo.logInformation = 'Get Subscription Details';
                subsCalloutInfo.actionDescription = 'Get Subscription Details';
                subsCalloutInfo.logMessage = '';
                subsCalloutInfo.serviceName = 'Subscription';
                subsCalloutInfo.serviceMethod = 'GetSubscription';
                subsCalloutInfo.contextClass = className;
                subsCalloutInfo.contextMethod = methodName;

                Sip_HttpUtil h = new Sip_HttpUtil (subsCalloutInfo);
                HTTPResponse htttpRes = h.callout();
                String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                // String resAfterHttpValidation = '{"Response": {"Error": [{"Code": "4000", "ErrorType": "Major", "Text": "Generic Subscription exception"}, {"Code": "1003", "ErrorType": "Minor", "Text": "Subscription exists :: SUB-CL-0AA-001 (6/21/2016 12:00:00 AM)(11/30/2077 11:59:59 PM)(SCL_SUB_PROMO)"}], "GUIDs": [{"Name": "TRANSACTIONID", "ID": "1495633503151010086025043297081"}], "TransactionID": "1495633503151010086025043297081"}}';

                //Mock logic

                Sip_Subscription obj = new Sip_Subscription();

                if (resAfterHttpValidation.equals(Label.Sip_Common_Error) ) {
                    String errorMsg = Label.Sip_Common_Error;
                    obj.vSubscription.success = false;
                    obj.vSubscription.messages.add(errorMsg);
                    log.flush();
                    return obj.vSubscription;
                }
                obj.parseGetSubscriptionInfo(resAfterHttpValidation);
                obj.calculateNewEffectiveData();
                obj.calculateNewExpiryDate ();

                // get product price
                obj.populatePrice('Membership', accountId);
                obj.vSubscription.MileagePlusNumber = premierQual.MileagePlusNumber;
                //Shivani for subscription PII commented
                //obj.vSubscription.LastName = premierQual.LastName;
                //obj.vSubscription.FirstName = premierQual.FirstName;
                //20170524
                obj.vSubscription.CurrentPremierLevel = premierQual.CurrentPremierLevel;
                if (amenityType == Sip_CommonConstant.SUBSCRIPTIONAMENITYTYPEMEMBER) {
                    // System.debug('Validate Subscription');
                    //20170614 check user permission for error msg 
                    obj.validateSubscriptionError(userInfoModel, userManagementInfo);
                }
                obj.vSubscription.success = obj.success;
                obj.vSubscription.messages = obj.messages;
                log.flush();
                return obj.vSubscription;
            } catch (Exception ex) {
                //20190130 lijuan update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_Subscription.VM_Subscription obj = new Sip_Subscription.VM_Subscription();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return obj;
            }
        }
    }

    //20210917 Moin Task 7079 :: HTTP Callout to get Offers
    @RemoteAction
    global static Sip_RemotingResultAbstract retrieveMerchOffers(String merchOfferRecordId,String productCode,String userId, String flowName){
        String methodName = 'retrieveOffers';
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();

        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.retrieveOffers', 'Sip_RemoteSecurityUtil', 'isValidUserId', userId,'');
            return null;
        }else{
            try{
                SIP_Merch_Offers__c offer = [Select Id,Customer_ID__c,First_Name__c,Surname__c FROM SIP_Merch_Offers__c WHERE Id =:merchOfferRecordId];
                system.debug('offer***'+offer);
                Sip_MerchandizingOffers.CM_MerchandizingOffersRequestBody resquestBody = new Sip_MerchandizingOffers.CM_MerchandizingOffersRequestBody();
                resquestBody.Requester.Requestor.ChannelName = 'SALES';
                resquestBody.Requester.Requestor.ChannelID = '4501';
                resquestBody.Requester.Requestor.LanguageCode = 'en';
                Sip_MerchandizingOffers.CM_Characteristic chars = new Sip_MerchandizingOffers.CM_Characteristic();
                chars.code ='TransactionLog';
                chars.value ='true';
                resquestBody.Requester.Requestor.Characteristic = new List<Sip_MerchandizingOffers.CM_Characteristic>{chars};
                //resquestBody.CountryCode = 'US';
                //resquestBody.CurrencyCode = 'USD';
                //resquestBody.TicketingCountryCode = 'US';
                
                Sip_MerchandizingOffers.CM_Filter filter = new Sip_MerchandizingOffers.CM_Filter();
                filter.IsIncluded = 'true';
                filter.ProductCode = productCode;
                resquestBody.Filters = new List<Sip_MerchandizingOffers.CM_Filter>{filter};

                Sip_MerchandizingOffers.CM_RProductLoyaltyProgramProfile profile = new Sip_MerchandizingOffers.CM_RProductLoyaltyProgramProfile();
                profile.IsPrimary = 'True';
                profile.LoyaltyProgramCarrierCode = 'UA';
                profile.LoyaltyProgramMemberID = offer.Customer_ID__c;
                profile.LoyaltyProgramMemberTierDescription = 0;

                //20210921 Moin Task 7079 :: prepare request attributes based on the product code
                if(flowName == Label.Sip_Premier_Access){// 2021-10-28 Suyash adding flowName - Premier access - 7104
                    Sip_MerchandizingOffers.CM_ReservationReferences ref = new Sip_MerchandizingOffers.CM_ReservationReferences();
                    //ref.ID = 'H434SN';//offer.Customer_ID__c
                    ref.ID = offer.Customer_ID__c;
                    resquestBody.ReservationReferences = new List<Sip_MerchandizingOffers.CM_ReservationReferences>{ref};
                }else{
                    Sip_MerchandizingOffers.CM_RTraveler traveler = new Sip_MerchandizingOffers.CM_RTraveler();
                    traveler.ProductLoyaltyProgramProfile = new List<Sip_MerchandizingOffers.CM_RProductLoyaltyProgramProfile>{profile};
                    traveler.ID = '1';
                    resquestBody.Travelers = new List<Sip_MerchandizingOffers.CM_RTraveler>{traveler};
                }
                System.debug('requestBody ::' + JSON.serialize(resquestBody));
                Sip_HttpUtil.CalloutInfoWrapper offerCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                offerCalloutInfo.requestBodyInJson = JSON.serialize(resquestBody);
                offerCalloutInfo.integrationType = 'GetMerchandizingoffers';
                offerCalloutInfo.oauthType = 'SIP OAuth';
                offerCalloutInfo.headers = null;
                offerCalloutInfo.logInformation = 'Get Offer Details';
                offerCalloutInfo.actionDescription = 'Get Offer Details';
                offerCalloutInfo.logMessage = '';
                offerCalloutInfo.serviceName = 'Offer';
                offerCalloutInfo.serviceMethod = 'GetOffer';
                offerCalloutInfo.contextClass = className;
                offerCalloutInfo.contextMethod = methodName;

                Sip_HttpUtil h = new Sip_HttpUtil (offerCalloutInfo);
                HTTPResponse htttpRes = h.callout();
                String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                //START :: 20211005 Moin Task 7080 :: Logic for return of view model for merchandizing offer service        
                Sip_MerchandizingOffers obj = new Sip_MerchandizingOffers();
                if (resAfterHttpValidation.equals(Label.Sip_Common_Error)) {
                    String errorMsg = Label.Sip_Common_Error;
                    obj.vMerchandizingOffers.success = false;
                    obj.vMerchandizingOffers.messages.add(errorMsg);
                    log.flush();
                    return obj.vMerchandizingOffers;
                }
               
                if(flowName == Label.Sip_Premier_Access){// 2021-10-28 Suyash adding flowName - Premier access - 7104
                    //Methods for Premier Access
                    obj.parseMerchandizingOffersInfoForPAS(resAfterHttpValidation,merchOfferRecordId);
                    obj.populateVMerchandizingOffersPAS(merchOfferRecordId,offer.First_Name__c,offer.Surname__c,offer.Customer_ID__c);
                }else {
                    obj.parseMerchandizingOffersInfo(resAfterHttpValidation,merchOfferRecordId);
                    obj.populateVMerchandizingOffers(merchOfferRecordId,offer.First_Name__c,offer.Surname__c,offer.Customer_ID__c);
                }
                
                if(!obj.success){
                    Sip_MerchandizingOffers.VM_MerchandizingOffers obj1 = new Sip_MerchandizingOffers.VM_MerchandizingOffers();
                    obj1.success = false;
                    obj1.messages.addAll(obj.messages);
                    return obj1;
                }
                log.flush();
                return obj.vMerchandizingOffers;
                //END
            }catch(Exception ex){
                System.debug('Exception ::'+ex.getMessage()+' :: '+ex.getLineNumber());
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_MerchandizingOffers.VM_MerchandizingOffers obj = new Sip_MerchandizingOffers.VM_MerchandizingOffers();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return obj;
            }
        }
    }

    //New method added for fulfillment HTTP callout - Hemant - Premier access
    @RemoteAction
    global static Sip_RemotingResultAbstract executeMerchFullfillment(Sip_MerchandizingOffers.VM_Fulfillment_Offer fullfillmentOffer ,String userId,String accountId,String serviceContext,String referenceNumber){
        String methodName = 'executeMerchFullfillment';
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.executeMerchFullfillment', 'Sip_RemoteSecurityUtil', 'isValidUserId', userId,'');
            return null;
        }else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(accountId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.executeMerchFullfillment', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, accountId);
            return null;
        }else{
            try{
                system.debug('referenceNumber***'+referenceNumber);
                 system.debug('fullfillmentOffer***'+fullfillmentOffer);
                if(referenceNumber != NULL && fullfillmentOffer != NULL){
                    Sip_MerchandizingOffers.CM_Fulfillment_Offer fulfillmentRequestBody = new Sip_MerchandizingOffers.CM_Fulfillment_Offer();
                    List<SIP_Transactions_line_item__c> transactionDetailsList = [SELECT    Id, 
                                                                                            Name, 
                                                                                            Merch_Fulfillment_Offer_ID__c,
                                                                                            SIP_Banking_Audit__r.Name,
                                                                                            Merch_Offer__c,
                                                                                            SIP_Cost__c,
                                                                                            Merch_Offer__r.Subproduct_Currency_Code__c,
                                                                                            EMD_Issue_Date__c,
                                                                                            EMD_Number__c
                                                                                FROM      SIP_Transactions_line_item__c 
                                                                                WHERE     SIP_Banking_Audit__r.Name =:referenceNumber];

                    Map<String, SIP_Transactions_line_item__c> mapOfferIdLineItem = new Map<String, SIP_Transactions_line_item__c>();
                    if(transactionDetailsList != NULL && !transactionDetailsList.isEmpty()){
                        for(SIP_Transactions_line_item__c record : transactionDetailsList){
                            mapOfferIdLineItem.put(record.Merch_Offer__c, record);
                        }  
                    }                                                     
                    
                    SI_Credit_Debit_Junction__c SICreditDebitJunctionRecord = [SELECT   Id, 
                                                                                        Sales_Instrument_Credit__r.End_Date__c,
                                                                                        Sales_Instrument_Debit__r.SIP_Banking_Audit__r.Name 
                                                                            FROM     SI_Credit_Debit_Junction__c 
                                                                            WHERE    RecordtypeId = :Sip_CommonConstant.RECORD_TYPE_FUND_SOURCE 
                                                                            AND      Sales_Instrument_Debit__r.SIP_Banking_Audit__r.Name =:referenceNumber LIMIT 1];
                    
                    String miscendDate = '';
                    if(SICreditDebitJunctionRecord != null && SICreditDebitJunctionRecord.Sales_Instrument_Credit__r.end_date__c != NULL){
                        miscendDate = String.Valueof(SICreditDebitJunctionRecord.Sales_Instrument_Credit__r.end_date__c);
                    }

                    if(fullfillmentOffer.Requester != NULL){
                        fulfillmentRequestBody.Requester = fullfillmentOffer.Requester;
                    }
                    if(fullfillmentOffer.ReservationReferences != NULL){
                        fulfillmentRequestBody.ReservationReferences = fullfillmentOffer.ReservationReferences;
                    }
                    if(fullfillmentOffer.FlightSegments != NULL && !fullfillmentOffer.FlightSegments.isEmpty()){
                        fulfillmentRequestBody.FlightSegments = new List<Sip_MerchandizingOffers.CM_FlightSegment_Fulfillment>();
                        for(Sip_MerchandizingOffers.VM_FlightSegment row : fullfillmentOffer.FlightSegments){
                            Sip_MerchandizingOffers.CM_FlightSegment_Fulfillment record = new Sip_MerchandizingOffers.CM_FlightSegment_Fulfillment();
                            record.ID = Integer.valueOf(row.ID);
                            record.DepartureAirport = row.DepartureAirport;
                            record.ArrivalAirport = row.ArrivalAirport;
                            record.DepartureDateTime = row.DepartureDateTime;
                            record.ArrivalDateTime = row.ArrivalDateTime;
                            record.FlightNumber = row.FlightNumber;
                            record.OperatingAirlineCode = row.OperatingAirlineCode;
                            fulfillmentRequestBody.FlightSegments.add(record);
                        }
                    }
                    if(fullfillmentOffer.Travelers != NULL && !fullfillmentOffer.Travelers.isEmpty()){
                        fulfillmentRequestBody.Travelers = new List<Sip_MerchandizingOffers.CM_Traveler_Fulfillment>();
                        for(Sip_MerchandizingOffers.VM_Traveler row : fullfillmentOffer.Travelers){
                            Sip_MerchandizingOffers.CM_Traveler_Fulfillment record = new Sip_MerchandizingOffers.CM_Traveler_Fulfillment();
                            record.ID = Integer.valueOf(row.TravelerID);
                            record.Surname = row.Surname;
                            record.GivenName = row.GivenName;
                            fulfillmentRequestBody.Travelers.add(record);
                        }
                    }
                    if(fullfillmentOffer.Products != NULL && !fullfillmentOffer.Products.isEmpty()){
                        List<Sip_MerchandizingOffers.CM_Product_Fulfillment> productList = new List<Sip_MerchandizingOffers.CM_Product_Fulfillment>();
                        List<Sip_MerchandizingOffers.CM_PaymentDetails_Fulfillment> offerPaymentDetailList = new List<Sip_MerchandizingOffers.CM_PaymentDetails_Fulfillment>();
                        for(Sip_MerchandizingOffers.VM_Product row : fullfillmentOffer.Products){
                            Sip_MerchandizingOffers.CM_Product_Fulfillment record = new Sip_MerchandizingOffers.CM_Product_Fulfillment();
                            record.ID = Integer.valueOf(row.ProductId); 
                            record.Code = row.ProductCode; 
                            List<Sip_MerchandizingOffers.CM_Offer_Fulfillment> offerList = new List<Sip_MerchandizingOffers.CM_Offer_Fulfillment>();
                            for(Sip_MerchandizingOffers.VM_Offer offerRow : row.Offers){
                                //Payment Details Section
                                if(mapOfferIdLineItem.containsKey(offerRow.subProductId)){
                                    Sip_MerchandizingOffers.CM_PaymentDetails_Fulfillment offerPaymentDetail = new Sip_MerchandizingOffers.CM_PaymentDetails_Fulfillment();
                                    Sip_MerchandizingOffers.CM_Miscellaneous_Fulfillment offerMisc = new Sip_MerchandizingOffers.CM_Miscellaneous_Fulfillment();
                                    offerMisc.MiscFopType = Sip_CommonConstant.EMD_MISC_FOP_TYPE;
                                    offerMisc.ExpirationDate = miscendDate;
                                    offerMisc.DocumentId = mapOfferIdLineItem.get(offerRow.subProductId).Name;
                                    offerMisc.AuditNumber = mapOfferIdLineItem.get(offerRow.subProductId).SIP_Banking_Audit__r.Name;
                                    offerMisc.AccountNumber = accountId;
                                    offerMisc.Amount = mapOfferIdLineItem.get(offerRow.subProductId).SIP_Cost__c;
                                    Sip_MerchandizingOffers.CM_Currenccy_Fulfillment offerMiscCurrency = new Sip_MerchandizingOffers.CM_Currenccy_Fulfillment();
                                    offerMiscCurrency.Code = mapOfferIdLineItem.get(offerRow.subProductId).Merch_Offer__r.Subproduct_Currency_Code__c;
                                    offerMisc.CurrencyTemp = offerMiscCurrency;
                                    Sip_MerchandizingOffers.CM_FormOfPayment_Fulfillment offerFormofPayment = new Sip_MerchandizingOffers.CM_FormOfPayment_Fulfillment();
                                    offerFormofPayment.Miscellaneous = offerMisc;
                                    offerPaymentDetail.FormOfPayment = offerFormofPayment;

                                    List<Sip_MerchandizingOffers.CM_Associations_Fulfillment> offerAssocList = new List<Sip_MerchandizingOffers.CM_Associations_Fulfillment>();
                                    Sip_MerchandizingOffers.CM_Associations_Fulfillment offerAssoc = new Sip_MerchandizingOffers.CM_Associations_Fulfillment();
                                    offerAssoc.OfferId = Integer.valueOf(mapOfferIdLineItem.get(offerRow.subProductId).Merch_Fulfillment_Offer_ID__c);
                                    offerAssoc.ProductID = Integer.valueOf(row.ProductId);
                                    offerAssocList.add(offerAssoc);
                                    offerPaymentDetail.Associations = offerAssocList;

                                    offerPaymentDetailList.add(offerPaymentDetail);
                                }
                                //
                                Sip_MerchandizingOffers.CM_Offer_Fulfillment offerRecord = new Sip_MerchandizingOffers.CM_Offer_Fulfillment();
                                offerRecord.GroupCode = offerRow.GroupCode; 
                                offerRecord.SubGroupCode = offerRow.SubGroupCode; 
                                offerRecord.Assocatiation = offerRow.association;

                                Sip_MerchandizingOffers.CM_PaymentOption_Fulfillment OfferPaymentOption = new Sip_MerchandizingOffers.CM_PaymentOption_Fulfillment(); 
                                OfferPaymentOption.Type = offerRow.PaymentOption.POType;
                                OfferPaymentOption.EDDCode = offerRow.PaymentOption.EDDCode;

                                List<Sip_MerchandizingOffers.CM_PriceComponent_Fulfillment> OfferPriceComponents = new List<Sip_MerchandizingOffers.CM_PriceComponent_Fulfillment>();
                                
                                for(Sip_MerchandizingOffers.VM_PriceComponent priceComponentRow : offerRow.PaymentOption.PriceComponents){
                                    Sip_MerchandizingOffers.CM_PriceComponent_Fulfillment recordOfferPriceComponents = new Sip_MerchandizingOffers.CM_PriceComponent_Fulfillment();
                                    Sip_MerchandizingOffers.CM_Price_Fulfillment offerPrice = new Sip_MerchandizingOffers.CM_Price_Fulfillment();

                                    List<Sip_MerchandizingOffers.CM_BasePrice_Fulfillment> offerBasePriceList = new List<Sip_MerchandizingOffers.CM_BasePrice_Fulfillment>();
                                    List<Sip_MerchandizingOffers.CM_Totals_Fulfillment> offerTotalsList = new List<Sip_MerchandizingOffers.CM_Totals_Fulfillment>();
                                    
                                    for(Sip_MerchandizingOffers.VM_BasePrice rowbasePrice : priceComponentRow.PCPrice.BasePrice){
                                        Sip_MerchandizingOffers.CM_BasePrice_Fulfillment recordOfferBasePrice = new Sip_MerchandizingOffers.CM_BasePrice_Fulfillment();
                                        recordOfferBasePrice.Amount = rowbasePrice.BasePriceAmount;
                                        recordOfferBasePrice.Type = rowbasePrice.BasePriceType;
                                        Sip_MerchandizingOffers.CM_Currency_Fulfillment offerCurrencyFulfillment = new Sip_MerchandizingOffers.CM_Currency_Fulfillment();
                                        offerCurrencyFulfillment.Code = rowbasePrice.CurrencyTemp.Code;
                                        recordOfferBasePrice.CurrencyTemp = offerCurrencyFulfillment;
                                        offerBasePriceList.add(recordOfferBasePrice);
                                    }
                                    for(Sip_MerchandizingOffers.VM_Totals rowTotals : priceComponentRow.PCPrice.Totals){
                                        Sip_MerchandizingOffers.CM_Totals_Fulfillment recordOfferTotals = new Sip_MerchandizingOffers.CM_Totals_Fulfillment();
                                        recordOfferTotals.Amount = rowTotals.TotalsAmount;
                                        recordOfferTotals.Type = rowTotals.TotalsType;
                                        Sip_MerchandizingOffers.CM_Currency_Fulfillment offerCurrencyFulfillment = new Sip_MerchandizingOffers.CM_Currency_Fulfillment();
                                        offerCurrencyFulfillment.Code = rowTotals.CurrencyTemp.Code;
                                        recordOfferTotals.CurrencyTemp = offerCurrencyFulfillment;
                                        offerTotalsList.add(recordOfferTotals);
                                    }
                                    if(offerBasePriceList != NULL && !offerBasePriceList.isEmpty()){
                                        offerPrice.BasePrice = offerBasePriceList;
                                    }
                                    if(offerTotalsList != NULL && !offerTotalsList.isEmpty()){
                                        offerPrice.Totals = offerTotalsList;
                                    }
                                    recordOfferPriceComponents.Price = offerPrice;
                                    OfferPriceComponents.add(recordOfferPriceComponents);
                                }
                                OfferPaymentOption.PriceComponents = OfferPriceComponents;
                                offerRecord.PaymentOption = OfferPaymentOption;
                                if(mapOfferIdLineItem.containsKey(offerRow.subProductId)){
                                    offerRecord.ID = Integer.valueOf(mapOfferIdLineItem.get(offerRow.subProductId).Merch_Fulfillment_Offer_ID__c);
                                }
                                //offerRecord.ID; 
                                offerList.add(offerRecord);
                            }
                            List<Sip_MerchandizingOffers.CM_Parameters_Fulfillment> offerParameters = new List<Sip_MerchandizingOffers.CM_Parameters_Fulfillment>();
                            for(Sip_MerchandizingOffers.VM_Parameters offerRow : row.Parameters){
                                Sip_MerchandizingOffers.CM_Parameters_Fulfillment recordParameters = new Sip_MerchandizingOffers.CM_Parameters_Fulfillment();
                                recordParameters.Name = offerRow.ParameterName;
                                recordParameters.Value = offerRow.ParameterValue;
                                offerParameters.add(recordParameters);
                            }
                            record.Offers = offerList;
                            record.Parameters = offerParameters;
                            productList.add(record);
                        }
                        Sip_MerchandizingOffers.CM_Cart_Fulfillment offerCart = new Sip_MerchandizingOffers.CM_Cart_Fulfillment();
                        offerCart.Products = productList;

                        Sip_MerchandizingOffers.CM_Payment_Fulfillment offerPayment = new Sip_MerchandizingOffers.CM_Payment_Fulfillment();
                        offerPayment.PaymentDetails = offerPaymentDetailList;

                        Sip_MerchandizingOffers.CM_PurchaseDetail_Fulfillment offerPurchaseDetail = new Sip_MerchandizingOffers.CM_PurchaseDetail_Fulfillment();
                        offerPurchaseDetail.Cart = offerCart;
                        offerPurchaseDetail.Payment = offerPayment;
                        fulfillmentRequestBody.PurchaseDetail = offerPurchaseDetail;
                        
                    }
                    
                    String requestBody = JSON.serialize(fulfillmentRequestBody);
                    requestBody = requestBody.replace('"CurrencyTemp"', '"Currency"');
                    
                    Sip_HttpUtil.CalloutInfoWrapper offerCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                    offerCalloutInfo.requestBodyInJson = requestBody;
                    offerCalloutInfo.integrationType = 'MerchFulfillment';
                    offerCalloutInfo.oauthType = 'SIP OAuth';
                    offerCalloutInfo.headers = null;
                    offerCalloutInfo.logInformation = 'Get Purchase Details';
                    offerCalloutInfo.actionDescription = 'Get Purchase Details';
                    offerCalloutInfo.logMessage = '';
                    offerCalloutInfo.serviceName = 'Purchase';
                    offerCalloutInfo.serviceMethod = 'PurchaseProducts';
                    offerCalloutInfo.contextClass = className;
                    offerCalloutInfo.contextMethod = methodName;

                    Sip_HttpUtil h = new Sip_HttpUtil (offerCalloutInfo);
                    system.debug('Request***');
                    HTTPResponse htttpRes = h.callout();
                        
                    String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                    system.debug('resAfterHttpValidation***'+resAfterHttpValidation);
                    Sip_MerchandizingOffers.CM_Fulfillment_Response issuePASResponse = (Sip_MerchandizingOffers.CM_Fulfillment_Response) JSON.deserialize(resAfterHttpValidation, Sip_MerchandizingOffers.CM_Fulfillment_Response.class);
                    System.debug('issuePASResponse'+issuePASResponse);

                    if(issuePASResponse.Response.Error != NULL && !issuePASResponse.Response.Error.isEmpty()){
                        Sip_MerchandizingOffers.VM_MerchandizingOffers obj = new Sip_MerchandizingOffers.VM_MerchandizingOffers();
                        obj.success = false;
                        obj.messages.add('Fulfilment Service Error');
                        log.flush();
                        return obj;
                    }

                    Map<String, Map<String, String>> mapOfferIdEDD = new Map<String, Map<String, String>>();
                    if(issuePASResponse.Confirmations != NULL && !issuePASResponse.Confirmations.isEmpty()){
                        for(Sip_MerchandizingOffers.CM_Confirmations_Response row : issuePASResponse.Confirmations){
                            if(row.Error != NULL && !row.Error.isEmpty() && row.Associations != NULL && !row.Associations.isEmpty()){
                                Sip_MerchandizingOffers.CM_Errors_Response errorResponse = row.Error[0];
                                if(errorResponse.Description != NULL && errorResponse.Description == 'SUCCESS'){
                                    Sip_MerchandizingOffers.CM_Associations_Response associationsResponse = row.Associations[0];
                                    Map<String,String> mapEDDKeyValue = new Map<String,String>();
                                    mapEDDKeyValue.put('EDDIssueDate',row.EDDIssueDate);
                                    mapEDDKeyValue.put('EDDConfirmationNumber',row.EDDConfirmationNumber);
                                    mapEDDKeyValue.put('EDDStatus','H');//Waiting for Merchindizing team to send
                                    mapOfferIdEDD.put(associationsResponse.OfferID, mapEDDKeyValue);
                                }
                            }
                        }
                    }
                    if(transactionDetailsList != NULL && !transactionDetailsList.isEmpty() && mapOfferIdEDD.values() != NULL && !mapOfferIdEDD.values().isEmpty()){
                        for(SIP_Transactions_line_item__c record : transactionDetailsList){
                            if(record.Merch_Fulfillment_Offer_ID__c != NULL && mapOfferIdEDD.containsKey(record.Merch_Fulfillment_Offer_ID__c)){
                                Map<String, String> mapEDD = mapOfferIdEDD.get(record.Merch_Fulfillment_Offer_ID__c);
                                if(mapEDD.values() != NULL && !mapEDD.values().isEmpty()){
                                    if(mapEDD.containsKey('EDDConfirmationNumber')){
                                        record.EMD_Number__c = mapEDD.get('EDDConfirmationNumber');
                                    }
                                    if(mapEDD.containsKey('EDDIssueDate')){
                                        String eddDate = mapEDD.get('EDDIssueDate');
                                        String[] strDTDivided = eddDate.split(' ');
                                        String[] dateval = strDTDivided[0].split('/');
                                        string month = dateval.get(0);
                                        string day = dateval.get(1).replace(',', '');
                                        string year = dateval.get(2);
                                        String stringDate = month + '/' + day + '/' + year;
                                        record.EMD_Issue_Date__c = Date.parse(stringDate);
                                    }
                                    if(mapEDD.containsKey('EDDStatus')){
                                        record.EMD_Status__c = mapEDD.get('EDDStatus');
                                    }
                                }
                            }
                        }
                        update transactionDetailsList;
                    }
                    return null;
                }
                return null;
            }catch(Exception ex){
                System.debug('Exception :: '+ ex.getStackTraceString());
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_MerchandizingOffers.VM_MerchandizingOffers obj = new Sip_MerchandizingOffers.VM_MerchandizingOffers();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return obj;
            }
        }
    }
    
    //To be Uploaded Enrollment
    @RemoteAction
    //20181122 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
    // global static Sip_RemotingResultAbstract submitUCMEnrollment (Sip_Subscription.VM_Subscription subscriptionInfo, String payerId, String beneficiaryId, String callerId, String comments, String userId, Decimal totalCost, String pendingAmountObjId) {
    // global static Sip_RemotingResultAbstract submitUCMEnrollment (Sip_Subscription.VM_Subscription subscriptionInfo, String payerId, String beneficiaryId, String callerId, String comments, String userId, Decimal totalCost, String pendingAmountObjId, List<String> agreements, String deduct) {
     //20181212 update,paymentdata means: front-end payment data detail ,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'} 
    global static Sip_RemotingResultAbstract submitUCMEnrollment (Sip_Subscription.VM_Subscription subscriptionInfo, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId, Sip_PaymentDataViewModel paymentdata, String deduct) {
        String methodName = 'submitUCMEnrollment'; 
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
    //2020 Security issue fix
        if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userID)) { 
            Sip_SessionCacheManager.insertGEHError(className + '.submitUCMEnrollment', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId); 
            return null;
        }
        //Shivani added for amenity
        if (Sip_RemoteSecurityUtil.isPassPlusIndividualUser(userId, 'Sip_AmenityController', methodName)) {
            return null;
        } 

        //20200925 rwern QuickAmenitySecurityFix
        // pass the userId, payerId, methodName, isGS
        if (!Sip_RemoteSecurityUtil.isValidFunds(userID, payerId, methodName, false)) {
            return null;
        } 

        else{
        //End
            Boolean isAmountAdded = false;
            try {
                Sip_SessionCacheManager managerObj = new Sip_SessionCacheManager ();
                //2020 Security issue fix
                if(!Test.isRunningTest() && !managerObj.validateAmenityAcountId(payerId)) { 
                    Sip_SessionCacheManager.insertGEHError(className + '.submitUCMEnrollment', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
                    return null;
                }
                //Hard code the price as 118 for POC. Will have a methods to calculate the total cost: calculateOTP()
                else if(!Test.isRunningTest() && !managerObj.validatePendingAmount('Membership', pendingAmountObjId, payerId)) {
                    Sip_SessionCacheManager.insertGEHError(className + '.submitUCMEnrollment', 'Sip_SessionCacheManager', 'validatePendingAmount', userID, payerId);
                    return null;
                }else {
                Sip_UCMEnrollment ucmEnrollmentMedelObj = new Sip_UCMEnrollment();
                // if (!Sip_CommonUtility.validateAccountBalance(payerId, totalCost)) {
                //     Sip_CommonUtility.generateInsufficientFundError(ucmEnrollmentMedelObj.vUCMEnrollment);
                //     return ucmEnrollmentMedelObj.vUCMEnrollment;
                // }
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);

                Sip_UCMEnrollment.UCMEnrollmentServiceRequestBody requestBodyToUCM = new Sip_UCMEnrollment.UCMEnrollmentServiceRequestBody ();
                requestBodyToUCM.Requester.Requestor.ChannelName = Sip_CommonConstant.CHANNELNAMEFORSUBSERVER;
                requestBodyToUCM.Requester.Requestor.ChannelID = Sip_CommonConstant.CHANNELIDFORSUBSERVER;
                requestBodyToUCM.Requester.Requestor.LanguageCode = Sip_CommonConstant.LANGUAGECODEFORSUBSERVER;
                requestBodyToUCM.Requester.Requestor.CRSCode = Sip_UCMEnrollment.generateCRSCode(userId);
                //Filter Component TBD with Karan
                Sip_UCMEnrollment.CM_Filter ucmFilterItem = new Sip_UCMEnrollment.CM_Filter ();
                ucmFilterItem.ProductCode = Sip_CommonConstant.PRODUCTCODEFORSUBSERVER;
                requestBodyToUCM.Filters.add(ucmFilterItem);

                Sip_UCMEnrollment.CM_Travelers ucmTravelerItem = new Sip_UCMEnrollment.CM_Travelers ();
                ucmTravelerItem.Surname = subscriptionInfo.LastName;
                ucmTravelerItem.GivenName = subscriptionInfo.FirstName;
                Sip_UCMEnrollment.CM_Characteristics cmCharacteristics = new Sip_UCMEnrollment.CM_Characteristics ();
                cmCharacteristics.Code = 'SIID';
                cmCharacteristics.Value = Sip_CommonUtility.returnGUID();
                ucmTravelerItem.Characteristics.add(cmCharacteristics); //TBD With Karan
                ucmTravelerItem.LoyaltyProgramProfile.LoyaltyProgramMemberID = subscriptionInfo.MileagePlusNumber;

                Sip_UCMEnrollment.CM_Subscriptions ucmSubscriptionsItem = new Sip_UCMEnrollment.CM_Subscriptions ();

                ucmSubscriptionsItem.EffectiveDate = subscriptionInfo.NewEffectiveDate;
                ucmSubscriptionsItem.ExpirationDate = subscriptionInfo.NewExpiryDate;
                //Shivani REQ-0877
                if(Date.valueOf(subscriptionInfo.NewEffectiveDate) > System.Today()){
                    Date activationdate = System.Today() > Date.valueOf(subscriptionInfo.NewEffectiveDate)-3 ? System.Today() : Date.valueOf(subscriptionInfo.NewEffectiveDate)-3;
                    ucmSubscriptionsItem.ActivationDate = String.valueOf(activationdate);
                }

                ucmTravelerItem.Subscriptions.add(ucmSubscriptionsItem);
                requestBodyToUCM.Travelers.add(ucmTravelerItem);

                String requestBodyInJson = JSON.serialize(requestBodyToUCM);
                Sip_HttpUtil.CalloutInfoWrapper subsCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                subsCalloutInfo.requestBodyInJson = requestBodyInJson;
                subsCalloutInfo.integrationType = 'CreatePromoSub';
                subsCalloutInfo.oauthType = 'SIP OAuth';
                subsCalloutInfo.headers = null;
                subsCalloutInfo.logInformation = 'Submit UCM Enrollment For the United Club';
                subsCalloutInfo.actionDescription = 'Submit UCM Enrollment For the United Club';
                subsCalloutInfo.logMessage = '';
                subsCalloutInfo.serviceName = 'PromoSub';
                subsCalloutInfo.serviceMethod = 'CreatePromoSub';
                subsCalloutInfo.contextClass = className;
                subsCalloutInfo.contextMethod = methodName;

                Sip_HttpUtil h = new Sip_HttpUtil (subsCalloutInfo);
                HTTPResponse htttpRes = h.callout();
                //201706013 TBD Added amount 
                // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                //20170619 TBD delete pending amount after call out
                Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                isAmountAdded = true;

                String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                // String resAfterHttpValidation = '{"Response": {"Error": [{"Code": "4000", "ErrorType": "Major", "Text": "Generic Subscription exception"}, {"Code": "1003", "ErrorType": "Minor", "Text": "Subscription exists :: SUB-CL-0AA-001 (6/21/2016 12:00:00 AM)(11/30/2077 11:59:59 PM)(SCL_SUB_PROMO)"}], "GUIDs": [{"Name": "TRANSACTIONID", "ID": "1495633503151010086025043297081"}], "TransactionID": "1495633503151010086025043297081"}}';

                
                if (resAfterHttpValidation.equals(Label.Sip_Common_Error) ) {
                    String errorMsg = Label.Sip_Common_Error;
                    ucmEnrollmentMedelObj.success = false;
                    ucmEnrollmentMedelObj.messages.add(errorMsg);
                    log.flush();
                    return ucmEnrollmentMedelObj.getViewModel();
                }
                ucmEnrollmentMedelObj.parseGetSubscriptionInfo(resAfterHttpValidation);
                //20170614 user management info
                ucmEnrollmentMedelObj.validateUCMResponse (userInfoModel, userManagementInfo);
                //20170421: Shan. Consider Purchase Success as long as response has membership 
                ucmEnrollmentMedelObj.popluateUCMEnrollmentViewModel(subscriptionInfo);

                if (ucmEnrollmentMedelObj.success) {

                    // ucmEnrollmentMedelObj.vUCMEnrollment.transactionNumber = ucmEnrollmentMedelObj.commitTransaction2(payerId, beneficiaryId, comments, userId, ucmEnrollmentMedelObj.vUCMEnrollment, subscriptionInfo, cmCharacteristics.Value, cmCharacteristics.Value, callerId);
                    // ucmEnrollmentMedelObj.vUCMEnrollment.transactionNumber = ucmEnrollmentMedelObj.commitTransaction2(payerId, beneficiaryId, comments, userId, ucmEnrollmentMedelObj.vUCMEnrollment, subscriptionInfo, cmCharacteristics.Value, cmCharacteristics.Value, callerId, agreements, deduct);
                    //20181217 update,paymentdata means: front-end payment data detail,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'}
                    ucmEnrollmentMedelObj.vUCMEnrollment.transactionNumber = ucmEnrollmentMedelObj.commitTransaction2(payerId, beneficiaryId, comments, userId, ucmEnrollmentMedelObj.vUCMEnrollment, subscriptionInfo, cmCharacteristics.Value, cmCharacteristics.Value, callerId, paymentdata, deduct);

                    // System.debug(LoggingLevel.INFO, '*** ucmEnrollmentMedelObj.vUCMEnrollment: ' + ucmEnrollmentMedelObj.vUCMEnrollment);
                }
                log.flush();
                    //2020 Security issue fix
                    Sip_SensitiveInfoManagement sensitiveInfoManageObj = new Sip_SensitiveInfoManagement(ucmEnrollmentMedelObj.getViewModel(), Sip_UCMEnrollment.VM_UCMEnrollment.class, false, Sip_SensitiveInfoManagement.VM_UCMEnrollment_SensitiveInfo_FieldMap);
                    Sip_UCMEnrollment.VM_UCMEnrollment vUCMEnrollment = (Sip_UCMEnrollment.VM_UCMEnrollment)sensitiveInfoManageObj.encryptSensitiveInfo();
                    //2020 Security issue fix
                    return vUCMEnrollment;
                    // return ucmEnrollmentMedelObj.getViewModel();
                }
            } catch (Exception ex) {
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_UCMEnrollment ucmEnrollmentMedelObj = new Sip_UCMEnrollment();
                ucmEnrollmentMedelObj.success = false;
                ucmEnrollmentMedelObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                //20170613 Added amount back if it is not added 
                if (!isAmountAdded) {
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //20170619 TBD delete pending amount after call out
                Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                }
                return ucmEnrollmentMedelObj.getViewModel();
            }
        }
    }

    @RemoteAction
    //20181031 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
    /*global static Sip_RemotingResultAbstract retrieveIssuePassWithMP(Sip_PremierQualification.VM_PremierQualification premierQual ,Sip_IssuePass.CM_requestInfoToIssuePassFromUI requestInfoFromUI,
            Sip_PassDetails.VM_PassDetail passDetail, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId){*/
    // global static Sip_RemotingResultAbstract retrieveIssuePassWithMP(Sip_PremierQualification.VM_PremierQualification premierQual ,Sip_IssuePass.CM_requestInfoToIssuePassFromUI requestInfoFromUI,
    //         Sip_PassDetails.VM_PassDetail passDetail, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId, List<String> agreements, String deduct){
    //20181212 update,paymentdata means: front-end payment data detail,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'}
     global static Sip_RemotingResultAbstract retrieveIssuePassWithMP(Sip_PremierQualification.VM_PremierQualification premierQual ,Sip_IssuePass.CM_requestInfoToIssuePassFromUI requestInfoFromUI,
            Sip_PassDetails.VM_PassDetail passDetail, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId, Sip_PaymentDataViewModel paymentdata, String deduct){
            String methodName = 'retrieveIssuePass';
            
            //Add by Crystal 11/26/2018
            if (!Sip_CommonUtility.isLoginUser()) {
                return null;
            }
      //2020 Security issue fix
            else if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userID)) {
                Sip_SessionCacheManager.insertGEHError(className + '.retrieveIssuePassWithMP', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
                return null;
            }
            //Shivani added for amenity
            if (Sip_RemoteSecurityUtil.isPassPlusIndividualUser(userId, 'Sip_AmenityController', methodName)) {
                return null;
            } 

            //20200925 rwern QuickAmenitySecurityFix
            // pass the userId, payerId, methodName, isGS
            if (!Sip_RemoteSecurityUtil.isValidFunds(userID, payerId, methodName, false)) {
                return null;
            } 
            else{
            //End
                
                Boolean isAmountAdded = false;
                try{
                    //2020 Security issue fix
                    Integer quantity = String.isNotBlank(passDetail.NumberOfPasses) ? Integer.valueOf(passDetail.NumberOfPasses) : 0;
                    Sip_SessionCacheManager managerObj = new Sip_SessionCacheManager ();
                    if(!Test.isRunningTest() && !managerObj.validateAmenityAcountId(payerId)) { 
                        Sip_SessionCacheManager.insertGEHError(className + '.retrieveIssuePassWithMP', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
                        return null;
                    //Hard code the price as 118 for POC. Will have a methods to calculate the total cost: calculateOTP()
                    }else if(!Test.isRunningTest() && !managerObj.validatePendingAmount(new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper('OTP', quantity), pendingAmountObjId, payerId)) {
                        Sip_SessionCacheManager.insertGEHError(className + '.retrieveIssuePassWithMP', 'Sip_SessionCacheManager', 'validatePendingAmount', userID, payerId);
                        return null;
                    }else {
                        //2020 Security issue fix
                        if (!Test.isRunningTest()) {
                            passDetail.EdocIdList = managerObj.getEdocIdList();
                        }
                        
                    //20170608 Fund balance check before purchase
                    Sip_IssuePass issuePassobj = new Sip_IssuePass();
                    //20170608 Fund balance check before purchase
                    // if (!Sip_CommonUtility.validateAccountBalance(payerId, totalCost)) {
                    //     Sip_CommonUtility.generateInsufficientFundError(issuePassobj.vIssuePass);
                    //     return issuePassobj.vIssuePass;
                    // }

                    Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                    Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                    SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);
                    Sip_IssuePass.IssuePassRequestBodyWithMP requestBody = Sip_IssuePass.constructReqBodyOfIssuePassServiceWithMP(requestInfoFromUI, passDetail, userID);
                    String amentityIssuePassBodyInJson = Json.serialize(requestBody);

                    Sip_HttpUtil.CalloutInfoWrapper issuePassCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper();
                    issuePassCalloutInfo.requestBodyInJson = amentityIssuePassBodyInJson;
                    issuePassCalloutInfo.integrationType = 'IssuePass'; //TBD
                    issuePassCalloutInfo.oauthType = 'SIP OAuth';
                    issuePassCalloutInfo.headers = null;
                    issuePassCalloutInfo.logInformation = 'Get Issue Pass';
                    issuePassCalloutInfo.actionDescription = 'Get Issue Pass';
                    issuePassCalloutInfo.logMessage = '';
                    issuePassCalloutInfo.serviceName = 'OneTimePass'; //TBD
                    issuePassCalloutInfo.serviceMethod = 'IssuePass'; //TBD
                    issuePassCalloutInfo.contextClass = className;
                    issuePassCalloutInfo.contextMethod = methodName;

                    Sip_HttpUtil h = new Sip_HttpUtil (issuePassCalloutInfo);
                    HTTPResponse htttpRes = h.callout();
                    //201706013 TBD Added amount
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //20170619 TBD delete pending amount after call out 
                    Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                    isAmountAdded = true;
                     
                    String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                    if (resAfterHttpValidation.equals(Label.Sip_Common_Error)) {
                        String errorMsg = Label.Sip_Common_Error;
                        //To Ivy    
                        issuePassobj.success = false;
                        issuePassobj.messages.add(errorMsg);
                        log.flush();
                        return issuePassobj.getViewModel();
                    }
                    issuePassobj.parsePasDetailInfo(resAfterHttpValidation);
                    issuePassobj.populateIssuePassViewModel();
                    
                    //20170614 check user permission for error msg
                    issuePassobj.validateIussePassResponse(userInfoModel, userManagementInfo);
                    if (issuePassobj.success) {
                        //20170609 TBD Added amount 
                        // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                        // issuePassobj.commitTransaction(payerId, 1,beneficiaryId,comments);
                        //20170509 Shan Commit Transaction 
                            //2020 Security issue fix
                            // Integer quantity = String.isNotBlank(passDetail.NumberOfPasses) ? Integer.valueOf(passDetail.NumberOfPasses) : 0;
                        //20181031 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
                        // issuePassobj.vIssuePass.transactionNumber =  issuePassobj.commitTransaction(payerId,quantity, beneficiaryId, userId,comments, passDetail.EdocIdList, issuePassobj.vIssuePass.transactionIdFromIssuePass, passDetail ,premierQual, callerId, userInfoModel, agreements, deduct);
                        // issuePassobj.vIssuePass.transactionNumber =  issuePassobj.commitTransaction(payerId,quantity, beneficiaryId, userId,comments, passDetail.EdocIdList, issuePassobj.vIssuePass.transactionIdFromIssuePass, passDetail ,premierQual, callerId, userInfoModel);
                        //20181212 update,paymentdata means: front-end payment data detail,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'}
                        issuePassobj.vIssuePass.transactionNumber =  issuePassobj.commitTransaction(payerId,quantity, beneficiaryId, userId,comments, passDetail.EdocIdList, issuePassobj.vIssuePass.transactionIdFromIssuePass, passDetail ,premierQual, callerId, userInfoModel,paymentdata, deduct);

                    }
                    log.flush();
                    return issuePassobj.getViewModel();
                    //obj.validatePassDetails();
                    }
                }catch(Exception ex){
                    //20190130 lijuna update,comment out debug
                    /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                    System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                    System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                    System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/

                    log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                    
                    Sip_IssuePass issuePassobj = new Sip_IssuePass();
                    issuePassobj.success = false;
                    issuePassobj.messages.add(Label.Sip_Common_Error);
                    log.flush();
                    //20170613 Added amount back if it is not added 
                    if (!isAmountAdded) {
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //20170619 TBD delete pending amount after call out
                    Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);

                    }
                    return issuePassobj.getViewModel();
                }
            }
    }

    //20181029 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
    @RemoteAction
    // global static Sip_RemotingResultAbstract retrieveIssuePassWithoutMP (Sip_PassDetails.VM_PassDetail passDetail, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId) {
    // global static Sip_RemotingResultAbstract retrieveIssuePassWithoutMP (Sip_PassDetails.VM_PassDetail passDetail, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId, List<String> agreements, String deduct) {
    //20181212 update, paymentdata means: front-end payment data detail,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'}
    global static Sip_RemotingResultAbstract retrieveIssuePassWithoutMP (Sip_PassDetails.VM_PassDetail passDetail, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId, Sip_PaymentDataViewModel paymentdata, String deduct) {
        String methodName = 'retrieveIssuePass';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        
        //Shivani added for amenity
        if (Sip_RemoteSecurityUtil.isPassPlusIndividualUser(userId, 'Sip_AmenityController', methodName)) {
            return null;
        } 

        //20200925 rwern QuickAmenitySecurityFix
        // pass the userId, payerId, methodName, isGS
        if (!Sip_RemoteSecurityUtil.isValidFunds(userID, payerId, methodName, false)) {
            return null;
        } 

        else{
        //End
            
            Boolean isAmountAdded = false;
            try{
                Sip_SessionCacheManager managerObj = new Sip_SessionCacheManager ();
            //2020 Security issue fix
            Integer quantity = String.isNotBlank(passDetail.NumberOfPasses) ? Integer.valueOf(passDetail.NumberOfPasses) : 0;
            if (!Sip_RemoteSecurityUtil.isValidUserId(userID)) {
                Sip_SessionCacheManager.insertGEHError(className + '.retrieveIssuePassWithoutMP', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
                return null;
            }
            // //2020 Security issue fix
            else if(!Test.isRunningTest() && !managerObj.validateAmenityAcountId(payerId)) { 
                Sip_SessionCacheManager.insertGEHError(className + '.retrieveIssuePassWithoutMP', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
                return null;
            //Hard code the price as 118 for POC. Will have a methods to calculate the total cost: calculateOTP()
            }else if(!Test.isRunningTest() && !managerObj.validatePendingAmount(new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper('OTP', quantity), pendingAmountObjId, payerId)) {
                Sip_SessionCacheManager.insertGEHError(className + '.retrieveIssuePassWithoutMP', 'Sip_SessionCacheManager', 'validatePendingAmount', userID, payerId);
                return null;
            }
            else {
                //2020 Security issue fix
                if (!Test.isRunningTest()) {
                    passDetail.EdocIdList = managerObj.getEdocIdList();
                }
                //20170608 Fund balance check before purchase
                Sip_IssuePass issuePassobj = new Sip_IssuePass();
                // if (!Sip_CommonUtility.validateAccountBalance(payerId, totalCost)) {
                //     Sip_CommonUtility.generateInsufficientFundError(issuePassobj.vIssuePass);
                //     return issuePassobj.vIssuePass;
                // }
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);
                Sip_IssuePass.IssuePassRequestBodyWithoutMP requestBody = Sip_IssuePass.constructReqBodyOfIssuePassServiceWithOutMP(passDetail, userID);
                String amentityIssuePassBodyInJson = Json.serialize(requestBody);

                Sip_HttpUtil.CalloutInfoWrapper issuePassCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper();
                issuePassCalloutInfo.requestBodyInJson = amentityIssuePassBodyInJson;
                issuePassCalloutInfo.integrationType = 'IssuePass'; 
                issuePassCalloutInfo.oauthType = 'SIP OAuth';
                issuePassCalloutInfo.headers = null;
                issuePassCalloutInfo.logInformation = 'Get Issue Pass';
                issuePassCalloutInfo.actionDescription = 'Get Issue Pass';
                issuePassCalloutInfo.logMessage = '';
                issuePassCalloutInfo.serviceName = 'OneTimePass'; //TBD
                issuePassCalloutInfo.serviceMethod = 'IssuePass'; //TBD
                issuePassCalloutInfo.contextClass = className;
                issuePassCalloutInfo.contextMethod = methodName;

                Sip_HttpUtil h = new Sip_HttpUtil (issuePassCalloutInfo);
                HTTPResponse htttpRes = h.callout();

                //201706013 TBD Added amount 
                // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                //20170619 TBD delete pending amount after call out
                
                Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                isAmountAdded = true;
                String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                // String resAfterHttpValidation = '{"Error": [{"Code": "41008.01", "Description": "[65059] : The passcode is already issued. Please provide different Edoc ID to generate again. ", "Text": "[65059] : The passcode is already issued. Please provide different Edoc ID to generate again. "}, {"Code": "41008.01", "Description": "[65041] : No pass was issued.  ", "Text": "[65041] : No pass was issued.  "}], "Version": null, "LanguageCode": null, "Exception": {"Code": "41008.01", "Source": ".Net SqlClient Data Provider", "Message": "Cannot insert duplicate key row in object \'dbo.OneTimeProfile\' with unique index \'ix_OneTimeProfile_PassCode\'. The duplicate key value is (88888803242017).\r\nThe statement has been terminated.", "DisplayError": ["Cannot insert duplicate key row in object \'dbo.OneTimeProfile\' with unique index \'ix_OneTimeProfile_PassCode\'. The duplicate key value is (88888803242017).\r\nThe statement has been terminated.", ".Net SqlClient Data Provider", "   at United.UClub.DbLib.Imp.OneTimePassService2.IssueOneTimePass(OneTimePassRequest oneTimePassRequest)\r\n   at United.UClub.Web.Api.Controllers.OneTimePassController.IssuePass(OneTimePassRequest passRequest)"]}, "ResponseCode": "IssuePass", "MachineName": "VCLD16GTAGPWS01", "CallDuration": 0, "ActivityDate": "2017-03-24T18:07:57.3439702-05:00", "TransactionId": null, "UnitedClubPass": []}';
                if (resAfterHttpValidation.equals(Label.Sip_Common_Error)) {
                    issuePassobj.success = false;
                    issuePassobj.messages.add(Label.Sip_Common_Error);
                    log.flush();
                    return issuePassobj.getViewModel();
                }
                issuePassobj.parsePasDetailInfo(resAfterHttpValidation);
                issuePassobj.populateIssuePassViewModel();
                
                //20170614 check user permission for error msg
                issuePassobj.validateIussePassResponse(userInfoModel, userManagementInfo);
                if (issuePassobj.success) {
                    //20170609 TBD Added amount 
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //2020 Security issue fix
                    // Integer quantity = String.isNotBlank(passDetail.NumberOfPasses) ? Integer.valueOf(passDetail.NumberOfPasses) : 0;
                    
                    //20181029 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
                    // issuePassobj.vIssuePass.transactionNumber =  issuePassobj.commitTransaction(payerId,quantity, beneficiaryId, userId,comments, requestBody.PassRequest.EdocIds, issuePassobj.vIssuePass.transactionIdFromIssuePass, passDetail ,null, callerId, userInfoModel, agreements, deduct);
                    // issuePassobj.vIssuePass.transactionNumber =  issuePassobj.commitTransaction(payerId,quantity, beneficiaryId, userId,comments, requestBody.PassRequest.EdocIds, issuePassobj.vIssuePass.transactionIdFromIssuePass, passDetail ,null, callerId, userInfoModel);

                    //20181212 update ,paymentdata means: front-end payment data detail,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'}
                    issuePassobj.vIssuePass.transactionNumber =  issuePassobj.commitTransaction(payerId,quantity, beneficiaryId, userId,comments, requestBody.PassRequest.EdocIds, issuePassobj.vIssuePass.transactionIdFromIssuePass, passDetail ,null, callerId, userInfoModel, paymentdata, deduct);

                    //20170621 save email history 
                    Sip_CommonUtility.insertEmailAddressAmenity (issuePassobj.vIssuePass.transactionNumber, passDetail.Email);
                }
                log.flush();
                return issuePassobj.getViewModel();
            }
            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/

                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                
                Sip_IssuePass issuePassobj = new Sip_IssuePass();
                issuePassobj.success = false;
                issuePassobj.messages.add(Label.Sip_Common_Error);
                log.flush();
                //20170613 Added amount back if it is not added 
                if (!isAmountAdded) {
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //20170619 TBD delete pending amount after call out
                    Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                }
                return issuePassobj.getViewModel();
            }
        }
    }

    @RemoteAction
    global static Sip_PassDetails.VM_PassDetail getPassDetail(Sip_PassDetails.CM_RequestInfoToRetrievePassFromUI requestInfoFromUI, Sip_Subscription.VM_Subscription subscriptionInfo, String accountId){
        String methodName = 'getPassDetail';
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(requestInfoFromUI.userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getPassDetail', 'Sip_RemoteSecurityUtil', 'isValidUserId', requestInfoFromUI.userId, accountId);
            return null;
        } else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(accountId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getPassDetail', 'Sip_SessionCacheManager', 'validateAmenityAcountId', requestInfoFromUI.userId, accountId);
            return null;
        }
        else{
        //End
            try{
                //20170606
                Sip_UserInfo userInfoItem = new Sip_UserInfo(requestInfoFromUI.userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(requestInfoFromUI.userId);
                //20170523 Shan Added status field into Req body
                Sip_PassDetails.CM_RetrievePassDetailsRequestBody passDetailsServiceReqBody = Sip_PassDetails.constructOTPReq(subscriptionInfo);
                String requestBodyInJSON = JSON.serialize(passDetailsServiceReqBody);
                Sip_HttpUtil.CalloutInfoWrapper passDetailsCalloutInfoWrapper = new Sip_HttpUtil.CalloutInfoWrapper();
                passDetailsCalloutInfoWrapper.requestBodyInJson = requestBodyInJSON;
                passDetailsCalloutInfoWrapper.integrationType = 'RetrievePassDetail';
                passDetailsCalloutInfoWrapper.oauthType = 'SIP OAuth';
                passDetailsCalloutInfoWrapper.headers=null;
                passDetailsCalloutInfoWrapper.logInformation = 'Retrieve Pass Details';
                passDetailsCalloutInfoWrapper.actionDescription ='Retrieve Pass Details';
                passDetailsCalloutInfoWrapper.logMessage = '';
                passDetailsCalloutInfoWrapper.serviceName = 'OneTimePass';
                passDetailsCalloutInfoWrapper.contextClass = 'RetrievePassDetail';
                passDetailsCalloutInfoWrapper.contextMethod = methodName;

                Sip_HttpUtil h = new Sip_HttpUtil(passDetailsCalloutInfoWrapper);
                HttpResponse httpResp = h.callout();
                String afterHttpValid = Sip_HttpUtil.validateHTTPResponse(httpResp);
                // String afterHttpValid = '{"Error": [{"Code": "41008.01", "Description": "[65059] : The passcode is already issued. Please provide different Edoc ID to generate again. ", "Text": "[65059] : The passcode is already issued. Please provide different Edoc ID to generate again. "}, {"Code": "41008.01", "Description": "[65041] : No pass was issued.  ", "Text": "[65041] : No pass was issued.  "}], "Version": null, "LanguageCode": null, "Exception": {"Code": "41008.01", "Source": ".Net SqlClient Data Provider", "Message": "Cannot insert duplicate key row in object \'dbo.OneTimeProfile\' with unique index \'ix_OneTimeProfile_PassCode\'. The duplicate key value is (88888803242017).\r\nThe statement has been terminated.", "DisplayError": ["Cannot insert duplicate key row in object \'dbo.OneTimeProfile\' with unique index \'ix_OneTimeProfile_PassCode\'. The duplicate key value is (88888803242017).\r\nThe statement has been terminated.", ".Net SqlClient Data Provider", "   at United.UClub.DbLib.Imp.OneTimePassService2.IssueOneTimePass(OneTimePassRequest oneTimePassRequest)\r\n   at United.UClub.Web.Api.Controllers.OneTimePassController.IssuePass(OneTimePassRequest passRequest)"]}, "ResponseCode": "IssuePass", "MachineName": "VCLD16GTAGPWS01", "CallDuration": 0, "ActivityDate": "2017-03-24T18:07:57.3439702-05:00", "TransactionId": null, "UnitedClubPass": []}';

                Sip_PassDetails passDetailObj = new Sip_PassDetails();
                if(afterHttpValid.equals(Label.Sip_Common_Error)){
                    String errorMess = Label.Sip_Common_Error;
                    passDetailObj.success = false;
                    passDetailObj.messages.add(errorMess);
                    log.flush();
                    return passDetailObj.getViewModel();
                }
                passDetailObj.parsePasDetailInfo(afterHttpValid);
                //20170606 validate Passdetail
                
                //20170614 check user permission for error msg
                passDetailObj.validatePassDetail(userInfoModel, userManagementInfo);
                passDetailObj.CalculateOTPBalance();
                passDetailObj.CalculateNewEffectiveDate();//TBD Emulation
                passDetailObj.CalculateNewExpriationDate();//TBD Emulation
                passDetailObj.populatePassViewModel(requestInfoFromUI, subscriptionInfo);
                //20170522 Internal User Issue
                passDetailObj.populateOneTimePassPrice('OTP', accountId, requestInfoFromUI.numberOfPassInputByUser);
                //add by john sun for random edocId at 5/26/2017
                passDetailObj.createEdocId(requestInfoFromUI.numberOfPassInputByUser);
                //2020 Security issue fix
                sessionObj.putEdocIdList(passDetailObj.vPassDetail.EdocIdList);
                passDetailObj.vPassDetail.EdocIdList = null;
                log.flush();


                // System.debug(LoggingLevel.INFO, '*** passDetailObj.vPassDetail: ' + passDetailObj.vPassDetail);
                return passDetailObj.getViewModel();
            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_PassDetails passDetailObj = new Sip_PassDetails();
                passDetailObj.success = false;
                passDetailObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return passDetailObj.getViewModel();
            }
        }
    }

    @RemoteAction
    global static Sip_RemotingResultAbstract getPassDetailWitEmail (Sip_PassDetails.CM_RequestInfoToRetrievePassFromUI requestInfoFromUI, String accountId) {
        String methodName = 'getPassDetailWitEmail';
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(requestInfoFromUI.userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getPassDetailWitEmail', 'Sip_RemoteSecurityUtil', 'isValidUserId', requestInfoFromUI.userId, accountId);
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(accountId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getPassDetailWitEmail', 'Sip_SessionCacheManager', 'validateAmenityAcountId', requestInfoFromUI.userId, accountId);
            return null;
        }else{
        //End
            try{
                Sip_PassDetails passDetailObj = new Sip_PassDetails();
                passDetailObj.populatePassViewModel (requestInfoFromUI);
                passDetailObj.CalculateNewEffectiveDate();
                passDetailObj.CalculateNewExpriationDate();
                //20170522 Internal User Issue
                passDetailObj.populateOneTimePassPrice('OTP', accountId, requestInfoFromUI.numberOfPassInputByUser);
                //add by john sun for random edocId at 5/26/2017
                passDetailObj.createEdocId(requestInfoFromUI.numberOfPassInputByUser);
                //2020 Security issue fix
                sessionObj.putEdocIdList(passDetailObj.vPassDetail.EdocIdList);
                passDetailObj.vPassDetail.EdocIdList = null;
                return passDetailObj.getViewModel();


            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_PassDetails passDetailObj = new Sip_PassDetails();
                passDetailObj.success = false;
                passDetailObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return passDetailObj.getViewModel();
            }
        }
    }

    @RemoteAction
    global static Sip_RemotingResultAbstract getBonusmilesQuota (Sip_PremierQualification.VM_PremierQualification premierQual, String userId) {
        String methodName = 'getBonusmilesQuota';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getBonusmilesQuota', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, '');
            return null;
        }else{
        //End
            try{
                Sip_AwardMiles awardMilesObj = new Sip_AwardMiles ();
                awardMilesObj.vm_amRequestor = new Sip_AwardMiles.VM_AMRequestor ();
                Decimal milesQuota = awardMilesObj.validateTenKLimit(premierQual);
                awardMilesObj.getBousMilesQuota(milesQuota);
                awardMilesObj.vm_amRequestor.success = awardMilesObj.success;
                awardMilesObj.vm_amRequestor.messages = awardMilesObj.messages;
                return awardMilesObj.vm_amRequestor;
            }catch (Exception ex) {
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_AwardMiles obj = new Sip_AwardMiles();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return obj;
            }
        }
    }

    @RemoteAction
    global static Sip_RemotingResultAbstract getAwardMiles(Sip_AwardMiles.VM_AMRequestor awardMiles, String callerId, Decimal totalCost, String pendingAmountObjId){
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
    Sip_SessionCacheManager managerObj = new Sip_SessionCacheManager ();
        //20200925 rwern QuickAmenitySecurityFix
        if(!Sip_RemoteSecurityUtil.isInternalUser('getAwardMiles')) {
            return null;
        }
        //2020 Security issue fix
        else if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(awardMiles.userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getAwardMiles', 'Sip_RemoteSecurityUtil', 'isValidUserId', awardMiles.userId, awardMiles.PayerId);
            return null;
        }
        else{
        //End
            String methodName = 'getAwardMiles';
            Boolean isAmountAdded = false;
            try{
                //2020 Security issue fix
                if (!Test.isRunningTest()) {
                    List<Sip_SessionCacheManager.CalAmenityAmountInfoWrapper> calAmountInfoList = new List<Sip_SessionCacheManager.CalAmenityAmountInfoWrapper>();
                    Integer miles = String.isNotBlank(awardMiles.MilesAmount) ? Integer.valueOf(awardMiles.MilesAmount) : 0;
                    if(miles == 500) {
                        calAmountInfoList.add(new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper('BM500', 1));
                    }else if (miles > 500) {

                        Integer numberOfOneKMiles = miles/1000;
                        calAmountInfoList.add(new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper('BM1000', numberOfOneKMiles));

                        if (miles > miles / 1000 * 1000) {
                            calAmountInfoList.add(new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper('BM500', 1));

                        }
                    }
                    if(!managerObj.validateAmenityAcountId(awardMiles.PayerId)) { 
                        Sip_SessionCacheManager.insertGEHError(className + '.getAwardMiles', 'Sip_SessionCacheManager', 'validateAmenityAcountId', awardMiles.userId, awardMiles.PayerId);
                        return null;
                    //Hard code the price as 118 for POC. Will have a methods to calculate the total cost: calculateOTP()
                    }else if(!managerObj.validatePendingAmount(calAmountInfoList, pendingAmountObjId, awardMiles.PayerId)) {
                        Sip_SessionCacheManager.insertGEHError(className + '.getAwardMiles', 'Sip_SessionCacheManager', 'validateAmenityAcountId', awardMiles.userId, awardMiles.PayerId);
                        return null;
                    }
                }
                

                Sip_AwardMiles objAW = new Sip_AwardMiles();
                Sip_UserInfo userInfoItem = new Sip_UserInfo(awardMiles.userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(awardMiles.userId);

                //20170608 Fund balance check before purchase
                // if (!Sip_CommonUtility.validateAccountBalance(awardMiles.PayerId, totalCost)) {
                //     Sip_CommonUtility.generateInsufficientFundError(objAW);
                //     return objAW;
                // }
                Sip_AwardMiles.CM_AMRequestor requstBodyOfAwardMiles = new Sip_AwardMiles.CM_AMRequestor();
                requstBodyOfAwardMiles.TransactionId = Sip_AwardMiles.returnTransferGUID();
                // System.debug(LoggingLevel.INFO, '*** TransactionId ' + requstBodyOfAwardMiles.TransactionId);
                requstBodyOfAwardMiles.PolicyCode = Sip_CommonConstant.POLICYCODEFORAWARDMILES;
                requstBodyOfAwardMiles.PartnerCode = Sip_CommonConstant.PARTNERCODEFORAWARDMILES;
                requstBodyOfAwardMiles.ClientId = Sip_CommonConstant.CLIENTIDFORAWARDMILES;
                requstBodyOfAwardMiles.AccountId = awardMiles.MPNumber;
                requstBodyOfAwardMiles.MilesAmount = awardMiles.MilesAmount;
                requstBodyOfAwardMiles.ActivityDate = String.valueOf(System.today());

                String requestBodyInJson = JSON.serialize(requstBodyOfAwardMiles);
                Sip_HttpUtil.CalloutInfoWrapper amCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                amCalloutInfo.requestBodyInJson = requestBodyInJson;
                amCalloutInfo.integrationType = 'GetAwardMiles';
                amCalloutInfo.oauthType = 'SIP OAuth';
                amCalloutInfo.headers = null;
                amCalloutInfo.logInformation = 'Get Award Details';
                amCalloutInfo.actionDescription = 'Get Award Details';
                amCalloutInfo.logMessage = '';
                amCalloutInfo.serviceName = 'AwardMiles';
                amCalloutInfo.serviceMethod = 'GetAwardMiles';
                amCalloutInfo.contextClass = className;
                amCalloutInfo.contextMethod = methodName;

                Sip_HttpUtil h = new Sip_HttpUtil (amCalloutInfo);
                HTTPResponse httpRes = h.callout();
                //201706013 TBD Added amount 
                // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(awardMiles.PayerId, totalCost, Sip_CommonConstant.OPERATORADD);
                //20170619 TBD delete pending amount after call out
                Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                isAmountAdded = true;
                String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponseForCreateStatus(httpRes);
                if (resAfterHttpValidation.equals(Label.Sip_Common_Error) ) {               
                    String errorMess = Label.Sip_Common_Error;
                    //2020 Security issue fix
                    objAW = new Sip_AwardMiles();
                    objAW.messages = new List<String>();
                    objAW.success = false;
                    objAW.messages.add(errorMess);
                    log.flush();
                    return objAW;
                }
                objAW.validateBonusMilesRs (resAfterHttpValidation, userInfoModel, userManagementInfo);
                objAW.populateAwardMilesViewModel(awardMiles);

                if (objAW.success) {
                    //20170609 TBD Added amount 
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(awardMiles.AccountId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //payerId, MilesAmount,mpNumber,beneficiaryId,comment,transactionId
                    objAW.transactionNumber = objAW.commitTransaction(
                        AwardMiles.PayerId,
                        AwardMiles.userId,
                        awardMiles.MilesAmount,
                        awardMiles.MPNumber,
                        awardMiles.Beneficiary,
                        callerId,
                        awardMiles.Comment,
                        awardMiles,
                        requstBodyOfAwardMiles.TransactionId
                    );
                }
                log.flush();
                return objAW;
            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_AwardMiles obj = new Sip_AwardMiles();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                //20170613 Added amount back if it is not added 
                if (!isAmountAdded) {
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(awardMiles.PayerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //20170619 TBD delete pending amount after call out
                    Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                }
                return obj;
            }
        }
    }

    // 2019-01-08. WT-02735. Suraphol.
    //20190530 rwern PPR minor debug changes
    @RemoteAction
    global static Sip_RemotingResultAbstract getUpgradeBalanceRestService(Sip_SWUDetail.CM_RequestInfoToSWUDetailFromUI requestInfoFromUI, String userId) {
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        String methodName = 'getUpgradeBalanceRestService';  
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        } 
        //2020 Security issue fix
        else if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getUpgradeBalanceRestService', 'Sip_RemoteSecurityUtil', 'isValidUserId', userId, requestInfoFromUI.accountId);
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(requestInfoFromUI.accountId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getUpgradeBalanceRestService', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userId, requestInfoFromUI.accountId);
            return null;
        } else {
            try {
                //2020 Security issue fix
                /*20210929 rwern 16707 START
                    - Have to consider the selected account may be an AOR. We don't want to take the CUB/SUB from the AOR itself, rather the Corp account
                        the AOR belongs to. */
                List<Account> accountList = [SELECT Id, SIP_CUB_SUB_ID__c, ParentId, RecordType.DeveloperName FROM Account WHERE Id =: requestInfoFromUI.accountId];
                if (accountList.size() > 0) {
                    // If AOR account perform another query for CUB/SUB for corporate account
                    if (accountList[0].RecordType.DeveloperName == Sip_CommonConstant.ACCTYPEAORTRANSACTION) {
                        List<Account> accountList2 = [SELECT Id, SIP_CUB_SUB_ID__c FROM Account WHERE Id = :accountList[0].ParentId];
                        if (accountList2.size() > 0) {
                            requestInfoFromUI.MileagePlusNumberOfCompany = accountList2[0].SIP_CUB_SUB_ID__c != null ? accountList2[0].SIP_CUB_SUB_ID__c : requestInfoFromUI.MileagePlusNumberOfCompany;
                        }
                    } else {
                        // If not an AOR account take the original account's CUB/SUB
                        requestInfoFromUI.MileagePlusNumberOfCompany = accountList[0].SIP_CUB_SUB_ID__c != null ? accountList[0].SIP_CUB_SUB_ID__c : requestInfoFromUI.MileagePlusNumberOfCompany;
                    }
                } else {
                    requestInfoFromUI.MileagePlusNumberOfCompany = requestInfoFromUI.MileagePlusNumberOfCompany;
                }
                //20210929 rwern 16707 END
                
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo = Sip_UserManagementUtil.getUserAccountPermission(userId);
                CSL_Integration__c csInt = CSL_Integration__c.getInstance('LoyaltyUCBBalances');
                Sip_HttpUtil.CalloutInfoWrapper passDetailsCalloutInfoWrapper = Sip_HttpUtil.createCalloutInfoPackage('', 'LoyaltyUCBBalances', 'SIP OAuth', null, null, 'Retrieve UCB Balanace', 'Retrieve UCB Balance', JSON.serialize(csInt), 'LoyaltyUCBBalances', 'Balances', className, methodName, requestInfoFromUI.MileagePlusNumberOfCompany);

                System.debug(LoggingLevel.INFO, 'Sip_AmenityController, purchaseUpgradesRestService(). passDetailsCalloutInfoWrapper=' + JSON.serialize(passDetailsCalloutInfoWrapper));

                Sip_HttpUtil h = new Sip_HttpUtil(passDetailsCalloutInfoWrapper);

                HttpResponse httpResp = h.callout();            
                String afterHttpValid = Sip_HttpUtil.validateHTTPResponse(httpResp);

                System.debug(LoggingLevel.INFO, 'Sip_AmenityController, getUpgradeBalanceRestService(). afterHttpValid=' + afterHttpValid);

                Sip_SWUDetail swuDetailObj = new Sip_SWUDetail();

                if (afterHttpValid.equals(Label.Sip_Common_Error)) {
                    String errorMess = Label.Sip_Common_Error;
                    swuDetailObj.success = false;
                    swuDetailObj.messages.add(errorMess);
                    log.flush();
                    return swuDetailObj.getViewModel();
                }
                swuDetailObj.parseSWUDetailResponseRest(afterHttpValid);
                swuDetailObj.validateSWUDetailRest(userInfoModel, userManagementInfo);
                swuDetailObj.populateSWUViewModelRest(userId);
                log.flush();
                return swuDetailObj.getViewModel();
            } catch(Exception ex) {
                //20190130 lijuan update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_SWUDetail swuDetailObj = new Sip_SWUDetail();
                swuDetailObj.success = false;
                swuDetailObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return swuDetailObj.getViewModel();
            }

        }
    }


    // 2019-01-17. WT-02737. Suraphol.
    @RemoteAction
  global static Sip_RemotingResultAbstract purchaseUpgradesRestService(String purchaseType, Sip_WSSWU.CM_RequestInfoToWSSWUFromUI requestInfoFromUI, String payerId, String beneficiaryId, String comments, String userID, Decimal totalCost, String callerId, String pendingAmountObjId, Sip_PaymentDataViewModel paymentdata, String deduct) {
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        String methodName = 'purchaseUpgradesRestService';
        System.debug(LoggingLevel.INFO, 'Sip_AmenityController, purchaseUpgradesRestService(). requestInfoFromUI=' + JSON.serialize(requestInfoFromUI));
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        } 
        //Shivani added for amenity
        if (Sip_RemoteSecurityUtil.isPassPlusIndividualUser(userId, 'Sip_AmenityController', methodName)) {
            return null;
        } 
        // 2020 Security issue fix
        else if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userID)) {
            Sip_SessionCacheManager.insertGEHError(className + '.purchaseUpgradesRestService', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(payerId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.purchaseUpgradesRestService', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
            return null;
        }
        Integer countOfUGC = requestInfoFromUI.UGCCount == null ? 0 : Integer.valueOf(requestInfoFromUI.UGCCount);
        if (!Test.isRunningTest() && !sessionObj.validatePendingAmount(new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper(Sip_CommonConstant.UGCTYPE, Integer.valueOf(countOfUGC)), pendingAmountObjId, payerId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.purchaseUpgradesRestService', 'Sip_SessionCacheManager', 'validatePendingAmount', userID, payerId);
            return null;
        }
        //20200925 rwern QuickAmenitySecurityFix
        // pass the userId, payerId, methodName, isGS
        if (!Sip_RemoteSecurityUtil.isValidFunds(userID, payerId, methodName, false)) {
            return null;
        } 
        
        else {
            try {
                //2020 Security issue fix
                /*20210929 rwern 16707 START
                    - Have to consider the selected account may be an AOR. We don't want to take the CUB/SUB from the AOR itself, rather the Corp account
                        the AOR belongs to. */
                List<Account> accountList = [SELECT Id, SIP_CUB_SUB_ID__c, ParentId, RecordType.DeveloperName FROM Account WHERE Id =: requestInfoFromUI.accountId];
                if (accountList.size() > 0) {
                    // If AOR account perform another query for CUB/SUB for corporate account
                    if (accountList[0].RecordType.DeveloperName == Sip_CommonConstant.ACCTYPEAORTRANSACTION) {
                        List<Account> accountList2 = [SELECT Id, SIP_CUB_SUB_ID__c FROM Account WHERE Id = :accountList[0].ParentId];
                        if (accountList2.size() > 0) {
                            requestInfoFromUI.MileagePlusNumberOfCompany = accountList2[0].SIP_CUB_SUB_ID__c != null ? accountList2[0].SIP_CUB_SUB_ID__c : requestInfoFromUI.MileagePlusNumberOfCompany;
                        }
                    } else {
                        // If not an AOR account take the original account's CUB/SUB
                        requestInfoFromUI.MileagePlusNumberOfCompany = accountList[0].SIP_CUB_SUB_ID__c != null ? accountList[0].SIP_CUB_SUB_ID__c : requestInfoFromUI.MileagePlusNumberOfCompany;
                    }
                } else {
                    requestInfoFromUI.MileagePlusNumberOfCompany = requestInfoFromUI.MileagePlusNumberOfCompany;
                }
                //20210929 rwern 16707 END

                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo = Sip_UserManagementUtil.getUserAccountPermission(userId);
                Sip_WSSWU WSSWUObj = new Sip_WSSWU();
                String requestBodyOfDeposit;
                Sip_HttpUtil.CalloutInfoWrapper WSSWUCalloutInfoWrapper;
                Sip_HttpUtil httpUtil;
                HttpResponse httpResp;
                String afterHttpValid;
                
                //2020 Security issue fix
        Sip_WSSWU.VM_WSSWUDetail vWSSWUDetail = null;
                //20190523 rwern PPR: we only can purchase UGC type (pluspoints)
                if (purchaseType.equalsIgnoreCase(Sip_CommonConstant.UGCTYPE) && requestInfoFromUI.UGCCount != null && Decimal.valueOf(requestInfoFromUI.UGCCount) > 0) {
                    requestBodyOfDeposit = WSSWUObj.constructRequestBodyOfWSSWURestService(requestInfoFromUI, userID, Sip_CommonConstant.UGCTYPE, userInfoModel);
                    WSSWUCalloutInfoWrapper = Sip_HttpUtil.createCalloutInfoPackage(requestBodyOfDeposit, 'LoyaltyCreditDeposit', 'SIP OAuth', null, null, 'Purchase PlusPoints', 'Purchase PlusPoints', '', 'Credit', 'Deposit', className, methodName, requestInfoFromUI.MileagePlusNumberOfCompany);
                    httpUtil = new Sip_HttpUtil(WSSWUCalloutInfoWrapper);
                    httpResp = httpUtil.callout();
                    afterHttpValid = Sip_HttpUtil.validateHTTPResponse(httpResp);
                    if (afterHttpValid.equals(Label.Sip_Common_Error)) {
                        String errorMess = Label.Sip_Common_Error + ' ' + 'Upgrades purchase failed';
                        WSSWUObj.success = false;
                        WSSWUObj.messages.add(errorMess);
                    } else {
                        WSSWUObj.parseWSSWUResponseRest(afterHttpValid, Sip_CommonConstant.UGCTYPE);
                        WSSWUObj.validateWSSWURest(userInfoModel, userManagementInfo, Sip_CommonConstant.UGCTYPE);
                        WSSWUObj.populateWSSWUViewModelRest(requestInfoFromUI, Sip_CommonConstant.UGCTYPE);
                    }
                    //2020 Security issue fix
                    vWSSWUDetail = WSSWUObj.getViewmodel();
                    Sip_UpgradeTransaction upgradeTransactionObj = new Sip_UpgradeTransaction();
                    Boolean isAmountAdded = false;
                    try {
                        Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                        isAmountAdded = true;
                        if (!Sip_CommonUtility.validateAccountBalance(payerId, totalCost)) {
                           Sip_CommonUtility.generateInsufficientFundError(upgradeTransactionObj.vUpgradeTransaction);
                           return upgradeTransactionObj.vUpgradeTransaction;
                        }
                        List<Sip_WSSWU.VM_WSSWUDetail> upgradesResults = new List<Sip_WSSWU.VM_WSSWUDetail>{vWSSWUDetail};
                        upgradeTransactionObj.vUpgradeTransaction.transactionNumber = upgradeTransactionObj.commitUpgradTransaction(upgradesResults, payerId,  beneficiaryId,  comments, userID, callerId, paymentdata, deduct);
                        Sip_UpgradeTransaction.VM_UpgradeTransaction vUpgradeTransaction = upgradeTransactionObj.getViewModel();
                        vWSSWUDetail.transactionNumber = vUpgradeTransaction.transactionNumber;
                    }catch(Exception ex) {
                        log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                        upgradeTransactionObj.success = false;
                        upgradeTransactionObj.messages.add(Label.Sip_Common_Error);
                        log.flush();
                        //20170613 Added amount back if it is not added 
                        if (!isAmountAdded) {
                            Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                        }
                    }
                }
                log.flush();
        return vWSSWUDetail;
            } catch(Exception ex) {
                //20190130 lijuan update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_WSSWU WSSWUObj = new Sip_WSSWU();
                WSSWUObj.success = false;
                WSSWUObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return WSSWUObj.getViewModel();
            }
        }
    }   

    @RemoteAction
    global static Sip_RemotingResultAbstract getCurrentPremierLevelStatus (Sip_PremierQualification.VM_PremierQualification premierQual) {
        String methodName = 'getCurrentPremierLevelStatus';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }else{
        //End
    //Shivani PII Qual quick fix
            try {
                Sip_WSloyalty wsloyaltyObj = new Sip_WSloyalty();
                if(premierQual.success){
                    //2020 Security issue fix
                    if (!Test.isRunningTest()) {
                        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager();
                        if (sessionObj.getMPWithCustomerIdFromRetrievePremier() != null
                            && sessionObj.getMPWithCustomerIdFromRetrievePremier().contains(premierQual.MileagePlusNumber)) {
                            premierQual.CustomerId = Decimal.valueOf(sessionObj.getMPWithCustomerIdFromRetrievePremier().remove(premierQual.MileagePlusNumber + '-'));
                        }
                    }

                    wsloyaltyObj.populateWSloyaltyViewModel (premierQual);
                    // return wsloyaltyObj.getViewModel();
                } else {
                    wsloyaltyObj.success = false;
                    wsloyaltyObj.messages.add(Label.Sip_Common_Error);
                    log.flush();
                    // return wsloyaltyObj.getViewModel();
                }
                //2020 Security issue fix
                Sip_SensitiveInfoManagement sensitiveInfoManageObj = new Sip_SensitiveInfoManagement(wsloyaltyObj.getViewModel(), Sip_WSloyalty.VM_WSloyalty.class, false, Sip_SensitiveInfoManagement.Sip_CurrentPremierLevelStatus_SensitiveInfo_FieldMap);
                Sip_WSloyalty.VM_WSloyalty wsloyalty = (Sip_WSloyalty.VM_WSloyalty)sensitiveInfoManageObj.encryptSensitiveInfo();
                //2020 Security issue fix
                return wsloyalty;
            } catch (Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_WSloyalty wsloyaltyObj = new Sip_WSloyalty();
                wsloyaltyObj.success = false;
                wsloyaltyObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return wsloyaltyObj.getViewModel();
             }
         }
    }

    @RemoteAction
    global static Sip_RemotingResultAbstract calculateNewExpirationDateByPremierLevelCutOffDate (String selectedLevelCode) {
        String methodName = 'calculateNewExpirationDateByPremierLevelCutOffDate';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }else{
        //End
            try{
                Sip_WSloyalty WSloyaltyObj = new Sip_WSloyalty ();
                WSloyaltyObj.generateNewExpirationDate (selectedLevelCode);
                return wsloyaltyObj.getViewModel();
            }catch (Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_WSloyalty wsloyaltyObj = new Sip_WSloyalty();
                wsloyaltyObj.success = false;
                wsloyaltyObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return wsloyaltyObj.getViewModel();
             }
         }
    }

    @RemoteAction
    /*global static Sip_RemotingResultAbstract purchasePremierLevel (Sip_WSloyalty.VM_WSloyalty vWSloyalty,
    Sip_WSloyalty.CM_RequestInfoToWSloyaltyFromUI requestInfoFromUI, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId ) {*/
    //20181031 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
    // global static Sip_RemotingResultAbstract purchasePremierLevel (Sip_WSloyalty.VM_WSloyalty vWSloyalty,
    // Sip_WSloyalty.CM_RequestInfoToWSloyaltyFromUI requestInfoFromUI, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId, List<String> agreements, String deduct ) {
    //rwern 20181026 REQ-0354: Add beneficiaryOrReason and reason
    //20181217 update, paymentdata means: front-end payment data detail,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'}
    global static Sip_RemotingResultAbstract purchasePremierLevel (
        Sip_WSloyalty.VM_WSloyalty vWSloyalty, Sip_WSloyalty.CM_RequestInfoToWSloyaltyFromUI requestInfoFromUI,
        String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId,String beneficiaryOrReason, String reason,
        Sip_PaymentDataViewModel paymentdata, String deduct
        
        ) {
        String methodName = 'purchasePremierLevel';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userID)) {
            Sip_SessionCacheManager.insertGEHError(className + '.purchasePremierLevel', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
            return null;
        }
        //Shivani added for amenity
        if (Sip_RemoteSecurityUtil.isPassPlusIndividualUser(userId, 'Sip_AmenityController', methodName)) {
            return null;
        } 

        //20200925 rwern QuickAmenitySecurityFix
        // pass the userId, payerId, methodName, isGS
        Boolean isGS = false;
        if (requestInfoFromUI != null) {
            if (requestInfoFromUI.premierLevelCode == 'GS') {
                isGS = true;
            }
        }

        if (!Sip_RemoteSecurityUtil.isValidFunds(userID, payerId, methodName, isGS)) {
            return null;
        } 
        
        
        else{
        //End
            Boolean isAmountAdded = false;
            try{
                
                //2020 Security issue fix start
                Sip_SessionCacheManager managerObj = new Sip_SessionCacheManager ();
                if(!Test.isRunningTest() && !managerObj.validateAmenityAcountId(payerId)) { 
                    Sip_SessionCacheManager.insertGEHError(className + '.purchasePremierLevel', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
                    return null;
                } else if (!Test.isRunningTest() && !managerObj.validateMPWithCurrentLevel(vWSloyalty.MileagePlusNumber, premierCodeWithPrdCodeMap.get(vWSloyalty.CurrentPremierCode))) {
                    Sip_SessionCacheManager.insertGEHError(className + '.purchasePremierLevel', 'Sip_SessionCacheManager', 'validateMPWithCurrentLevel: ' + premierCodeWithPrdCodeMap.get(vWSloyalty.CurrentPremierCode), userID, payerId);
                    return null;
                }
                if (!Test.isRunningTest()) {
                    Sip_SessionCacheManager.CalAmenityAmountInfoWrapper calAmountInfo;
                    String premLevelCode;
                    if (premierCodeWithPrdCodeMap.containsKey(requestInfoFromUI.getPremLevelCode())) {
                        premLevelCode = premierCodeWithPrdCodeMap.get(requestInfoFromUI.getPremLevelCode());
                    } else {
                        premLevelCode = requestInfoFromUI.getPremLevelCode();
                    }
                    if (Sip_PendingAmount.isGlobalService(premLevelCode)) {
                        calAmountInfo = new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper('GS', 1);
                    } else {
                        if (vWSloyalty.CurrentPremierCode == 'MP') {
                            calAmountInfo = new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper(premLevelCode, 1);
                        } else {
                            String discountedProductCode;
                            String qualifiedLevelProductCode;

                            String qualifiedLevelNumWithMP = managerObj.getMPWithQualifiedLevel();
                            if (String.isNotBlank(qualifiedLevelNumWithMP)) {
                                Integer qualifiedLevelNum = Integer.valueOf(qualifiedLevelNumWithMP.removeStart(vWSloyalty.MileagePlusNumber + '-'));
                                qualifiedLevelProductCode = nominationLevelWithCodeMap.get((Decimal)qualifiedLevelNum);
                            }

                            if ((Date.today().month() > 6 || Date.today().month() == 1) && qualifiedLevelProductCode != null) {
                                if (qualifiedLevelProductCode == 'MP') {
                                    discountedProductCode = '';
                                }

                                if (qualifiedLevelProductCode != 'GS') {
                                    if (premierCodeWithPrdCodeMap.containsKey(qualifiedLevelProductCode)) {
                                        discountedProductCode = premierCodeWithPrdCodeMap.get(qualifiedLevelProductCode);
                                    } else {
                                        discountedProductCode = qualifiedLevelProductCode;
                                    }
                                }
                            } else if (Date.today().month() <= 6 && Date.today().month() != 1) {
                                if (premierCodeWithPrdCodeMap.containsKey(vWSloyalty.CurrentPremierCode)) {
                                    discountedProductCode = premierCodeWithPrdCodeMap.get(vWSloyalty.CurrentPremierCode);
                                } else {
                                    discountedProductCode = vWSloyalty.CurrentPremierCode;
                                }
                                
                            }
                            
                            calAmountInfo = new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper(premLevelCode, discountedProductCode, 1);
                        }
                    }

                    if(!managerObj.validatePendingAmount(calAmountInfo, pendingAmountObjId, payerId)) {
                        Sip_SessionCacheManager.insertGEHError(className + '.purchasePremierLevel', 'Sip_SessionCacheManager', 'validatePendingAmount', userID, payerId);
                        return null;
                    }

                    if (managerObj.getMPWithCustomerIdFromRetrievePremier() != null
                        && managerObj.getMPWithCustomerIdFromRetrievePremier().contains(vWSloyalty.MileagePlusNumber)) {
                        vWSloyalty.CustomerId = managerObj.getMPWithCustomerIdFromRetrievePremier().remove(vWSloyalty.MileagePlusNumber + '-');
                    }
                }
                //2020 Security issue fix end
                //20170608 Fund balance check before purchase
                Sip_WSloyalty wsloyaltyObj = new Sip_WSloyalty();
                // if (!Sip_CommonUtility.validateAccountBalance(payerId, totalCost)) {
                //     Sip_CommonUtility.generateInsufficientFundError(wsloyaltyObj.vWSloyalty);
                //     return wsloyaltyObj.vWSloyalty;
                // }
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);
                
                //Shivani changes User Story 473452
                Account acc = new Account();
                acc = [SELECT Id, Program__c, Program__r.Name FROM Account WHERE Id =: payerId];
                if(acc != null && acc.Program__c != null){
                    if(acc.Program__c == Label.Sip_ChairmanCircle_ProgramID){
                        promoCodeApplied = 'ID';
                    }
                }
                //System.debug('promoCodeApplied==>'+promoCodeApplied);
                //End
                
                String requestBodyInJson = Sip_WSloyalty.constructRequestBodyOfWSloyaltyService(vWSloyalty, requestInfoFromUI, userId);

                Sip_HttpUtil.CalloutInfoWrapper WSloyaltyCalloutInfoWrapper = Sip_HttpUtil.createCalloutInfoPackage (requestBodyInJson, 'tierLevelEntitlements', Label.SIP_FltSummaryWebServicesOAuth, null, Sip_WSloyalty.generateHeaderForWSLoyalty(),'Purchase Premier Status', 'Purchase Premier Status', '', 'WSloyalty' ,'WSloyalty', className, methodName, vWSloyalty.MileagePlusNumber);

                Sip_HttpUtil h             = new Sip_HttpUtil(WSloyaltyCalloutInfoWrapper);
                HttpResponse httpResp      = h.callout();
                //201706013 TBD Added amount 
                // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                //20170619 TBD delete pending amount after call out
                Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                isAmountAdded = true;
                String afterHttpValid      = Sip_HttpUtil.validateHTTPResponse(httpResp);
                // String afterHttpValid      = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">    <s:Body>        <s:Fault>            <faultcode xmlns:a="http://schemas.microsoft.com/net/2005/12/windowscommunicationfoundation/dispatcher">a:InternalServiceFault</faultcode>            <faultstring xml:lang="en-US">Response code [7]: DIFF YEAR=20170605/20180131</faultstring>            <detail>                <ExceptionDetail xmlns="http://schemas.datacontract.org/2004/07/System.ServiceModel" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">                    <HelpLink i:nil="true"></HelpLink>                    <InnerException i:nil="true"></InnerException>                    <Message>Response code [7]: DIFF YEAR=20170605/20180131</Message>                    <StackTrace> at United.Loyalty.Ims.ImsTransactions.SendTransaction(IImsConnect imsConnect, ImsWpieMessageRequest request) at United.Loyalty.WebCore.AccountServices.AddInstantElite(InstantEliteAward request) in c:CustomApplicationsCoreServicessourcelibsUnited.Loyalty.WebCoreAccountElite.cs:line 111 at WsWeb.WsLoyalty.AddInstantEliteAward(InstantEliteAward instantEliteAward) in c:CustomApplicationsCoreServicessourceservicesContinental.Loyalty.WsWebWsLoyalty.svc.cs:line 147 at SyncInvokeAddInstantEliteAward(Object , Object[] , Object[] ) at System.ServiceModel.Dispatcher.SyncMethodInvoker.Invoke(Object instance, Object[] inputs, Object[]&amp; outputs) at System.ServiceModel.Dispatcher.DispatchOperationRuntime.InvokeBegin(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.ImmutableDispatchRuntime.ProcessMessage5(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.ImmutableDispatchRuntime.ProcessMessage41(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.ImmutableDispatchRuntime.ProcessMessage4(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.ImmutableDispatchRuntime.ProcessMessage31(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.ImmutableDispatchRuntime.ProcessMessage3(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.ImmutableDispatchRuntime.ProcessMessage2(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.ImmutableDispatchRuntime.ProcessMessage11(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.ImmutableDispatchRuntime.ProcessMessage1(MessageRpc&amp; rpc) at System.ServiceModel.Dispatcher.MessageRpc.Process(Boolean isOperationContextSet)</StackTrace>                    <Type>United.Loyalty.Ims.TransactionException</Type>                </ExceptionDetail>            </detail>        </s:Fault>    </s:Body></s:Envelope>';
                

                if(afterHttpValid.equals(Label.Sip_Common_Error)){
                    String errorMess     = Label.Sip_Common_Error;
                    wsloyaltyObj.success = false;
                    wsloyaltyObj.messages.add(errorMess);
                    log.flush();
                    return wsloyaltyObj.getViewModel();
                }

                //wsloyaltyObj.parseWSLoyaltyResponse(afterHttpValid);
               // wsloyaltyObj.populateWSloyaltyViewModelAfterPurchase ();
                //20170607
                wsloyaltyObj.parseErrResponseCodeNew(afterHttpValid);
                //20170614 check user permission for error msg
                //wsloyaltyObj.validateNominationRes(userInfoModel, userManagementInfo);

                if (wsloyaltyObj.success) {
                    //20170609 TBD Added amount 
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //20181031 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
                    // wsloyaltyObj.vWSloyalty.transactionNumber = wsloyaltyObj.commitTransaction (payerId, beneficiaryId, userId, callerId, comments, vWSloyalty, agreements, deduct);
                    // wsloyaltyObj.vWSloyalty.transactionNumber = wsloyaltyObj.commitTransaction (payerId, beneficiaryId, userId, callerId, comments, vWSloyalty);
                    //20181217 update
                    //rwern 20181029 REQ-0354: Add beneficiaryOrReason and reason
                    
                    //Shivani REQ-0823 Changes
                   String DiscountedProductCode = vWSloyalty.DiscountedProductCode;
                   if(DiscountedProductCode != null && DiscountedProductCode != ''){
                       isDiscountApplied = true;
                       List<PricebookEntry> productEntries = new List<PricebookEntry>([SELECT Id, Name, UnitPrice, ProductCode, Product2Id
                                                                                   FROM PricebookEntry
                                                                                   WHERE ProductCode = :DiscountedProductCode]);
                       if(productEntries != null && productEntries.size() > 0){
                           discountedPrice = productEntries[0].UnitPrice;
                           qualifiedLevelOnFeb = productEntries[0].Name;
                       }
                   }
                  //Shivani REQ-0823 to use in line items qualified level on feb 1
                   if(System.Today().month() > 6 || System.Today().month() == 1){
                       qualifiedLevelOnFeb = qualifiedLevelOnFeb != '' ? qualifiedLevelOnFeb : 'General Member';
                   } else {
                    qualifiedLevelOnFeb = '';
                   }
                   //end
                    
                    wsloyaltyObj.vWSloyalty.transactionNumber = wsloyaltyObj.commitTransaction (payerId, beneficiaryId, userId, callerId, comments, vWSloyalty, paymentdata, deduct, beneficiaryOrReason, reason);

                }

                log.flush();

                //2020 Security issue fix
                Sip_SensitiveInfoManagement sensitiveInfoManageObj = new Sip_SensitiveInfoManagement(wsloyaltyObj.getViewModel(), Sip_WSloyalty.VM_WSloyalty.class, false, Sip_SensitiveInfoManagement.Sip_WSloyalty_SensitiveInfo_FieldMap);
                Sip_WSloyalty.VM_WSloyalty tmpWsloyaltyObj = (Sip_WSloyalty.VM_WSloyalty)sensitiveInfoManageObj.encryptSensitiveInfo();
                //2020 Security issue fix
                return tmpWsloyaltyObj;
                // return wsloyaltyObj.getViewModel();

            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/

                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);

                Sip_WSloyalty WSloyaltyObj = new Sip_WSloyalty();
                WSloyaltyObj.success       = false;
                WSloyaltyObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                //20170613 Added amount back if it is not added 
                if (!isAmountAdded) {
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    //20170619 TBD delete pending amount after call out
                    Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                }
                return WSloyaltyObj.getViewModel();
            }
        }
    }

    @RemoteAction
    global static Sip_RemotingResultAbstract getCertAllocationByEmpID () {
        String methodName = 'getCertAllocationByEmpID';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }else{
        //End
            try {
                Sip_CertAllocationByEmpID certAllocationObj = new Sip_CertAllocationByEmpID ();
                String requestBodyInJson = certAllocationObj.constructReqOfCertAllocationByEmpID ();

                Sip_HttpUtil.CalloutInfoWrapper CertAllocationCalloutInfoWrapper = Sip_HttpUtil.createCalloutInfoPackage (requestBodyInJson, 'getCertAllocationByEmpID', Label.SIP_FltSummaryWebServicesOAuth, null, null,'get CertAllocation By EmpID', 'get CertAllocation By EmpID', '', 'Certificate Service' ,'get CertAllocation By EmpID', className, methodName, '');

                Sip_HttpUtil        h = new Sip_HttpUtil(CertAllocationCalloutInfoWrapper);
                HttpResponse httpResp = h.callout();
                String afterHttpValid = Sip_HttpUtil.validateHTTPResponse(httpResp);
                
                if(afterHttpValid.equals(Label.Sip_Common_Error)){

                    String errorMess          = Label.Sip_Common_Error;
                    certAllocationObj.success = false;
                    certAllocationObj.messages.add(errorMess);
                    log.flush();
                    return certAllocationObj.getViewModel();
                }
                certAllocationObj.parseCertAllocaionResponse(afterHttpValid);
                certAllocationObj.populateCertAllocationByEmpIDViewModel();

                log.flush();
                //2020 Security issue fix
                if (UserInfo.getUserType() != 'Standard') {
                    certAllocationObj.vCertAllocationByEmpID.AuthorizerList = null;
                    certAllocationObj.vCertAllocationByEmpID.DivisionList = null;
                    certAllocationObj.vCertAllocationByEmpID.ReasonCodeList = null;
                }
                return certAllocationObj.getViewModel();
            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/

                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_CertAllocationByEmpID certAllocationObj = new Sip_CertAllocationByEmpID ();
                certAllocationObj.success = false;
                certAllocationObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return certAllocationObj.getViewModel();
            }
        }
    }

    //To be Completed
    @RemoteAction
    global static Sip_RemotingResultAbstract activateTravelCert (
        Sip_Activatecertificate.CM_TravelCertFromUI certsTobeActivated
        , Sip_CertAllocationByEmpID.VM_CertAllocationByEmpID certAllocations
        , Integer certsTobeActivatedIndex
        , String payerId
        , String beneficiaryId
        , String comments
        , String userID
        , Decimal totalCost
        // New parameters
        , String pendingPayTravelCertExId
        , String callerId
        , String deduct
        , Sip_PaymentDataViewModel paymentdata
        , String emailAddress
        ) {

        String methodName = 'activateTravelCert';
        //2020 Security issue fix
        SIP_Pending_Pay_Travel_Certificate__c pendingPayTravelCert;
        String productCode;
        Decimal currentItemCost;
        Decimal recalculatedTotalCost;
        Id pendingAmountIdInSession;
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager();

        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userID)) {
            Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
            return null;
        }
    //Shivani added for amenity
        if (Sip_RemoteSecurityUtil.isPassPlusIndividualUser(userId, 'Sip_AmenityController', methodName)) {
            return null;
        } 

        //2020 Security issue fix
        if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(payerId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
            return null;
        }

        if (certsTobeActivated == null || certsTobeActivated.cTravelCertDetails == null) {
            Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', className, 'activateTravelCert: certsTobeActivated/certsTobeActivated.cTravelCertDetails', userID, payerId);
            return null;
        }
        
        String certsTobeActivatedJSON = JSON.serialize(certsTobeActivated);
        if (!Test.isRunningTest()) {
            String entityName = certsTobeActivated.Entity;
            productCode = entityName.substring(0, 1) + entityName.substring(entityName.length() - 1, entityName.length()) + certsTobeActivated.ServiceClass;
            Pricebook2 pricebook2 = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            List<PricebookEntry> productPrices = [SELECT Id, ProductCode, UnitPrice
                                               FROM PricebookEntry
                                               WHERE ProductCode = :productCode
                                               AND Pricebook2Id = :pricebook2.Id];
            if (productPrices.isEmpty()) {
                Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', className, 'activateTravelCert: productPrices', userID, payerId);
                return null;
            }
            currentItemCost = productPrices[0].UnitPrice * Integer.valueOf(certsTobeActivated.cTravelCertDetails[certsTobeActivatedIndex].CreditCount) * Integer.valueOf(certsTobeActivated.cTravelCertDetails[certsTobeActivatedIndex].Quantity);
            recalculatedTotalCost = 0;
            for (Sip_Activatecertificate.CM_TravelCertDetails travelCertDetail : certsTobeActivated.cTravelCertDetails) {
                recalculatedTotalCost += productPrices[0].UnitPrice * Integer.valueOf(travelCertDetail.CreditCount) * Integer.valueOf(travelCertDetail.Quantity);
            }

            if (recalculatedTotalCost != totalCost) {
                Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', className, 'activateTravelCert: recalculatedTotalCost', userID, payerId);
                return null;
            }

            Set<Id> pendingAmountIdSet = sessionObj.getPendingAmountId();
            if (pendingAmountIdSet != null && !pendingAmountIdSet.isEmpty()) {
                pendingAmountIdInSession = (new List<Id>(pendingAmountIdSet))[0];
            } else {
                Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', 'Sip_SessionCacheManager', 'getPendingAmountId', userID, payerId);
                return null;
            }

            if (String.isNotBlank(pendingPayTravelCertExId)) {
                List<SIP_Pending_Pay_Travel_Certificate__c> pendingPayTravelCerts = [
                    SELECT Id,
                        SIP_External_ID__c,
                        SIP_Count_of_Travel_Certificates__c,
                        SIP_Count_of_Travel_Cert_Active_Results__c,
                        SIP_Total_Cost_of_Items__c,
                        SIP_Cert_Tobe_Active_JSON__c,
                        SIP_Deduct__c,
                        SIP_BeneficiaryId__c,
                        SIP_CallerId__c,
                        SIP_PayerId__c,
                        SIP_PaymentdataJSON__c,
                        SIP_Pending_Amount__c,
                        SIP_Pending_Amount__r.SIP_Locked_Amount__c,
                        SIP_Pro_Code__c,
                        SIP_TotalCost__c,
                        SIP_UserID__c,
                        SIP_Email__c
                    FROM SIP_Pending_Pay_Travel_Certificate__c
                    WHERE SIP_External_ID__c =: pendingPayTravelCertExId
                ];

                if (pendingPayTravelCerts.isEmpty()) {
                    Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', className, 'activateTravelCert: pendingPayTravelCerts', userID, payerId);
                    return null;
                }

                pendingPayTravelCerts[0].SIP_BeneficiaryId__c = String.isBlank(pendingPayTravelCerts[0].SIP_BeneficiaryId__c) ? '' : pendingPayTravelCerts[0].SIP_BeneficiaryId__c;
                pendingPayTravelCerts[0].SIP_CallerId__c = String.isBlank(pendingPayTravelCerts[0].SIP_CallerId__c) ? '' : pendingPayTravelCerts[0].SIP_CallerId__c;
                if (pendingPayTravelCerts[0].SIP_Cert_Tobe_Active_JSON__c != certsTobeActivatedJSON
                    || pendingPayTravelCerts[0].SIP_Count_of_Travel_Cert_Active_Results__c >= pendingPayTravelCerts[0].SIP_Count_of_Travel_Certificates__c
                    || certsTobeActivatedIndex <= pendingPayTravelCerts[0].SIP_Count_of_Travel_Cert_Active_Results__c - 1
                    || pendingPayTravelCerts[0].SIP_Pending_Amount__c != pendingAmountIdInSession
                    || pendingPayTravelCerts[0].SIP_Pending_Amount__r.SIP_Locked_Amount__c - pendingPayTravelCerts[0].SIP_Total_Cost_of_Items__c < currentItemCost
                    || pendingPayTravelCerts[0].SIP_Deduct__c != deduct
                    || pendingPayTravelCerts[0].SIP_BeneficiaryId__c != beneficiaryId
                    || pendingPayTravelCerts[0].SIP_CallerId__c != callerId
                    || pendingPayTravelCerts[0].SIP_PayerId__c != payerId
                    || pendingPayTravelCerts[0].SIP_PaymentdataJSON__c != JSON.serialize(paymentdata)
                    || pendingPayTravelCerts[0].SIP_Pro_Code__c != productCode
                    || pendingPayTravelCerts[0].SIP_TotalCost__c != recalculatedTotalCost
                    || pendingPayTravelCerts[0].SIP_UserID__c != userID
                    || pendingPayTravelCerts[0].SIP_Email__c != emailAddress
                    ) {
                    Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', className, 'activateTravelCert: all fields checking in pendingPayTravelCerts[0] ' + pendingPayTravelCerts[0].Id, userID, payerId);
                    return null;
                }
                pendingPayTravelCert = pendingPayTravelCerts[0];

            } else {
                List<SIP_Pending_Amount__c> pendingAmountRecords = [Select Id
                                                            , SIP_Locked_Amount__c
                                                            , SIP_Payment_Account__c
                                                            From SIP_Pending_Amount__c
                                                            where Id =: pendingAmountIdInSession];
                if (pendingAmountRecords.isEmpty()) {
                    Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', className, 'activateTravelCert: pendingAmountRecords', userID, payerId);
                    return null;
                }

                List<SIP_Pending_Pay_Travel_Certificate__c> pendingPayCertsWithPendingAmount = [
                    SELECT Id
                    FROM SIP_Pending_Pay_Travel_Certificate__c
                    WHERE SIP_Pending_Amount__c =: pendingAmountIdInSession
                ];

                if (!pendingPayCertsWithPendingAmount.isEmpty()) {
                    Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', className, 'activateTravelCert: pendingPayCertsWithPendingAmount ' + pendingPayCertsWithPendingAmount[0].Id, userID, payerId);
                    return null;
                }

                if (pendingAmountRecords[0].SIP_Locked_Amount__c != recalculatedTotalCost
                    || pendingAmountRecords[0].SIP_Locked_Amount__c < currentItemCost) {
                    Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', className, 'activateTravelCert: pendingAmountRecords[0].SIP_Locked_Amount__c', userID, payerId);
                    return null;
                }
            }
        }

        //20200925 rwern QuickAmenitySecurityFix
        // pass the userId, payerId, methodName, isGS
        if (!Sip_RemoteSecurityUtil.isValidFunds(userID, payerId, methodName, false)) {
            return null;
        } 
        
        else{
        //End
            try{
                Sip_SessionCacheManager managerObj = new Sip_SessionCacheManager ();
                if(!Test.isRunningTest() && !managerObj.validateAmenityAcountId(payerId)) { 
                    Sip_SessionCacheManager.insertGEHError(className + '.activateTravelCert', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
                    return null;
                }
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);

                Sip_Activatecertificate activateCertObj = new Sip_Activatecertificate();

                if (certsTobeActivated != null && 
                    certsTobeActivated.cTravelCertDetails != null && 
                    !certsTobeActivated.cTravelCertDetails.isEmpty()) {

                        if (certAllocations.vSAAllocationInventoryMap.get(certsTobeActivated.Entity + certsTobeActivated.ServiceClass) != null) {

                            //String requestBodyInJson = Sip_Activatecertificate.constructRequestbodyofActivateCert (certsTobeActivated.cTravelCertDetails[certsTobeActivatedIndex], certAllocations.vSAAllocationInventoryMap.get(certsTobeActivated.Entity + certsTobeActivated.ServiceClass), certAllocations.authEmpId, certAllocations.promId, certsTobeActivated, userInfoModel);
                            //Jerry Wu 20180228 Adding payerId ucsId to call constructRequestbodyofActivateCert
                            String requestBodyInJson = Sip_Activatecertificate.constructRequestbodyofActivateCert (certsTobeActivated.cTravelCertDetails[certsTobeActivatedIndex], certAllocations.vSAAllocationInventoryMap.get(certsTobeActivated.Entity + certsTobeActivated.ServiceClass), certAllocations.authEmpId, certAllocations.promId, payerId, certsTobeActivated, userInfoModel);

                            Sip_HttpUtil.CalloutInfoWrapper CertAllocationCalloutInfoWrapper = Sip_HttpUtil.createCalloutInfoPackage (requestBodyInJson, 'activatecertificate', Label.SIP_FltSummaryWebServicesOAuth, null, null, '  Activate Travel    Certificate', 'Activate Travel Certificate', '', 'Activate Certificate Service' ,' Activate CertAllocation',   className, methodName, '');
                            Sip_HttpUtil h = new Sip_HttpUtil(CertAllocationCalloutInfoWrapper);
                            HttpResponse httpResp = h.callout();
                            String afterHttpValid = Sip_HttpUtil.validateHTTPResponse(httpResp);
                            if(afterHttpValid.equals(Label.Sip_Common_Error)){
                                String errorMess = certsTobeActivated.Entity + ' ' + certsTobeActivated.ServiceClass + ' ' + certsTobeActivated.cTravelCertDetails[certsTobeActivatedIndex].Quantity + ' ' + certsTobeActivated.cTravelCertDetails[certsTobeActivatedIndex].CreditCount + ' ' + 'Failed';
                                activateCertObj.messages.add(errorMess);
                                log.flush();
                                return activateCertObj.getViewModel();
                            }
                            activateCertObj.parseActivateCertResponse(afterHttpValid);
                            activateCertObj.populateActivateCertViewModel(certsTobeActivated);
                            //20170620 
                            activateCertObj.parseErrResponseCode(afterHttpValid);
                            activateCertObj.validateTravelCertRes(userInfoModel, userManagementInfo);
                            // Lijuan add
                            if (pendingPayTravelCert == null) {
                                pendingPayTravelCert = new SIP_Pending_Pay_Travel_Certificate__c();
                                pendingPayTravelCert.SIP_BeneficiaryId__c = beneficiaryId;
                                pendingPayTravelCert.SIP_CallerId__c = callerId;
                                pendingPayTravelCert.SIP_Cert_Tobe_Active_JSON__c = certsTobeActivatedJSON;
                                pendingPayTravelCert.SIP_Comments__c = comments;
                                pendingPayTravelCert.SIP_Count_of_Travel_Certificates__c = certsTobeActivated.cTravelCertDetails.size();
                                pendingPayTravelCert.SIP_Deduct__c = deduct;
                                pendingPayTravelCert.SIP_External_ID__c = Sip_CommonUtility.returnGUID();
                                pendingPayTravelCert.SIP_PayerId__c = payerId;
                                pendingPayTravelCert.SIP_PaymentdataJSON__c = JSON.serialize(paymentdata);
                                pendingPayTravelCert.SIP_TotalCost__c = totalCost;
                                pendingPayTravelCert.SIP_UserID__c = userID;
                                pendingPayTravelCert.SIP_Email__c = emailAddress;
                                pendingPayTravelCert.SIP_Pro_Code__c = productCode;
                                pendingPayTravelCert.SIP_Pending_Amount__c = pendingAmountIdInSession;

                                Database.insert(pendingPayTravelCert);
                            }

                            SIP_Pending_Pay_Travel_Cert_Item__c pendingPayCertItem = new SIP_Pending_Pay_Travel_Cert_Item__c();
                            pendingPayCertItem.SIP_Pending_Pay_Travel_Certificate__c = pendingPayTravelCert.Id;
                            pendingPayCertItem.SIP_Active_Travel_Cert_Result_JSON__c = JSON.serialize(activateCertObj.vActivateCert);
                            pendingPayCertItem.SIP_Cost__c = currentItemCost;
                            Database.insert(pendingPayCertItem);

                            activateCertObj.vActivateCert.travelCertInfoFromUi.pendingPayTravelCertExId = pendingPayTravelCert.SIP_External_ID__c;
                        }                
                }else {
                    activateCertObj.success = false;
                    String errorMess = Label.Sip_Common_Error;
                    activateCertObj.success = false;
                    activateCertObj.messages.add(errorMess);
                }

                log.flush();
                return activateCertObj.getViewModel();
            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(),   Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_Activatecertificate activateCertObj = new Sip_Activatecertificate();
                activateCertObj.success = false;
                activateCertObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return activateCertObj.getViewModel();
            }
        }
    }

    @RemoteAction
    //20181031 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
    // global static Sip_RemotingResultAbstract purchaseBeverageCoupons (Sip_BeverageCoupon.BeverageCouponInfo requestInfo, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId) {
    // global static Sip_RemotingResultAbstract purchaseBeverageCoupons (Sip_BeverageCoupon.BeverageCouponInfo requestInfo, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId, List<String> agreements, String deduct) {
    //20181217 update, paymentdata means: front-end payment data detail,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'}
    global static Sip_RemotingResultAbstract purchaseBeverageCoupons (Sip_BeverageCoupon.BeverageCouponInfo requestInfo, String payerId, String beneficiaryId, String callerId, String comments, String userID, Decimal totalCost, String pendingAmountObjId, Sip_PaymentDataViewModel paymentdata, String deduct) {

        String methodName = 'purchaseBeverageCoupons';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
    //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userID)) {
            Sip_SessionCacheManager.insertGEHError(className + '.purchaseBeverageCoupons', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
            return null;
        }
        //Shivani added for amenity
        if (Sip_RemoteSecurityUtil.isPassPlusIndividualUser(userId, 'Sip_AmenityController', methodName)) {
            return null;
        } 

        //20200925 rwern QuickAmenitySecurityFix
        // pass the userId, payerId, methodName, isGS
        if (!Sip_RemoteSecurityUtil.isValidFunds(userID, payerId, methodName, false)) {
            return null;
        } 
        
        else{
        //End
            Boolean isAmountAdded = false;
            try{
                //2020 Security issue fix start
                Sip_SessionCacheManager managerObj = new Sip_SessionCacheManager ();
                if(!Test.isRunningTest() && !managerObj.validateAmenityAcountId(payerId)) {
                    Sip_SessionCacheManager.insertGEHError(className + '.purchaseBeverageCoupons', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
                    return null;
                } else if(!Test.isRunningTest() && !managerObj.validatePendingAmount(new Sip_SessionCacheManager.CalAmenityAmountInfoWrapper('BV', Integer.valueOf(requestInfo.NumberOfCoupons)), pendingAmountObjId, payerId)) {
                    Sip_SessionCacheManager.insertGEHError(className + '.purchaseBeverageCoupons', 'Sip_SessionCacheManager', 'validatePendingAmount', userID, payerId);
                    return null;
                }
                Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                isAmountAdded = true;
                Sip_BeverageCoupon beverageCouponObj = new Sip_BeverageCoupon ();
                //201706013 TBD Added amount 
                // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                //20170619 TBD delete pending amount after call out
                // Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                // isAmountAdded = true;
                //20170608 Fund balance check before purchase
                // if (!Sip_CommonUtility.validateAccountBalance(payerId, totalCost)) {
                //     Sip_CommonUtility.generateInsufficientFundError(beverageCouponObj.vBeverageCoupon);
                //     return beverageCouponObj.vBeverageCoupon;
                // }
                beverageCouponObj.generateBeverageCouponCases (requestInfo, payerId, beneficiaryId, comments);
                //20170609 TBD Added amount 
                // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                //20181031 add agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
                // String transactionNumber = beverageCouponObj.commitTransaction (requestInfo, payerId, beneficiaryId, callerId, userID, comments, agreements, deduct);
                // String transactionNumber = beverageCouponObj.commitTransaction (requestInfo, payerId, beneficiaryId, callerId, userID, comments);
                //20181217 update, paymentdata means: front-end payment data detail,deduct means: {'Sip_CommonConstant.PAYMENTBYJETACCOUNT','Sip_CommonConstant.PAYMENTBYACCOUNT','Sip_CommonConstant.PAYMENTBYAGREEMENT'}
                String transactionNumber = beverageCouponObj.commitTransaction (requestInfo, payerId, beneficiaryId, callerId, userID, comments, paymentdata, deduct);

                beverageCouponObj.populateBeverageCouponViewModel(transactionNumber);

                return beverageCouponObj.getViewModel();
            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(),   Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_BeverageCoupon beverageCouponObj = new Sip_BeverageCoupon ();
                beverageCouponObj.success = false;
                beverageCouponObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                //20170613 Added amount back if it is not added 
                if (!isAmountAdded) {
                    // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                    Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
                }
                return beverageCouponObj.getViewModel();
            }
        }
    }
    
    @RemoteAction
    global static Sip_RemotingResultAbstract sendTravelCertEmails (String htmlBody, String email, String userId, String transactionNumber) {
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userID)) {
            Sip_SessionCacheManager.insertGEHError(className + '.sendTravelCertEmails', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, '');
            return null;
        }else{
        //End
            String methodName = 'sendTravelCertEmails';

            /* REQ-0581: get # of retries if callout fails */
            integer numRetryAttempts = numRetryAttempts('Cert Email');
            
            try{
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);
                String html = htmlBody;
                html = html.escapeUnicode();

                String htmlformat = String.format('"ToAddress":"{0}","TextBody":"Test","Subject":"United Jetstream Travel Certificate","HtmlBody":"{1}","FromName":"United Jetstream","FromAddress":"jetstream-noreply@united.com","Format":2', new String[]{email, html});
                htmlformat = '{' + htmlformat;
                htmlformat = htmlformat + '}';

                Sip_HttpUtil.CalloutInfoWrapper CertEmailCalloutInfoWrapper = Sip_HttpUtil.createCalloutInfoPackage (htmlformat, 'sendTravelCertEmail', 'SIP OAuth', null, null, 'Send Cert Email', 'Send Cert Email', '', 'Cert Email' , 'Cert Email', className, methodName, '');
                Sip_HttpUtil h = new Sip_HttpUtil(CertEmailCalloutInfoWrapper);
                HttpResponse httpResp = h.callout();

                String afterHttpValid = Sip_HttpUtil.validateHTTPResponse(httpResp);

                if (test.isRunningTest() && numRetryAttempts > 0) {
                    afterHttpValid = '{"Errors": [{"MajorCode": "20003.01", "MinorDescription": "Service Error \u00e2\u20ac\u201c Processing error", "Message": "Object reference not set to an instance of an object.", "MinorCode": "10036", "MajorDescription": "email/SendEmail", "CallTime": "2017-06-15T03:36:52.8013578-05:00"}, {"MajorCode": "20003.01", "MinorDescription": "Service Error \u00e2\u20ac\u201c Processing error", "Message": "Test Error", "MinorCode": "9999", "MajorDescription": "email/SendEmail", "CallTime": "2017-06-15T03:36:52.8013578-05:00"}], "LastCallDateTime": "06/15/2017 03:36:52", "EmailMessage": null, "Status": 0, "CallTime": "06/15/2017 03:36:52"}';
                }

                Sip_TravelCertEmail travelCertEmailObj = new Sip_TravelCertEmail();
                
                //if res is null or status code is not 200, display common error
                if (afterHttpValid.equals(Label.Sip_Common_Error)) {
                    String errorMess = Label.Sip_Common_Error;
                    travelCertEmailObj.success = false;
                    travelCertEmailObj.messages.add(errorMess);
                    log.flush();
                    return travelCertEmailObj.getViewModel();

                } else {
                    
                    /* ---RESPONSE AND STATUS OK--- */

                    //parse and validate response
                    travelCertEmailObj.parseTravelCertRes(afterHttpValid);
                    travelCertEmailObj.validateTravelCertEmail(userInfoModel, userManagementInfo);

                    /* ---EMAIL SUCCESS--- */
                    if (travelCertEmailObj.success) {
                        //20170628 save email history
                        Sip_CommonUtility.insertEmailAddressAmenity(transactionNumber, email);

                    } else {
                        /* ---EMAIL NOT SUCCESSFUL--- */

                        /* REQ-0581: resend it if retryRecall is true */
                        integer retryNum = 0;
                        if (travelCertEmailObj.retryCallout) {
                            boolean retryCallout = travelCertEmailObj.retryCallout;
                            while (retryNum < numRetryAttempts && retryCallout) {
                                httpResp = h.callout();
                                afterHttpValid = Sip_HttpUtil.validateHTTPResponse(httpResp);
                                travelCertEmailObj = new Sip_TravelCertEmail();
                                travelCertEmailObj.parseTravelCertRes(afterHttpValid);
                                travelCertEmailObj.validateTravelCertEmail(userInfoModel, userManagementInfo);
                                retryCallout = travelCertEmailObj.retryCallout;
                                retryNum++;         
                            } 
                        }

                        /* ---AFTER RETRIES, CHECK SUCCESS--- */
                        if (travelCertEmailObj.success) {
                            //20170628 save email history
                            Sip_CommonUtility.insertEmailAddressAmenity(transactionNumber, email);
                        } 

                        //if retries were needed, make sure we are notified
                        if (retryNum > 0) {
                            string errorMessage;
                            if (travelCertEmailObj.success) {
                                errorMessage = 'sendTravelCertEmails successful, attempted ' + (retryNum + 1) + ' times.';
                            } else {
                                errorMessage = 'sendTravelCertEmails NOT successful, attempted ' + (retryNum + 1) + ' times.';
                            }
                            log.appendWebserviceError(Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, errorMessage, Sip_CommonConstant.POF.Process.Name(), 'Cert Email', 'Cert Email', className, methodName);
                        }
                    }

                    /* ---FINALLY, WRITE LOG AND RETURN OBJ--- */
                    //clear log
                    log.flush();
                    //return to js
                    return travelCertEmailObj.getViewModel(); 
                }
            } catch(Exception ex) {
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(),   Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_TravelCertEmail travelCertEmailObj = new Sip_TravelCertEmail();
                travelCertEmailObj.success = false;
                travelCertEmailObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return travelCertEmailObj.getViewModel();
            }
        }
    }

    @RemoteAction
    public static Sip_RemotingResultAbstract sendUnitedClubOTPEmail (String emailAddress, List<String> passCode, String userId) {
        String methodName = 'sendUnitedClubOTPEmail';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userID)) {
            Sip_SessionCacheManager.insertGEHError(className + '.sendUnitedClubOTPEmail', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, '');
            return null;
        }else{
        //End
            try{
                String requestInfoFromUI = Json.serialize(Sip_UnitedClubEmail.constructureReqForOTPEmail (emailAddress, passCode));
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                Sip_UnitedClubEmail unitedClubObj = new Sip_UnitedClubEmail ();

                Sip_HttpUtil.CalloutInfoWrapper OTPEmailCalloutInfoWrapper = Sip_HttpUtil.createCalloutInfoPackage (requestInfoFromUI, 'sendOTPEmail', 'SIP OAuth', null, null, '  Send OTP Email', 'Send OTP Email', '', 'Activate Certificate Service' ,' Send OTP Email',  className, methodName, '');

                Sip_HttpUtil h = new Sip_HttpUtil(OTPEmailCalloutInfoWrapper);
                HttpResponse httpResp = h.callout();
                String afterHttpValid = Sip_HttpUtil.validateHTTPResponse(httpResp);
                //20170606 Parse and Validate OTP Email Res
                unitedClubObj.parseUnitedClubEmail(afterHttpValid);
                // unitedClubObj.validateRes(userInfoModel);

                if(afterHttpValid.equals(Label.Sip_Common_Error)){
                    String errorMess = Label.Sip_Common_Error;
                    unitedClubObj.success = false;
                    unitedClubObj.messages.add(errorMess);
                    log.flush();
                    return unitedClubObj.getViewModel();
                }
                log.flush();
                return unitedClubObj.getViewModel();
            }catch(Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(),   Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_UnitedClubEmail unitedClubObj = new Sip_UnitedClubEmail ();
                unitedClubObj.success = false;
                unitedClubObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return unitedClubObj.getViewModel();
            }
        }
    }

    @RemoteAction
    public static Sip_RemotingResultAbstract commitTravelCertsTransaction (
        List<Sip_Activatecertificate.VM_ActivateCert> certResults
        , String proCode
        , String payerId
        , String beneficiaryId
        , String callerId
        , String comments
        , String userID
        , Decimal totalCost
        , String pendingAmountObjId
        , Sip_PaymentDataViewModel paymentdata
        , String deduct
        // New parameters
        , String pendingPayTravelCertExId
        ) {

        String methodName = 'commitTravelCertsTransaction';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        if (!Test.isRunningTest() && String.isBlank(pendingPayTravelCertExId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.commitTravelCertsTransaction', className, 'commitTravelCertsTransaction: pendingPayTravelCertExId', userID, payerId);
            return null;
        }

        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager();
        SIP_Pending_Pay_Travel_Certificate__c pendingPayCert;
        if (!Test.isRunningTest()) {

            List<SIP_Pending_Pay_Travel_Certificate__c> pendingPayTravelCerts = [
                SELECT Id,
                    SIP_Deduct__c,
                    SIP_BeneficiaryId__c,
                    SIP_CallerId__c,
                    SIP_PayerId__c,
                    SIP_PaymentdataJSON__c,
                    SIP_Pending_Amount__c,
                    SIP_Pro_Code__c,
                    SIP_Total_Cost_of_Items__c,
                    SIP_UserID__c,
                    (
                        SELECT Id
                            , SIP_Active_Travel_Cert_Result_JSON__c
                            , SIP_Cost__c
                        FROM Pending_Pay_Travel_Cert_Items__r
                        )
                FROM SIP_Pending_Pay_Travel_Certificate__c
                WHERE SIP_External_ID__c =: pendingPayTravelCertExId
            ];

            if (pendingPayTravelCerts.isEmpty()) {
                Sip_SessionCacheManager.insertGEHError(className + '.commitTravelCertsTransaction', className, 'commitTravelCertsTransaction: pendingPayTravelCerts', userID, payerId);
                return null;
            }
            pendingPayCert = pendingPayTravelCerts[0];
        }

        if (!Test.isRunningTest() && !isSkipCheckInCommitTravelCertsTransaction) {
            if (!Sip_RemoteSecurityUtil.isValidUserId(userID)) {
                Sip_SessionCacheManager.insertGEHError(className + '.commitTravelCertsTransaction', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
                return null;
            }

            if (!sessionObj.validateAmenityAcountId(payerId)) {
                Sip_SessionCacheManager.insertGEHError(className + '.commitTravelCertsTransaction', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
                return null;
            }

            pendingPayCert.SIP_BeneficiaryId__c = String.isBlank(pendingPayCert.SIP_BeneficiaryId__c) ? '' : pendingPayCert.SIP_BeneficiaryId__c;
            pendingPayCert.SIP_CallerId__c = String.isBlank(pendingPayCert.SIP_CallerId__c) ? '' : pendingPayCert.SIP_CallerId__c;

            if (pendingPayCert.SIP_Pro_Code__c != proCode
                || pendingPayCert.SIP_PayerId__c != payerId
                || pendingPayCert.SIP_BeneficiaryId__c != beneficiaryId
                || pendingPayCert.SIP_CallerId__c != callerId
                || pendingPayCert.SIP_UserID__c != userID
                || pendingPayCert.SIP_Total_Cost_of_Items__c != totalCost
                || pendingPayCert.SIP_Pending_Amount__c != pendingAmountObjId
                || pendingPayCert.SIP_PaymentdataJSON__c != JSON.serialize(paymentdata)
                || pendingPayCert.SIP_Deduct__c != deduct
                || pendingPayCert.Pending_Pay_Travel_Cert_Items__r.size() != certResults.size()) {
                Sip_SessionCacheManager.insertGEHError(className + '.commitTravelCertsTransaction', className, 'commitTravelCertsTransaction: all fields checking in pendingPayCert ' + pendingPayCert.Id, userID, payerId);
                return null;
            }
        }

        Boolean isAmountAdded = false;
        //2020 Security issue fix
        Savepoint sp = Database.setSavepoint();
        try{
            Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
            isAmountAdded = true;
            Sip_TravelCertTransaction transactionCertTransactionObj = new Sip_TravelCertTransaction ();
            transactionCertTransactionObj.vTravelCertTransaction.transactionNumber = transactionCertTransactionObj.commitTransaction(certResults, proCode, payerId,  beneficiaryId, comments, userID, callerId, paymentdata, deduct);
            //2020 Security issue fix
            if (!Test.isRunningTest()) {
                Database.delete(pendingPayCert);
            }

            return transactionCertTransactionObj.getViewModel();
        }catch(Exception ex){
            //2020 Security issue fix
            Database.rollback(sp);
            log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
            Sip_TravelCertTransaction transactionCertTransactionObj = new Sip_TravelCertTransaction ();
            transactionCertTransactionObj.success = false;
            transactionCertTransactionObj.messages.add(Label.Sip_Common_Error);
            log.flush();
            //201706013 TBD Added amount 
            //20170613 Added amount back if it is not added 
            if (!isAmountAdded) {
                // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                //20170619 TBD delete pending amount after call out
                Sip_PendingAmount.deletePendingAmount(pendingAmountObjId);
            }
            return transactionCertTransactionObj.getViewModel();
        }
    }

    //20170609 pre deduct the account balance before calling out
    @RemoteAction
    //20181129 update, agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
    // global static Sip_RemotingResultAbstract preDeductAccountBalance (String payerId, Decimal totalCost, String userId) {
    // global static Sip_RemotingResultAbstract preDeductAccountBalance (String payerId, Decimal totalCost, String userId, List<String> agreements, String deduct) {
    //20181207 update the parameters list
    //Sip_PaymentDataViewModel means:the information about payment
    global static Sip_RemotingResultAbstract preDeductAccountBalance (String payerId, Decimal totalCost, String userId, Sip_PaymentDataViewModel paymentDataVM, String deduct) {

        String methodName = 'preDeductAccountBalance';
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix   
        else if(!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.preDeductAccountBalance', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
            return null;
        }
        else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(payerId)){
            Sip_SessionCacheManager.insertGEHError(className + '.preDeductAccountBalance', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
            return null;
        } else if (!Test.isRunningTest() && totalCost < 0) {
            Sip_SessionCacheManager.insertGEHError(className + '.preDeductAccountBalance', className, 'preDeductAccountBalance: totalCost ' + totalCost, userID, payerId);
            return null;
        }else{
        //End
            try{
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);
                Sip_PendingAmount pendingAmountObj = new Sip_PendingAmount();
                // pendingAmountObj.deductAmount(payerId, totalCost, userInfoModel);

                //20181129,update start
                //20170619 TBD generate pending amount 
                // pendingAmountObj.generatePendingAmount (payerId, totalCost, userId, userInfoModel, userManagementInfo);
                // pendingAmountObj.generatePendingAmount (payerId, totalCost, userId, userInfoModel, userManagementInfo, agreements, deduct);
                //20181129,update end

                //20181207 update the parameters list
                //Sip_PaymentDataViewModel means:the information about payment
                pendingAmountObj.generatePendingAmount (payerId, totalCost, userId, userInfoModel, userManagementInfo, paymentDataVM, deduct);
                //2020 Security issue fix. Put pending amount record Id into the session cache
                sessionObj.putPendingAmountId (pendingAmountObj.getpendingAmountId());
                return pendingAmountObj.getViewModel();
            }catch (Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_PendingAmount pendingAmountObj = new Sip_PendingAmount();
                pendingAmountObj.success = false;
                pendingAmountObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return pendingAmountObj.getViewModel();
            }
        }
    }

    @RemoteAction
    //20181203 update, agreements means:the sorted agreements to purchase; deduct means:which way to purchase :{AgreementQuery, MeetAccountQuery, JetAccountQuery}
    // global static Sip_RemotingResultAbstract preDeductAccountBalanceForNomination (String payerId, Decimal totalCost, String premierLevel, String userId) {
    // global static Sip_RemotingResultAbstract preDeductAccountBalanceForNomination (String payerId, Decimal totalCost, String premierLevel, String userId, List<String> agreements, String deduct) {
    //20181213 update, Sip_PaymentDataViewModel means:the information about payment
    global static Sip_RemotingResultAbstract preDeductAccountBalanceForNomination (String payerId, Decimal totalCost, String premierLevel, String userId, Sip_PaymentDataViewModel paymentDataVM, String deduct) {
        String methodName = 'preDeductAccountBalance';
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        //2020 Security issue fix
        if (!Sip_CommonUtility.isLoginUser() || !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.preDeductAccountBalanceForNomination', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
            return null;
        } 
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(payerId)){
            Sip_SessionCacheManager.insertGEHError(className + '.preDeductAccountBalanceForNomination', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
            return null;
        } else if (!Test.isRunningTest() && totalCost < 0) {
            Sip_SessionCacheManager.insertGEHError(className + '.preDeductAccountBalanceForNomination', className, 'preDeductAccountBalanceForNomination: totalCost ' + totalCost, userID, payerId);
            return null;
        }else{
        //End
            try{
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);

                Sip_PendingAmount pendingAmountObj = new Sip_PendingAmount();
                //20170629 Global Service
                if (Sip_PendingAmount.isGlobalService(premierLevel)) {
                    pendingAmountObj.generatePendingAmountWithGlobalService(payerId, premierLevel, userId, userInfoModel, userManagementInfo);
                }else {
                    //20170619 TBD generate pending amount
                    //20181203 start
                    // pendingAmountObj.generatePendingAmount (payerId, totalCost, userId, userInfoModel, userManagementInfo, agreements, deduct);
                    // pendingAmountObj.generatePendingAmount (payerId, totalCost, userId, userInfoModel, userManagementInfo);
                    //20181203 end

                    //20181213 update the parameters list
                    //Sip_PaymentDataViewModel means:the information about payment
                    pendingAmountObj.generatePendingAmount (payerId, totalCost, userId, userInfoModel, userManagementInfo, paymentDataVM, deduct);
                }
                //2020 Security issue fix
                sessionObj.putPendingAmountId(pendingAmountObj.getpendingAmountId());
                return pendingAmountObj.getViewModel();
            }catch (Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_PendingAmount pendingAmountObj = new Sip_PendingAmount();
                pendingAmountObj.success = false;
                pendingAmountObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return pendingAmountObj.getViewModel();
             }
         }
    }

    @RemoteAction
  global static Sip_TransactionEntity.TransactionInfo confirmSubscriptionPayment(String serviceContext,String subProductId,Sip_MerchandizingOffersSubs.VM_Fulfillment_Offer fullFillmentOffer, String userId, String payerId, String beneficiaryId, String callerId, String firstName, String lastName, String comment, String remarks) {
        //2020 Security issue fix
        
        if (!Test.isRunningTest()) {
            Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager();
            if (!Sip_RemoteSecurityUtil.isValidUserId(userID)) {
                Sip_SessionCacheManager.insertGEHError(className + '.confirmSubscriptionPayment', 'Sip_RemoteSecurityUtil', 'isValidUserId', userId, payerId);
                return null;
            }
            if (!sessionObj.validateNormalAcountId(payerId)) {
                Sip_SessionCacheManager.insertGEHError(className + '.confirmSubscriptionPayment', 'Sip_SessionCacheManager', 'validateNormalAcountId', userId, payerId);
                return null;
            }
            if (sessionObj.getPendingAmountId() == null || sessionObj.getPendingAmountId().isEmpty()) {
                Sip_SessionCacheManager.insertGEHError(className + '.confirmSubscriptionPayment', 'Sip_SessionCacheManager', 'getPendingAmountId', userId, payerId);
                return null;
            }
            System.debug('sessionObj.getPendingAmountId()==>'+ sessionObj.getPendingAmountId());
            Database.delete(new List<Id>(sessionObj.getPendingAmountId())[0]);            
        }
        log.flush();
        Sip_TransactionEntity.TransactionInfo transactionInfo = new Sip_TransactionEntity.TransactionInfo();
        Map<String, Id> pMap = new Map<String, Id> ();
        List<String> subProductIdList = new List<String>();
        Sip_MerchandizingOffersSubs.VM_Offer selectedSubProductOffer;
    
            // Added by Madhu
            String subProductSelected = 'N';
    if (fullFillmentOffer != null && fullFillmentOffer.Products != null) 
    {
            System.debug('**** Fulfillment Products:'+fullFillmentOffer.Products);
      for (Sip_MerchandizingOffersSubs.VM_Product vmProduct : fullFillmentOffer.Products)
      {
        if (fullFillmentOffer != null && vmProduct.Offers != null) 
        {
                    System.debug('**** vmProduct.Offers:'+vmProduct.Offers);
          for(Sip_MerchandizingOffersSubs.VM_Offer Offer : vmProduct.Offers) 
          {
            if(offer.SubProductId == subProductId)
            {
              selectedSubProductOffer = offer; 
                            subProductIdList.add(Offer.SubProductId);    
                            System.debug('**** selectedSubProductOffer:'+selectedSubProductOffer);
                            subProductSelected = 'Y';
                            break;
            }
          }
        }
                if (subProductSelected == 'Y')
                {
                    break;
                }
      }
        // End code change madhu
        //if (fullFillmentOffer != null && fullFillmentOffer.Products[0].Offers != null) {
        /*
            for(Sip_MerchandizingOffersSubs.VM_Offer Offer : fullFillmentOffer.Products[0].Offers) {
                if(String.isNotBlank(offer.SubProductId) && String.isNotBlank(subProductId) && offer.SubProductId == subProductId){
                    selectedSubProductOffer = offer;
                    subProductIdList.add(Offer.SubProductId);
                }                
            }
      */
      
            if(subProductIdList != NULL && !subProductIdList.isEmpty()){
                Map<Id, SIP_Merch_Offers_Subproduct__c> mapIdSubProduct = new Map<Id, SIP_Merch_Offers_Subproduct__c>([ SELECT  Id,
                                                                                Name, Subproduct_Currency_Code__c,SubProduct_Current_Expiration_Date__c,
                                                                                Subproduct_Price__c,
                                                                                Subproduct_Surname__c, 
                                                                                Subproduct_First_Name__c,
                                                                                Subproduct_OD_Departure__c,
                                                                                Subproduct_OD_Arrival__c,
                                                                                Merch_Offers__r.First_Name__c,
                                                                                Merch_Offers__r.Surname__c,
                                                                                Merch_Offers__r.Customer_ID__c,
                                                                                Subproduct_Effective_Date__c,
                                                                                Subproduct_Expiration_Date__c,
                                                                                Subproduct_Description__c,
                                                                                Subproduct_isUpgrade__c,
                                                                                Merch_Offers__r.Current_Premier_Status__c
                                                                        FROM    SIP_Merch_Offers_Subproduct__c
                                                                        WHERE   Id = :subProductId]);
                if(mapIdSubProduct != NULL & !mapIdSubProduct.values().isEmpty()){
                    Sip_SubscriptionPayment payment = new Sip_SubscriptionPayment(serviceContext, payerId, userId, beneficiaryId, callerId, comment, mapIdSubProduct);
                    payment.addRemark(remarks);
                    payment.callerFirstName = String.isNotBlank(firstName) ? firstName : null;
                    payment.callerLastName = String.isNotBlank(lastName) ? lastName : null;
                    if(String.isNotBlank(selectedSubProductOffer.SubProductId) 
                        && mapIdSubProduct.containsKey(selectedSubProductOffer.SubProductId)){
                        Sip_SubscriptionPaymentEntry paymentEntry = new Sip_SubscriptionPaymentEntry(serviceContext,selectedSubProductOffer, mapIdSubProduct.get(selectedSubProductOffer.SubProductId));
                        payment.addEntry(paymentEntry);
                    }
                    transactionInfo.referenceNumber = payment.purchase();
                    //Add NewExpiryDate for Transaction Modal Popup
                    if(transactionInfo.referenceNumber != null){
                        List<SIP_Transactions_line_item__c> trans = [Select Id,SIP_Expiration_Date__c FROM SIP_Transactions_line_item__c WHERE SIP_Banking_Audit__r.Name =: transactionInfo.referenceNumber];
                        if(trans != null && trans.size() > 0 && trans[0].SIP_Expiration_Date__c != null){
                            transactionInfo.NewExpiryDate = DateTime.newInstance(trans[0].SIP_Expiration_Date__c.year(),
                                                            trans[0].SIP_Expiration_Date__c.month(),
                                                            trans[0].SIP_Expiration_Date__c.day()).format('MMM dd, yyyy');
                        }
                    }
                    System.debug('NewExpiryDate:'+transactionInfo.NewExpiryDate);                   
                    System.debug('Ref no:'+transactionInfo.referenceNumber);                   
                }
            }
            System.debug('txnWrapper' + Json.serialize(transactionInfo));
            return transactionInfo;
        }
        return null;
  }   


    //20170613 Add amount back 
    @RemoteAction
    global static Sip_RemotingResultAbstract addAmount (String payerId, Decimal totalCost, String userId, String pendingAmountObjId) {
        String methodName = 'addAmount';
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.addAmount', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, payerId);
            return null;
        } else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(payerId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.addAmount', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, payerId);
            return null;
        }else{
        //End
            try{
                Sip_UserInfo userInfoItem = new Sip_UserInfo(userId);
                Sip_UserModel.Sip_UserInfo userInfoModel = userInfoItem.getUserInfoById();
                SIP_User_Management__c userManagementInfo= Sip_UserManagementUtil.getUserAccountPermission(userId);
                Sip_PendingAmount pendingAmountObj = new Sip_PendingAmount();
                // Sip_PendingAmount.updateAccountBalanceWithPendingAmount(payerId, totalCost, Sip_CommonConstant.OPERATORADD);
                //20170619 TBD delete pending amount after call out
                Sip_PendingAmount.deletePendingAmount (pendingAmountObjId);
                return pendingAmountObj.getViewModel();
            }catch (Exception ex){
                //20190130 lijuna update,comment out debug
                /*System.debug(LoggingLevel.INFO, '*** ex.getMessage(): ' + ex.getMessage());
                System.debug(LoggingLevel.INFO, '*** ex.getLineNumber(): ' + ex.getLineNumber());
                System.debug(LoggingLevel.INFO, '*** ex.getTypeName(): ' + ex.getTypeName());
                System.debug(LoggingLevel.INFO, '*** ex.getStackTraceString(): ' + ex.getStackTraceString());*/
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_PendingAmount pendingAmountObj = new Sip_PendingAmount();
                pendingAmountObj.success = false;
                pendingAmountObj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return pendingAmountObj.getViewModel();
             }
         }
    }

    //20181025 lijuan Add get approval Agreement list by AccId for purchase 
    @RemoteAction
    global static Sip_RemotingResult getAgreementVMListByMeetAccount(String userId, String accId) {
        String methodName = 'getAgreementVMListByMeetAccount';
        Sip_RemotingResult returnResult;
        //2020 Security issue fix
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();
        //Add by Crystal 11/26/2018
        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }
        //2020 Security issue fix
        else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getAgreementVMListByMeetAccount', 'Sip_RemoteSecurityUtil', 'isValidUserId', userID, accId);
            return null;
        } else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(accId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.getAgreementVMListByMeetAccount', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, accId);
            return null;
        }else{
        //End
            try {
                Sip_MeetingAgreementVMManagement managementObj = new Sip_MeetingAgreementVMManagement(userId, accId);           
                returnResult = new Sip_RemotingResult (managementObj.getAgreementVMListByMeetAccount(), true, '');
                return returnResult;
            } catch (Exception ex) {
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                log.flush();
                return new Sip_RemotingResult (false, Label.Sip_Common_Error);
            }
        }
    }

    /* REQ-0581: return number of retries */
    public static integer numRetryAttempts(string csName) {
        decimal numRetryAttempts = 0;
        Callout_Settings__c cs = Callout_Settings__c.getInstance(csName);
        if (cs != null) {
            if (cs.Active__c) {
                numRetryAttempts = cs.Num_Retry_Attempts__c;
            } 
        }
        return Integer.valueOf(numRetryAttempts);
    }
    
    //20210917 Moin Task 7079 :: HTTP Callout to get Offers
    @RemoteAction
    global static Sip_RemotingResultAbstract retrieveMerchOffersSubs(String merchOfferRecordId,String productCode,String userId,String accountId,String serviceContext){
        String methodName = 'retrieveMerchOffersSubs';
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();

        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.retrieveMerchOffersSubs', 'Sip_RemoteSecurityUtil', 'isValidUserId', userId,'');
            return null;
        }else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(accountId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.retrieveMerchOffersSubs', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, accountId);
            return null;
        }else{
            try{
                //Updated By Moin :: Execute only for Baggage/Economy Plus/United Club Membership/WIFI Subscription Tiles
                if(serviceContext == Label.Sip_Amenity_Baggage_Subscriptions
                    || serviceContext == Label.Sip_Amenity_Economy_Plus_Subscriptions
                    || serviceContext == Label.Sip_Amenity_Club_Membership_Subscriptions
                    || serviceContext == Label.Sip_Amenity_United_WIFI_Subscriptions){
                    SIP_Merch_Offers__c offer = [Select Id,Customer_ID__c,First_Name__c,Surname__c,Current_Premier_Status__c FROM SIP_Merch_Offers__c WHERE Id =:merchOfferRecordId];
                
                    Sip_MerchandizingOffersSubs.CM_MerchandizingOffersRequestBody resquestBody = new Sip_MerchandizingOffersSubs.CM_MerchandizingOffersRequestBody();
                    resquestBody.Requester.Requestor.ChannelName = Sip_CommonConstant.CHANNELNAMEFORSUBSERVER;
                    resquestBody.Requester.Requestor.ChannelID = Sip_CommonConstant.CHANNELIDFORSUBSERVER;
                    resquestBody.Requester.Requestor.LanguageCode = Sip_CommonConstant.LANGUAGECODEFORSUBSERVER;
                    Sip_MerchandizingOffersSubs.CM_Characteristic chars = new Sip_MerchandizingOffersSubs.CM_Characteristic();
                    chars.code = Sip_CommonConstant.CHARACTRISTIC_CODE;
                    chars.value ='true';
                    resquestBody.Requester.Requestor.Characteristic = new List<Sip_MerchandizingOffersSubs.CM_Characteristic>{chars};
                    
                    Sip_MerchandizingOffersSubs.CM_Filter filter = new Sip_MerchandizingOffersSubs.CM_Filter();
                    filter.IsIncluded = 'true';
                    filter.ProductCode = productCode;
                    resquestBody.Filters = new List<Sip_MerchandizingOffersSubs.CM_Filter>{filter};
    
                    Sip_MerchandizingOffersSubs.CM_RProductLoyaltyProgramProfile profile = new Sip_MerchandizingOffersSubs.CM_RProductLoyaltyProgramProfile();
                    profile.IsPrimary = 'True';
                    profile.LoyaltyProgramCarrierCode = Sip_CommonConstant.UACARRIERCODE;
                    profile.LoyaltyProgramMemberID = offer.Customer_ID__c;
                    profile.LoyaltyProgramMemberTierDescription = 0;
    
                    //20210921 Moin Task 7079 :: prepare request attributes based on the product code
                    Sip_MerchandizingOffersSubs.CM_RTraveler traveler = new Sip_MerchandizingOffersSubs.CM_RTraveler();
                    traveler.ProductLoyaltyProgramProfile = new List<Sip_MerchandizingOffersSubs.CM_RProductLoyaltyProgramProfile>{profile};
                    traveler.ID = '1';
                    resquestBody.Travelers = new List<Sip_MerchandizingOffersSubs.CM_RTraveler>{traveler};
                    
                    Sip_HttpUtil.CalloutInfoWrapper offerCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                    offerCalloutInfo.requestBodyInJson = JSON.serialize(resquestBody);
                    offerCalloutInfo.integrationType = 'GetMerchandizingoffers';
                    offerCalloutInfo.oauthType = 'SIP OAuth';
                    offerCalloutInfo.headers = null;
                    offerCalloutInfo.logInformation = 'Get Offer Details';
                    offerCalloutInfo.actionDescription = 'Get Offer Details';
                    offerCalloutInfo.logMessage = '';
                    offerCalloutInfo.serviceName = 'Merch Offer';
                    offerCalloutInfo.serviceMethod = 'Merch Offer';
                    offerCalloutInfo.contextClass = className;
                    offerCalloutInfo.contextMethod = methodName;
    
                    Sip_HttpUtil h = new Sip_HttpUtil (offerCalloutInfo);
                    HTTPResponse htttpRes = h.callout();
                    String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                    //START :: 20211005 Moin Task 7080 :: Logic for return of view model for merchandizing offer service        
                    Sip_MerchandizingOffersSubs obj = new Sip_MerchandizingOffersSubs();
                    if (resAfterHttpValidation.equals(Label.Sip_Common_Error)) {
                        String errorMsg = Label.Sip_Common_Error;
                        obj.vMerchandizingOffers.success = false;
                        obj.vMerchandizingOffers.messages.add(errorMsg);
                        log.flush();
                        return obj.vMerchandizingOffers;
                    }
                    obj.parseMerchandizingOffersInfo(resAfterHttpValidation,merchOfferRecordId,accountId,serviceContext);
                    //obj.populateVMerchandizingOffers(merchOfferRecordId,offer.First_Name__c,offer.Surname__c,offer.Customer_ID__c,offer.Current_Premier_Status__c);
    
                    if(!obj.success){
                        Sip_MerchandizingOffersSubs.VM_MerchandizingOffers obj1 = new Sip_MerchandizingOffersSubs.VM_MerchandizingOffers();
                        obj1.success = false;
                        obj1.messages.addAll(obj.messages);
                        return obj1;
                    }
                    //TASK 19494 Scenario 2::Moin::VM For No Offers in response
                    /*if(obj.success && obj.vMerchandizingOffers.DropdownSubProductToShow == null && obj.vMerchandizingOffers.CurrentsubProducts == null){
                        Sip_MerchandizingOffersSubs.VM_MerchandizingOffers obj1 = new Sip_MerchandizingOffersSubs.VM_MerchandizingOffers();
                        obj1.success = false;
                        obj1.messages.add(Label.Sip_No_Merch_Offers_Baggage_Subscription);
                        return obj1;
                    }*/
                    log.flush();
                    return obj.vMerchandizingOffers;
                    //END
                }
                return null;
            }catch(Exception ex){
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_MerchandizingOffersSubs.VM_MerchandizingOffers obj = new Sip_MerchandizingOffersSubs.VM_MerchandizingOffers();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return obj;
            }
        }
    }
    
    @RemoteAction
    global static Sip_RemotingResultAbstract executeMerchFullfillmentSubs(Sip_MerchandizingOffersSubs.VM_Fulfillment_Offer fullfillmentOffer ,String subProductId,String transactionNumber,String userId,String accountId,String serviceContext){
        String methodName = 'executeMerchFullfillmentSubs';
        Sip_SessionCacheManager sessionObj = new Sip_SessionCacheManager ();

        if (!Sip_CommonUtility.isLoginUser()) {
            return null;
        }else if (!Test.isRunningTest() && !Sip_RemoteSecurityUtil.isValidUserId(userId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.executeMerchFullfillmentSubs', 'Sip_RemoteSecurityUtil', 'isValidUserId', userId,'');
            return null;
        }else if (!Test.isRunningTest() && !sessionObj.validateAmenityAcountId(accountId)) {
            Sip_SessionCacheManager.insertGEHError(className + '.executeMerchFullfillmentSubs', 'Sip_SessionCacheManager', 'validateAmenityAcountId', userID, accountId);
            return null;
        }else{
            try{
                Sip_MerchandizingOffersSubs.CM_Fulfillment_Offer requestBody = new Sip_MerchandizingOffersSubs.CM_Fulfillment_Offer();
                Sip_MerchandizingOffersSubs.CM_Requester_Fulfillment requester = new Sip_MerchandizingOffersSubs.CM_Requester_Fulfillment();
                requestBody.Requester = requester;
                requestBody.TicketingCountryCode = Sip_CommonConstant.EMD_COUNTRY_CODE;
                
				// Selected subproduct offer from the drop down
                Sip_MerchandizingOffersSubs.VM_Offer selectedSubProductOffer;
				// Selected product to be added to the fulfillment request
				Sip_MerchandizingOffersSubs.CM_Product_Fulfillment product = new Sip_MerchandizingOffersSubs.CM_Product_Fulfillment();
				// Selected product service parameters
				List<Sip_MerchandizingOffersSubs.CM_Parameters_Fulfillment> parameters = new List<Sip_MerchandizingOffersSubs.CM_Parameters_Fulfillment>();
				
				// find the selected product using the sub product id in the fulfillment offer
                for (Sip_MerchandizingOffersSubs.VM_Product vmProduct : fullFillmentOffer.Products)
                {
                    if (fullFillmentOffer != null && vmProduct.Offers != null) {
                        for(Sip_MerchandizingOffersSubs.VM_Offer Offer : vmProduct.Offers) 
						{
                            if(offer.SubProductId == subProductId)
							{
                                selectedSubProductOffer = offer;  
								product.ID = Integer.valueOf(selectedSubProductOffer.OfferId); // Set the Product Id
								// Madhu - Set the product code for the selected offer
								product.Code = vmProduct.ProductCode;
								// Madhu - set the service parameters for the selected offer
								for(Sip_MerchandizingOffersSubs.VM_Parameters vmParameter : vmProduct.Parameters)
								{
									Sip_MerchandizingOffersSubs.CM_Parameters_Fulfillment parameter = new Sip_MerchandizingOffersSubs.CM_Parameters_Fulfillment();
									parameter.Name = vmParameter.ParameterName;
									parameter.Value = vmParameter.ParameterValue;
									parameters.add(parameter);
									product.Parameters = parameters;
									
								}
                            }                
                        }
                    }
                }
               /*if (fullFillmentOffer != null && fullFillmentOffer.Products[0].Offers != null) {
                    for(Sip_MerchandizingOffersSubs.VM_Offer Offer : fullFillmentOffer.Products[0].Offers) {
                        if(offer.SubProductId == subProductId){
                            selectedSubProductOffer = offer;                            
                        }                
                    }
                }
                */
				
				// Get the subproduct details for the selected sub product
                List<SIP_Merch_Offers_Subproduct__c> spRec = [Select Id,Subproduct_Code__c,Subproduct_isUpgrade__c,Merch_Offers__r.Surname__c,Merch_Offers__r.First_Name__c
                                                                FROM SIP_Merch_Offers_Subproduct__c 
                                                                WHERE Id =: subProductId LIMIT 1];
				// Get the banking audit details and get the expiraton date for the sales instrument
                List<Transactions__c> bankingAudit = [Select Id,Name,SIP_Transaction__c,SIP_Status__c,
                                                        (Select Id,Name,SIP_Cost__c,SIP_Expiration_Date__c,EMD_RFISC_Cost_Currency__c  
                                                            FROM Banking_Audit_Detail__r),
                                                        (Select Id From Sales_Instrument_Debit__r)
                                                        FROM Transactions__c
                                                        WHERE Name =: transactionNumber LIMIT 1 ];

                Date endDate = null;
                if(bankingAudit != null && bankingAudit.size() > 0 && bankingAudit[0].Sales_Instrument_Debit__r != null){
                    List<SI_Credit_Debit_Junction__c> SICreditDebitJunction = [select id,Sales_Instrument_Credit__r.end_date__c,Sales_Instrument_Credit__c 
                                                                                from SI_Credit_Debit_Junction__c 
                                                                                where Sales_Instrument_Debit__c = :bankingAudit[0].Sales_Instrument_Debit__r[0].id 
                                                                                and RecordTypeId =: Sip_CommonConstant.RECORD_TYPE_FUND_SOURCE];


                    if(SICreditDebitJunction != null && SICreditDebitJunction.size()>0 && SICreditDebitJunction[0].Sales_Instrument_Credit__r.end_date__c != null){
                        endDate = SICreditDebitJunction[0].Sales_Instrument_Credit__r.end_date__c;
                    }  
                }

				// set the GUIDS information
                List<Sip_MerchandizingOffersSubs.CM_Guid_Fulfillment> Guids = new List<Sip_MerchandizingOffersSubs.CM_Guid_Fulfillment>();
                for(Sip_MerchandizingOffersSubs.VM_Guid vmGuid : fullfillmentOffer.Requester.Guids){
                    Sip_MerchandizingOffersSubs.CM_Guid_Fulfillment guid = new Sip_MerchandizingOffersSubs.CM_Guid_Fulfillment();
                    guid.ID = vmGuid.ID;
                    guid.Name = vmGuid.Name;
                    Guids.add(guid);
                }                
                requestBody.Requester.Guids = Guids;

				// set the requestor information
                Sip_MerchandizingOffersSubs.CM_Requestor_Fulfillment requestor = new Sip_MerchandizingOffersSubs.CM_Requestor_Fulfillment();
                String requestUserType = Sip_UserDMLHandler.getUserTypeByIdForEPlus(UserInfo.getUserId());
				String sharesAAA = Sip_CommonConstant.EMD_SHARES_AAA_MAP.get(requestUserType);
			    String[] components = sharesAAA.split('/');

                requestor.AgentAAA = components[0];
                requestor.AgentSine = components[2];               
                requestor.ChannelID = Sip_CommonConstant.CHANNELIDFORSUBSERVER;
                requestor.ChannelName = Sip_CommonConstant.CHANNELNAMEFORSUBSERVER;
                requestor.DutyCode = components[1];
                requestor.LanguageCode =Sip_CommonConstant.LANGUAGECODEFORSUBSERVER;
                requestBody.Requester.Requestor = requestor;

				// set the Travelers information
                List<Sip_MerchandizingOffersSubs.CM_Traveler_Fulfillment> travelers = new List<Sip_MerchandizingOffersSubs.CM_Traveler_Fulfillment>();
                for(Sip_MerchandizingOffersSubs.VM_Traveler vmTraveler : fullfillmentOffer.Travelers){
                    Sip_MerchandizingOffersSubs.CM_Traveler_Fulfillment traveler = new Sip_MerchandizingOffersSubs.CM_Traveler_Fulfillment();
                    traveler.TravelerNameIndex = '1.1';//vmTraveler.TravelerNameIndex;
                    traveler.ID = Integer.valueOf(vmTraveler.TravelerID);
                    //Moin::Decode Surname
                    traveler.Surname = EncodingUtil.base64Decode(spRec[0].Merch_Offers__r.Surname__c).toString();
                    //Moin::Decode First Name
                    traveler.GivenName = EncodingUtil.base64Decode(spRec[0].Merch_Offers__r.First_Name__c).toString();
                    Sip_MerchandizingOffersSubs.CM_ProductLoyaltyProgramProfile_Fulfillment programProfile = new 						 Sip_MerchandizingOffersSubs.CM_ProductLoyaltyProgramProfile_Fulfillment();
                    programProfile.LoyaltyProgramMemberID = vmTraveler.ProductLoyaltyProgramProfile[0].LoyaltyProgramMemberID;
                    traveler.ProductLoyaltyProgramProfile = new List<Sip_MerchandizingOffersSubs.CM_ProductLoyaltyProgramProfile_Fulfillment>{programProfile};
                    travelers.add(traveler);
                }
                requestBody.Travelers = travelers;

				/*
                Sip_MerchandizingOffersSubs.CM_Product_Fulfillment product = new Sip_MerchandizingOffersSubs.CM_Product_Fulfillment();
                product.Code = fullfillmentOffer.Products[0].ProductCode;
                List<Sip_MerchandizingOffersSubs.CM_Parameters_Fulfillment> parameters = new List<Sip_MerchandizingOffersSubs.CM_Parameters_Fulfillment>();
                for(Sip_MerchandizingOffersSubs.VM_Parameters vmParameter : fullfillmentOffer.Products[0].Parameters){
                    Sip_MerchandizingOffersSubs.CM_Parameters_Fulfillment parameter = new Sip_MerchandizingOffersSubs.CM_Parameters_Fulfillment();
                    parameter.Name = vmParameter.ParameterName;
                    parameter.Value = vmParameter.ParameterValue;
                    parameters.add(parameter);
                }
                product.Parameters = parameters;
				*/

				// Set the subscription details for the selected sub product offer
                Sip_MerchandizingOffersSubs.CM_Details_Fulfillment details = new Sip_MerchandizingOffersSubs.CM_Details_Fulfillment();
                details.ActivationType = selectedSubProductOffer.Subscription.Details.ActivationType;
                details.Code = selectedSubProductOffer.Subscription.Details.Code;
                details.IsAutoRenew = selectedSubProductOffer.Subscription.Details.IsAutoRenew;
                details.PurchaseType = selectedSubProductOffer.Subscription.Details.PurchaseType;
                if(spRec[0].Subproduct_isUpgrade__c == 'Y'){
                    details.IsUpgrade = 'true';
                }                
            
                Sip_MerchandizingOffersSubs.CM_Subscription_Fulfillment subscription = new Sip_MerchandizingOffersSubs.CM_Subscription_Fulfillment();
                subscription.Details = details;

				// Set the traveler association for the selected sub product offer
                Sip_MerchandizingOffersSubs.CM_Assocatiation_Fulfillment associtation = new Sip_MerchandizingOffersSubs.CM_Assocatiation_Fulfillment();
                associtation.TravelerRefIDs = selectedSubProductOffer.Association.TravelerRefIDs;

				// Set the totals price information                
                List<Sip_MerchandizingOffersSubs.CM_Totals_Fulfillment> totals = new List<Sip_MerchandizingOffersSubs.CM_Totals_Fulfillment>();
                //For Totals
                for(Sip_MerchandizingOffersSubs.VM_Totals vTotal : selectedSubProductOffer.PaymentOption.PriceComponents[0].PCPrice.Totals){
                    Sip_MerchandizingOffersSubs.CM_Totals_Fulfillment total = new Sip_MerchandizingOffersSubs.CM_Totals_Fulfillment();
                    total.Amount = vTotal.TotalsAmount;
                    total.Type = selectedSubProductOffer.PaymentOption.POType;
                    Sip_MerchandizingOffersSubs.CM_Currency_Fulfillment cT = new Sip_MerchandizingOffersSubs.CM_Currency_Fulfillment();
                    cT.Code = vTotal.CurrencyTemp.Code;
                    total.CurrencyTemp = cT;
                    totals.add(total);
                }

                 //Set  Base Price
                List<Sip_MerchandizingOffersSubs.CM_BasePrice_Fulfillment> basePrice = new List<Sip_MerchandizingOffersSubs.CM_BasePrice_Fulfillment>();
                for(Sip_MerchandizingOffersSubs.VM_BasePrice vBase : selectedSubProductOffer.PaymentOption.PriceComponents[0].PCPrice.BasePrice){
                    Sip_MerchandizingOffersSubs.CM_BasePrice_Fulfillment bp = new Sip_MerchandizingOffersSubs.CM_BasePrice_Fulfillment();
                    bp.Amount = vBase.BasePriceAmount;
                    bp.Type = selectedSubProductOffer.PaymentOption.POType;
                    Sip_MerchandizingOffersSubs.CM_Currency_Fulfillment cT = new Sip_MerchandizingOffersSubs.CM_Currency_Fulfillment();
                    cT.Code = vBase.CurrencyTemp.Code;
                    bp.CurrencyTemp = cT;
                    basePrice.add(bp);
                }
               
                Sip_MerchandizingOffersSubs.CM_Price_Fulfillment pPrice = new Sip_MerchandizingOffersSubs.CM_Price_Fulfillment();
                pPrice.BasePrice = basePrice;
                pPrice.Totals = totals;

                List<Sip_MerchandizingOffersSubs.CM_PriceComponent_Fulfillment> priceComponents = new List<Sip_MerchandizingOffersSubs.CM_PriceComponent_Fulfillment>();
                Sip_MerchandizingOffersSubs.CM_PriceComponent_Fulfillment priceComponent = new Sip_MerchandizingOffersSubs.CM_PriceComponent_Fulfillment();
                priceComponent.Price = pPrice;
                priceComponents.add(priceComponent);

                List<Sip_MerchandizingOffersSubs.CM_PaymentOption_Fulfillment> paymentOptions = new List<Sip_MerchandizingOffersSubs.CM_PaymentOption_Fulfillment>();
                Sip_MerchandizingOffersSubs.CM_PaymentOption_Fulfillment paymentOption = new Sip_MerchandizingOffersSubs.CM_PaymentOption_Fulfillment();
                paymentOption.Type = selectedSubProductOffer.PaymentOption.POType;
                paymentOption.EDDCode = selectedSubProductOffer.PaymentOption.EDDCode;
                paymentOption.PriceComponents = priceComponents;
                
                List<Sip_MerchandizingOffersSubs.CM_Offer_Fulfillment> offers = new List<Sip_MerchandizingOffersSubs.CM_Offer_Fulfillment>();
                Sip_MerchandizingOffersSubs.CM_Offer_Fulfillment offer = new Sip_MerchandizingOffersSubs.CM_Offer_Fulfillment();
                offer.GroupCode = selectedSubProductOffer.GroupCode;
                offer.SubGroupCode = selectedSubProductOffer.SubGroupCode;
                offer.ID = Integer.valueOf(selectedSubProductOffer.OfferId);
                offer.Subscription = subscription;
                offer.Assocatiation = associtation;
                offer.PaymentOption = paymentOption;
                offers.add(offer);

                List<Sip_MerchandizingOffersSubs.CM_Product_Fulfillment> products = new List<Sip_MerchandizingOffersSubs.CM_Product_Fulfillment>();
                //product.ID = Integer.valueOf(selectedSubProductOffer.OfferId); // Set the Product Id
                //product.Code = fullfillmentOffer.Products[0].ProductCode;
                //product.Parameters = parameters; // Set the product parameters
                product.Offers = offers;  // Set the offers for the product
                products.add(product);

                Sip_MerchandizingOffersSubs.CM_Cart_Fulfillment cart = new Sip_MerchandizingOffersSubs.CM_Cart_Fulfillment();
                cart.Products = products;

                Sip_MerchandizingOffersSubs.CM_PurchaseDetail_Fulfillment purchaseDetail = new Sip_MerchandizingOffersSubs.CM_PurchaseDetail_Fulfillment();
                purchaseDetail.Cart = cart;
                
                Sip_MerchandizingOffersSubs.CM_Miscellaneous_Fulfillment miss = new Sip_MerchandizingOffersSubs.CM_Miscellaneous_Fulfillment();
                miss.MiscFopType = Sip_CommonConstant.EMD_MISC_FOP_TYPE;
                if(bankingAudit != null && bankingAudit.size() > 0){
                    miss.AccountNumber = bankingAudit[0].SIP_Transaction__c;
                    miss.AuditNumber = bankingAudit[0].Name;  
                    if(bankingAudit[0].Banking_Audit_Detail__r != null){
                        miss.Amount = bankingAudit[0].Banking_Audit_Detail__r[0].SIP_Cost__c;
                        miss.DocumentId = bankingAudit[0].Banking_Audit_Detail__r[0].Name;
                        miss.ExpirationDate = String.valueOf(endDate);
                        Sip_MerchandizingOffersSubs.CM_Currenccy_Fulfillment cT = new Sip_MerchandizingOffersSubs.CM_Currenccy_Fulfillment();
                        cT.Code = bankingAudit[0].Banking_Audit_Detail__r[0].EMD_RFISC_Cost_Currency__c;
                        miss.CurrencyTemp = cT;
                    }              
                }                

                Sip_MerchandizingOffersSubs.CM_FormOfPayment_Fulfillment formOfPayment = new Sip_MerchandizingOffersSubs.CM_FormOfPayment_Fulfillment();
                formOfPayment.Miscellaneous = miss;
                
                List<Sip_MerchandizingOffersSubs.CM_Associations_Fulfillment> associations = new List<Sip_MerchandizingOffersSubs.CM_Associations_Fulfillment>();
                Sip_MerchandizingOffersSubs.CM_Associations_Fulfillment association = new Sip_MerchandizingOffersSubs.CM_Associations_Fulfillment();
                association.OfferID = Integer.valueOf(selectedSubProductOffer.OfferId);
                association.ProductID = Integer.valueOf(selectedSubProductOffer.OfferId); 
                associations.add(association);

                List<Sip_MerchandizingOffersSubs.CM_PaymentDetails_Fulfillment> paymentDetails = new List<Sip_MerchandizingOffersSubs.CM_PaymentDetails_Fulfillment>();
                Sip_MerchandizingOffersSubs.CM_PaymentDetails_Fulfillment paymentDetail = new Sip_MerchandizingOffersSubs.CM_PaymentDetails_Fulfillment();
                paymentDetail.FormOfPayment = formOfPayment;
                paymentDetail.Associations = associations;
                paymentDetails.add(paymentDetail);

                Sip_MerchandizingOffersSubs.CM_Payment_Fulfillment payment = new Sip_MerchandizingOffersSubs.CM_Payment_Fulfillment();
                payment.PaymentDetails = paymentDetails;

                purchaseDetail.Payment = payment;
                requestBody.PurchaseDetail = purchaseDetail;

                String requestBodyJson = JSON.serialize(requestBody);
                requestBodyJson = requestBodyJson.replace('"CurrencyTemp"', '"Currency"');
                Sip_HttpUtil.CalloutInfoWrapper offerCalloutInfo = new Sip_HttpUtil.CalloutInfoWrapper ();
                offerCalloutInfo.requestBodyInJson = requestBodyJson;
                offerCalloutInfo.integrationType = 'MerchFulfillment';
                offerCalloutInfo.oauthType = 'SIP OAuth';
                offerCalloutInfo.headers = null;
                offerCalloutInfo.logInformation = 'Get Purchase Details';
                offerCalloutInfo.actionDescription = 'Get Purchase Details';
                offerCalloutInfo.logMessage = '';
                offerCalloutInfo.serviceName = 'Purchase';
                offerCalloutInfo.serviceMethod = 'PurchaseProducts';
                offerCalloutInfo.contextClass = className;
                offerCalloutInfo.contextMethod = methodName;

                Sip_HttpUtil h = new Sip_HttpUtil (offerCalloutInfo);
                HTTPResponse htttpRes = h.callout();
                String resAfterHttpValidation = Sip_HttpUtil.validateHTTPResponse(htttpRes);
                Sip_MerchandizingOffersSubs.CM_FullfillmentOffer subscriptionsResponse = (Sip_MerchandizingOffersSubs.CM_FullfillmentOffer) JSON.deserialize(resAfterHttpValidation, Sip_MerchandizingOffersSubs.CM_FullfillmentOffer.class);
                
                if(subscriptionsResponse.Response.Error != NULL && !subscriptionsResponse.Response.Error.isEmpty()){
                    Sip_MerchandizingOffers.VM_MerchandizingOffers obj = new Sip_MerchandizingOffers.VM_MerchandizingOffers();
                    obj.success = false;
                    obj.messages.add(Label.Sip_Amenity_Fulfillment_Service_Error);
                    log.flush();
                    return obj;
                }

                Map<String,String> mapEDDKeyValue = new Map<String,String>();
                if(subscriptionsResponse.Confirmations != NULL && !subscriptionsResponse.Confirmations.isEmpty()){
                    for(Sip_MerchandizingOffersSubs.CM_Confirmation row : subscriptionsResponse.Confirmations){
                        if(row.Error != NULL && !row.Error.isEmpty() && row.Error[0].Description == 'SUCCESS' ){
                            mapEDDKeyValue.put('EDDIssueDate',row.EDDIssueDate);
                            mapEDDKeyValue.put('EDDConfirmationNumber',row.EDDConfirmationNumber);
                            mapEDDKeyValue.put('EDDStatus','H');//Waiting for Merchindizing team to send
                        }
                    }
                }

                if(bankingAudit[0].Banking_Audit_Detail__r != null && mapEDDKeyValue != null && !mapEDDKeyValue.isEmpty()){
                    SIP_Transactions_line_item__c lineItemToUpdate = new SIP_Transactions_line_item__c();
                    lineItemToUpdate.Id = bankingAudit[0].Banking_Audit_Detail__r[0].Id;
                    if(mapEDDKeyValue.containsKey('EDDConfirmationNumber')){
                        lineItemToUpdate.EMD_Number__c = mapEDDKeyValue.get('EDDConfirmationNumber');
                    }
                    if(mapEDDKeyValue.containsKey('EDDIssueDate')){
                        // Change by MADHU 01/22/2022
                        /*
                        String eddDate = mapEDDKeyValue.get('EDDIssueDate');
                     List<String> splitDate = eddDate.split('/', 3);
                      String MM = splitDate[0];
                      String DD = splitDate[1];
                      String YYYY = splitDate[2];
                      String tmpDate = MM + '/' + DD + '/' + YYYY;
                        Date issueDate = Date.parse(tmpDate);*/
                                        String eddDate = mapEDDKeyValue.get('EDDIssueDate');
                                        String[] strDTDivided = eddDate.split(' ');
                                        String[] dateval = strDTDivided[0].split('/');
                                        string month = dateval.get(0);
                                        string day = dateval.get(1).replace(',', '');
                                        string year = dateval.get(2);
                                        String stringDate = month + '/' + day + '/' + year;
                        Date issueDate = Date.parse(stringDate);
                        lineItemToUpdate.EMD_Issue_Date__c = issueDate;
                    }
                    //lineItemToUpdate.EMD_Status__c = bankingAudit[0].SIP_Status__c;   
                    if(mapEDDKeyValue.containsKey('EDDStatus')){
                        lineItemToUpdate.EMD_Status__c = mapEDDKeyValue.get('EDDStatus');
                    }                 
                    update lineItemToUpdate;
                }
                return null;
            }catch(Exception ex){
                log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
                Sip_MerchandizingOffersSubs.VM_MerchandizingOffers obj = new Sip_MerchandizingOffersSubs.VM_MerchandizingOffers();
                obj.success = false;
                obj.messages.add(Label.Sip_Common_Error);
                log.flush();
                return obj;
            }
        }
    }





    @RemoteAction
    public static TermsConditionsWrapper getTermConditionContents(String language,String staticPageName){
        String methodName = 'getTermConditionContents';
        try{
            language = String.isBlank(language) ? UserInfo.getLanguage() : language;
            List<TermsConditionsWrapper> agreementWrapperList = new List<TermsConditionsWrapper>();
            TermsConditionsWrapper wrapperObj = new TermsConditionsWrapper();
            // get Meeting Agreement's Miscellaneous Terms and Conditions for New Agreement
            for (Static_Pages_Content__c spc : [SELECT  Name,
                                                        SIP_Default_Language__c,
                                                        Content__c,
                                                        (
                                                            SELECT  SIP_Content__c,
                                                                    SIP_Language__c,
                                                                    SIP_Static_Pages_Content_Name__c,
                                                                    SIP_Status__c
                                                            FROM    Static_Pages_Content_Multiple_Language__r
                                                            WHERE   SIP_Language__c = :language
                                                            AND     SIP_Status__c = 'Published'
                                                            )
                                                FROM    Static_Pages_Content__c
                                                WHERE   Name =:staticPageName 
                                                AND     SIP_Active__c = true]) {

            if(spc.Static_Pages_Content_Multiple_Language__r != NULL && !spc.Static_Pages_Content_Multiple_Language__r.isEmpty()) {
                    spc.Content__c = spc.Static_Pages_Content_Multiple_Language__r[0].SIP_Content__c;
                    spc.Name = spc.Static_Pages_Content_Multiple_Language__r[0].SIP_Static_Pages_Content_Name__c;
                    spc.SIP_Default_Language__c = spc.Static_Pages_Content_Multiple_Language__r[0].SIP_Language__c;
                }
                agreementWrapperList.add(new TermsConditionsWrapper(spc, Label.SipMW_Meeting_Agreement_Terms_Conditions));
                wrapperObj = new TermsConditionsWrapper(spc, Label.SipMW_Meeting_Agreement_Terms_Conditions);
                break;
            }
            if(wrapperObj == NULL){
                wrapperObj = new TermsConditionsWrapper();
				wrapperObj.messages = new List<String>();
                wrapperObj.success = false;
                wrapperObj.messages.add(Label.Sip_Common_Error);
            }
            return wrapperObj;
        }catch(Exception ex){
            log.appendExceptionsInCatchBlock('', Sip_CommonConstant.SIPAPPLICATIONNAME, System.LoggingLevel.Error, ex.getCause() + ' ' + ex.getMessage() + ' ' + ex.getLineNumber() + ' ' + ex.getStackTraceString(), Sip_CommonConstant.POF.Process.Name(), '', '', className, methodName);
            TermsConditionsWrapper wrapperObj = new TermsConditionsWrapper();
            wrapperObj.success = false;
            
            wrapperObj.messages.add(Label.Sip_Common_Error);
            log.flush();
            return wrapperObj;
        }  
    }

    public class TermsConditionsWrapper{
        public Static_Pages_Content__c pageContent;
        public String termsConditionsLabel;
        public Boolean success;
        List<String> messages;
        public TermsConditionsWrapper(){}

        public TermsConditionsWrapper(Static_Pages_Content__c spc,String termsConditionsLabel){
            this.pageContent = spc;
            this.termsConditionsLabel =termsConditionsLabel;
            this.success = true;
        }
    }
}