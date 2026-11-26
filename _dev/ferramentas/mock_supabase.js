(function(){
  const DB=window.__DB={plano_itens:[],sessoes:[],plano_feito:[],checkup:[{email:'aluno@x.com',respostas:{lingua:'Inglês'}}]};
  const mats=['Matemática','Física','Química','Biologia','Português','História','Geografia','Filosofia','Sociologia','Inglês','Espanhol'];
  const ws=['2026-11-23','2026-11-30','2026-12-07','2026-12-14'];let id=1;
  ws.forEach(w=>mats.forEach(m=>{for(let k=0;k<2;k++)DB.plano_itens.push({id:id++,semana:w,materia:m,frente:'Frente '+(k+1),assunto:m+' — assunto '+id});}));
  // sessões de exemplo nos últimos dias
  const tipos=['teoria','questoes','revisao','correcao'];let sid=1;const now=Date.now();
  for(let d=20;d>=0;d--){if(d%3===1)continue;const n=1+(d%3);for(let j=0;j<n;j++){const ini=new Date(now-d*864e5);ini.setHours(14+j*2,0,0,0);const seg=1800+((d*7+j*13)%5)*900;const t=tipos[(d+j)%4];const q=t==='questoes'||t==='correcao'?10+(d%6)*2:0;const a=Math.round(q*(0.45+((d+j)%5)*0.1));
    DB.sessoes.push({id:sid++,email:'aluno@x.com',inicio:ini.toISOString(),fim:new Date(ini.getTime()+seg*1000).toISOString(),segundos:seg,tipo:t,materia:mats[(d+j)%9],assunto:'Assunto',plano_item:null,questoes:q,acertos:a,erros:q-a});}}
  function Q(t){this.t=t;this.f=[];this.o=null;this.sg=false;this.op='select';this.payload=null;}
  Q.prototype.select=function(){return this;};
  Q.prototype.eq=function(k,v){this.f.push(r=>r[k]==v);return this;};
  Q.prototype.gte=function(k,v){this.f.push(r=>r[k]>=v);return this;};
  Q.prototype.in=function(k,v){this.f.push(r=>v.includes(r[k]));return this;};
  Q.prototype.order=function(k,o){this.o=[k,!(o&&o.ascending===false)];return this;};
  Q.prototype.maybeSingle=function(){this.sg=true;return this;};
  Q.prototype.insert=function(row){this.op='insert';this.payload=row;return this;};
  Q.prototype.delete=function(){this.op='delete';return this;};
  Q.prototype.upsert=function(row){this.op='insert';this.payload=row;return this;};Q.prototype.update=function(row){this.op='update';this.payload=row;return this;};Q.prototype.limit=function(){return this;};Q.prototype.single=function(){this.sg=true;return this;};
  Q.prototype.then=function(res,rej){const T=DB[this.t]=DB[this.t]||[];let out;
    if(this.op==='insert'){const L=Array.isArray(this.payload)?this.payload:[this.payload];const rs=L.map((x,k)=>Object.assign({id:Date.now()+k,criado:new Date().toISOString()},x));rs.forEach(r=>T.push(r));out={data:rs[0],error:null};}
    else if(this.op==='update'){const p=this.payload;T.filter(r=>this.f.every(f=>f(r))).forEach(r=>Object.assign(r,p));out={data:null,error:null};}
    else if(this.op==='delete'){const keep=T.filter(r=>!this.f.every(f=>f(r)));DB[this.t]=keep;out={data:null,error:null};}
    else{let L=T.filter(r=>this.f.every(f=>f(r)));if(this.o){const [k,asc]=this.o;L=L.slice().sort((a,b)=>(a[k]>b[k]?1:-1)*(asc?1:-1));}out={data:this.sg?(L[0]||null):L,error:null};}
    return Promise.resolve(out).then(res,rej);};
  window.supabase={createClient:()=>({auth:{getSession:async()=>({data:{session:{user:{email:window.__EMAIL||'aluno@x.com'}}}}),signOut:async()=>({})},
    rpc:async(n,args)=>{const D=window.__DB;if(window.__RPC&&n in window.__RPC)return {data:window.__RPC[n]};D.msgs=D.msgs||[{id:1,minha:false,texto:'Oi! Bora estudar junto? 💪',criada:new Date(Date.now()-600000).toISOString()}];
 if(n==='admin_lista')return {data:[{email:'aluno@x.com',nome:'Aluna Teste',assessoria:true}]};
 if(n==='quem_online')return {data:[{uid:'u0',nome:'Aluna T.',estudando:false,eu:true,oculto:false},{uid:'u1',nome:'Emily S.',estudando:true,materia:'Química',tipo:'teoria,questoes',desde:new Date(Date.now()-42*60000).toISOString()},{uid:'u2',nome:'Pedro H.',estudando:true,materia:'Matemática',tipo:'questoes',desde:new Date(Date.now()-95*60000).toISOString()},{uid:'u3',nome:'Ana L.',estudando:false},{uid:'u4',nome:'Prof. Jazz',estudando:false}]};
 if(n==='nao_lidas')return {data:1};if(n==='meu_estado')return {data:[{uid:'u0',oculto:false}]};
 if(n==='minhas_conversas')return {data:[{uid:'u1',nome:'Emily S.',ultima:'Oi! Bora estudar junto? 💪',quando:new Date(Date.now()-600000).toISOString(),nao_lidas:1,online:true,estudando:true}]};
 if(n==='conversa')return {data:D.msgs.slice().reverse()};
 if(n==='enviar_msg'){D.msgs.push({id:D.msgs.length+1,minha:true,texto:args.p_texto,criada:new Date().toISOString()});return {data:null};}
 if(n==='minhas_areas'){const P=window.__PAPEL||'aluno';return {data:{papel:P,turma:P!=='mentorado',mentoria:P==='admin'||P==='mentorado'}};}
 if(n==='m_lista'){return {data:[{email:'ana@x.com',nome:'Ana Clara Souza',cadastrado:true,checkup_em:'2026-11-20',itens:(D.m_plano||[]).filter(x=>x.email==='ana@x.com').length,feitos:0,proximo:'2026-11-26'},{email:'exemplo.mentoria@preparaufu.com.br',nome:'Aluno Exemplo da Mentoria',cadastrado:false,itens:0,feitos:0}]};}
 if(n==='m_copiar_plano'){D.m_plano=(D.m_plano||[]).filter(x=>x.email!==args.p_email);let i=5000;D.plano_itens.forEach(x=>D.m_plano.push(Object.assign({},x,{id:i++,email:args.p_email})));return {data:D.plano_itens.length};}
 if(n==='meu_papel')return {data:window.__PAPEL||'aluno'};if(n==='admin_assessores')return {data:[{email:'maria@x.com',nome:'Maria Souza',cadastrado:false}]};if(n==='is_assessoria'||n==='is_allowed')return {data:true};
 if(n==='bloqueio')return {data:false};if(n==='admin_denuncias')return {data:[{id:1,de:'a@x',de_nome:'Ana L.',contra:'b@x',contra_nome:'Pedro H.',motivo:'Mensagens chatas',conversa:[{autor:'Pedro H.',texto:'oi',criada:new Date().toISOString()},{autor:'Ana L.',texto:'para por favor',criada:new Date().toISOString()}],criada:new Date().toISOString(),resolvida:false}]};
 return {data:true};},
    storage:{from:()=>({getPublicUrl:p=>({data:{publicUrl:'/img/'+p}}),upload:async()=>({data:{},error:null}),remove:async()=>({data:null,error:null}),createSignedUrl:async p=>({data:{signedUrl:'/img/'+p}})})},
    from:t=>new Q(t)})};
})();
