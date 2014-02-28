# Lumen

Lumen started life as a group discussion platform akin to [Google Groups](http://groups.google.com), [GroupServer](http://groupserver.org/), 
[Mailman](http://www.list.org/) or [Sympa](http://www.sympa.org/). Since then, it's gained some powerful extras. An outline of its features:

* Open-source (under [Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported](http://creativecommons.org/licenses/by-nc-sa/3.0/))
* Self-hosted using Heroku (for the web interface, free in initial case), Amazon S3 (for file attachments, typically free or a few pennies/cents per month) and Virtualmin (for the mail sever, requires a low-end VPS at a cost of around £20/$40 per year)
* Designed for custom domains (group email addresses of the form yourgroup@yourdomain.org)
* Sends and receives mail via regular SMTP and IMAP accounts on Virtualmin
* Dual web/email access
* Extensible member profiles
* Flexible digest engine
* Events calendar
* Daily summaries of news stories tweeted by group members via news.me integration
* Geographically-aware lists feature for maintaining lists of venues, contacts etc

Lumen is written in Ruby using the [Padrino](http://padrinorb.com/) framework.

[<img src="http://wordsandwriting.github.io/lumen/images/top.jpg">](http://wordsandwriting.github.io/lumen/images/top.jpg)

See below for more images.

## Getting up and running

### 1. Register a domain

We'll add the DNS records shortly.

### 2. Push code to Heroku

```
git clone https://github.com/wordsandwriting/lumen.git
cd lumen
heroku create yourappname
git push heroku master
heroku addons:add mongohq
heroku addons:add memcachier
heroku addons:add papertrail
heroku addons:add scheduler
heroku config:set HEROKU_APP_NAME=yourappname
heroku config:set HEROKU_API_KEY=yourapikey
```

(You can find your Heroku API key at [http://dashboard.heroku.com/account](http://dashboard.heroku.com/account).)

###  3. Set up Virtualmin

Purchase a VPS (check out [http://lowendbox.com/](http://lowendbox.com/), 512mb RAM should do) and follow [this guide](http://lowendbox.com/blog/your-own-mail-server-with-virtualmin/) to set up Virtualmin. 
You probably don't need ClamAV or SpamAssassin, and so you can untick Spam and Virus filtering from the 'Features and Plugins' screen.

Create an email address no-reply@yourdomain.org with the same password as the Virtualmin user.

### 4. Set DNS

Supposing the IP of your VPS is 11.22.33.44:

* Point www. to Heroku `www.yourdomain.org CNAME yourappname.herokuapp.com`
* Naked domain redirect via [wwwizer.com](http://wwwizer.com) `yourdomain.org A 174.129.25.170` 
* For mail delivery `yourdomain.org MX mail.yourdomain.org` and `mail.yourdomain.org A 11.22.33.44`
* SPF `yourdomain.org TXT "v=spf1 a mx a:yourdomain.org ip4:11.22.33.44 ?all"`
* DKIM: Visit Email Messages > DomainKeys Identified Mail in Virtualmin. Set 'Reject incoming email with invalid DKIM signature?' to 'No' and enter yourdomain.org to 'Additional domains to sign for'. Then add the record under 'DNS records for additional domains'.

### 5. Configuration

Visit www.yourdomain.org and complete the configuration (don't forget your S3 details).

You can find an example notification script (VIRTUALMIN_NOTIFICATION_SCRIPT) in `/notify`. Visit http://www.yourdomain.org/admin/index/Account and click 'Edit' to
find your secret token.

### 6. Rake tasks

```
heroku run rake mi:create_indexes
heroku addons:open scheduler
```

Add the following tasks to the scheduler:
```
rake news:update 7am
rake digests:daily 7.30am
rake digests:weekly 11pm (only runs on Sunday)
rake cleanup 4am
```

## Switching mail servers

If you switch your mail server, you'll need to re-setup the group mail accounts on the new server. Fire up a console (`heroku run bash; padrino c`) and run:
```
Group.all.each { |g| g.setup_mail_accounts_and_forwarder }
ConversationPost.all.each { |c| c.update_attribute(:mid, nil) }
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

### A list
[<img src="http://wordsandwriting.github.io/lumen/images/list.jpg">](http://wordsandwriting.github.io/lumen/images/list.jpg)

### A profile 
[<img src="http://wordsandwriting.github.io/lumen/images/profile.jpg">](http://wordsandwriting.github.io/lumen/images/profile.jpg)

