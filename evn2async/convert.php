<?php
processEDAMClass(45430, "Note");
processEDAMClass(3770, "User");

function processEDAMClass($startLine, $prefix){
	$lines = file("original/{$prefix}Store.m");
	$methods = array();
	$codes = array();
	$categoryFunctions = array();
	foreach($lines as $num => $line){
		if($num < $startLine){
			continue;
		}
		if(preg_match('/^-.+?send_.+?$/', $line, $regs)){
			$categoryFunctions[] = $regs[0] . ";";
		}else if(preg_match('/^-.+?recv_.+?$/', $line, $regs)){
			$categoryFunctions[] = $regs[0] . ";";
		}else if(preg_match('/return \[self recv_(.+?)\];/', $line, $regs)){
			$lf = array_slice($lines, $num - 3, 5);
			$results = generateOverrideFunction($regs[1], $lf);
			$methods[] = $results["method"] . ";";
			$codes[] = $results["source"];
		}
	}

	$date = date("Y/m/d H:i:s");

	$methods = implode("\n", $methods);
	$source = file_get_contents("templates/Evernote{$prefix}StoreClient.h");
	$source = sprintf($source, $date, $methods);
	file_put_contents("generated/Evernote{$prefix}StoreClient.h", $source);

	$codes = implode("\n\n\n", $codes);
	$source = file_get_contents("templates/Evernote{$prefix}StoreClient.m");
	$source = sprintf($source, $date, $codes);
	file_put_contents("generated/Evernote{$prefix}StoreClient.m", $source);

	$categoryFunctions = implode("\n", $categoryFunctions);
	$source = file_get_contents("templates/EDAM{$prefix}StoreClient+PrivateMethods.h");
	$source = sprintf($source, $date, $categoryFunctions);
	file_put_contents("generated/EDAM{$prefix}StoreClient+PrivateMethods.h", $source);
}

function generateOverrideFunction($name, $lines){
	preg_match('/\(([^*)]+( ?\*)?)\)/', $lines[0], $regs);
	$returnType = $regs[1];
	$isPointer = isset($regs[2]);
	$lines[0] = preg_replace('/^-[^\)]+\)/', '- (void)', $lines[0]);
	//$lines[0] = preg_replace('/^-[^\)]+\)(.+?):/', '- (void)\1Async:', $lines[0]);
	$lines[0] = trim($lines[0]) . " andDelegate:(id<EvernoteHTTPClientDelegate>) delegate";
	$lines[2] = trim($lines[2]);
	$didLoadSelector = "client:" . $name . "DidLoad:";
	$send = <<< EOD
{$lines[0]}
{
  EvernoteHTTPClient *client = (EvernoteHTTPClient *)[outProtocol transport];
  delegate_ = delegate;
  client.delegate = delegate;
  [client setTarget:self action:@selector({$didLoadSelector})];
  @try{
    {$lines[2]}
  }@catch(NSException *exception){
    if([delegate_ respondsToSelector:@selector(client:didFailWithException:)]){
      [delegate_ client:client didFailWithException:exception];
    }
  }
}
EOD;
	if($isPointer){
		$recv = str_replace("return ", "{$returnType}retval = ", $lines[3]);
	}else if($returnType == "int32_t"){
		$recv = str_replace("return ", "{$returnType} rawResult = ",
							$lines[3]);
		$recv .= "    NSNumber *retval = [NSNumber numberWithInt:rawResult];\n";
	}else if($returnType == "int64_t"){
		$recv = str_replace("return ", "{$returnType} rawRetval = ",
							$lines[3]);
		$recv .= "    NSNumber *retval = [NSNumber numberWithLong:rawRetval];\n";
		
	}else if($returnType == "BOOL"){
		$recv = str_replace("return ", "{$returnType} rawRetval = ",
							$lines[3]);
		$recv .= "    NSNumber *retval = [NSNumber numberWithBool:rawRetval];\n";
		
	}else{
		throw new Exception("$returnType is not supported.");
	}
	
	$source = <<<EOD
/*!
 * send {$name} request
 */
{$send}
/*!
 * recieve {$name} result
 */
- (void) client:(EvernoteHTTPClient *)client {$name}DidLoad:(NSData *)result{
  @try{
  {$recv}
    if([delegate_ respondsToSelector:@selector(client:didLoad:)]){
      [delegate_ client:client didLoad:retval];
    }
  }@catch(NSException *exception){
    if([delegate_ respondsToSelector:@selector(client:didFailWithException:)]){
      [delegate_ client:client didFailWithException:exception];
    }
  }
}
EOD;
    return array("source" => $source, "method" => trim($lines[0]));
}