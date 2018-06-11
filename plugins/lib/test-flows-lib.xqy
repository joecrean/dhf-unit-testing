xquery version "1.0-ml";

module namespace tf = "http://acme.com/unittest/test-flows-lib";

import module namespace cfg = "http://acme.com/unittest/config" at "/lib/config.xqy";

declare namespace http="xdmp:http";
declare namespace hub = "http://marklogic.com/data-hub";

declare variable $FLOW-URL as xs:string :=  "/v1/resources/flow?";
declare variable $RUN-COLLECTOR-URL as xs:string :=  "/com.marklogic.hub/endpoints/collector.xqy?";

declare variable $HTTP-OK as xs:integer := 200;

declare variable $HARMONIZE_FLOW := "harmonize";


(:make sure Accept header is set to control how exceptions are returned to caller:)
declare variable $HTTP-OPTIONS as element(http:options) :=
    <options xmlns="xdmp:http">
        <authentication method="digest">
            <username>admin</username>
            <password>admin</password>
        </authentication>
        <headers>
            <Accept>application/xml</Accept>
            <Content-Type>application/xml</Content-Type>
        </headers>
    </options>;


declare variable $HTTP-POST as function(item(), item()) as item()+ := xdmp:http-post#2;
declare variable $HTTP-GET as function(item(), item()) as item()+ := xdmp:http-get#2;

(:~

?rs:identifiers=someIdentifier&rs:entity-name=EntityName&rs:flow-name=FlowName&rs:target-database=Documents&rs:options={"some":"json"}&rs:job-id=SomeJobID

 -PentityName=$ENTITY \
  -PflowName=$FLOW \
  -PbatchSize=10 \
  -PthreadCount=4 \
  -PsourceDB=unitTest-STAGING \
  -PdestDB=unitTest-FINAL \
  -PshowOptions=true \
  -PenvironmentName=$ENV \
  -Pdhf.inputCollections=$COLLS
:)
declare function tf:build-flow-url(
    $ids as xs:string*,
    $entity as xs:string,
    $flow-name as xs:string,
    $target-db as xs:string,
    $source-db as xs:string,
    $options as xs:string,
    $job-id as xs:string

) as xs:string
{
  fn:concat(
           if ($job-id) then fn:concat("rs:job-id=",$job-id ) else (),
           if ($flow-name) then fn:concat("&amp;rs:flow-name=",$flow-name ) else (),
           if ($target-db) then fn:concat("&amp;rs:target-database=",$target-db ) else (),
           if ($options) then fn:concat("&amp;rs:options=",$options ) else (),
           if ($entity) then fn:concat("&amp;rs:entity-name=",$entity ) else (),
           if ($source-db) then fn:concat("&amp;database=",$source-db ) else (),
           fn:concat("&amp;rs:identifiers=",fn:string-join($ids,"&amp;rs:identifiers=" ) )

  )
};

declare function tf:exec-http(
        $http-func as function(item(), item()) as item()+,
        $url as xs:string,
        $options as element(http:options)?
) as element(response)
{
    let $response := $http-func($url,if ($options) then $options else $HTTP-OPTIONS)
    let $_ := xdmp:log(" http response[1] " ||xdmp:quote($response[1]) )
    let $_ := xdmp:log(" http response[2] " ||xdmp:quote($response[2]) )
    return <response><part1>{$response[1]}</part1><part2>{if (fn:count($response[2]/(element()|text())) eq 0) then () else $response[2]}</part2></response>
};


(:~


:)
(:~
: get the xml representation of a harmonisation flow.
:
: based on the following http commands extracted from the MarkLogic Access Log
:
GET /v1/resources/flow?rs:flow-name=HarmonizePublicationsAcrossSources&rs:flow-type=harmonize&rs:entity-name=Asset&database=unitTest-STAGING

: @param url  url of the custom resource flow endpoint
: @param entity  name of the entity
: @param flow-name name of the flow
: @param db the source db e.g. STAGING
: @return  response xml
:)

