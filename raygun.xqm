xquery version "1.0-ml";

(:
 : Module Name:     Raygun MarkLogic Provider
 : Module Version:  Alpha
 : Date:            July 30, 2015
 : Module Overview: This module is a Raygun.io provider for MarkLogic. You can use it
                    to report unhandled MarkLogic exceptions to Raygun.io.
 :)

module namespace raygun = "http://raygun.io";
declare namespace http = "xdmp:http";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
declare variable $RAYGUN-CONFIG as element(raygun) := raygun:read-raygun-config();

(:
 : Transforms report payload appropriately according to used MarkLogic version.
 :)
declare function raygun:handle-version(
  $payload as map:map
) as xs:string
{
  if (contains(xdmp:version(), "8")) 
  then xdmp:to-json-string($payload)
  else xdmp:to-json($payload)        
};

(: 
 : Takes JSON error report as a string and submits it to Raygun.io using given api key.
 :
 : @param $payload Error report map - formatted  with accordance to
 :                 the following API: https://raygun.io/raygun-providers/rest-json-api
 : @param $apiKey Api key of the Raygun application
 : @return HTTP response from Raygun API
 :)
declare function raygun:report-error(
  $payload as map:map,
  $api-key as xs:string
) as element(http:response)
{ 
  xdmp:http-post(
    "https://api.raygun.io/entries",
    <options xmlns="xdmp:http">
      <data>{ raygun:handle-version($payload) }</data>
      <headers>
        <x-apikey>{ $api-key }</x-apikey> 
        <content-type>application/json</content-type>
        <host>api.raygun.io</host>
      </headers>
    </options>)[1]
};

(: 
 : Takes MarkLogic error data and returns a JSON string compatible with Raygun.io API
 : (https://raygun.io/raygun-providers/rest-json-api).
 :
 : @param $innerError XQueryException.name 
 : @param $data JSON array representig XQueryException.data[] 
 : @param $className XQueryException.expr
 : @param $message Sequence of maps representing QueryStackFrame[] 
 : @param $mode Valid Raygun mode: "development"/"qa"/"production"
 : @return Error report map
 :)
declare function raygun:create-json-map(
  $inner-error as xs:string, 
  $data as json:array, 
  $class-name as xs:string,
  $message as xs:string, 
  $stack-trace-data as map:map+,
  $mode as xs:string
) as map:map 
{                
  map:new((
    map:entry("occurredOn", current-dateTime()),
    map:entry("details", 
      map:new(( 
        map:entry("machineName", "MarkLogic"),
        map:entry("version", xdmp:version()),
        map:entry("client", 
          map:new((
            map:entry("name", "MarkLogic Raygun Provider"),
            map:entry("version", "beta"),
            map:entry("clientUrl", "soon to come (github acc)")
          ))
        ),
        map:entry("error", 
          map:new((
            map:entry("innerError", $inner-error),
            map:entry("data", $data),
            map:entry("className", $class-name),
            map:entry("message", $message),
            map:entry("stackTrace", json:to-array($stack-trace-data))
          ))
        ),
        map:entry("environment",
          map:new((
            map:entry("architecture", xdmp:architecture())
          ))
        ),
        map:entry("tags", json:to-array($mode)),
        map:entry("request", 
          map:new((
            map:entry("hostName", xdmp:host-name()),
            map:entry("url", xdmp:get-request-url()),
            map:entry("httpMethod", xdmp:get-request-method()),
            map:entry("iPAddress", xdmp:get-request-client-address()),
            map:entry("queryString", xdmp:get-request-body()),
            map:entry("headers",
              map:new((
                map:entry("host", xdmp:host-name()),
                map:entry("user-Agent", (xdmp:get-request-header("User-Agent"), "unknown")[1])
              ))
            )
          ))
        ),
        map:entry("response", 
          map:new((
            map:entry("statusCode", xdmp:get-response-code())
          ))
        ),
        map:entry("user",
          map:new((
            map:entry("identifier", xdmp:get-current-user())
          ))
        )
      ))
    )
  ))
};

(:
 : Reads Raygun mode (development/qa/production) and api key from configuration file.  
 :
 : @return Raygun configuration file
 :)
declare function raygun:read-raygun-config() as element(raygun)
{
  if (doc-available("/raygun.xml")) 
  then doc("/raygun.xml")/raygun
  else error((), "No configuration file available. Run module method raygun-deploy:init() and try again.")
};

(: 
 : Sends error report to Raygun.io. If config mode is set to "development", returns empty.
 :
 : @param $error Element representing XQueryException 
 : @param $mode Valid Raygun mode: "development"/"qa"/"production" (optional)
 : @param $api-key Raygun application api key (optional)
 : @return Empty sequence if succeeded 
:)
declare function raygun:report-error(
  $error as element(error:error)) 
  as element(http:response)?
{   
  raygun:report-error(
    $error/error:name/string(), 
    json:to-array(
      $error/error:data/error:datum/string()
    ), 
    $error/error:expr/string(), 
    concat(
      $error/error:format-string/string(), "&#10;",
      string-join(
        for $var in $error/error:stack/error:frame/error:variables/error:variable
        return (concat('$', $var/error:name, ' = ', $var/error:value, "&#10;"))
      )
    ), 
    for $frame in $error/error:stack/error:frame
    return 
      map:new((
        map:entry("lineNumber", concat($frame/error:line, ":", $frame/error:column)),
        map:entry("className", ($frame/error:contextItem, "")[1]),
        map:entry("fileName",concat($frame/error:uri, " [", $frame/error:xquery-version, "]")),
        map:entry("methodName", $frame/error:operation/string())
      ))
  )
};

(: 
 : Sends error report to Raygun.io. If config mode is set to "development", returns empty.
 :
 : @param $innerError XQueryException.name 
 : @param $data JSON array representig XQueryException.data[] 
 : @param $className XQueryException.expr 
 : @param $message Sequence of maps representing QueryStackFrame[] 
 : @return Empty sequence if in development mode, HTTP response in qa/production mode.
 :)
declare function raygun:report-error(
  $inner-error as xs:string, 
  $data as json:array, 
  $class-name as xs:string,
  $message as xs:string, 
  $stack-trace-data as map:map+
) as element(http:response)?
{
  raygun:report-error(
    $inner-error,
    $data,
    $class-name,
    $message,
    $stack-trace-data,
    $RAYGUN-CONFIG/mode[. ne "development"], 
    $RAYGUN-CONFIG/api-key
  )
};

(: 
 : Sends error report to Raygun.io. If config mode is set to "development", returns empty.
 :
 : @param $innerError XQueryException.name 
 : @param $data JSON array representig XQueryException.data[] 
 : @param $className XQueryException.expr 
 : @param $message Sequence of maps representing QueryStackFrame[] 
 : @param $mode Valid Raygun mode: development/qa/production
 : @param @api-key Raygun application api key
 : @return Empty sequence if in development mode, HTTP response in qa/production mode.
:)
declare function raygun:report-error(
  $inner-error as xs:string, 
  $data as json:array, 
  $class-name as xs:string,
  $message as xs:string, 
  $stack-trace-data as map:map+,
  $mode as xs:string,
  $api-key as xs:string
) as element(http:response)
{   
  let $raygun-json-map :=
  raygun:create-json-map(
    $inner-error, 
    $data, 
    $class-name, 
    $message, 
    $stack-trace-data, 
    $mode
  )
  return raygun:report-error($raygun-json-map, $api-key) 
};