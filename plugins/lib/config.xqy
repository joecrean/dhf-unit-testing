xquery version "1.0-ml";

module namespace cfg = "http://acme.com/unittest/config";

import module namespace sec="http://marklogic.com/xdmp/security" at "/MarkLogic/security.xqy";

declare namespace di="xdmp:document-insert";
declare namespace es="http://marklogic.com/entity-services";

declare variable $SECURITY-DB as xs:string := "Security";
declare variable $UNITTEST-USER-ROLE as xs:string := "unittest-role";
declare variable $UNITTEST-USER as xs:string := "unittest-user";
declare variable $UNITTEST-USER-PWD as xs:string := "J$la04#xh13";


(:databases:)
declare variable $STAGING-DB as xs:string := "unitTest-STAGING";
declare variable $FINAL-DB as xs:string := "unitTest-FINAL";
declare variable $FINAL-TEST-DB as xs:string := "unitTest-FINAL-TEST";

declare variable $JOB-ID-KEY as xs:string := "job-id";
declare variable $INPUT-COLLECTIONS-KEY as xs:string := "dhf.inputCollections";

declare variable $HTTP-BAD-REQUEST as xs:integer := 400;

declare variable $DEFAULT-GRAPH-NAME as xs:string := "http://acme.com/unittest/ontologies/MeSH";


(:harmonisation error qname:)
declare variable $HARMONISATION-ERROR-QNAME as xs:QName := xs:QName("HARMONISATION-ERROR");


(:collations:)
declare variable $CODEPOINT-COLLATION as xs:string := "collation=http://marklogic.com/collation/codepoint";
declare variable $ROOT-COLLATION as xs:string := "collation=http://marklogic.com/collation/";

declare variable $UNITTEST-USER-ROLE-DEFAULT-PERMISSIONS as element(sec:permission)* :=
    xdmp:invoke-function(
            function() {
                sec:role-get-default-permissions($UNITTEST-USER-ROLE)
            },
            <options xmlns="xdmp:eval"><database>{xdmp:database($SECURITY-DB)}</database></options>
    );

declare function get-insert-doc-options(
    $options as map:map
) as element(di:options)
{
    <options xmlns="xdmp:document-insert">
        <permissions>{$cfg:UNITTEST-USER-ROLE-DEFAULT-PERMISSIONS}</permissions>
        <collections>{ (map:get($options, "entity"), map:get($options, "flow"), map:get($options, "job-id") ) ! element collection {.}}</collections>
    </options>
};



