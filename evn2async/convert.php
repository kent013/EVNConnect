<?php
$lines = file("original/NoteStore.m");
$methods = array();
$codes = array();
$categoryFunctions = array();
foreach($lines as $num => $line){
	if($num < 45430){
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
$source = file_get_contents("templates/EvernoteNoteStoreClient.h");
$source = sprintf($source, $date, $methods);
file_put_contents("generated/EvernoteNoteStoreClient.h", $source);

$codes = implode("\n\n\n", $codes);
$source = file_get_contents("templates/EvernoteNoteStoreClient.m");
$source = sprintf($source, $date, $codes);
file_put_contents("generated/EvernoteNoteStoreClient.m", $source);

$categoryFunctions = implode("\n", $categoryFunctions);
$source = file_get_contents("templates/EDAMNoteStoreClient+PrivateMethods.h");
$source = sprintf($source, $date, $categoryFunctions);
file_put_contents("generated/EDAMNoteStoreClient+PrivateMethods.h", $source);

function generateOverrideFunction($name, $lines){
	preg_match('/\(([^*)]+( ?\*)?)\)/', $lines[0], $regs);
	$returnType = $regs[1];
	$isPointer = isset($regs[2]);
	$lines[0] = preg_replace('/^-[^\)]+\)/', '- (void)', $lines[0]);
	//$lines[0] = preg_replace('/^-[^\)]+\)(.+?):/', '- (void)\1Async:', $lines[0]);
	$lines[0] = trim($lines[0]) . " andDelegate:(id<EvernoteHTTPClientDelegate>) delegate\n";

	$didLoadSelector = "client:" . $name . "DidLoad:";
	$insert = <<< EOD
  EvernoteHTTPClient *client = (EvernoteHTTPClient *)[outProtocol transport];
  delegate_ = delegate;
  client.delegate = delegate;
  [client setTarget:self action:@selector({$didLoadSelector})];

EOD;
    array_splice($lines, 2, 0, $insert);
	//$lines[3] = str_replace('[self', '[super', $lines[3]);
	//$lines[4] = str_replace('[self', '[super', $lines[4]);
	if($isPointer){
		$recv = str_replace("return ", "{$returnType}retval = ", $lines[4]);
	}else if($returnType == "int32_t"){
		$recv = str_replace("return ", "{$returnType} rawResult = ",
							$lines[4]);
		$recv .= "  NSNumber *retval = [NSNumber numberWithInt:rawResult];\n";
	}else if($returnType == "int64_t"){
		$recv = str_replace("return ", "{$returnType} rawRetval = ",
							$lines[4]);
		$recv .= "  NSNumber *retval = [NSNumber numberWithLong:rawRetval];\n";
		
	}else{
		throw new Exception("$returnType is not supported.");
	}
	unset($lines[4]);
	//var_dump($lines[0]);
	
	$sendMethod = implode("", $lines);
	$source = <<<EOD
/*!
 * send {$name} request
 */
{$sendMethod}
/*!
 * recieve {$name} result
 */
- (void) client:(EvernoteHTTPClient *)client {$name}DidLoad:(NSData *)result{
{$recv}
  if([delegate_ respondsToSelector:@selector(client:didLoad:)]){
    [delegate_ client:client didLoad:retval];
  }
}
EOD;
    return array("source" => $source, "method" => trim($lines[0]));
}