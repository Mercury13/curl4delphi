<?php

function at($arr, $ind)
{
	if (isset($arr[$ind]))
		return $arr[$ind];
		else return '';
}

header('Content-Type: text/plain; charset=utf-8');

define('PHOTO', 'photo');

if (!isset($_FILES[PHOTO]))
	die('No photo.');

$fileName = $_FILES[PHOTO]['name'];
$tempName = $_FILES[PHOTO]['tmp_name'];
if (!is_uploaded_file($tempName))
	die('No photo.');

$fileType = $_FILES[PHOTO]['type'];
switch ($fileType) {
case 'image/jpeg':
	$image = imagecreatefromjpeg ($tempName);
	break;
case 'image/png':
	$image = imagecreatefrompng ($tempName);
	break;
default:
	die('Unknown file type.');
}

if (!$image)
	die('Cannot load file.');

$w = imagesx($image);
$h = imagesy($image);

echo "File $fileName: ${w}×${h}";

?>