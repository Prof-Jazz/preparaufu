# Atualiza o número de versão em todas as páginas e em /versao.txt (rodar antes de cada commit)
import re,time,sys
raiz=sys.argv[1]
v=str(int(time.time()))
for p in ['index.html','assessoria/index.html','bancodequestoes/index.html','aulas/index.html','estudos/index.html','mentoria/index.html','minhasaulas/index.html']:
    s=open(f'{raiz}/{p}').read()
    s2=re.sub(r"var V='\d+'","var V='%s'"%v,s,count=1)
    s2=re.sub(r'(presenca|menu|estatisticas)\.js(\?v=\d+)?"',lambda m:'%s.js?v=%s"'%(m.group(1),v),s2)
    open(f'{raiz}/{p}','w').write(s2)
open(f'{raiz}/versao.txt','w').write(v+"\n")
open(f'{raiz}/assessoria/versao.txt','w').write(v+"\n")
print(v)
