'use strict';
const link=document.getElementById('canonical-destination');
if(link){
 const destination=new URL(link.getAttribute('href'),location.href);
 if(destination.origin===location.origin){
  destination.search=location.search;
  destination.hash=location.hash;
  location.replace(destination.href);
 }
}
