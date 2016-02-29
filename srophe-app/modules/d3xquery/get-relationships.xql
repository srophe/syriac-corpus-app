xquery version "3.0";

import module namespace rel="http://syriaca.org/related" at "../lib/get-related.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace json="http://www.json.org";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";

declare variable $collection {request:get-parameter('collection', '')};
declare variable $rel {request:get-parameter('rel', '')};
declare variable $uri {request:get-parameter('uri', '')};
declare variable $event {request:get-parameter('event', '')};
declare variable $reltype {request:get-parameter('reltype', '')};
declare variable $graphType {request:get-parameter('graphType', '')};

declare function local:get-events($event as xs:string*){
let $relationships := 
    if($event != '') then 
        let $e-uri := concat('http://syriaca.org/keyword/',$event)
        return 
        util:eval(concat("collection('/db/apps/srophe-data/data/spear/tei')//tei:event[@ref[matches(.,'(^|\W)",$e-uri,"(\W|$)')]][parent::tei:listEvent]"))
    else collection('/db/apps/srophe-data/data/spear/tei')//tei:event[@ref][parent::tei:listEvent]
return 
   <root>
      <nodes>
        {(:Keyword nodes:)
          (let $uris := distinct-values(for $r in $relationships return tokenize($r/@ref,' '))
          for $uri in $uris
          return  
              <json:value>
                   <id>{$uri}</id>
                   {
                    if(rel:get-names-json($uri) != '') then rel:get-names-json($uri)
                    else (<name>{tokenize($uri,'/')[last()]}</name>,<desc>No description</desc>)
                    }        
                    <type>{tokenize($uri,'/')[4]}</type>
              </json:value>,
          for $r in $relationships
          let $uri := string($r/ancestor::tei:div[@uri][1]/@uri)
          return  
              <json:value>
                   <id>{$uri}</id>
                   {
                   if(rel:get-names-json($uri) != '') then rel:get-names-json($uri)
                   else (<name>{tokenize($uri,'/')[last()]}</name>,<desc>No description</desc>)
                    }        
                    <type>{tokenize($uri,'/')[4]}</type>
              </json:value>              
              )
          }
        </nodes>
        <links>
              {
                for $r in $relationships
                return
                    if(contains($r/@ref,' ')) then 
                        for $rel in tokenize($r/@ref,' ')
                        return 
                        <json:value>
                            <target>{string($r/ancestor::tei:div[@uri][1]/@uri)}</target>
                            <source>{string($rel)}</source>
                            <relationship>{tokenize(string($rel),'/')[last()]}</relationship>
                            <value>0</value>
                        </json:value>
                    else   
                        <json:value>
                        {if(count($relationships) = 1) then attribute {xs:QName("json:array")} {'true'} else ()}
                            <target>{string($r/ancestor::tei:div[@uri][1]/@uri)}</target>
                            <source>{string($r/@ref)}</source>
                            <relationship>{tokenize(string($r/@ref),'/')[last()]}</relationship>
                            <value>0</value>
                        </json:value>
            }
        </links>
    </root> 

};
(:
: Note: issues with json serialization, if only one link, not serialized as an array, if used this: it becomes a nested array <links json:array="true">
:)
declare function local:get-relationships($uri as xs:string*, $rel-type as xs:string*){
let $relationships :=
    (: Return just the record and its relations? Or find all relations with that uri? :)
    if($uri != '') then 
        util:eval(concat("collection('/db/apps/srophe-data/data/spear/tei')//tei:relation[@passive[matches(.,'",$uri,"(\W|$)')] or @active[matches(.,'",$uri,"')] or @mutual[matches(.,'",$uri,"')]]
        "))
    else if($reltype != '') then    
        util:eval(concat("collection('/db/apps/srophe-data/data/spear/tei')//tei:relation[@name[replace(.,'^(.*?):','') = '",$reltype,"']]"))
    else collection('/db/apps/srophe-data/data/spear/tei')//tei:relation
return 
        <root>
            <nodes>
                {
                let $uris := 
                    distinct-values(
                        (for $r in $relationships return tokenize($r/@active,' '), 
                        for $r in $relationships return tokenize($r/@passive,' '),
                        for $r in $relationships return tokenize($r/@mutual,' '))
                    )
                for $uri in $uris
                return 
                    <json:value>
                            <id>{$uri}</id>
                            {
                                if(rel:get-names-json($uri) != '') then rel:get-names-json($uri)
                                else <name>{tokenize($uri,'/')[last()]}</name>
                            }        
                            <type>{if(contains($uri,'/')) then tokenize($uri,'/')[4] else 'spear'}</type>
                   </json:value>
                }
            </nodes>
            <links>
                { 
                    for $r in $relationships
                    return  
                        if($r/@mutual) then 
                             for $m in tokenize($r/@mutual,' ')
                             return 
                                 let $node := 
                                     for $p in tokenize($r/@mutual,' ')
                                     where $p != $m
                                     return 
                                         <json:value>
                                             <source>{$m}</source>
                                             <target>{$p}</target>
                                             <relationship>{replace($r/@name,'^(.*?):','')}</relationship>
                                             <value>0</value>
                                         </json:value>
                                 return $node
                        else
                            if(contains($r/@active,' ')) then 
                                (: Check passive for spaces/multiple values :)
                                if(contains($r/@passive,' ')) then 
                                    for $a in tokenize($r/@active,' ')
                                    return 
                                        for $p in tokenize($r/@passive,' ')
                                        return 
                                           <json:value>
                                                <source>{string($p)}</source>
                                                <target>{string($a)}</target>
                                                <relationship>{replace($r/@name,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value> 
                                (: multiple active, one passive :)
                                else 
                                    let $passive := string($r/@passive)
                                    for $a in tokenize($r/@active,' ')
                                    return 
                                            <json:value>
                                                <source>{string($passive)}</source>
                                                <target>{string($a)}</target>
                                                <relationship>{replace($r/@name,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value>
                            else 
                                (: One active multiple passive :)
                                if(contains($r/@passive,' ')) then 
                                    let $active := string($r/@active)
                                    for $p in tokenize($r/@passive,' ')
                                    return 
                                            <json:value>
                                            {if(count($relationships) = 1) then attribute {xs:QName("json:array")} {'true'} else ()}
                                                <source>{string($p)}</source>
                                                <target>{string($active)}</target>
                                                <relationship>{replace($r/@name,'^(.*?):','')}</relationship>
                                                <value>0</value>
                                            </json:value>
                                (: One active one passive :)            
                                else 
                                    <json:value>
                                    {if(count($relationships) = 1) then attribute {xs:QName("json:array")} {'true'} else ()}
                                        <source>{string($r/@passive)}</source>
                                        <target>{string($r/@active)}</target>
                                        <relationship>{replace($r/@name,'^(.*?):','')}</relationship>
                                        <value>0</value>
                                    </json:value>
                    }
            </links>
    </root>                        
};


if($rel) then
    if($rel = 'event') then
        if($event != '' and $event !='all') then
            local:get-events($event)
        else util:base64-decode(util:binary-doc('spear-events.json')) 
        (:local:get-events(''):)
    else 
        if($uri != '') then local:get-relationships($uri,'')
        else if($rel) then local:get-relationships('',$reltype)
        else (:local:get-relationships('',''):)util:base64-decode(util:binary-doc('spear-relationships.json'))
else (:local:get-relationships('',''):)util:base64-decode(util:binary-doc('spear-relationships.json'))

(:local:get-relationships(''):)
(:local:get-events('birth'):)
(:local:get-relationships('http://syriaca.org/place/78'):)