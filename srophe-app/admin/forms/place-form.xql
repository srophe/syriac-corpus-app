xquery version "3.0";
(:~
 : Submit new data to data folder for review
 : Send email alert to appropriate editor?
:)
import module namespace forms="http://syriaca.org//forms" at "build-place-instance.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";


declare variable $id {request:get-parameter('id','')};
(:~
 : Builds xform and populates working instance from build-place-instance.xqm
 : @param $id passed to form for adding data to existing place, if no id new place will be created
:)
(:forms:build-instance($id):)
declare function local:build-form(){
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:bf="http://betterform.sourceforge.net/xforms" xmlns:xf="http://www.w3.org/2002/xforms" bf:toaster-position="tl-down">
    <head>
        <title>Add place data</title>
        <meta name="author" content="wsalesky at gmail.com"/>
        <meta name="description" content="Add place data"/>
        <link rel="stylesheet" type="text/css" href="$shared/resources/css/bootstrap.min.css"/>
        <link rel="stylesheet" type="text/css" href="$shared/resources/css/bootstrap-responsive.min.css"/>
        <link rel="stylesheet" type="text/css" href="/exist/apps/srophe/resources/css/xforms.css"/>
        <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/loadsource.js"/>
        <script type="text/javascript" src="$shared/resources/scripts/bootstrap.min.js"/>
    </head>
    <body class="soria" style="margin:30px;">
        <div id="xforms" style="width: 975px;">
            <div style="display:none">
                <xf:model id="master">
                    <xf:instance xmlns="" id="new">
                        {forms:build-instance($id)}
                    </xf:instance>
                    <xf:instance xmlns="" id="simple" src="templates/new.xml"/>
                    <xf:instance xmlns="" id="template" src="templates/template.xml"/>
                    <xf:instance xmlns="" id="confessions" src="/exist/apps/srophe/documentation/confessions.xml"/>
                    <xf:bind id="bib-id" nodeset="instance('new')//tei:place/tei:bibl/@xml:id" calculate="concat('bibl',{$id},'-',position())"/>
                    <xf:submission id="save" action="submit.xql" ref="instance('new')" instance="new" replace="all" method="post"/>
                </xf:model>
            </div>
            <div class="Section" dojotype="dijit.layout.ContentPane">
            <div class="navbar navbar-fixed-top">
                <div class="row-fluid">
                    <div class="span10">
                        <span class="brand">
                        <a href="#"><img alt="The Syriac Gazetteer" src="../../resources/img/syriaca-logo-blue.png" style="height:45px;"/></a>
                        The Syriac Gazetteer: Data Entry</span>
                    </div>
                    <div class="span2">
                        <xf:trigger appearance="minimal" class="btn" style="mrgin-top:.5em;">
                            <xf:label>Save Record</xf:label>
                            <xf:hint>Be calm - this is just a demo!</xf:hint>
                            <xf:send submission="save"/>
                        </xf:trigger>
                    </div>
                </div>
            </div>
                <div>
                    <h1 class="inline">Add aditional data for: {replace(forms:build-instance($id)//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text(),'—','')} ({$id})</h1>
                </div>
                <div id="myAccordion" class="accordion">
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseOne" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Source</a>
                        </div>
                        <div class="accordion-body collapse in" id="collapseOne">
                            <div class="accordion-inner">
                                <fieldset>
                                    <!-- bind bibid bind bib id to all source attributes for following items-->
                                    <xf:repeat ref="instance('new')//tei:place/tei:bibl" id="new-source">
                                        <div class="well">
                                            <xf:output ref="@xml:id">
                                                <xf:label class="inline">Source ID: </xf:label>
                                            </xf:output>
                                            <xf:repeat ref="tei:author" id="source-author">
                                                <div class="row-fluid divider">
                                                    <div class="span4">
                                                        <xf:input ref=".">
                                                            <xf:label>Author: </xf:label>
                                                        </xf:input>
                                                    </div>
                                                    <div class="span1">
                                                        <xf:trigger class="btn add" appearance="minimal">
                                                            <xf:label>+</xf:label>
                                                            <xf:insert ev:event="DOMActivate" context="." ref="." at="last()" position="after" origin="instance('template')//tei:place/tei:bibl/tei:author"/>
                                                        </xf:trigger>
                                                    </div>
                                                    <div class="span1">
                                                        <xf:trigger class="add btn" appearance="minimal">
                                                            <xf:label>x</xf:label>
                                                            <xf:delete ev:event="DOMActivate" ref="." at="index('source-author')"/>
                                                        </xf:trigger>
                                                        <br style="clear:both"/>
                                                    </div>
                                                    <div class="span6"/>
                                                </div>
                                            </xf:repeat>
                                            <xf:repeat ref="tei:title" id="source-title">
                                                <div class="row-fluid divider" style="padding-bottom:-2em;">
                                                    <div class="span3">
                                                        <xf:input ref="." class="input-medium">
                                                            <xf:label>Title: </xf:label>
                                                        </xf:input>&#160;</div>
                                                    <div class="span3" style="margin-left:1em;">
                                                        <xf:select1 ref="@level">
                                                            <xf:label>Level: </xf:label>
                                                            <xf:item>
                                                                <xf:label>Article</xf:label>
                                                                <xf:value>a</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Manuscript</xf:label>
                                                                <xf:value>m</xf:value>
                                                            </xf:item>
                                                        </xf:select1>
                                                    </div>
                                                    <div class="span3">
                                                        <xf:switch id="lang">
                                                            <xf:case id="select-lang" selected="true()">
                                                                <xf:trigger appearance="minimal" class="inline">
                                                                    <xf:label>Select OR </xf:label>
                                                                    <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                                </xf:trigger>
                                                                <xf:trigger appearance="minimal" class="inline">
                                                                    <xf:label>Enter Language</xf:label>
                                                                    <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                                </xf:trigger>
                                                                <xf:select1 ref="@xml:lang">
                                                                    <xf:item>
                                                                        <xf:label>--- Select Language ---</xf:label>
                                                                        <xf:value/>
                                                                    </xf:item>
                                                                    <xf:item>
                                                                        <xf:label>English</xf:label>
                                                                        <xf:value>en</xf:value>
                                                                    </xf:item>
                                                                    <xf:item>
                                                                        <xf:label>Vocalized West Syriac</xf:label>
                                                                        <xf:value>syr-Syrj</xf:value>
                                                                    </xf:item>
                                                                    <xf:item>
                                                                        <xf:label>Vocalized East Syriac</xf:label>
                                                                        <xf:value>syr-Syrn</xf:value>
                                                                    </xf:item>
                                                                    <xf:item>
                                                                        <xf:label>Arabic</xf:label>
                                                                        <xf:value>ar</xf:value>
                                                                    </xf:item>
                                                                </xf:select1>
                                                            </xf:case>
                                                            <xf:case id="enter-lang">
                                                                <xf:trigger appearance="minimal" class="inline">
                                                                    <xf:label>Select OR </xf:label>
                                                                    <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                                </xf:trigger>
                                                                <xf:trigger appearance="minimal" class="inline">
                                                                    <xf:label>Enter Language</xf:label>
                                                                    <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                                </xf:trigger>
                                                                <xf:input ref="@xml:lang"/>
                                                            </xf:case>
                                                        </xf:switch>
                                                    </div>
                                                    <div class="span1">
                                                        <xf:trigger class="add btn" appearance="minimal">
                                                            <xf:label>+</xf:label>
                                                            <xf:insert ev:event="DOMActivate" context="." ref="." at="last()" position="after" origin="instance('template')//tei:place/tei:bibl/tei:title"/>
                                                        </xf:trigger>
                                                    </div>
                                                    <div class="span1">
                                                        <xf:trigger class="add btn" appearance="minimal">
                                                            <xf:label>x</xf:label>
                                                            <xf:delete ev:event="DOMActivate" ref="." at="index('source-title')"/>
                                                        </xf:trigger>
                                                    </div>
                                                </div>
                                            </xf:repeat>
                                            <xf:input ref="tei:citedRange">
                                                <xf:label>Cited Range: </xf:label>
                                            </xf:input>
                                            <xf:trigger class="small-btn btn" appearance="minimal">
                                                <xf:label>Remove</xf:label>
                                                <xf:delete ev:event="DOMActivate" ref="."/>
                                            </xf:trigger>
                                        </div>
                                    </xf:repeat>
                                </fieldset>
                                <div>
                                    <xf:trigger class="editTrigger btn" appearance="minimal">
                                        <xf:label>New source</xf:label>
                                        <xf:insert ev:event="DOMActivate" context="instance('new')//tei:place" ref="instance('new')//tei:place/tei:bibl" at="last()" position="after" origin="instance('template')//tei:place/tei:bibl"/>
                                    </xf:trigger>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseTwo" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Place Name</a>
                        </div>
                        <div class="accordion-body collapse" id="collapseTwo">
                            <div class="accordion-inner">
                                <fieldset class="well">
                                    <label>Place </label>
                                    <xf:repeat ref="instance('new')//tei:place/tei:placeName" id="newPlaceName">
                                        <div class="row-fluid" style="color:#666; size:.5em;">
                                            <div class="span3">
                                                <xf:input ref=".">
                                                    <xf:label>Name</xf:label>
                                                </xf:input>
                                            </div>
                                            <div class="span3">
                                                <xf:switch id="lang">
                                                    <xf:case id="select-lang" selected="true()">
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Select OR </xf:label>
                                                            <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Enter Language</xf:label>
                                                            <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:select1 ref="@xml:lang">
                                                            <xf:item>
                                                                <xf:label>--- Select Language ---</xf:label>
                                                                <xf:value/>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>English</xf:label>
                                                                <xf:value>en</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Vocalized West Syriac</xf:label>
                                                                <xf:value>syr-Syrj</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Vocalized East Syriac</xf:label>
                                                                <xf:value>syr-Syrn</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Arabic</xf:label>
                                                                <xf:value>ar</xf:value>
                                                            </xf:item>
                                                        </xf:select1>
                                                    </xf:case>
                                                    <xf:case id="enter-lang">
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Select OR </xf:label>
                                                            <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Enter Language</xf:label>
                                                            <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:input ref="@xml:lang"/>
                                                    </xf:case>
                                                </xf:switch>
                                            </div>
                                            <div class="span3">
                                                <xf:select1 ref="@source" class="input-small">
                                                    <xf:label>Source:</xf:label>
                                                    <xf:itemset ref="instance('new')//tei:bibl">
                                                        <xf:label ref="tei:title"/>
                                                        <xf:value ref="@xml:id"/>
                                                    </xf:itemset>
                                                </xf:select1>
                                            </div>
                                            <div class="span1">
                                                <xf:trigger ref="." class="add btn" appearance="minimal">
                                                    <xf:label>x</xf:label>
                                                    <xf:delete ev:event="DOMActivate" ref="." at="index('newPlaceName')"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2"/>
                                        </div>
                                        <div class="divider"/>
                                    </xf:repeat>
                                </fieldset>
                                <xf:trigger class="btn" appearance="minimal">
                                    <xf:label>New Name</xf:label>
                                    <xf:insert ev:event="DOMActivate" context="instance('new')//tei:place" ref="instance('new')//tei:place/tei:placeName" at="last()" position="after" origin="instance('template')//tei:place/tei:placeName"/>
                                </xf:trigger>
                            </div>
                        </div>
                    </div>
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseThree" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Description</a>
                        </div>
                        <div class="accordion-body collapse" id="collapseThree">
                            <div class="accordion-inner">
                                <fieldset class="well">
                                    <label>Description</label>
                                    <div class="row-fluid">
                                        <div class="span4">
                                            <xf:switch id="lang">
                                                <xf:case id="select-lang" selected="true()">
                                                    <xf:trigger appearance="minimal" class="inline">
                                                        <xf:label>Select OR </xf:label>
                                                        <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                    </xf:trigger>
                                                    <xf:trigger appearance="minimal" class="inline">
                                                        <xf:label>Enter Language</xf:label>
                                                        <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                    </xf:trigger>
                                                    <xf:select1 ref="@xml:lang">
                                                        <xf:item>
                                                            <xf:label>--- Select Language ---</xf:label>
                                                            <xf:value/>
                                                        </xf:item>
                                                        <xf:item>
                                                            <xf:label>English</xf:label>
                                                            <xf:value>en</xf:value>
                                                        </xf:item>
                                                        <xf:item>
                                                            <xf:label>Vocalized West Syriac</xf:label>
                                                            <xf:value>syr-Syrj</xf:value>
                                                        </xf:item>
                                                        <xf:item>
                                                            <xf:label>Vocalized East Syriac</xf:label>
                                                            <xf:value>syr-Syrn</xf:value>
                                                        </xf:item>
                                                        <xf:item>
                                                            <xf:label>Arabic</xf:label>
                                                            <xf:value>ar</xf:value>
                                                        </xf:item>
                                                    </xf:select1>
                                                </xf:case>
                                                <xf:case id="enter-lang">
                                                    <xf:trigger appearance="minimal" class="inline">
                                                        <xf:label>Select OR </xf:label>
                                                        <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                    </xf:trigger>
                                                    <xf:trigger appearance="minimal" class="inline">
                                                        <xf:label>Enter Language</xf:label>
                                                        <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                    </xf:trigger>
                                                    <xf:input ref="@xml:lang"/>
                                                </xf:case>
                                            </xf:switch>
                                        </div>
                                        <div class="span4">
                                            <xf:select1 ref="@source" class="input-small">
                                                <xf:label>Source:</xf:label>
                                                <xf:itemset ref="instance('new')//tei:bibl">
                                                    <xf:label ref="@xml:id"/>
                                                    <xf:value ref="@xml:id"/>
                                                </xf:itemset>
                                            </xf:select1>
                                        </div>
                                        <div class="span4"/>
                                    </div>
                                    <xf:textarea ref="instance('new')//tei:place/tei:desc/tei:quote"/>
                                </fieldset>
                            </div>
                        </div>
                    </div>
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseFour" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Location</a>
                        </div>
                        <div class="accordion-body collapse" id="collapseFour">
                            <div class="accordion-inner">
                                <fieldset class="well">    
                                    <!-- Need to work on more complex location element -->
                                    <xf:input ref="instance('new')//tei:place/tei:location/tei:geo">
                                        <xf:label>Coordinates</xf:label>
                                    </xf:input>
                                    <xf:trigger class="btn" appearance="minimal">
                                        <xf:label>Add coordinates</xf:label>
                                        <xf:insert ev:event="DOMActivate" context="instance('new')//tei:place" ref="instance('new')//tei:place/tei:location[tei:geo]" at="last()" position="after" origin="instance('template')//tei:place/tei:location[tei:geo][1]"/>
                                    </xf:trigger>
                                </fieldset>
                                <fieldset class="well">    
                                    <!-- Need to work on more complex location element -->
                                    <xf:textarea ref="instance('new')//tei:place/tei:location[@type='relative']">
                                        <xf:label>Location:</xf:label>
                                    </xf:textarea>
                                    <br/>
                                    <xf:trigger class="btn" appearance="minimal">
                                        <xf:label>Add location</xf:label>
                                        <xf:insert ev:event="DOMActivate" context="instance('new')//tei:place" ref="instance('new')//tei:place/tei:location[@type='relative']" at="last()" position="after" origin="instance('template')//tei:place/tei:location[@type='relative'][1]"/>
                                    </xf:trigger>
                                </fieldset>
                            </div>
                        </div>
                    </div>
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseFive" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Events</a>
                        </div>
                        <div class="accordion-body collapse" id="collapseFive">
                            <div class="accordion-inner">
                                <fieldset class="well">
                                    <xf:repeat ref="instance('new')//tei:place/tei:event[not(@type='attestation')]" id="newevent">
                                        <div class="row-fluid">
                                            <div class="span3">
                                                <xf:input ref="tei:p">
                                                    <xf:label>Event: </xf:label>
                                                </xf:input>
                                            </div>
                                            <div class="span3">
                                                <xf:switch id="lang">
                                                    <xf:case id="select-lang" selected="true()">
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Select OR </xf:label>
                                                            <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Enter Language</xf:label>
                                                            <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:select1 ref="tei:p/@xml:lang">
                                                            <xf:item>
                                                                <xf:label>--- Select Language ---</xf:label>
                                                                <xf:value/>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>English</xf:label>
                                                                <xf:value>en</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Vocalized West Syriac</xf:label>
                                                                <xf:value>syr-Syrj</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Vocalized East Syriac</xf:label>
                                                                <xf:value>syr-Syrn</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Arabic</xf:label>
                                                                <xf:value>ar</xf:value>
                                                            </xf:item>
                                                        </xf:select1>
                                                    </xf:case>
                                                    <xf:case id="enter-lang">
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Select OR </xf:label>
                                                            <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Enter Language</xf:label>
                                                            <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:input ref="tei:p/@xml:lang"/>
                                                    </xf:case>
                                                </xf:switch>
                                            </div>
                                            <div class="span3">
                                                <xf:select1 ref="@source" class="input-small">
                                                    <xf:label>Source:</xf:label>
                                                    <xf:itemset ref="instance('new')//tei:bibl">
                                                        <xf:label ref="@xml:id"/>
                                                        <xf:value ref="@xml:id"/>
                                                    </xf:itemset>
                                                </xf:select1>
                                            </div>
                                            <div class="span3"/>
                                        </div>
                                        <label>Dates:</label>
                                        <div class="row-fluid">
                                            <div class="span2">
                                                <xf:input ref="@when" class="input-small">
                                                    <xf:label>When: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@when)]">
                                                    <xf:label>+ when</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[not(@type='attestation')][2]/@when"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@from" class="input-small">
                                                    <xf:label>From: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@from)]">
                                                    <xf:label>+ from</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[not(@type='attestation')][2]/@from"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@to" class="input-small">
                                                    <xf:label>To: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@to)]">
                                                    <xf:label>+ to</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[not(@type='attestation')][2]/@to"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@notBefore" class="input-small">
                                                    <xf:label>Not Before: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@notBefore)]">
                                                    <xf:label>+ notBefore</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[not(@type='attestation')][2]/@notBefore"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@notAfter" class="input-small">
                                                    <xf:label>Not After: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@notAfter)]">
                                                    <xf:label>+ notAfter</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[not(@type='attestation')][2]/@notAfter"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2"/>
                                        </div>
                                        <!-- select date type from dropdown, have input popup -->
                                        <!-- Toggle dates -->
                                        <xf:trigger class="btn small-btn" appearance="minimal">
                                            <xf:label>Remove</xf:label>
                                            <xf:delete ev:event="DOMActivate" ref="." at="index('newevent')"/>
                                        </xf:trigger>
                                    </xf:repeat>
                                </fieldset>
                                <xf:trigger class="btn" appearance="minimal">
                                    <xf:label>New event</xf:label>
                                    <xf:insert ev:event="DOMActivate" context="instance('new')//tei:place" ref="instance('new')//tei:place/tei:event" at="last()" position="after" origin="instance('template')//tei:place/tei:event[1]"/>
                                </xf:trigger>
                            </div>
                        </div>
                    </div>
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseSix" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Attestations</a>
                        </div>
                        <div class="accordion-body collapse" id="collapseSix">
                            <div class="accordion-inner">
                                <fieldset class="well">
                                    <xf:repeat ref="instance('new')//tei:place/tei:event[@type='attestation']" id="newattestation">
                                        <div class="row-fluid">
                                            <div class="span3">
                                                <xf:input ref="tei:p">
                                                    <xf:label>Attestation: </xf:label>
                                                </xf:input>
                                            </div>
                                            <div class="span3">
                                                <xf:switch id="lang">
                                                    <xf:case id="select-lang" selected="true()">
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Select OR </xf:label>
                                                            <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Enter Language</xf:label>
                                                            <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:select1 ref="@xml:lang">
                                                            <xf:item>
                                                                <xf:label>--- Select Language ---</xf:label>
                                                                <xf:value/>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>English</xf:label>
                                                                <xf:value>en</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Vocalized West Syriac</xf:label>
                                                                <xf:value>syr-Syrj</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Vocalized East Syriac</xf:label>
                                                                <xf:value>syr-Syrn</xf:value>
                                                            </xf:item>
                                                            <xf:item>
                                                                <xf:label>Arabic</xf:label>
                                                                <xf:value>ar</xf:value>
                                                            </xf:item>
                                                        </xf:select1>
                                                    </xf:case>
                                                    <xf:case id="enter-lang">
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Select OR </xf:label>
                                                            <xf:toggle case="select-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:trigger appearance="minimal" class="inline">
                                                            <xf:label>Enter Language</xf:label>
                                                            <xf:toggle case="enter-lang" ev:event="DOMActivate"/>
                                                        </xf:trigger>
                                                        <xf:input ref="@xml:lang"/>
                                                    </xf:case>
                                                </xf:switch>
                                            </div>
                                            <div class="span3">
                                                <xf:select1 ref="@source" class="input-small">
                                                    <xf:label>Source:</xf:label>
                                                    <xf:itemset ref="instance('new')//tei:bibl">
                                                        <xf:label ref="@xml:id"/>
                                                        <xf:value ref="@xml:id"/>
                                                    </xf:itemset>
                                                </xf:select1>
                                            </div>
                                            <div class="span3"/>
                                        </div>
                                        <label>Dates:</label>
                                        <div class="row-fluid">
                                            <div class="span2">
                                                <xf:input ref="@when" class="input-small">
                                                    <xf:label>When: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@when)]">
                                                    <xf:label>+ When</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[@type='attestation'][2]/@when"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@from" class="input-small">
                                                    <xf:label>From: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@from)]">
                                                    <xf:label>+ From</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[@type='attestation'][2]/@from"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@to" class="input-small">
                                                    <xf:label>To: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@to)]">
                                                    <xf:label>+ To</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[@type='attestation'][2]/@to"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@notBefore" class="input-small">
                                                    <xf:label>Not Before: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@notBefore)]">
                                                    <xf:label>+ notBefore</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[@type='attestation'][2]/@notBefore"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@notAfter" class="input-small">
                                                    <xf:label>Not After: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@notAfter)]">
                                                    <xf:label>+ notAfter</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:event[@type='attestation'][2]/@notAfter"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2"/>
                                        </div>
                                        <!-- select date type from dropdown, have input popup -->
                                        <xf:trigger class="btn small-btn" appearance="minimal">
                                            <xf:label>Remove</xf:label>
                                            <xf:delete ev:event="DOMActivate" ref="." at="index('newattestation')"/>
                                        </xf:trigger>
                                    </xf:repeat>
                                </fieldset>
                                <xf:trigger class="btn" appearance="minimal">
                                    <xf:label>New attestation</xf:label>
                                    <xf:insert ev:event="DOMActivate" context="instance('new')//tei:place" ref="instance('new')//tei:place/tei:event[@type='attestation']" at="last()" position="after" origin="instance('template')//tei:place/tei:event[@type='attestation']"/>
                                </xf:trigger>
                            </div>
                        </div>
                    </div>
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseSeven" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Confessions</a>
                        </div>
                        <div class="accordion-body collapse" id="collapseSeven">
                            <div class="accordion-inner">
                                <fieldset class="well">
                                    <xf:repeat ref="instance('new')//tei:place/tei:state[@type='confession']" id="newconfession">
                                        <div class="row-fluid">
                                            <div class="span4">
                                                <xf:select1 ref="tei:label">
                                                    <xf:label>Confession:</xf:label>
                                                    <xf:itemset ref="instance('confessions')//tei:item">
                                                        <xf:label ref="child::tei:label"/>
                                                        <xf:value ref="@xml:id"/>
                                                    </xf:itemset>
                                                </xf:select1>
                                            </div>
                                            <div class="span4">
                                                <xf:select1 ref="@source" class="input-small">
                                                    <xf:label>Source:</xf:label>
                                                    <xf:itemset ref="instance('new')//tei:bibl">
                                                        <xf:label ref="@xml:id"/>
                                                        <xf:value ref="@xml:id"/>
                                                    </xf:itemset>
                                                </xf:select1>
                                            </div>
                                            <div class="span4"/>
                                        </div>
                                        <div class="row-fluid">
                                            <div class="span12">
                                                <label>Dates:</label>
                                            </div>
                                        </div>
                                        <div class="row-fluid">
                                            <div class="span2">
                                                <xf:input ref="@when" class="input-small">
                                                    <xf:label>When: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@when)]">
                                                    <xf:label>+ When</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:state[@type='confession'][2]/@when"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@from" class="input-small">
                                                    <xf:label>From: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@from)]">
                                                    <xf:label>+ From</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:state[@type='confession'][2]/@from"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@to" class="input-small">
                                                    <xf:label>To: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@to)]">
                                                    <xf:label>+ To</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:state[@type='confession'][2]/@to"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@notBefore" class="input-small">
                                                    <xf:label>Not Before: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@notBefore)]">
                                                    <xf:label>+ notBefore</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:state[@type='confession'][2]/@notBefore"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2">
                                                <xf:input ref="@notAfter" class="input-small">
                                                    <xf:label>Not After: </xf:label>
                                                </xf:input>
                                                <xf:trigger class="btn" appearance="minimal" ref="self::node()[not(@notAfter)]">
                                                    <xf:label>+ notAfter</xf:label>
                                                    <xf:insert ev:event="DOMActivate" context="." at="." origin="instance('template')//tei:place/tei:state[@type='confession'][2]/@notAfter"/>
                                                </xf:trigger>
                                            </div>
                                            <div class="span2"/>
                                        </div>
                                        <!-- bind ref to confession bind bibl, or have dropdown -->
                                        <xf:trigger class="btn small-btn" appearance="minimal">
                                            <xf:label>Remove</xf:label>
                                            <xf:delete ev:event="DOMActivate" ref="." at="index('newconfession')"/>
                                        </xf:trigger>
                                    </xf:repeat>
                                </fieldset>
                                <xf:trigger class="btn" appearance="minimal">
                                    <xf:label>New confession</xf:label>
                                    <xf:insert ev:event="DOMActivate" context="instance('new')//tei:place" ref="instance('new')//tei:place/tei:state[@type='confession']" at="last()" position="after" origin="instance('template')//tei:place/tei:state[@type='confession'][1]"/>
                                </xf:trigger>
                            </div>
                        </div>
                    </div>
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseEight" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Notes</a>
                        </div>
                        <div class="accordion-body collapse" id="collapseEight">
                            <div class="accordion-inner">
                                <fieldset class="well">
                                    <xf:repeat ref="instance('new')//tei:place/tei:note" id="newnote">
                                        <xf:select1 ref=".">
                                            <xf:label>Type:</xf:label>
                                            <xf:item>
                                                <xf:label>--- Select Note Type ---</xf:label>
                                                <xf:value/>
                                            </xf:item>
                                            <xf:item>
                                                <xf:label>Errata</xf:label>
                                                <xf:value>errata</xf:value>
                                            </xf:item>
                                            <xf:item>
                                                <xf:label>Corrigenda</xf:label>
                                                <xf:value>corrigenda</xf:value>
                                            </xf:item>
                                            <xf:item>
                                                <xf:label>Incerta</xf:label>
                                                <xf:value>incerta</xf:value>
                                            </xf:item>
                                        </xf:select1>
                                        <xf:textarea ref="."/>
                                        <!-- select date type from dropdown, have input popup -->
                                        <xf:trigger class="btn small-btn" appearance="minimal">
                                            <xf:label>Remove</xf:label>
                                            <xf:delete ev:event="DOMActivate" ref="." at="index('newnote')"/>
                                        </xf:trigger>
                                    </xf:repeat>
                                </fieldset>
                                <xf:trigger class="btn" appearance="minimal">
                                    <xf:label>New note</xf:label>
                                    <xf:insert ev:event="DOMActivate" context="instance('new')//tei:place" ref="instance('new')//tei:place/tei:note" at="last()" position="after" origin="instance('template')//tei:place/tei:note"/>
                                </xf:trigger>
                            </div>
                        </div>
                    </div>
                    <div class="accordion-group">
                        <div class="accordion-heading">
                            <a href="#collapseNine" data-parent="#myAccordion" data-toggle="collapse" class="accordion-toggle">Contributor Details</a>
                        </div>
                        <div class="accordion-body collapse in" id="collapseNine">
                            <div class="accordion-inner">
                                <fieldset>
                                    <!-- bind bibid bind bib id to all source attributes for following items-->
                                        <div class="well">
                                            <xf:repeat ref="instance('new')//tei:respStmt/tei:name" id="source-author">
                                                <div class="row-fluid">
                                                    <div class="span6">
                                                        <xf:input ref=".">
                                                            <xf:label>Your Name: </xf:label>
                                                        </xf:input>
                                                    </div>
                                                    <div class="span1">
                                                        <xf:trigger class="btn add" appearance="minimal">
                                                            <xf:label>+</xf:label>
                                                            <xf:insert ev:event="DOMActivate" context="." ref="." at="last()" position="after" origin="instance('template')//tei:place/tei:bibl/tei:author"/>
                                                        </xf:trigger>
                                                    </div>
                                                    <div class="span1">
                                                        <xf:trigger class="add btn" appearance="minimal">
                                                            <xf:label>x</xf:label>
                                                            <xf:delete ev:event="DOMActivate" ref="." at="index('source-author')"/>
                                                        </xf:trigger>
                                                        <br style="clear:both"/>
                                                    </div>
                                                    <div class="span4"/>
                                                </div>
                                            </xf:repeat>
                                        </div>
                                </fieldset>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </body>
</html> 
};

let $cache := 'change value to force refresh: 344'
return local:build-form()