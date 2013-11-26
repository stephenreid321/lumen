# Lumen

## Setup

### .env

```
DOMAIN=neweconomyorganisersnetwork.org
MAIL_DOMAIN=neweconomyorganisersnetwork.org
SITE_NAME=New Economy Organisers Network
SITE_NAME_DEFINITE=the New Economy Organisers Network
SITE_NAME_SHORT=NEON
HELP_ADDRESS=help@neweconomyorganisersnetwork.org

SITEWIDE_ANALYTICS_CONVERSATION_THRESHOLD=4

DEFAULT_SMTP_SERVER=smtp.neweconomyorganisersnetwork.org
DEFAULT_SMTP_PASSWORD=
DEFAULT_IMAP_SERVER=imap.neweconomyorganisersnetwork.org
DEFAULT_IMAP_PASSWORD=
NOREPLY_SERVER=smtp.neweconomyorganisersnetwork.org
NOREPLY_PORT=25
NOREPLY_AUTHENTICATION=login
NOREPLY_SSL=false
NOREPLY_USERNAME=no-reply@neweconomyorganisersnetwork.org
NOREPLY_PASSWORD=
NOREPLY_NAME=New Economy Organisers Network
NOREPLY_ADDRESS=no-reply@neweconomyorganisersnetwork.org
NOREPLY_SIG=Stephen, Dan, Huw and the rest of the NEON team

CPANEL_URL=https://www.neweconomyorganisersnetwork.org/cpanel
CPANEL_USERNAME=neon
CPANEL_PASSWORD=
CPANEL_NOTIFICATION_SCRIPT=notify.php

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

AIRBRAKE_API_KEY=
```

### Seeding the database

``` ruby
Fragment.create!(slug: 'about', body: 'this is the about page')
Fragment.create!(slug: 'first-time', body: 'this is the message displayed when someone signs in for the first time')
Fragment.create!(slug: 'sign-in', body: 'this is the message on the sign in page')

account = Account.create!(name: 'Stephen Reid', email: 'admin@neweconomyorganisersnetwork.org', password: 'password', password_confirmation: 'password', role: 'admin')
group = Group.create!(slug: 'post-keynesian-chat')
membership = Membership.create!(group: group, account: account, role: 'admin')

NewsSummary.create!(title: 'According to us', url: 'http://www.news.me/neon_nefbot', selector: '.top-stories.stories-list', order: 0)
NewsSummary.create!(title: 'According to neoliberals', url: 'http://www.news.me/NeoliberalBot', selector: '.top-stories.stories-list', order: 1)
```