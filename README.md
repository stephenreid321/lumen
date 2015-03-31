# Lumen

[![Build Status](https://travis-ci.org/wordsandwriting/lumen.png?branch=master)](https://travis-ci.org/wordsandwriting/lumen)
[![Code Climate](https://codeclimate.com/github/wordsandwriting/lumen.png)](https://codeclimate.com/github/wordsandwriting/lumen)

**For a live preview of Lumen, feel free to [request access to the previewers group on lumenapp.com](http://www.lumenapp.com/groups/previewers/request_membership).**

Lumen started life as a group discussion platform akin to [Google Groups](http://groups.google.com), [GroupServer](http://groupserver.org/), 
[Mailman](http://www.list.org/) or [Sympa](http://www.sympa.org/). Since then, it's gained some powerful extras. An outline of its features:

* Open-source (under [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported](http://creativecommons.org/licenses/by-nc-sa/3.0/))
* Hosted using dokku or Heroku (web app), Amazon S3 (file attachments) and a VPS (mail sever). You can run dokku and the mail server on the same VPS.
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

## Getting up and running

### 1. Register a domain

We'll add the DNS records shortly.

###  2. Purchase a VPS and set up the mail server

Purchase a VPS (Try [RamNode](http://www.ramnode.com/) or [Digital Ocean](http://www.digitalocean.com), 512mb RAM should do). If in doubt use `mail.yourdomain.org` as the hostname and choose Ubuntu 14.04 64-bit as your operating system.
Make sure you obtain a password for the root user. (Since we're using password authentication, it's highly recommended that you install [fail2ban](https://www.liberiangeek.net/2014/10/install-configure-fail2ban-ubuntu-14-04-servers/).)

Follow the guide on [How To Set Up a Postfix E-Mail Server with Dovecot](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-postfix-e-mail-server-with-dovecot) and
then the guide on [How To Install and Configure DKIM with Postfix](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy).

Add the following lines to `/etc/postfix/main.cf`:

```
virtual_alias_domains = lists.lumenapp.com
virtual_alias_maps = hash:/etc/postfix/virtual
home_mailbox = Maildir/
```

In `nano /etc/dovecot/dovecot.conf`, change `mail_location = mbox:~/mail:INBOX=/var/mail/%u` to

```
mail_location = maildir:~/Maildir
```

In `/etc/opendkim.conf`, add the line
```
SenderHeaders           Sender,From
```

Restart postfix, dovecot and opendkim.

### 3. Push code and run rake tasks

Clone the Lumen repo and push it to dokku/Heroku.

Prepare a MongoDB database: you can use [dokku-mongodb-plugin](https://github.com/jeffutter/dokku-mongodb-plugin) on dokku
or [MongoLab](https://addons.heroku.com/mongolab) on Heroku.

Optionally, add a custom domain (see instructions for [dokku](http://progrium.viewdocs.io/dokku/nginx) or [Heroku](https://devcenter.heroku.com/articles/custom-domains).)

Set the following configuration variables:
```
APP_NAME=yourappname DOMAIN=www.yourdomain.org MAIL_DOMAIN=yourdomain.org MONGO_URL=yourmongourl MAIL_SERVER_ADDRESS=yourmailserveraddress MAIL_SERVER_USERNAME=root MAIL_SERVER_PASSWORD=yourmailserverpassword S3_BUCKET_NAME=yourbucketname S3_ACCESS_KEY=youraccesskey S3_SECRET=yours3secret AIRBRAKE_HOST=yourairbrakehost AIRBRAKE_API_KEY=yourairbrakeapikey SESSION_SECRET=somelongsecretstring DRAGONFLY_SECRET=somelongsecretstring
```
If using Heroku, also set `HEROKU_OAUTH_TOKEN` (see [https://github.com/heroku/platform-api](https://github.com/heroku/platform-api) for details of how to generate it).

Run `rake languages:default[English,en]` to set a default language and `rake mi:create_indexes` to create the database indexes.

Schedule the following tasks using [cron](https://www.digitalocean.com/community/tutorials/how-to-use-cron-to-automate-tasks-on-a-vps) (dokku) or the [Scheduler addon](https://devcenter.heroku.com/articles/scheduler) (Heroku):
* `rake cleanup` (daily, 4am)
* `rake news:update` (daily, suggested 7am)
* `rake digests:daily` (daily, 8am)
* `rake digests:weekly` (weekly, but you can schedule it daily and it will only run on Sunday)

If using dokku, your crontab should look something like this:
```
0 4 * * * dokku run yourappname rake cleanup
0 7 * * * dokku run yourappname rake news:update
0 8 * * * dokku run yourappname rake digests:daily
0 0 * * 0 dokku run yourappname rake digests:weekly
```

### 4. Check DNS

* For mail delivery `yourdomain.org MX mail.yourdomain.org` and `mail.yourdomain.org A {your VPS IP}`
* SPF `yourdomain.org TXT "v=spf1 a mx a:yourdomain.org ip4:{your VPS IP} ?all"`
* DKIM: see DKIM guide above

If using a custom domain with Heroku you'll also have something like `www.yourdomain.org CNAME yourappname.herokuapp.com`. 
You can also make use of [wwwizer.com](http://wwwizer.com)'s free naked domain redirect `yourdomain.org A 174.129.25.170`.

### 5. Configuration

Visit www.yourdomain.org for the first time. (You should be automatically logged in as an administrator. If not, sign in with the email address 'admin@example.com' and the password 'lumen'.) Change the admin name, email address and password. Click 'Lumen configuration' in the footer and complete the configuration. You're done!

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

