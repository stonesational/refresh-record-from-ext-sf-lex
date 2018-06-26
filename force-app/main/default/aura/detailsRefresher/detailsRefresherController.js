({
    /*	Update any near-real-time fields with a callout to the System of Record before rendering details
        Used a timeout here to simulate callout time for demo purposes
	 */
    doInit : function(cmp, event, helper) {
        setTimeout(function() { 
            helper.refresh(cmp); 
        }, 3000);
    }
})
