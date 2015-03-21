<?php

function at($arr, $ind)
{
	if (isset($arr[$ind]))
		return $arr[$ind];
		else return '';
}

$a = at($_POST, 'a');
$b = at($_POST, 'b');

header('Content-Type: text/plain; charset=utf-8');

$c = $a + $b;

echo "a + b = $c";

?>