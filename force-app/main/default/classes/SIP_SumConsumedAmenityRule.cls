/**
 * Created by Pao
 * Task No.56995
 * 3/30/2022
 * Rule: Sum all monies consumed by Amenity ruleset path =/Account/Amenity
 */
public with sharing class SIP_SumConsumedAmenityRule extends SIP_Rule {
    public SIP_SumConsumedAmenityRule() {

    }


    public override void execute() {
        System.debug('Inside SIP_SumConsumedAmenityRule class in executeRuleSet method');
        //super.execute();
    } 

}