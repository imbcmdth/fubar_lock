<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');
ob_start();
require_once('./lib/JSON.php');

$data = load_json('fubar.js');

if(isset($_REQUEST['rfid']))
{
  $rfid_new = $_REQUEST['rfid'];
  $offset = 0;
  $found = false;
  foreach($data as $rfid_entry)
  {
    if(strcmp($rfid_entry, $rfid_new) == 0)
    {
      array_splice($data, $offset, 1);
      $found = true;
    } else {
      $offset++;
    }
  }
  if(!$found)
  {
    $data[] = $rfid_new;
  }
  save_json('fubar.js', $data);
  echo count($data);
} else {
  /* 
  $hRandomSalt = "";
  for ($i = 0; $i<24; $i++)
  {
    $hSalt = rand(33, 255);
    $hRandomSalt .= chr($hSalt);
  }
  $hRandomSalt = hash("sha256", $hRandomSalt);
  */
  echo count($data);
}

function load_json($filename)
{
  $json = new Services_JSON();

  //$block =  file_get_contents('fubar.orig');
  $block =  file_get_contents($filename);
  $pos = stripos($block, "\n"); // We have to remove the first line, everything including the =...
  if ($pos !== false) 
  {
    $block = substr($block, $pos);
//      $block = str_replace("\n" , "", $block); // I get rid of any newlines or carrige returns...
    $block = str_replace("\t" , "", $block); // I also get rid of any tabs...
    $block = str_replace(";more();" , "", $block);  // Finally remove the trailing ';' char...
  }
  $decoded = $json->decode($block);
  return $decoded;
}

function save_json($filename, $output)
{
  $json = new Services_JSON();
  $prefix = "var d=document,more=function(){var t = d.getElementsByTagName(\"script\");for(var i = t.length; --i>=0;){if(t[i].src.indexOf(\"fubar.js\") >= 0){var new_div = document.createElement(\"div\");new_div.innerHTML = fubar.join(\", \");t[i].parentNode.insertBefore(new_div,t[i]);t[i].parentNode.removeChild(t[i]);}}},fubar =";
  $encoded = $prefix."\n".$json->encode($output).";more();";
//    $encoded = "var todaysspecials = \n".json_encode($output).";";
  $encoded = str_replace("\\/" , "/", $encoded); // I get rid of extras \'s...
  return file_put_contents($filename, $encoded);
}
?>