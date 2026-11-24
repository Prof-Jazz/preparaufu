/* Presença: avisa ao site que o aluno está online (e se está estudando) */
(function(){
  function ping(){
    try{
      if(typeof SB==='undefined'||!SB)return;
      var s=null;try{s=JSON.parse(localStorage.getItem('bqufu-sessao')||'null');}catch(e){}
      SB.auth.getSession().then(function(r){
        if(!r||!r.data||!r.data.session){try{Object.keys(sessionStorage).filter(function(x){return x.indexOf('bqufu-aviso-venc-')===0;}).forEach(function(x){sessionStorage.removeItem(x);});}catch(e){}return;}
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
  function logoAreas(){
    try{
      if(typeof SB==='undefined'||!SB)return;
      if(sessionStorage.getItem('bqufu-mentoria-puro'))return;
      SB.auth.getSession().then(function(r){
        if(!r||!r.data||!r.data.session)return;
        SB.rpc('minhas_areas').then(function(x){var a=x&&x.data;if(!a||!a.turma||!a.mentoria)return;
          document.querySelectorAll('a.logos').forEach(function(l){l.href='/?area=escolher';l.title='Escolher a área: Turmas ou Mentoria individual';});
        },function(){});
      });
    }catch(e){}
  }
  setTimeout(logoAreas,800);
  function avisoMsgs(){
    try{
      if(typeof SB==='undefined'||!SB)return;
      SB.auth.getSession().then(function(r){
        if(!r||!r.data||!r.data.session)return;
        SB.rpc('nao_lidas').then(function(x){var n=x&&x.data||0;
          document.querySelectorAll('header nav a[href*="estudos/"]').forEach(function(l){var b=l.querySelector('.msgbdg');
            if(!n){if(b)b.remove();return;}
            if(!b){b=document.createElement('em');b.className='msgbdg';b.style.cssText='display:inline-grid;place-items:center;min-width:18px;height:18px;padding:0 5px;margin-left:6px;border-radius:999px;background:#E5484D;color:#fff;font:800 11px system-ui;font-style:normal;vertical-align:middle';l.appendChild(b);}
            b.textContent=n;b.title=n+' mensagem(ns) nova(s) na Sala de Estudos';});
        },function(){});
      });
    }catch(e){}
  }
  setTimeout(avisoMsgs,1500);setInterval(function(){if(!document.hidden)avisoMsgs();},60000);
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
