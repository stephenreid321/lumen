Lumen
=================

Setup
---
Fragment.create!(slug: 'about', body: 'this is the about page')
Fragment.create!(slug: 'first-time', body: 'this is the message displayed when someone signs in for the first time')
Fragment.create!(slug: 'sign-in', body: 'this is the message on the sign in page')

account = Account.create!(name: 'Stephen Reid', email: 'postscript07@gmail.com', password: 'password', password_confirmation: 'password', role: 'admin')
organisation = Organisation.create!(name: 'More Than Enough')
affiliation = Affiliation.create!(account: account, organisation: organisation, title: 'Director')

NewsSummary.create!(title: 'According to us', url: 'http://www.news.me/neon_nefbot', selector: '.top-stories.stories-list', order: 0)
NewsSummary.create!(title: 'According to neoliberals', url: 'http://www.news.me/NeoliberalBot', selector: '.top-stories.stories-list', order: 1)

group = Group.create!(slug: 'sparrow')
membership = Membership.create!(group: group, account: account, role: 'admin')