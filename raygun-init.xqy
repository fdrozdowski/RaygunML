xquery version "1.0-ml";
(:
 : Endpoint for Raygun provider initialization.
 :)
import module namespace raygun-deploy = "http://raygun.io" at "raygun-deploy.xqm";

declare variable $PARAMS := local:load-params();

declare function local:load-params() as element()
{    
  <params>{
    for $i in xdmp:get-request-field-names()
    (: fall in with the jQuery convention for sequences :)
    let $name := replace($i, '^([-\w]+)(\[\])$', '$1')
    where $name
    return        
      for $v in xdmp:get-request-field($i, "")            
      where $v
      return element {fn:lower-case($name)} {$v}
  }</params>
};

switch($PARAMS/isconfig/string())
	case "true" return
		raygun-deploy:init(
			xdmp:unquote($PARAMS/config)/raygun
		)	
	case "false" return
		raygun-deploy:init(
			$PARAMS/user/string(),
			$PARAMS/database/string(),
			$PARAMS/api-key/string(),
			$PARAMS/mode/string()
		)
	default return error((), "Missing parameter.")
