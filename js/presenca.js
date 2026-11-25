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
            if(!a.turma){nav.querySelectorAll('a').forEach(function(l){var h=l.getAttribute('href')||'';if(/(^|[.\/])aulas\/|assessoria/.test(h))l.style.display='none';});}
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
  var AC=null;
  function somMsg(){try{AC=AC||new (window.AudioContext||window.webkitAudioContext)();if(AC.state==='suspended')AC.resume();
    [[880,0],[1320,0.16]].forEach(function(n){var o=AC.createOscillator(),g=AC.createGain();o.type='sine';o.frequency.value=n[0];
      var t=AC.currentTime+n[1];g.gain.setValueAtTime(0.0001,t);g.gain.exponentialRampToValueAtTime(0.25,t+0.02);g.gain.exponentialRampToValueAtTime(0.0001,t+0.22);o.connect(g);g.connect(AC.destination);o.start(t);o.stop(t+0.25);});}catch(e){}}
  document.addEventListener('click',function(){try{AC=AC||new (window.AudioContext||window.webkitAudioContext)();if(AC.state==='suspended')AC.resume();}catch(e){}},{once:true});
  function toastMsg(nome,n){try{var t=document.getElementById('msgToast');if(!t){t=document.createElement('a');t.id='msgToast';t.href='/estudos/#mensagens';
      t.style.cssText='position:fixed;right:18px;bottom:18px;z-index:200;display:flex;align-items:center;gap:12px;max-width:340px;padding:14px 16px;border-radius:16px;background:#16304F;color:#fff;text-decoration:none;font:600 14.5px system-ui,sans-serif;box-shadow:0 14px 40px rgba(0,0,0,.4);border:1px solid #DDDD24;transition:opacity .3s,transform .3s';
      document.body.appendChild(t);}
    t.innerHTML='<span style="flex:none;width:38px;height:38px;border-radius:50%;background:#DDDD24;color:#16304F;display:grid;place-items:center;font-size:18px">&#9993;</span><span><b style="display:block;font-size:15px">Nova mensagem'+(n>1?'s':'')+'</b><span style="opacity:.85">'+(nome?('de '+nome.replace(/[<>&]/g,'')):'')+(n>1?' · '+n+' não lidas':'')+'</span></span>';
    t.style.opacity='1';t.style.transform='none';clearTimeout(t._tm);t._tm=setTimeout(function(){t.style.opacity='0';t.style.transform='translateY(10px)';},9000);}catch(e){}}
  function avisoMsgs(){
    try{
      if(typeof SB==='undefined'||!SB)return;
      SB.auth.getSession().then(function(r){
        if(!r||!r.data||!r.data.session)return;
        SB.rpc('nao_lidas').then(function(x){var n=x&&x.data||0;
          var antes=null;try{antes=sessionStorage.getItem('bqufu-nl');}catch(e){}
          try{sessionStorage.setItem('bqufu-nl',String(n));}catch(e){}
          if(antes===null&&n>0){SB.rpc('minhas_conversas').then(function(c){var L=(c&&c.data)||[];var u=L.find(function(z){return z.nao_lidas>0;});toastMsg(u?u.nome:'',n);},function(){});}
          if(antes!==null&&n>+antes){somMsg();
            SB.rpc('minhas_conversas').then(function(c){var L=(c&&c.data)||[];var u=L.find(function(z){return z.nao_lidas>0;});toastMsg(u?u.nome:'',n);},function(){toastMsg('',n);});}
          document.querySelectorAll('header nav a[href*="estudos/"]').forEach(function(l){var b=l.querySelector('.msgbdg');
            if(!n){if(b)b.remove();return;}
            if(!b){b=document.createElement('em');b.className='msgbdg';b.style.cssText='display:inline-grid;place-items:center;min-width:18px;height:18px;padding:0 5px;margin-left:6px;border-radius:999px;background:#E5484D;color:#fff;font:800 11px system-ui;font-style:normal;vertical-align:middle';l.appendChild(b);}
            b.textContent=n;b.title=n+' mensagem(ns) nova(s) na Sala de Estudos';});
        },function(){});
      });
    }catch(e){}
  }
  window.avisoMsgs=avisoMsgs;
  setTimeout(avisoMsgs,1500);setInterval(function(){if(!document.hidden)avisoMsgs();},20000);
  function modoAlunoMentoria(){
    try{
      if(/^\/mentoria\//.test(location.pathname))return;
      var pu=sessionStorage.getItem('bqufu-mentoria-puro'),v=JSON.parse(sessionStorage.getItem('bqufu-mentoria-ver')||'null');
      if(!pu||!v||!v.email)return;
      document.querySelectorAll('header nav').forEach(function(nav){
        nav.querySelectorAll('a').forEach(function(l){var h=l.getAttribute('href')||'';if(/(^|[.\/])aulas\/|assessoria|area=escolher/.test(h))l.style.display='none';});
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
