xquery version "3.0";
(:~
 : Shared functions for search modules 
 :)
module namespace common="http://syriaca.org//common";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : Cleans search parameters to replace bad/undesirable data in strings
 : @param-string parameter string to be cleaned
 : NOTE to self: Need to handle ' in full text search, currently stripped before sent to ft:query() function
 due to difficulties with util:eval;
replace(replace($param-string, "^\*", ""),"'",'"')     
replace(replace($param-string, "(^|\W\*)|(^|\W\?)|[&amp;!@#$%^+=_]:", ""),"'",'"')
 replace(replace($text, '&amp;', '&amp;amp;'), '''', '&amp;apos;')
 replace(replace($param-string, "(^|\W\*)|(^|\W\?)|[&amp;!@#$%^+=_]:", ""),"'","")
 
 
 :
:)
declare function common:clean-string($param-string){
replace(replace(replace($param-string, "(^|\W\*)|(^|\W\?)|[!@#$%^+=_]:", ""), '&amp;', '&amp;amp;'), '''', '&amp;apos;')
};

(:~
 : Search options passed to ft:query functions
:)
declare function common:options(){
    <options>
        <default-operator>and</default-operator>
        <phrase-slop>1</phrase-slop>
        <leading-wildcard>no</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
};

(:
 : @depreciated
 : Uses eXistdb syntax to build complex search queries
:)
declare function common:build-query($param-string){
    <query>
        {
        if(starts-with($param-string,'"')) then 
         <query>
             <phrase slop="5">
                 {
                 for $term in tokenize($param-string,' ')
                 return
                     <term>{replace(common:clean-string($term),'"','')}</term>
                 }
             </phrase>
         </query>
        else 
            for $term in tokenize($param-string,' ')
            return 
                <term>{common:clean-string($term)}</term>
        }
    </query>
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

(:
 : Function to truncate description text after first 12 words
 : @param $string
:)
declare function common:truncate-sentance($sentance as xs:string*) as xs:string? {
let $string := string-join($sentance, ' ')
return concat(string-join(for $word in tokenize($string, '\W+')[position() lt 10] return $word, ' '),'...')
};