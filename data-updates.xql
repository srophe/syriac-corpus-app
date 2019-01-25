xquery version "3.0";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace fn="http://www.w3.org/2005/xpath-functions";
import module namespace functx="http://www.functx.com";

declare function local:add-pages($nodes, $id){
    for $node in $nodes
    return
        typeswitch ( $node )
            case comment() return $node
            case text() return
                let $normalized := replace($node, '\s+', ' ')
                for $segment in analyze-string($normalized, '܀܀܀')/node()
                return
                    if ($segment instance of element(fn:match)) then 
                        <pb xmlns="http://www.tei-c.org/ns/1.0" ed="{$id}" n=""/>
                    else 
                        $segment/string()      
            case element() return element { QName("http://www.tei-c.org/ns/1.0", local-name($node)) } {($node/@*, local:add-pages($node/node(),$id))}                        
            default return local:add-pages($node/node(),$id)
};

declare function local:add-page-number($nodes){
    for $node in $nodes
    return
        typeswitch ( $node )
            case text() return $node
            case comment() return $node
            case element(tei:pb) return 
                 element { QName("http://www.tei-c.org/ns/1.0", local-name($node)) } 
                  {($node/@*[not(name(.) = 'n')], 
                    attribute n { count($node/preceding::tei:pb) + 1 }
                  )}
            case element() return element { QName("http://www.tei-c.org/ns/1.0", local-name($node)) } {($node/@*, local:add-page-number($node/node()))}                        
            default return local:add-page-number($node/node())
};

let $name := request:get-uploaded-file-name("fileUpload")
let $file := request:get-uploaded-file-data("fileUpload")
let $file := util:parse(util:base64-decode($file))
let $id := $file//tei:publicationStmt/descendant::tei:idno[1]
return 
if($name != '') then
   local:add-page-number(local:add-pages($file, $id))
else 
    <html xmlns="http://www.w3.org/1999/xhtml">
        <meta charset="UTF-8"/>
        <title>Data Updates</title>
        <link rel="stylesheet" type="text/css" href="$nav-base/resources/css/bootstrap.min.css"/>
        <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"/>
        <body>
            <div style="padding:3em;">
                <h1>Data Updates</h1>
                <p>Upload file to tranlate '܀܀܀' to incremental tei:pb elements</p>
                <form enctype="multipart/form-data" method="post" action="data-updates.xql" class="form-horizontal" id="upload">
                    <input type="file" size="80" name="fileUpload"/><br/>
                    
                    <input type="submit" value="Upload" class="btn btn-primary"/>
                </form> 
            </div>
        </body>
    </html>