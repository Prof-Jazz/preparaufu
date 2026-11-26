/* Menu híbrido do PREPARA UFU: lateral com abas (Estudar · Organizar · Acompanhar · Equipe) + barra de cima.
   Um arquivo só para o site inteiro: os itens apontam para as páginas e, dentro de cada página, acionam as abas que ela já tem. */
(function(){
  var ADMIN='jesrrael.santos@gmail.com';
  var PG=(location.pathname.split('/')[1]||'').toLowerCase();
  var IC={
    sala:'<path d="M12 7v5l3 2"/><circle cx="12" cy="12" r="8"/>',
    cad:'<path d="M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3z"/><path d="M5 17a3 3 0 0 1 3-3h11"/><path d="M10 8l3 3M13 8l-3 3"/>',
    banco:'<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M8 9h8M8 13h8M8 17h5"/>',
    aulas:'<rect x="3" y="5" width="18" height="13" rx="3"/><path d="M10 9l5 2.5-5 2.5z"/>',
    mat:'<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
    agenda:'<rect x="4" y="5" width="16" height="15" rx="3"/><path d="M4 10h16M9 3v4M15 3v4"/>',
    crono:'<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M4 9h16M9 9v11M14 9v11"/>',
    plano:'<path d="M9 6h11M9 12h11M9 18h11"/><path d="M4 6l1 1 2-2M4 12l1 1 2-2M4 18l1 1 2-2"/>',
    perfil:'<circle cx="12" cy="8" r="4"/><path d="M4 20a8 8 0 0 1 16 0"/>',
    duv:'<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.3-1 .9-1 1.7M12 17h.01"/>',
    dash:'<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>',
    ini:'<path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"/>',
    enc:'<path d="M17 20v-2a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v2"/><circle cx="10" cy="7" r="4"/><path d="M21 20v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8"/>',
    turma:'<path d="M3 3v18h18"/><path d="M7 15l4-4 3 3 5-6"/>',
    alunos:'<path d="M16 20v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/>',
    cadastro:'<rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8M8 12h8M8 16h4"/>',
    ver:'<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    den:'<path d="M4 21V4h11l-1 4 6 0-2 6H4"/>',
    ment:'<circle cx="12" cy="8" r="4"/><path d="M6 21v-1a6 6 0 0 1 12 0v1"/><path d="M17 4l2-2M19 6h2"/>',
    lock:'<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>'
  };
  function svg(k){return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'+(IC[k]||'')+'</svg>';}
  function ss(k,v){try{if(v===undefined)return sessionStorage.getItem(k);if(v===null)sessionStorage.removeItem(k);else sessionStorage.setItem(k,v);}catch(e){return null;}}

  async function papel(email){
    var ck='bqufu-menu-'+email,c=null;try{c=JSON.parse(ss(ck)||'null');}catch(e){}
    if(c&&Date.now()-c.t<10*60000)return c.r;
    var r={adm:email===ADMIN,staff:false,asse:false,ment:false,turma:true,rec:[]};
    try{
      var x=await Promise.all([SB.rpc('meu_papel'),SB.rpc('is_assessoria'),SB.rpc('minhas_areas')]);
      r.staff=r.adm||(x[0]&&x[0].data==='assessor');r.asse=!!(x[1]&&x[1].data);
      var a=x[2]&&x[2].data;if(a&&!r.adm){r.ment=!!a.mentoria;r.turma=a.turma!==false;}
      if(!r.asse&&!r.staff&&!r.ment){var y=await SB.rpc('meus_recursos');r.rec=(y&&y.data)||[];}
    }catch(e){}
    ss(ck,JSON.stringify({t:Date.now(),r:r}));return r;}

  function itens(r){
    var ex=r.staff&&!!ss('bqufu-exemplo');            // equipe no modo "Ver como aluno"
    var al=!r.staff||ex;                               // enxerga o menu de aluno
    var mt=al&&r.ment&&!ex,ass=ex||r.asse||r.ment;    // mentorado / tem Assessoria
    var rec=function(k){return ass||r.rec.indexOf(k)>=0;};
    var L=[];function I(g,k,t,href,pg,btn,o){L.push(Object.assign({g:g,k:k,t:t,href:href,pg:pg,btn:btn},o||{}));}
    // Estudar
    I('Estudar','sala','Sala de Estudos','/estudos/#sala','estudos','tabSala');
    if(al)I('Estudar','cad','Caderno de Erros','/estudos/#caderno','estudos','tabCad');
    I('Estudar','banco','Banco de Questões','/bancodequestoes/','bancodequestoes');
    I('Estudar','aulas','Minhas Aulas','/minhasaulas/','minhasaulas');
    if(mt)I('Estudar','mat','Materiais','/mentoria/#materiais','mentoria','tabMat');
    else I('Estudar','mat','Materiais','/aulas/#materiais','aulas','tabMat');
    // Organizar
    if(mt){I('Organizar','ini','Início','/mentoria/#inicio','mentoria','tabInicio');
      I('Organizar','crono','Cronograma Semanal','/mentoria/#cronograma','mentoria','tabCrono');
      I('Organizar','plano','Plano de Estudos','/mentoria/#plano','mentoria','tabPlano');
      I('Organizar','enc','Encontros','/mentoria/#encontros','mentoria','tabEnc');}
    else if(al){if(rec('crono'))I('Organizar','crono','Cronograma Semanal','/assessoria/#cronograma','assessoria','tabCrono');
      if(rec('plano'))I('Organizar','plano','Plano de Estudos','/assessoria/#plano','assessoria','tabPlano');}
    if(al)I('Organizar','agenda','Agenda','/aulas/#agenda','aulas','tabAg');
    if(mt){I('Organizar','perfil','Perfil de estudos','/mentoria/#perfil','mentoria','tabForm');I('Organizar','duv','Dúvidas','/mentoria/#duvidas','mentoria','tabFaq');}
    else if(al&&(ass||r.rec.length)){I('Organizar','perfil','Perfil de estudos','/assessoria/#perfil','assessoria','tabForm');I('Organizar','duv','Dúvidas','/assessoria/#duvidas','assessoria','tabFaq');}
    if(al&&!ass&&!r.rec.length)I('Organizar','lock','Assessoria PREPARA UFU','/assessoria/','assessoria',null,{lock:true});
    // Acompanhar
    if(mt)I('Progresso','dash','Meu Dashboard','/mentoria/#dashboard','mentoria','tabDash');
    else if(al&&rec('dash'))I('Progresso','dash','Meu Dashboard','/estudos/#painel','estudos','tabPainel');
    if(al)I('Progresso','cad','Caderno de Erros','/estudos/#caderno','estudos','tabCad',{dup:true});
    // Equipe
    if(r.staff&&!ex){
      if(!al){I('Estudar','agenda','Agenda','/aulas/#agenda','aulas','tabAg');}
      I('Equipe','turma','Comportamento da turma','/assessoria/#turma','assessoria','tabGeral');
      I('Equipe','alunos','Alunos','/assessoria/#alunos','assessoria','tabResp');
      I('Equipe','dash','Dashboard dos alunos','/estudos/#alunos','estudos','tabAlunos');
      if(!al)I('Equipe','plano','Plano de Estudos da turma','/assessoria/#plano','assessoria','tabPlano');
      if(r.adm)I('Equipe','cadastro','Cadastro','/assessoria/#cadastro','assessoria','tabCad');
      I('Equipe','ver','Ver como aluno','/estudos/#ver','estudos','tabEx',{ver:true});
      if(r.adm)I('Equipe','den','Denúncias','/estudos/#denuncias','estudos','tabDen');
      if(r.adm)I('Equipe','ment','Mentoria individual','/mentoria/','mentoria',null,{fora:true});}
    return {L:L,al:al,ex:ex};}

  var CSS='\
body.mn{padding-left:248px}body.mn>header{margin-left:-248px}\
body.mn>header nav.tabs>a,.mn-esc{display:none!important}\
#mnSide{position:fixed;left:0;top:0;bottom:0;width:248px;z-index:40;background:var(--card,#132238);border-right:1px solid var(--line,#2a3a55);display:flex;flex-direction:column;font-family:var(--body,system-ui)}\
#mnSide .tb{display:grid;gap:3px;margin:12px 12px 8px;padding:3px;border-radius:12px;background:var(--soft,rgba(127,140,160,.15))}\
#mnSide .tb button{border:0;background:none;color:var(--muted,#8a97ad);font:700 12px var(--body,system-ui);padding:8px 2px;overflow:hidden;text-overflow:ellipsis;border-radius:9px;cursor:pointer;white-space:nowrap}\
#mnSide .tb button.on{background:var(--bg,#0b1424);color:var(--ink,#fff);box-shadow:0 1px 4px rgba(0,0,0,.18)}\
#mnSide .ls{flex:1;overflow:auto;padding:4px 10px 12px;display:flex;flex-direction:column;gap:2px}\
#mnSide a.it{display:flex;align-items:center;gap:11px;padding:10px 12px;border-radius:11px;color:var(--ink,#e8eef7);text-decoration:none;font:600 14.5px var(--body,system-ui);border:1px solid transparent}\
#mnSide a.it svg{width:20px;height:20px;flex:none;opacity:.75}\
#mnSide a.it:hover{background:var(--soft,rgba(127,140,160,.12))}\
#mnSide a.it.on{background:rgba(58,140,203,.16);border-color:rgba(58,140,203,.45);color:var(--ink,#fff)}#mnSide a.it.on svg{opacity:1;color:#3A8CCB}\
#mnSide a.it.lock{color:#C9A227}#mnSide a.it.lock svg{opacity:1}\
#mnSide .ex{margin:0 12px 12px;padding:9px 11px;border-radius:11px;background:rgba(242,200,17,.14);border:1px solid rgba(242,200,17,.5);font:600 12.5px var(--body,system-ui);color:var(--ink,#fff)}\
#mnSide .ex button{display:block;width:100%;margin-top:8px;border:0;border-radius:9px;padding:8px;background:#F2C811;color:#16304F;font:800 12.5px var(--body,system-ui);cursor:pointer}\
#mnSide .hd{display:none}\
#mnBtn{display:none;width:40px;height:40px;border-radius:12px;border:1px solid rgba(255,255,255,.25);background:rgba(255,255,255,.08);color:#fff;font-size:20px;cursor:pointer;flex:none}\
#mnVeu{display:none}\
@media (max-width:1000px){body.mn{padding-left:0}body.mn>header{margin-left:0}\
 #mnBtn{display:inline-flex;align-items:center;justify-content:center}\
 #mnSide{top:0!important;transform:translateX(-105%);transition:transform .2s;width:280px;box-shadow:0 0 40px rgba(0,0,0,.45);z-index:90}\
 #mnSide .hd{display:flex;align-items:center;justify-content:space-between;padding:14px 14px 0;font:800 16px var(--display,system-ui);color:var(--ink,#fff)}\
 #mnSide .hd button{border:0;background:none;color:var(--muted,#999);font-size:22px;cursor:pointer}\
 body.mn-aberto #mnSide{transform:none}\
 body.mn-aberto #mnVeu{display:block;position:fixed;inset:0;z-index:89;background:rgba(5,8,18,.55)}}\
@media print{#mnSide,#mnBtn{display:none!important}body.mn{padding-left:0}body.mn>header{margin-left:0}}';

  var R=null,M=null,GRP=null;
  function el(id){return document.getElementById(id);}
  function ativo(it){if(it.pg!==PG)return false;if(it.fora||!it.btn)return true;var b=el(it.btn);return !!(b&&!it.ver&&b.classList.contains('on'));}
  function vaiPara(it,ev){
    if(it.pg===PG&&it.btn&&el(it.btn)){ev&&ev.preventDefault();var b=el(it.btn);
      if(it.ver||!b.classList.contains('on'))b.click();
      try{history.replaceState(null,'',it.href.replace(/^[^#]*/,'')||location.pathname);}catch(e){}
      document.body.classList.remove('mn-aberto');setTimeout(marca,60);return;}
    document.body.classList.remove('mn-aberto');}
  function desenha(){var s=el('mnSide');var gs=[];M.L.forEach(function(x){if(gs.indexOf(x.g)<0)gs.push(x.g);});
    if(!GRP||gs.indexOf(GRP)<0){var a=M.L.filter(function(x){return !x.dup&&ativo(x);})[0];GRP=a?a.g:gs[0];}
    s.innerHTML='<div class="hd"><span>Menu</span><button type="button" aria-label="Fechar menu">✕</button></div>'+
      (M.ex?'<div class="ex">Você está vendo a plataforma como aluno: o menu Equipe some, como para ele.<button type="button" id="mnSaiEx">← Voltar à visão do professor</button></div>':'')+
      (gs.length>1?'<div class="tb" style="grid-template-columns:repeat('+(gs.length>3?2:gs.length)+',minmax(0,1fr))">'+gs.map(function(g){return '<button type="button" data-g="'+g+'"'+(g===GRP?' class="on"':'')+'>'+g+'</button>';}).join('')+'</div>':'<div style="height:10px"></div>')+
      '<nav class="ls" aria-label="Menu da plataforma">'+M.L.filter(function(x){return x.g===GRP;}).map(function(x,i){return '<a class="it'+(x.lock?' lock':'')+'" href="'+x.href+'" data-i="'+M.L.indexOf(x)+'">'+svg(x.lock?'lock':x.k)+'<span>'+x.t+'</span></a>';}).join('')+'</nav>';
    s.querySelectorAll('.tb button').forEach(function(b){b.onclick=function(){GRP=b.dataset.g;desenha();};});
    s.querySelectorAll('a.it').forEach(function(a){a.onclick=function(ev){vaiPara(M.L[+a.dataset.i],ev);};});
    var sx=el('mnSaiEx');if(sx)sx.onclick=function(){ss('bqufu-exemplo',null);ss('bqufu-ver',null);location.href='/estudos/#alunos';};
    var f=s.querySelector('.hd button');if(f)f.onclick=function(){document.body.classList.remove('mn-aberto');};
    marca();}
  function marca(){var s=el('mnSide');if(!s)return;s.querySelectorAll('a.it').forEach(function(a){a.classList.toggle('on',ativo(M.L[+a.dataset.i]));});
    // esconde no topo as abas desta página que já estão na lateral
    M.L.forEach(function(x){if(x.pg===PG&&x.btn){var b=el(x.btn);if(b)b.classList.add('mn-esc');}});
    document.querySelectorAll('nav.subnav').forEach(function(n){var vs=[].some.call(n.querySelectorAll('button,a,span'),function(b){return !b.hidden&&!b.classList.contains('mn-esc')&&b.offsetParent!==null&&b.textContent.trim();});n.style.display=vs?'':'none';});}
  function posiciona(){var s=el('mnSide'),h=document.querySelector('body>header');if(!s||!h||innerWidth<=1000)return;s.style.top=Math.max(0,h.getBoundingClientRect().bottom)+'px';}
  function abreHash(){if(!location.hash)return;var h=location.hash;
    var it=M.L.filter(function(x){return x.pg===PG&&x.btn&&x.href.indexOf(h)>=0&&x.href.slice(x.href.indexOf('#'))===h;})[0];if(!it)return;
    var n=0,t=setInterval(function(){var b=el(it.btn);n++;if(b&&(!b.hidden||it.ver)&&(n>3||!it.ver)){clearInterval(t);if(it.ver){if(!ss('bqufu-exemplo'))b.click();}else if(!b.classList.contains('on'))b.click();setTimeout(marca,60);}else if(n>40)clearInterval(t);},150);}
  async function inicia(){
    if(typeof SB==='undefined'||!SB||!document.querySelector('body>header'))return;
    var r0=await SB.auth.getSession();var se=r0&&r0.data&&r0.data.session;if(!se)return;
    var email=(se.user.email||'').toLowerCase();R=await papel(email);M=itens(R);
    if(!el('mnCss')){var st=document.createElement('style');st.id='mnCss';st.textContent=CSS;document.head.appendChild(st);}
    var s=document.createElement('aside');s.id='mnSide';document.body.appendChild(s);
    var v=document.createElement('div');v.id='mnVeu';v.onclick=function(){document.body.classList.remove('mn-aberto');};document.body.appendChild(v);
    var hd=document.querySelector('body>header');var bt=document.createElement('button');bt.id='mnBtn';bt.type='button';bt.setAttribute('aria-label','Abrir menu');bt.textContent='☰';
    bt.onclick=function(){document.body.classList.add('mn-aberto');};hd.insertBefore(bt,hd.firstChild);
    document.body.classList.add('mn');desenha();posiciona();abreHash();
    addEventListener('scroll',posiciona,{passive:true});addEventListener('resize',posiciona);
    setInterval(function(){marca();posiciona();},700);
    window.menuPlataforma={redesenha:function(){ss('bqufu-menu-'+email,null);papel(email).then(function(r){R=r;M=itens(r);GRP=null;desenha();});}};}
  // o "Ver como aluno" muda o menu: observa o sessionStorage
  var exAnt=ss('bqufu-exemplo');setInterval(function(){var e=ss('bqufu-exemplo');if(e!==exAnt&&R){exAnt=e;M=itens(R);GRP=null;desenha();}},800);
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',function(){setTimeout(inicia,50);});else setTimeout(inicia,50);
})();
