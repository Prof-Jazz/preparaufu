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
  setTimeout(ping,2500);
  setInterval(function(){if(!document.hidden)ping();},60000);
  document.addEventListener('visibilitychange',function(){if(!document.hidden)ping();});
})();
