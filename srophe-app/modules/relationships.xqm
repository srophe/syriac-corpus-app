xquery version "3.0";
import module namespace tm="http://exist-db.org/xquery/mallet-topic-modeling";
declare namespace tei="http://www.tei-c.org/ns/1.0";
'experiments'
(:
let $text := 
("Ett lite st√∂rre test √§n det borde g√• an om n√•gra dagar. 
Vad √§r √§mnet om inte n√•gra √§mnesord kommer med? 
eXist-db applikationen f√•r ber√§tta n√§r den funkar. ", "Dessutom nu med tv√• texter som str√§ngargument. ")
let $text2 := (<text>{$text[1]}</text>, <text>{$text[2]}</text>)
let $text3 := xs:anyURI("/db/apps/srophe/data/spear/")
let $instances-doc-suffix := ".mallet"
let $topic-model-doc-suffix := ".tm"
let $instances-doc-prefix := "/db/apps/mallet-topic-modeling/resources/instances/topic-example"
let $instances-path := $instances-doc-prefix || $instances-doc-suffix
let $instances-path2 := $instances-doc-prefix || "2" || $instances-doc-suffix
let $instances-path3 := $instances-doc-prefix || "3" || $instances-doc-suffix

let $mode := 2
let $call-type := ("string", "node", "collection")[$mode]
let $instances-uri := xs:anyURI(($instances-path, $instances-path2, $instances-path3)[$mode])
let $topic-model-uri := xs:anyURI(($instances-path || $topic-model-doc-suffix, $instances-path2 || $topic-model-doc-suffix, $instances-path2 || $topic-model-doc-suffix)[$mode])

let $create-instances-p := false()

let $created := if ($create-instances-p) then 
    switch ($call-type)
        case "string" return tm:create-instances-string($instances-uri, $text)
        case "node" return tm:create-instances-node($instances-uri, $text2)
        case "collection" return tm:create-instances-collection($instances-uri, $text3, xs:QName("tei:body"))
        default return tm:create-instances-string($instances-uri, $text)
    else ()
return 
    if ($create-instances-p) then
        tm:topic-model-inference($instances-uri, 5, 25, 50, (), (), (), "sv", $instances-uri)
        else
    tm:topic-model-inference($topic-model-uri, $instances-uri, 50, (), ())
    :)
(:  :tm:topic-model($instances-uri, 5, 25, 50, (), (), (), "sv") :)

(:
import module namespace graphing="http://exist-db.org/xquery/tei-graphing";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:listPerson(){
for $person in collection('/db/apps/srophe/data')//tei:listPerson[not(parent::tei:listPerson)]
return 
    $person
};
declare function local:listRelation(){
for $relation in collection('/db/apps/srophe/data')//tei:relation[not(parent::tei:listPerson)]
return <listRelation xmlns="http://www.tei-c.org/ns/1.0">{$relation}</listRelation>
};
graphing:relation-graph(
local:listPerson(), 
local:listRelation(),
<parameters>
    <param name="output" value="graphml"/>
</parameters>)
:)