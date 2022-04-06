/**
 * Created by Ken
 * Task No. 57900
 * 4/2/2022
 */
public with sharing class SIP_RuleSetEngine implements SIP_RuleSetEngineInterface{
    public SIP_RuleSetEngine() {

    }

    public List<Id> findRuleSet(String permissionPath){
        //List<Limit__c> limitList = [SELECT Id, Rule_Set__c FROM Limit__c WHERE Id IN (SELECT Limit__c FROM Limit_Line_Item__c WHERE sObjectId__c = :recordId AND LimitItemType__c = :type)];
        //Map<Id, Ruleset_Path__c> ruleSetPathMap = new Map<Id, Ruleset_Path__c>([SELECT Id FROM Ruleset_Path__c WHERE Limit__c IN :limitList]);
        //return new List<Id>(ruleSetPathMap.keySet());
        List<Id> lid = new List<Id>();
        for(Ruleset_Path__c rsp : [SELECT Id, Permission_Path__c FROM Ruleset_Path__c WHERE Permission_Path__c 
        LIKE 'Account=123/Amenity%'
        AND Permission_Path__c = : permissionPath]){
            lid.add(rsp.id);
        }
        return lid;
    }

    public void executeRuleSet(List<Id> ruleSetPathIdList){
        List<Limit__c> limitList = [SELECT Id FROM Limit__c WHERE Id IN (SELECT Limit__c FROM Ruleset_Path__c WHERE Id IN :ruleSetPathIdList)];
        List<Limit_Line_Item__c> limitLineItemList = [SELECT Id, Rule_Id__c, Rule_Id__r.ApexClassName__c,Rule_Id__r.SObjectJsonClassName__c FROM Limit_Line_Item__c WHERE Limit__c IN :limitList];
        List<Rule__c> ruleList = new List<Rule__c>();
        for(Limit_Line_Item__c limitLineItem : limitLineItemList){
            try{
                SIP_RuleInterface ruleInterface = (SIP_RuleInterface)Type.forName(limitLineItem.Rule_Id__r.ApexClassName__c).newInstance();
                ruleInterface.execute();
            }catch(Exception e){
                System.debug(e);
            }
        }

        // List<Ruleset_Path__c> ruleSetPathList = [SELECT Id, Limit__c FROM Ruleset_Path__c WHERE Id IN :ruleSetPathIdList];
        // List<Id> limitIdList = new List<Id>();
        // for(Ruleset_Path__c ruleSetPath : ruleSetPathList){
        //     limitIdList.add(ruleSetPath.Limit__c);
        // }

        // List<Limit_Line_Item__c> limitLineItemList = [SELECT Id, (SELECT Id, ApexClassName__c, SObjectJsonClassName__c FROM Rules__r) FROM Limit_Line_Item__c WHERE Limit__c IN :limitIdList];
        // List<Rule__c> ruleList = new List<Rule__c>();

        // for(Limit_Line_Item__c limitLineItem : limitLineItemList){
        //     ruleList.addAll(limitLineItem.Rules__r);
        // }

        // for(Rule__c rule : ruleList){
        //     try{
        //         SIP_RuleInterface ruleInterface = (SIP_RuleInterface)Type.forName(rule.ApexClassName__c).newInstance();
        //         ruleInterface.execute();
        //     }catch(Exception e){
        //         System.debug(e);
        //     }
        // }
    }

    public Id cloneRuleSet(Id ruleSetId){
        
        Savepoint sp;
        Rule_Set__c ruleSet;
        List<Limit__c> limitList;
        List<Limit_Line_Item__c> limitLineItemList;
        List<Ruleset_Path__c> rulesetPathItemList;
        System.debug('start Clone');
        try{
            System.debug('start try');
            sp = Database.setSavepoint();
            ruleSet = Database.query('SELECT ' + getFieldsForQuery('Rule_Set__c', null) + ' FROM Rule_Set__c WHERE Id= :ruleSetId');
            Rule_Set__c newRuleSet = ruleSet.clone(false, true);
            newRuleSet.Name = 'Clone of '+ruleSet.Name;
            insert newRuleSet;
            
            limitList = Database.query('SELECT ' + getFieldsForQuery('Limit__c', null) + ' FROM Limit__c WHERE Rule_Set__c=:ruleSetId');
            List<Limit__c> newLimitList = new List<Limit__c>();
            List<Id> orderedLimitIdList = new List<Id>();	
            for(Limit__c lim : limitList){
                Limit__c newLimit = lim.clone(false, true);
                newLimit.Rule_Set__c = newRuleSet.Id;
                newLimit.Name = 'Clone of ' +lim.Name;
                orderedLimitIdList.add(lim.Id);
                newLimitList.add(newLimit);
            }
            insert newLimitList;
            limitLineItemList = Database.query('SELECT ' + getFieldsForQuery('Limit_Line_Item__c', null ) + ' FROM Limit_Line_Item__c WHERE Limit__c IN :limitList');
            List<Limit_Line_Item__c> newLimitLineItemList = new List<Limit_Line_Item__c>();
            for(Limit_Line_Item__c lineItem : limitLineItemList){
                Limit_Line_Item__c newLineItem = lineItem.clone(false, true);
                newLineItem.Limit__c = newLimitList.get(orderedLimitIdList.indexOf(newLineItem.Limit__c)).Id;
                newLineItem.Name = 'Clone of ' +lineItem.Name;
                newLimitLineItemList.add(newLineItem);
            }
            insert newLimitLineItemList;
            rulesetPathItemList = Database.query('SELECT ' + getFieldsForQuery('Ruleset_Path__c', null ) + ' FROM Ruleset_Path__c WHERE Limit__c IN :limitList');
            List<Ruleset_Path__c> newRulesetPathList = new List<Ruleset_Path__c>();
            for(Ruleset_Path__c rulesetPathItem : rulesetPathItemList){
                Ruleset_Path__c newRulesetPathItem = rulesetPathItem.clone(false,true);
                newRulesetPathItem.Limit__c = newLimitList.get(orderedLimitIdList.indexOf(newRulesetPathItem.Limit__c)).Id;
                newRulesetPathItem.Name = 'Clone of ' +rulesetPathItem.Name;
                newRulesetPathList.add(newRulesetPathItem);
            }
            insert newRulesetPathList;
            return newRuleSet.Id;
        }  catch (Exception ex)
		{
            system.debug('EXCEPTION in OnboardingQuestionnaireControlListCtrlr.cloneQuestionnaire at row ' + ex.getLineNumber() + ': ' + ex.getMessage());
			if(sp != null)
			{
				Database.rollback(sp);
			}
		}
        return null;
    }
	public static String getFieldsForQuery(string objectName, List<String> additionalFields)
	{
        System.debug('get Fields Query');
		Schema.DescribeSObjectResult[] dors = Schema.describeSObjects(new String[]{objectName});
		Set<String> fields = new Set<String>();

		if(dors != null && !dors.isEmpty())
		{
			Map<String, Schema.SObjectField> fieldsMap = dors[0].fields.getMap();

			for (String fieldName : fieldsMap.keySet())
			{
				fields.add(fieldName.toLowerCase());
			}
		}

        if(additionalFields != null)
		{
			for(String fieldName : additionalFields)
			{
				fields.add(fieldName.toLowerCase());
			}
		}

		return String.join(new List<String>(fields), ', ');
	}

    public List<Id> generateRuleSetPath(Id ruleSetId){

		//List<Rule_Set__c> limitType = [SELECT (SELECT Id, Type__c FROM Limits__r) FROM Rule_Set__c WHERE Id =: ruleSetId];
		
		List<Limit__c> testLimit = [SELECT Id, Type__c FROM Limit__c WHERE Rule_Set__r.Id =: ruleSetId ORDER BY Type__c];
		String limitPath = '';
		Integer i = testLimit.size() - 1;		

		for(Limit__c limitObject : testLimit){
			limitPath = limitPath + limitObject.Type__c + '=' + limitObject.Id;

			if(i-- != 0){
				limitPath = limitPath + '/';
			}
		}
		
		List<Ruleset_Path__c> newRuleRetPathList = new List<Ruleset_Path__c>();
		List<Id> tempLimitId = new List<Id>();

        Integer j = 0;

		for(Limit__c dump : testLimit){
			Ruleset_Path__c rSetPath = new Ruleset_Path__c();
			rSetPath.Name 		   	 = 'Sample Rule Set ' + system.now() + ' ' + j++;
			rSetPath.Match_Type__c 	 = 'Exact Set';
            rSetPath.Limit__c        = dump.Id;
			rSetPath.Limits_Path__c  = limitPath;
			newRuleRetPathList.add(rSetPath);
		}

		insert newRuleRetPathList;

        for(Ruleset_Path__c returnId : newRuleRetPathList){
            tempLimitId.add(returnId.Id);
        }

        return tempLimitId;
    }
}