xquery version "3.0";

(: module namespace timeline="http://syriaca.org//timeline"; :)

(:~
 : Module to build timeline json passed to http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js widget
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-08-05
:)
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace xqi="http://xqueryinstitute.org/ns";
declare option exist:serialize "method=json media-type=text/javascript encoding=UTF-8";

declare variable $uri {request:get-parameter('uri', '')};
declare variable $collection {request:get-parameter('collection', '')};
(:
    NOTES on display,
    headline should be person names perhaps Events: PersName
    credit syriaca.org?
:)

(:~
 : Return person record
 : @param $uri matches record uri specified in tei:idno
:)
declare function local:get-pers-rec(){
    for $rec in collection('/db/apps/srophe/data')//tei:idno[. = $uri]
    let $title := string($rec/ancestor::tei:TEI//tei:titleStmt/tei:title[1])
    let $title-en := substring-before($title,'—')
    let $person := $rec/ancestor::tei:TEI//tei:person
    return 
    <json>
        <timeline>
            <headline>{$title-en}</headline>
            <type>default</type>
            <text></text>
            <asset>
                <media>syriaca.org</media>
                <credit>Syriaca.org</credit>
                <caption>Events for {$title-en}</caption>
            </asset>
            {(local:get-pers-birth($person), local:get-pers-death($person), local:get-pers-floruit($person), local:get-pers-state($person), local:get-pers-events($person))}
         </timeline> 
    </json>
    
};

(:~
 : Return all dates in a collection
 : @param $uri matches record uri specified in tei:idno
:)
declare function local:get-all-recs(){
    <json>
        <timeline>
            <headline>Browse by Date</headline>
            <type>default</type>
            <text></text>
            <asset>
                <media>syriaca.org</media>
                <credit>Syriaca.org</credit>
                <caption>Events for Persons</caption>
            </asset>
            {
                for $rec in collection('/db/apps/srophe/data/persons/tei')//tei:body
                let $person := $rec/descendant::tei:person
                return
                (local:get-pers-birth($person), local:get-pers-death($person), local:get-pers-floruit($person), local:get-pers-state($person), local:get-pers-events($person))
            }
         </timeline> 
    </json>
    
};
(:~
 : Build birth date ranges
 : @param $person as node
:)
declare function local:get-pers-birth($person as node()?) as node()?{
    if($person//tei:birth) then
        let $birth-date := $person//tei:birth
        let $start := if($birth-date/@when) then string($birth-date/@when)
                      else if($birth-date/@notBefore) then string($birth-date/@notBefore)
                      else ()
        let $end :=   if($birth-date/@when) then string($birth-date/@when)
                      else if($birth-date/@notAfter) then string($birth-date/@notAfter)
                      else ()                    
        return
            <date json:array="true">
                <startDate>{$start}</startDate>
                <endDate>{$end}</endDate>
                <headline>
                    {string($birth-date)} Birth
                </headline>
            </date>
    else () 
};

(:~
 : Build death date ranges
 : @param $person as node
:)
declare function local:get-pers-death($person as node()?) as node()?{
       if($person//tei:death) then 
        let $death-date := $person//tei:death
        let $start := if($death-date/@when) then string($death-date/@when)
                      else if($death-date/@notBefore) then string($death-date/@notBefore)
                      else ()
        let $end :=   if($death-date/@when) then string($death-date/@when)
                      else if($death-date/@notAfter) then string($death-date/@notAfter)
                      else () 
        return
            <date json:array="true">
                <startDate>{$start}</startDate>
                <endDate>{$end}</endDate>
                <headline>{string($death-date)} Death</headline>
            </date>
    else () 
};

(:~
 : Build floruit date ranges
 : @param $person as node
:)
declare function local:get-pers-floruit($person as node()?) as node()*{
   if($person//tei:floruit) then 
        for $floruit-date in $person//tei:floruit
        let $start := if($floruit-date/@when) then string($floruit-date/@when)
                      else if($floruit-date/@notBefore) then string($floruit-date/@notBefore)
                      else ()
        let $end :=   if($floruit-date/@when) then string($floruit-date/@when)
                      else if($floruit-date/@notAfter) then string($floruit-date/@notAfter)
                      else () 
        return
            <date json:array="true">
                <startDate>{$start}</startDate>
                <endDate>{$end}</endDate>
                <headline>{string($floruit-date)} Floruit</headline>
            </date>
    else () 
};

(:~
 : Build state date ranges
 : @param $person as node
:)
declare function local:get-pers-state($person as node()?) as node()*{
    if($person//tei:state) then 
        for $state-date in $person//tei:state
        let $start := if($state-date/@when) then string($state-date/@when)
                      else if($state-date/@notBefore) then string($state-date/@notBefore)
                      else if($state-date/@from) then string($state-date/@from)
                      else ()
        let $end :=   if($state-date/@when) then string($state-date/@when)
                      else if($state-date/@notAfter) then string($state-date/@notAfter)
                      else if($state-date/@to) then string($state-date/@to)
                      else () 
        let $office := if($state-date/@role) then concat(' ',string($state-date/@role)) else concat(' ',string($state-date/@type))                 
        return
            <date json:array="true">
                <startDate>{$start}</startDate>
                <endDate>{$end}</endDate>
                <headline>{string($state-date)} {$office}</headline>
            </date>
    else () 
};

(:~
 : Build events date ranges
 : @param $person as node
:)
declare function local:get-pers-events($person as node()?) as node()*{
     if($person//tei:event) then 
        for $event in $person//tei:event
        let $event-date := $person//tei:event/child::*
        let $start := if($event-date/@when) then string($event-date/@when)
                      else if($event-date/@notBefore) then string($event-date/@notBefore)
                      else if($event-date/@from) then string($event-date/@from)
                      else ()
        let $end :=   if($event-date/@when) then string($event-date/@when)
                      else if($event-date/@notAfter) then string($event-date/@notAfter)
                      else if($event-date/@to) then string($event-date/@to)
                      else () 
        return
            <date json:array="true">
                <startDate>{$start}</startDate>
                <endDate>{$end}</endDate>
                <headline>{string($event-date)}</headline>
                <text>{$event/descendant::*/text()}</text>
            </date>
    else ()   
};
  
if($collection != '') then  local:get-all-recs() 
else local:get-pers-rec()