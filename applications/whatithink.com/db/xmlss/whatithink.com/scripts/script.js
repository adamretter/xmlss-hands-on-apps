/*
 Copyright 2011 Adam Retter

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

function processListChange(checkbox) {
    
    var isChecked = $(checkbox).is(":checked");
    
    if(!isChecked) {
        $.get("http://localhost:8080/exist/apps/xmlss/whatithink.com/mylist/remove/entry/" + $(checkbox).val(), function(data) {
            $(checkbox).attr("checked", "");
            var li = $(checkbox).parent();
            if(li != null && li.parent().attr("id") == "myEntryList") {
                $(li).remove();
            }
        });
    } else {
        $.get("http://localhost:8080/exist/apps/xmlss/whatithink.com/mylist/add/entry/" + $(checkbox).val(), function(data) {
            $(checkbox).attr("checked", "checked");
        });
    }
}

$(document).ready(function(){
    
    $("#searchResultsList input").each(function(){
        var checkbox = this;
        $(this).click(function(){
            processListChange(checkbox);
        });
    });
    
    $("#userEntryList input").each(function(){
        var checkbox = this;
        $(this).click(function(){
            processListChange(checkbox);
        });
    });
    
    $("#myEntryList input").each(function(){
        var checkbox = this;
        $(this).click(function(){
            processListChange(checkbox);
        });
    });
});