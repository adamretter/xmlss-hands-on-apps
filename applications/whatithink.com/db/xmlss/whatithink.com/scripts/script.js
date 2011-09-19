$(document).ready(function(){
    
    $("#userEntryList input").each(function(){
        $(this).click(function(){
            
            var that = this;
            
            var isChecked = $(that).is(":checked");
            
            if(!isChecked) {
                $.get("../mylist/remove/entry/" + $(that).val(), function(data) {
                    $(that).attr("checked", "");
                });
            } else {
                $.get("../mylist/add/entry/" + $(that).val(), function(data) {
                    $(that).attr("checked", "checked");
                });
            }
        });
    });
});