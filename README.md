# Lumen

### Example notification script

```php
#!/usr/local/bin/php -n
<?php
require_once('PlancakeEmailParser.php');

$domain = 'www.neweconomyorganisersnetwork.org';
$maildomain = 'neweconomyorganisersnetwork.org';
$token = '\$2a\$10\$n8NnPYSKmblrLH4fqwAOp.dAK43r3';

$fd = fopen("php://stdin", "r");
$email = "";
while (!feof($fd))
{
    $email .= fread($fd, 1024);
}
fclose($fd);

$emailParser = new PlancakeEmailParser($email);

$sender = $emailParser->getHeader('Sender');
if ($sender != $argv[1].'-noreply@'.$maildomain) { 
	exec('curl --silent http://'.$domain.'/groups/'.$argv[1].'/check?token='.$token);
}

?>
```

### Seeding the database

``` ruby
Account.create!(name: 'Stephen Reid', email: 'admin@neweconomyorganisersnetwork.org', password: 'password', password_confirmation: 'password', role: 'admin')
```
