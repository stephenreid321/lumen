# Lumen

## Setup

### Environment variables

```
DOMAIN=neweconomyorganisersnetwork.org
MAIL_DOMAIN=neweconomyorganisersnetwork.org
SITE_NAME=New Economy Organisers Network
SITE_NAME_DEFINITE=the New Economy Organisers Network
SITE_NAME_SHORT=NEON
HELP_ADDRESS=help@neweconomyorganisersnetwork.org

SITEWIDE_ANALYTICS_CONVERSATION_THRESHOLD=4
NEWSME_SWITCH_HOUR=11

DEFAULT_SMTP_SERVER=smtp.neweconomyorganisersnetwork.org
DEFAULT_SMTP_PASSWORD=
DEFAULT_IMAP_SERVER=imap.neweconomyorganisersnetwork.org
DEFAULT_IMAP_PASSWORD=
NOREPLY_SERVER=smtp.neweconomyorganisersnetwork.org
NOREPLY_PORT=25
NOREPLY_AUTHENTICATION=login
NOREPLY_STARTTLS_AUTO=false
NOREPLY_USERNAME=no-reply@neweconomyorganisersnetwork.org
NOREPLY_PASSWORD=
NOREPLY_NAME=New Economy Organisers Network
NOREPLY_ADDRESS=no-reply@neweconomyorganisersnetwork.org
NOREPLY_SIG=Stephen, Dan, Huw and the rest of the NEON team

MAILSERV_INTERFACE=cpanel-11.4
MAILSERV_URL=https://www.neweconomyorganisersnetwork.org/cpanel
MAILSERV_USERNAME=neon
MAILSERV_PASSWORD=
MAILSERV_NOTIFICATION_SCRIPT=notify.php
VIRTUALMIN_DOM=

S3_BUCKET_NAME=
S3_ACCESS_KEY=
S3_SECRET=

FACEBOOK_KEY=
FACEBOOK_SECRET=
LINKEDIN_KEY=
LINKEDIN_SECRET=
GOOGLE_KEY=
GOOGLE_SECRET=
TWITTER_KEY=
TWITTER_SECRET=

EXTRA_FIELDS_ACCOUNT=bio:wysiwyg,research_proposal:file

HEROKU_APP_NAME=
HEROKU_API_KEY=

AIRBRAKE_API_KEY=
AIRBRAKE_HOST=

SESSION_SECRET=
```

### Fragments

<dl>
  <dt>about</dt>
  <dd>Text of about page</dd>

  <dt>sign-in</dt>
  <dd>Text displayed on sign in page</dd>

  <dt>first-time</dt>
  <dd>Text displayed on account edit page upon first login</dd>

  <dt>home</dt>
  <dd>If defined, creates a default landing tab on the homepage with this text</dd>

  <dt>head</dt>
  <dd>Extra content for &lt;head&gt;</dd>

  <dt>affiliation-positions</dt>
  <dd>Comma-separated list of acceptable positions e.g. Novice,Intermediate,Master</dd>

  <dt>tip-affiliations</dt>
  <dd>Tip for affiliations field on account edit page</dd>

  <dt>tip-location</dt>
  <dd>Tip for location field on account edit page</dd>

  <dt>hide-organisations</dt>
  <dd>If defined, hides the 'organisations' tab</dd>

  <dt>hide-sectors</dt>
  <dd>If defined, hides the 'sectors' tab</dd>

  <dt>tt-organisation</dt>
  <dd>Alternative name for 'Organisation'</dd>

  <dt>tt-sector</dt>
  <dd>Alternative name for 'Sector'</dd>

  <dt>organisations-icon</dt>
  <dd>Alternative Font Awesome icon for organisations tab</dd>
</dl>


#### Example notification script

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
account = Account.create!(name: 'Stephen Reid', email: 'admin@neweconomyorganisersnetwork.org', password: 'password', password_confirmation: 'password', role: 'admin')
group = Group.create!(slug: 'post-keynesian-chat')
membership = Membership.create!(group: group, account: account, role: 'admin')
```
