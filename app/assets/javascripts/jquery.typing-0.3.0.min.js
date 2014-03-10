// jQuery-typing
//
// Version: 0.3.0
// Website: http://narf.pl/jquery-typing/
// License: public domain <http://unlicense.org/>
// Author:  Maciej Konieczny <hello@narf.pl>, Mike Taylor <mike@bonuslevel.co.uk>
(function(e){function t(t,n){function u(e){if(!s){s=true;if(r.start){r.start(e,i)}}}function a(e,t){if(s){clearTimeout(o);o=setTimeout(function(){s=false;if(r.stop){r.stop(e,i)}},t>=0?t:r.delay)}}var r=e.extend({start:null,stop:null,delay:400},n);var i=e(t),s=false,o;i.keypress(u);i.keydown(function(e){if(e.keyCode===8||e.keyCode===46){u(e)}});i.keyup(a);i.blur(function(e){a(e,0)});i.bind("paste",function(e){u(e)})}e.fn.typing=function(e){return this.each(function(n,r){t(r,e)})}})(jQuery)