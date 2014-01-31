xquery version "3.0";

(:~
 : Builds dynamic nav menu based on url called by page.html
 :)


declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mail="http://exist-db.org/xquery/mail";

declare variable $id {request:get-parameter('id', '')};

declare function local:form(){
    <form action="email.xql" method="post">
        <label>Name:</label> <input type="text" name="name"/>
        <label>e-mail address:</label><input type="text" name="email"/>
        <label>Subject:</label><input type="text" name="subject"/>
        <label>Comments:</label>
        <textarea name="comments" id="comments" rows="20" cols="60"/>
        <input type="hidden" name="id" value="{$id}"/>
        <submit/>
    </form>   
};

declare function local:build-message(){
let $email-data := request:get-data()
let $email-address := xmldb:decode(substring-before(substring-after($email-data, 'email='), '&amp;'))
let $place-id := xmldb:decode(substring-before(substring-after($email-data, 'id='), '&amp;'))
let $subject := xmldb:decode(substring-before(substring-after($email-data, 'subject='), '&amp;'))

return
  <mail>
    <from>{$email-address}</from>
    <to>wsalesky@gmail.com</to>
    <subject>{$place-id} {$subject}</subject>
    <message>
      <xhtml>
           <html>
               <head>
                 <title>{$place-id} {$subject}</title>
               </head>
               <body>
                  {
                  let $parsed-data := tokenize($email-data , "&amp;" )
                  for $parsed-query-term in $parsed-data
                  let $parse-query-value := substring-after($parsed-query-term,"=")
                  let $parameter-name := substring-before($parsed-query-term, concat("=", $parse-query-value))
                  return 
                  (
                  <h3>{$parameter-name}</h3>,
                  <p>{xmldb:decode($parse-query-value)}</p>
                    )

                  }
              </body>
           </html>
      </xhtml>
    </message>
  </mail>

};

let $cache := 'test'
return
if(request:get-data()) then 
    if ( mail:send-email(local:build-message(),(), ()) ) then
      <h1>Sent Message OK :-)</h1>
    else
      <h1>Could not Send Message :-(</h1>
else local:form()      