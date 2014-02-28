#!/usr/bin/php -n
<?php
require_once('PlancakeEmailParser.php');

$domain = 'www.yourdomain.org';
$maildomain = 'yourdomain.org';
$token = '\$2a\$10\$n8NnPYSKmblrLH4fqwAOp.dAK43r31d08g2e';

$fd = fopen("php://stdin", "r");
$email = "";
while (!feof($fd)) { $email .= fread($fd, 1024); }
fclose($fd);

$emailParser = new PlancakeEmailParser($email);

$sender = $emailParser->getHeader('Sender');
if ($sender != $argv[1].'-noreply@'.$maildomain) { 
	exec('curl --silent http://'.$domain.'/groups/'.$argv[1].'/check?token='.$token);
}

?>