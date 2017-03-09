xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;
(:
<div>
    <p>$exist:path: {$exist:path}</p>
    <p>$exist:resource: {$exist:resource}</p>
    <p>$exist:controller: {$exist:controller}</p>
    <p>$exist:prefix: {$exist:prefix}</p>
    <p>$exist:root: {$exist:root}</p>
</div>
:)

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($exist:controller, 'index.html')}" absolute="yes"/>
    </dispatch>
else if ($exist:resource eq '') then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>   
else if (ends-with($exist:path,"/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
else if (ends-with($exist:path, "/atom") or ends-with($exist:path, "/tei") or ends-with($exist:path, "/ttl")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat('/restxq/srophe', $exist:path)}" absolute="yes"/>
    </dispatch>
else if(matches($exist:path, '/place/\d+') or matches($exist:path, '/place/\d+.html')) then 
    let $id :=  
            if(matches($exist:resource,"^[0-9]+$")) then $exist:resource
            else substring-before($exist:resource,'.html')
    return            
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/geo/place.html"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <add-parameter name="id" value="{$id}"/>
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
         </dispatch> 
else if(matches($exist:path, '/person/\d+') or matches($exist:path, '/person/\d+.html')) then 
    let $id :=  
            if(matches($exist:resource,"^[0-9]+$")) then $exist:resource
            else substring-before($exist:resource,'.html')
    return            
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/persons/person.html"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <add-parameter name="id" value="{$id}"/>
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
         </dispatch>          
else if(matches($exist:path, '/work/\d+') or matches($exist:path, '/work/\d+.html')) then 
    let $id :=  
            if(matches($exist:resource,"^[0-9]+$")) then $exist:resource
            else substring-before($exist:resource,'.html')
    return            
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/bhse/work.html"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        {if(starts-with($exist:path, "/work/")) then <add-parameter name="id" value="{concat('http://syriaca.org/work/',$id)}"/>
                         else <add-parameter name="id" value="{$id}"/>
                        }
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
         </dispatch>          
else if(matches($exist:path, '/manuscript/\d+') or matches($exist:path, '/manuscript/\d+.html')) then 
    let $id :=  
            if(matches($exist:resource,"^[0-9]+$")) then $exist:resource
            else substring-before($exist:resource,'.html')
    return            
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/mss/manuscript.html"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <add-parameter name="id" value="{$id}"/>
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
         </dispatch>  
else if(matches($exist:path, '/spear/\d+') or matches($exist:path, '/spear/\d+.html')) then 
    let $id :=  
            if(matches($exist:resource,"^[0-9]+$")) then $exist:resource
            else substring-before($exist:resource,'.html')
    return            
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/spear/factoid.html"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <add-parameter name="id" value="{$id}"/>
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
         </dispatch>  
else if(matches($exist:path, '/bibl/\d+') or matches($exist:path, '/bibl/\d+.html')) then 
    let $id :=  
            if(matches($exist:resource,"^[0-9]+$")) then $exist:resource
            else substring-before($exist:resource,'.html')
    return            
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/bibl/bibl.html"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                        <add-parameter name="id" value="{$id}"/>
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
         </dispatch>  
else if (contains($exist:path,'/api/')) then
  if (ends-with($exist:path,"/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="/api-documentation/index.html"/>
    </dispatch> 
   else if($exist:resource = 'index.html') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="/api-documentation/index.html"/>
    </dispatch>
    else if($exist:resource = 'oai') then
     <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{replace($exist:path,'/api/oai','/srophe/modules/oai.xql')}"/>
     </dispatch>
    else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat('/restxq/srophe', $exist:path)}" absolute="yes"/>
    </dispatch>
else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
(: Resource paths starting with $app-root are resolved relative to app :)
else if (contains($exist:path, "/$app-root/")) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{concat($exist:controller,'/', substring-after($exist:path, '/$app-root/'))}">
                <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
            </forward>
        </dispatch>        
(: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
(: Redirects paths with directory, and no trailing slash to index.html in that directory :)    
else if (matches($exist:resource, "^([^.]+)$")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat($exist:path,'/index.html')}"/>
    </dispatch>         
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>