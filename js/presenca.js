/* Presença: avisa ao site que o aluno está online (e se está estudando) */
(function(){
  function ping(){
    try{
      if(typeof SB==='undefined'||!SB)return;
      var s=null;try{s=JSON.parse(localStorage.getItem('bqufu-sessao')||'null');}catch(e){}
      SB.auth.getSession().then(function(r){
        if(!r||!r.data||!r.data.session)return;
        var est=!!(s&&s.rodando);
        SB.rpc('ping',{p_estudando:est,p_materia:s?s.materia:null,p_tipo:s?s.tipo:null,p_desde:s?new Date(s.inicio).toISOString():null}).then(function(){},function(){});
      });
    }catch(e){}
  }
  window.pingPresenca=ping;
  function navArea(){
    try{
      if(typeof SB==='undefined'||!SB||/^\/mentoria\//.test(location.pathname))return;
      SB.auth.getSession().then(function(r){
        if(!r||!r.data||!r.data.session)return;
        SB.rpc('minhas_areas').then(function(x){var a=x&&x.data;if(!a||!a.mentoria||a.papel==='admin')return;
          var navs=document.querySelectorAll('header nav');
          navs.forEach(function(nav){
            if(!a.turma){nav.querySelectorAll('a').forEach(function(l){var h=l.getAttribute('href')||'';if(/aulas\/|assessoria/.test(h))l.style.display='none';});}
            if(!nav.querySelector('a[href="/mentoria/"]')){var l=document.createElement('a');l.href='/mentoria/';l.textContent='Minha Mentoria';var c=nav.querySelector('a');if(c)l.className=c.className;var sair=nav.querySelector('#sair,button:last-child');if(sair&&sair.parentNode===nav)nav.insertBefore(l,sair);else nav.appendChild(l);}
          });
        },function(){});
      });
    }catch(e){}
  }
  setTimeout(navArea,1200);
  function modoAlunoMentoria(){
    try{
      if(/^\/mentoria\//.test(location.pathname))return;
      var pu=sessionStorage.getItem('bqufu-mentoria-puro'),v=JSON.parse(sessionStorage.getItem('bqufu-mentoria-ver')||'null');
      if(!pu||!v||!v.email)return;
      document.querySelectorAll('header nav').forEach(function(nav){
        nav.querySelectorAll('a').forEach(function(l){var h=l.getAttribute('href')||'';if(/aulas\/|assessoria|area=escolher/.test(h))l.style.display='none';});
        var c=nav.querySelector('a');var sair=nav.querySelector('#sair,button:last-child');
        var m=document.createElement('a');m.href='/mentoria/';m.textContent='Minha Mentoria';if(c)m.className=c.className;
        var b=document.createElement('a');b.href='/mentoria/';b.textContent='Sair do modo aluno';if(c)b.className=c.className;b.style.borderColor='#DDDD24';b.style.color='#DDDD24';
        b.onclick=function(){try{sessionStorage.removeItem('bqufu-mentoria-puro');}catch(e){}};
        if(sair&&sair.parentNode===nav){nav.insertBefore(m,sair);nav.insertBefore(b,sair);}else{nav.appendChild(m);nav.appendChild(b);}
      });
    }catch(e){}
  }
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',modoAlunoMentoria);else modoAlunoMentoria();
  setTimeout(ping,2500);
  setInterval(function(){if(!document.hidden)ping();},60000);
  document.addEventListener('visibilitychange',function(){if(!document.hidden)ping();});
})();