declare function tf:get-harmonisation-flow(
        $url as xs:string,
        $entity as xs:string,
        $flow-name as xs:string,
        $db as xs:string
) as element(response)
{

    tf:exec-http($HTTP-GET,
                    fn:concat(
                            $url,
                        "rs:flow-name=",
                        $flow-name,
                        "&amp;rs:flow-type=",
                        $HARMONIZE_FLOW,
                        "&amp;rs:entity-name=",
                        $entity,
                        "&amp;database=",
                        $db

                    ),
                    ()
    )

};

(:~
: run the collector of a given harmonisation flow.
:
: based on the following http commands extracted from the MarkLogic Access Log
:
GET /com.marklogic.hub/endpoints/collector.xqy?job-id=1c7a7862-8183-4e44-b310-8c1eb5727105&entity-name=Asset&flow-name=HarmonizePublicationsAcrossSources
&database=unitTest-STAGING
&options=%7B%22dhf.inputCollections%22%3A%22%22%2C%22entity%22%3A%22Asset%22%2C%22flow%22%3A%22HarmonizePublicationsAcrossSources%22%2C%22flowType%22%3A%22harmonize%22%7D

: @param url  url of the custom resource flow endpoint
: @param job-id  job id
: @param entity-name  name of the entity
: @param flow-name name of the flow
: @param options  will be passed to the xquery code
: @param db the source db e.g. STAGING
: @return  response xml
:)
declare function tf:run-collector(
        $url as xs:string,
        $job-id as xs:string,
        $entity-name as xs:string,
        $flow-name as xs:string,
        $options as xs:string,
        $db as xs:string
) as element(response)
{

    tf:exec-http($HTTP-GET,
            fn:concat(
                    $url,
                    "job-id=",
                    $job-id,
                    "&amp;entity-name=",
                    $entity-name,
                    "&amp;flow-name=",
                    $flow-name,
                    "&amp;database=",
                    $db,
                    "&amp;options=",
                    $options
            ),
            ()
    )

};

