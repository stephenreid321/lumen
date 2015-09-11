# Lumen

[![Build Status](https://travis-ci.org/wordsandwriting/lumen.png?branch=master)](https://travis-ci.org/wordsandwriting/lumen)
[![Code Climate](https://codeclimate.com/github/wordsandwriting/lumen.png)](https://codeclimate.com/github/wordsandwriting/lumen)

**For a live preview of Lumen, feel free to [request access to the previewers group on lumenapp.com](http://www.lumenapp.com/groups/previewers/request_membership).**

Lumen started life as a group discussion platform akin to [Google Groups](http://groups.google.com), [GroupServer](http://groupserver.org/), 
[Mailman](http://www.list.org/) or [Sympa](http://www.sympa.org/). Since then, it's gained some powerful extras. An outline of its features:

* Open-source (under [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported](http://creativecommons.org/licenses/by-nc-sa/3.0/))
* Hosted using dokku/Heroku (web app), a VPS (mail sever) and Amazon S3 (file attachments)
* You can run dokku and the mail server on the same VPS
* Designed for custom domains (group email addresses of the form yourgroup@yourdomain.org)
* Sends and receives mail via regular SMTP and IMAP accounts
* Dual web/email access
* Extensible member profiles
* Flexible digest engine
* Events calendar
* Daily summaries of news stories tweeted by group members via news.me integration
* Maps placing people, organisations and venues
* Google Docs integration
* Facebook-style walls
* Google Spreadsheets-like surveys feature

Lumen is written in Ruby using the [Padrino](http://padrinorb.com/) framework. It was originally created for the [New Economy Organisers Network](http://neweconomyorganisersnetwork.org/) (hosted by the [New Economics Foundation](http://neweconomics.org/)) who kindly agreed to open source the project and continue to sponsor its development.

[<img src="http://wordsandwriting.github.io/lumen/images/top.jpg">](http://wordsandwriting.github.io/lumen/images/top.jpg)

See below for more images.

## How the mailing lists work, in brief

1. Your mail server receives a mail to yourgroup@yourdomain.org
2. The mail triggers a simple notification script on the mail server that in turn alerts your web app to the fact there's a new message for the group
3. Your web app connects to the mail server via IMAP to fetch the new mail
4. Your web app distributes the message to group members via SMTP

## Installation instructions for DigitalOcean/dokku

* Register a domain `$DOMAIN`. In this simple setup, `$DOMAIN = $MAIL_DOMAIN = $MAIL_SERVER_ADDRESS`.

* Create a 2GB (or greater) droplet with the hostname `$MAIL_SERVER_ADDRESS` and select the image 'Dokku 0.3.26 on 14.04' 

* System update: `apt-get update; apt-get dist-upgrade`

* Install fail2ban: `apt-get install fail2ban`

* Install MongoDB and the dokku MongoDB plugin

  ```
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10; echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list; apt-get update; apt-get install -y mongodb-org; git clone https://github.com/jeffutter/dokku-mongodb-plugin.git /var/lib/dokku/plugins/mongodb; dokku plugins-install; dokku mongodb:start
  ```

* Create certificates

  ```
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/mail.key -out /etc/ssl/certs/mailcert.pem`
  ```

  (You can hit enter a bunch of times to leave the fields empty)

* Install mail packages (**make sure you replace `$MAIL_SERVER_ADDRESS` and `$MAIL_DOMAIN` with your domain**)

  ```
  aptitude install postfix dovecot-core dovecot-imapd opendkim opendkim-tools; mkdir /etc/opendkim; mkdir /etc/opendkim/keys; wget https://raw.github.com/wordsandwriting/lumen/master/script/lumen-install.sh; chmod +x lumen-install.sh; ./lumen-install.sh $MAIL_SERVER_ADDRESS $MAIL_DOMAIN; newaliases; service postfix restart; service dovecot restart; service opendkim restart
  ```

  When dovecot-core asks whether you want to create a self-signed SSL certificate, answer no.

* Get DKIM key with `nano -$ /etc/opendkim/keys/$MAIL_DOMAIN/mail.txt` and add DNS records

  ```
  $MAIL_DOMAIN MX $MAIL_SERVER_ADDRESS  
  $MAIL_SERVER_ADDRESS A $MAIL_SERVER_IP  
  $MAIL_DOMAIN TXT "v=spf1 a mx a:$MAIL_DOMAIN ip4:$MAIL_SERVER_IP ?all"  
  mail._domainkey.$MAIL_DOMAIN TXT "v=DKIM1; k=rsa; p=..."
  ```

* Visit `$DOMAIN`. Enter `$DOMAIN` as the hostname and check 'Use virtualhost naming for apps'

* From your own machine run

  ```
  git clone https://github.com/wordsandwriting/lumen.git; cd lumen; git remote add $APP_NAME dokku@$DOMAIN:lumen; git push $APP_NAME master
  ```

* Create a Mongo instance for the app: `dokku mongodb:create lumen`

* Set configuration variables
  ```
  dokku config:set lumen APP_NAME=$APP_NAME DOMAIN=$DOMAIN MAIL_DOMAIN=$MAIL_DOMAIN MAIL_SERVER_ADDRESS=$MAIL_SERVER_ADDRESS MAIL_SERVER_USERNAME=root MAIL_SERVER_PASSWORD=$MAIL_SERVER_PASSWORD S3_BUCKET_NAME=$S3_BUCKET_NAME S3_ACCESS_KEY=$S3_ACCESS_KEY S3_SECRET=$S3_SECRET SESSION_SECRET=$SESSION_SECRET DRAGONFLY_SECRET=$DRAGONFLY_SECRET`
  ```

  (If you didn't obtain a password for the root user, enable password authentication and set one with: nano /etc/ssh/sshd_config, set PasswordAuthentication yes; restart ssh; passwd)

* Start a worker process: `dokku ps:scale lumen web=1 worker=1`

* Create a default language and database indices: `dokku run lumen rake languages:default[English,en]; dokku run lumen rake mi:create_indexes`

* Set cron tasks (`crontab -e`)

  ```
  0 4 * * * dokku run $APP_NAME rake cleanup  
  0 7 * * * dokku run $APP_NAME rake news:update  
  0 8 * * * dokku run $APP_NAME rake digests:daily  
  0 0 * * 0 dokku run $APP_NAME rake digests:weekly
  ```

* Visit `$DOMAIN`. (You should be automatically logged in as an administrator. If not, sign in with the email address 'admin@example.com' and the password 'lumen'.) Change the admin name, email address and password.

* Visit /config and 'Create notification script'. Add additional configuration variables via `dokku config:set lumen VAR=$VAR`. You're done!

## Switching mail servers

If you switch your mail server, you'll need to re-setup the group mail accounts on the new server. Fire up a console (`padrino c`) and run:
```
Group.each { |group| group.setup_mail_accounts_and_forwarder }
ConversationPost.update_all(imap_uid: nil)
```

## Gallery

### Homepage (amalgamates newsfeeds from all groups)
[<img src="http://wordsandwriting.github.io/lumen/images/home.jpg">](http://wordsandwriting.github.io/lumen/images/home.jpg)

### Home calendar (amalgamates events from all groups)
[<img src="http://wordsandwriting.github.io/lumen/images/calendar.jpg">](http://wordsandwriting.github.io/lumen/images/calendar.jpg)

### A group
[<img src="http://wordsandwriting.github.io/lumen/images/group.jpg">](http://wordsandwriting.github.io/lumen/images/group.jpg)

### A group digest
[<img src="http://wordsandwriting.github.io/lumen/images/digest.jpg">](http://wordsandwriting.github.io/lumen/images/digest.jpg)

### A group's map
[<img src="http://wordsandwriting.github.io/lumen/images/map.jpg">](http://wordsandwriting.github.io/lumen/images/map.jpg)

### A profile 
[<img src="http://wordsandwriting.github.io/lumen/images/profile.jpg">](http://wordsandwriting.github.io/lumen/images/profile.jpg)

### Email accounts corresponding to groups 
[<img src="http://wordsandwriting.github.io/lumen/images/virtualmin.jpg">](http://wordsandwriting.github.io/lumen/images/virtualmin.jpg)

