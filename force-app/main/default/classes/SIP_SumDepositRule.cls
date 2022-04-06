/**
 * Created by Kim
 * Task No.56993
 * 3/30/2022
 * Rule: Sum all eligible deposits for an account
 */

public with sharing class SIP_SumDepositRule extends SIP_Rule{
    public SIP_SumDepositRule() {

    }

    public override void execute() {
        System.debug('Inside SIP_SumDepositRule class in execute method');
        //super.execute();
    }
}