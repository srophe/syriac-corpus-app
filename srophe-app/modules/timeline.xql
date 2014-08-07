xquery version "3.0";

(:module namespace timeline="http://syriaca.org//timeline";:)
(:~
 : NOTE: not currently used, timeline generated in persons.xsl
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
(:
NOTES on display,
headline should be person names perhaps Events: PersName
credit syriaca.org?
:)
for $rec in collection('/db/apps/srophe/data')//tei:idno[. = $uri]
let $title := string($rec/ancestor::tei:TEI//tei:titleStmt/tei:title[1])
let $title-en := substring-before($title,'—')
let $person := $rec/ancestor::tei:TEI//tei:person
let $birth :=
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
                <headline>{string($birth-date)} Birth</headline>
                <text>Death (ADD footnote) </text>
            </date>
    else () 
let $death :=
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
                <text>Death (ADD footnote) </text>
            </date>
    else ()
let $floruit :=
    if($person//tei:floruit) then 
        let $floruit-date := $person//tei:floruit
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
                <text>Floruit (ADD footnote) </text>
            </date>
    else ()   
let $state :=
    if($person//tei:state) then 
        let $state-date := $person//tei:state
        let $start := if($state-date/@when) then string($state-date/@when)
                      else if($state-date/@notBefore) then string($state-date/@notBefore)
                      else if($state-date/@from) then string($state-date/@from)
                      else ()
        let $end :=   if($state-date/@when) then string($state-date/@when)
                      else if($state-date/@notAfter) then string($state-date/@notAfter)
                      else if($state-date/@to) then string($state-date/@to)
                      else () 
        return
            <date json:array="true">
                <startDate>{$start}</startDate>
                <endDate>{$end}</endDate>
                <headline>{string($state-date)} Reign</headline>
                <text>Reign (ADD footnote) </text>
            </date>
    else () 
let $events :=
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
                <text>Event (ADD footnote) </text>
            </date>
    else ()      
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
    {($birth, $death,$floruit,$state)}
 </timeline> 
</json>