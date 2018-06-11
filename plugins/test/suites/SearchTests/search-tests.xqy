xquery version "1.0-ml";

import module namespace cfg = "http://acme.com/unittest/config" at "/lib/config.xqy";
import module namespace test = "http://marklogic.com/roxy/test-helper" at "/test/test-helper.xqy";

declare namespace http="xdmp:http";
declare namespace es = "http://marklogic.com/entity-services";
declare namespace s="http://marklogic.com/appservices/search";

declare variable $BASE-URL as xs:string := "http://" || "localhost" || ":" || "8014";
declare variable $EXT-ROOT-URL as xs:string := $BASE-URL || "/v1/search";

declare variable $QTXT := "&quot;stuff&quot; sort:relevance" => xdmp:url-encode();

declare variable $SEARCH-OPTIONS-NAME as xs:string := "asset-1.0.0-options";
declare variable $ENDPOINT as xs:string :=
    $EXT-ROOT-URL || "?q="|| $QTXT ||"&amp;view=all&amp;start=1&amp;pageLength=10&amp;options="||$SEARCH-OPTIONS-NAME||"&amp;transform=enrich-search-results";


declare variable $HTTP-OK as xs:string := "200";
declare variable $HTTP-UPDATED as xs:string := "204";
declare variable $HTTP-BAD-REQUEST as xs:string := "400";


declare variable $HTTP-POST as function(item(), item()) as item()+ := xdmp:http-post#2;
declare variable $HTTP-GET as function(item(), item()) as item()+ := xdmp:http-get#2;

declare variable $ACCEPTABLE-MEDIA-TYPE as xs:string := "application/xml";
declare variable $OUTPUT-OPTIONS := <options xmlns="xdmp:quote">
                                                    <indent>yes</indent>
                                                    <omit-xml-declaration>yes</omit-xml-declaration>
                                            </options>;



declare function local:get-GET-http-options() as element(http:options)
{
    <options xmlns="xdmp:http">
        <authentication method="digest">
            <username>{$cfg:UNITTEST-USER}</username>
            <password>{$cfg:UNITTEST-USER-PWD}</password>
        </authentication>
        <headers>
            <Accept>{$ACCEPTABLE-MEDIA-TYPE}</Accept>
            <Content-Type>{$ACCEPTABLE-MEDIA-TYPE}</Content-Type>
        </headers>
    </options>

};

declare function local:exec-http(
        $http-func as function(item(), item()) as item()+,
        $options as element(http:options),
        $url as xs:string
)
{
    let $response := $http-func($url,$options)
    let $_ := xdmp:log(" http url " ||$url )
    let $_ := xdmp:log(" http response[1] " ||xdmp:quote($response[1]) )
    let $_ := xdmp:log(" http response[2] " ||xdmp:quote($response[2]) )
    return $response
};

(:required for Search with POST :)
declare function local:set-post-http-options(
        $payload as element(payload)
) as element(http:options)
{
    <options xmlns="xdmp:http">
        <authentication method="digest">
            <username>{$cfg:UNITTEST-USER}</username>
            <password>{$cfg:UNITTEST-USER-PWD}</password>
        </authentication>
        <headers>
            <Accept>{$ACCEPTABLE-MEDIA-TYPE}</Accept>
            <Content-Type>{$ACCEPTABLE-MEDIA-TYPE}</Content-Type>
        </headers>
        <data>{xdmp:quote($payload/*)}</data>
    </options>

};

(:required for Search with POST :)
declare variable $QUERY := ();
(:~
in case we need a query some day - here is an example
    <query xmlns="http://marklogic.com/appservices/search">
        <and-query>
            <word-query>
                <field name="baseline-content-and-searchable-text"></field>
                <text>{$QTXT}</text>
                <term-option>case-insensitive</term-option>
                <weight>1.0</weight>
            </word-query>
        </and-query>
    </query>;

:)

(:required for Search with POST :)
declare variable $OPTIONS :=
    <options xmlns="http://marklogic.com/appservices/search">
      <term >
        <empty apply="all-results"/>
        <term-option>punctuation-insensitive</term-option>
        <term-option>case-insensitive</term-option>
        <term-option>stemmed</term-option>
        <term-option>wildcarded</term-option>
      </term>
      <debug>true</debug>
      <return-query>true</return-query>
    </options>;

declare variable $SEARCH := element {xs:QName("s:search")} {($QUERY, $OPTIONS)};


declare variable $run-test := function( $search as node()?, $endpoint as xs:string ) {
    (:let $response := local:exec-http($HTTP-POST, local:set-post-http-options(element payload {$search}),$ENDPOINT):)
    let $response := local:exec-http($HTTP-GET, local:get-GET-http-options(),$endpoint)
    return element tuple {
        element code { $response[1]/http:code/fn:string(.) },
        element response { $response[2]}
    }
};



(:~
    Test Description:

    Run a harmonisation process in the setup

:)


xdmp:log("Search Tests BEGINNING.....")
,
(:define all the tests to be run in the following anon function which will be executed in the correct context
at the end:)
let $tests := function() {


        (:only needed for Search with POST:)
        let $tuple := $run-test((),$ENDPOINT)
        let $code := $tuple/code
        let $response := $tuple/response
        return (
            test:assert-true( $code eq 200, " unexpected http code "|| $code  ),
            let $t := $response/s:response/@total  return  test:assert-true( $t/fn:data() eq 3, " unexpected search total  "|| $t ),
            (:when you enable synonyms this result will be in the first position:)
            let $u := $response/s:response/s:result[@index eq 1]/@uri/fn:string()
            (:when you enable synonyms this hit will be in the first position:)
            let $result := $response/s:response/s:result[@index eq 1]
            (:when you enable synonyms there will be two matches:)
            let $_ := test:assert-true(fn:count($result/s:snippet/s:match) eq 5, " unexpected number of snippet matches " ||fn:count($result/s:snippet/s:match) )
            return ()
            ,
            xdmp:log("Code: " || $code || " Response: "||xdmp:quote($response) )
        )


}
return
    xdmp:invoke-function(
        $tests,
        <options xmlns="xdmp:eval">
            <database>{xdmp:database($cfg:FINAL-TEST-DB)}</database>
        </options>
    )

,
xdmp:log("Search Tests ENDING.....")
