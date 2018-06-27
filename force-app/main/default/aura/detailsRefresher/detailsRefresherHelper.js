({
    /*	Update any near-real-time fields with a callout to the System of Record before rendering details
        Controller: DetailRefresher_CC
        Method: updateFields
        Parameter: recordId
        Return: none
	 */
    refresh : function(cmp, helper) {
        var action = cmp.get("c.updateFields");
        action.setParams({ argRecordId : cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                const hasUpdate = response.getReturnValue() ? true : false; //null value means no update was made 
                if(hasUpdate){
                    helper.updateRecord(cmp, response.getReturnValue());
                }
                else {
                    $A.util.addClass(cmp.find("spinner"), "slds-hide");
                }
            }
            else if (state === "INCOMPLETE") console.log('Incomplete');
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) console.log("Error message: " + errors[0].message);
                } else console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);       
    },

    updateRecord : function(cmp, record) {
        
        var simpleRecord = cmp.get("v.simpleRecord");
        simpleRecord.Phone = record.Phone;
        simpleRecord.Last_Field_Refresh__c = record.Last_Field_Refresh__c;


        cmp.find("recordHandler").saveRecord(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                // record is saved successfully
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Refreshed",
                    "message": "Phone number was refreshed from a remote source."
                });
                resultsToast.fire();
                $A.util.addClass(cmp.find("spinner"), "slds-hide");
            } else if (saveResult.state === "INCOMPLETE") {
                // handle the incomplete state
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                // handle the error state
                console.log('Problem saving contact, error: ' + 
                             JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state +
                            ', error: ' + JSON.stringify(saveResult.error));
            }
        });
    }
})
