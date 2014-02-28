# Lumen

Lumen started life as a group discussion platform akin to [Google Groups](http://groups.google.com), [GroupServer](http://groupserver.org/), 
[Mailman](http://www.list.org/) or [Sympa](http://www.sympa.org/). Since then, it's gained some powerful extras. To give an outline of its features:

* Open-source
* Self-hosted using Heroku (for the web interface, free in initial case), Amazon S3 (for file attachments, typically free or a few pennies/cents per month) and Virtualmin (for the mail sever, requires a low-end VPS at a cost of around £20/$40 per year)
* Designed for custom domains (group email addresses of the form yourgroup@yourdomain.org)
* Dual web/email access
* Extensible member profiles with maps
* Flexible digest engine
* Events calendar
* Daily summaries of news stories tweeted by group members via news.me integration
* Geographically-aware lists feature for maintaining lists of venues, contacts etc

## Getting up and running

### 1. Register a domain

We'll add the DNS records shortly.

### 2. Pull and push code to Heroku

```
git clone https://github.com/wordsandwriting/lumen.git
cd lumen
heroku create yourappname
git push yourappname master
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
* For mail delivery `yourdomain.org MX mail.yourdomain.org` `mail.yourdomain.org A 11.22.33.44`
* SPF `yourdomain.org TXT "v=spf1 a mx a:yourdomain.org ip4:11.22.33.44 ?all"`
* DKIM: Visit Email Messages > DomainKeys Identified Mail in Virtualmin. Set 'Reject incoming email with invalid DKIM signature?' to 'No' and enter yourdomain.org to 'Additional domains to sign for'. Then add the record under 'DNS records for additional domains'.

### 5. Configuration

Visit www.yourdomain.org and complete the configuration (don't forget your S3 details).

You can find an example notification script (VIRTUALMIN_NOTIFICATION_SCRIPT) in /notify.

### 6. Rake tasks

`
heroku run rake mi:create_indexes
heroku addons:open scheduler

Add the following tasks to the scheduler:
`
rake news:update 7am
rake digests:daily 7.30am
rake digests:weekly 11pm (only runs on Sunday)
rake cleanup
`

## Switching mail servers

If you switch your mail server, you'll need to re-setup your mail accounts on the new server. Fire up a console (`heroku run bash; padrino c`) and run:
`
Group.all.each { |g| g.setup_mail_accounts_and_forwarder }
ConversationPost.all.each { |c| c.update_attribute(:mid, nil) }
`