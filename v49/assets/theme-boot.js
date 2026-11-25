(()=>{'use strict';let value='dark';try{const saved=localStorage.getItem('pge.theme');if(saved==='light'||saved==='dark')value=saved;}catch{}document.documentElement.dataset.theme=value;})();