(:~
: run  the main part of a harmonisation flow i.e. the bit without the collector
:
:
: based on the following http commands extracted from the MarkLogic Access Log
: POST batches of URIs to a flow for processing
:
"POST /v1/resources/flow?rs:job-id=1c7a7862-8183-4e44-b310-8c1eb5727105&rs:flow-name=HarmonizePublicationsAcrossSources&rs:target-database=unitTest-FINAL&rs:options={%22dhf.inputCollections%22:%22%22,%22entity%22:%22Asset%22,%22flow%22:%22HarmonizePublicationsAcrossSources%22,%22flowType%22:%22harmonize%22}&rs:entity-name=Asset&rs:identifiers=/content/pmc/3339582.xml--&rs:identifiers=/content/pmc/3339586.xml--&database=unitTest-STAGING HTTP/1.1"

"POST /v1/resources/flow?rs:job-id=1c7a7862-8183-4e44-b310-8c1eb5727105&rs:flow-name=HarmonizePublicationsAcrossSources&rs:target-database=unitTest-FINAL&rs:options={%22dhf.inputCollections%22:%22%22,%22entity%22:%22Asset%22,%22flow%22:%22HarmonizePublicationsAcrossSources%22,%22flowType%22:%22harmonize%22}&rs:entity-name=Asset&rs:identifiers=/content/pmc/3339580.xml--/content/medline/22582158.xml&rs:identifiers=--/content/medline/274718.xml&rs:identifiers=--/content/medline/274720.xml&rs:identifiers=--/content/medline/274721.xml&rs:identifiers=--/content/medline/274722.xml&rs:identifiers=--/content/medline/274723.xml&rs:identifiers=--/content/medline/274724.xml&rs:identifiers=/content/pmc/2291374.xml--&rs:identifiers=/content/pmc/2844510.xml--&rs:identifiers=/content/pmc/3339580.xml--/content/medline/22582158.xml&database=unitTest-STAGING HTTP/1.1"

: @param url  url of the custom resource flow endpoint
: @param ids  urls from staging of the documents to be written
: @param job-id  job id
: @param entity-name  name of the entity
: @param flow-name name of the flow
: @param target-db  the target db where the docs will be writting
: @param options  will be passed to the xquery code
: @param flow  the flow xml as element(hub:flow),
: @param db the source db e.g. STAGING
: @return  response xml
:)
declare function tf:run-flow(
        $url as xs:string,
        $ids as xs:string*,
        $job-id as xs:string,
        $entity-name as xs:string,
        $flow-name as xs:string,
        $target-db as xs:string,
        $options as xs:string,
        $flow as element(hub:flow),
        $db as xs:string
) as element(response)
{
    xdmp:log("XXX url="||tf:build-flow-url($ids, $entity-name, $flow-name, $target-db , $db, $options, $job-id) ),
    tf:exec-http($HTTP-POST,
                    fn:concat(
                            $url,
                            tf:build-flow-url($ids, $entity-name, $flow-name, $target-db , $db, $options, $job-id)
                    ),
                     <options xmlns="xdmp:http">
                        <authentication method="digest">
                            <username>admin</username>
                            <password>admin</password>
                        </authentication>
                        <headers>
                            <Accept>application/xml</Accept>
                            <Content-Type>application/xml</Content-Type>
                        </headers>
                        <data>{xdmp:quote($flow)}</data>
                    </options>
    )

};
(:~
: run an entire harmonisation flow (all components)
:
: @param entity-name  name of the entity
: @param flow-name name of the flow
: @param source-db the source db e.g. STAGING
: @param target-db  the target db where the docs will be writting
: @param host  the hostname where the DHF is running
: @param port  the port on which the DHF is listening
: @param input-collections  a comma separated string with collection names to be included in the initial selection of
:                           documents in the collector
: @param input-pub-year the publication year to be used in the collector, must 4 digit e.g. 2017
: @return  response xml
:)
declare function tf:run-harmonisation-flow(
    $entity as xs:string,
    $flow-name as xs:string,
    $source-db as xs:string,
    $target-db as xs:string,
    $host as xs:string,
    $port as xs:string,
    $input-collections as xs:string?,
    $input-pub-year as xs:string?
) as item()?
{
    let $throw-harmonization-error := function($message as xs:string) {
        fn:error(xs:QName("HARMONIZATION-ERROR"), $message)
    }
    let $base-url := "http://" || $host || ":" || $port
    let $flow as element(hub:flow)?  := tf:get-harmonisation-flow($base-url || $FLOW-URL, $entity, $flow-name, $source-db)
    ! (if ($HTTP-OK ne ./part1/http:response/http:code/fn:data()) then
            $throw-harmonization-error(" GET Flow http status was "||./part1/http:response/http:code/fn:string() )
        else ./part2/hub:flow)

    let $job-id := sem:uuid-string()
    let $options := let $map := map:map()
                    let $_ := $map => map:with($cfg:INPUT-COLLECTIONS-KEY, $input-collections)
                                    => map:with('entity', $entity)
                                    => map:with('flow', $flow-name)
                                    => map:with('flowType', $HARMONIZE_FLOW)
                    return xdmp:to-json-string($map)  => xdmp:url-encode()
    let $_ := xdmp:log("XX running collector")
    let $uris := tf:run-collector($base-url || $RUN-COLLECTOR-URL, $job-id, $entity, $flow-name, $options, $source-db)
        ! (if ($HTTP-OK ne ./part1/http:response/http:code/fn:data()) then
            $throw-harmonization-error(" Run Collector http status was "||./part1/http:response/http:code/fn:string() )
           else ./part2 => fn:tokenize("\n")  )

    let $_ :=  xdmp:log("URIS = "||fn:count($uris) )

    let $_ := xdmp:log("XX running flow")
    return if ($uris) then tf:run-flow($base-url || $FLOW-URL, $uris, $job-id, $entity, $flow-name, $target-db, $options,  $flow, $source-db)
    ! (if ($HTTP-OK ne ./part1/http:response/http:code/fn:data()) then
        $throw-harmonization-error(" Run Flow http status was "||./part1/http:response/http:code/fn:string() )
       else ./part2)
    else xdmp:log("found no uris to process")
};