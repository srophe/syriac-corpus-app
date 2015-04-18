xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;
import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

declare variable $syriaca-root := concat($exist:root,'/exist/apps/srophe/');

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($syriaca-root, 'index.html')}" absolute="yes"/>
    </dispatch>
else if ($exist:resource eq '') then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
else if (ends-with($exist:path,"/atom")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat('/restxq', $exist:path)}" absolute="yes"/>
    </dispatch>    
else if (ends-with($exist:path,"/tei")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat('/restxq', $exist:path)}" absolute="yes"/>
    </dispatch>
else if (ends-with($exist:path,"/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
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
(: Resource paths starting with $app-shared are loaded from the shared-resources app :)
else if (contains($exist:path, "$app-shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($syriaca-root, substring-after($exist:path, '$app-shared/'))}" absolute="yes">
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
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
