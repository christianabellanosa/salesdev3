/**
 * Created by Ken
 * Task No. 57001
 * 4/01/2022
 */
public interface SIP_RuleSetEngineInterface {
    List<Id> findRuleSet(String permissionPath);
    void executeRuleSet(List<Id> ruleSetPathIdList);
    Id cloneRuleSet(Id ruleSetId);
    List<Id> generateRuleSetPath(Id ruleSetId);
}