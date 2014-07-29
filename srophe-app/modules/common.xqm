xquery version "3.0";
(:~
 : Shared functions for search modules 
 :)
module namespace common="http://syriaca.org//common";

(:~
 : Cleans search parameters to replace bad/undesirable data in strings
 : NOTE: need to add handling for * at the beginning of words and in phrases
 : @param-string parameter string to be cleaned
 for $term in $tokenize($param-string,' ') 
return 
if(starts-wth($term),'*') then  
    replace(replace($param-string, "[&amp;!@#$%^+=_]:", ""),'"',"'")
else replace(replace($param-string, "[&amp;!@#$%^+=_]:", ""),'"',"'")   
 :
:)
declare function common:clean-string($param-string){  
 replace(replace($param-string, "[&amp;!@#$%^+=_]:", ""),'"',"'")        
};

(:~
 : Function to cast dates strings from url to xs:date
 : Tests string length, may need something more sophisticated to test dates, 
 : or form validation via js before submit. 
 : @param $date passed to function from parent function
:)
declare function common:do-date($date){
let $date-format := if(string-length($date) eq 4) then concat(string($date),'-01-01')
                    else if(string-length($date) eq 5) then concat(string($date),'-01-01')
                    else if(string-length($date) eq 3) then concat('0',string($date),'-01-01')
                    else if(string-length($date) eq 2) then concat('00',string($date),'-01-01')
                    else if(string-length($date) eq 1) then concat('000',string($date),'-01-01')
                    else string($date)
let $final-date := xs:date($date-format) 
return $final-date
};