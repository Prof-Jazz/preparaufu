/* Respostas do Banco de Questões viram "sessões de estudo" para as estatísticas (dashboard, comportamento da turma, rankings).
   Respostas seguidas da mesma matéria, com até 15 minutos entre uma e outra, formam uma sessão.
   Tempo da sessão = da primeira à última resposta + 3 minutos (a última questão). */
(function(){
  var GAP=15*60000,POR_Q=180;
  window.bancoSessoes=function(R){
    var L=(R||[]).slice().sort(function(a,b){return a.email<b.email?-1:a.email>b.email?1:(a.criado<b.criado?-1:a.criado>b.criado?1:0);});
    var out=[],cur=null;
    L.forEach(function(r){var t=new Date(r.criado).getTime(),m=r.materia||'Outras';
      if(cur&&cur.email===r.email&&cur.materia===m&&t-cur._fim<=GAP){cur._fim=t;cur.questoes++;if(r.correta)cur.acertos++;else cur.erros++;cur._tops[r.topico||'']=1;}
      else{cur={id:'banco-'+r.email+'-'+t,email:r.email,_ini:t,_fim:t,materia:m,tipo:'questoes',questoes:1,acertos:r.correta?1:0,erros:r.correta?0:1,plano_item:null,banco:true,detalhe:{banco:true},_tops:{}};cur._tops[r.topico||'']=1;out.push(cur);}});
    out.forEach(function(s){s.segundos=Math.round((s._fim-s._ini)/1000)+POR_Q;s.inicio=new Date(s._ini).toISOString();s.fim=new Date(s._fim+POR_Q*1000).toISOString();
      var tp=Object.keys(s._tops).filter(Boolean);s.assunto='Banco de Questões'+(tp.length?' · '+tp.slice(0,2).join(', ')+(tp.length>2?' e mais '+(tp.length-2):''):'');delete s._ini;delete s._fim;delete s._tops;});
    return out;};
})();
