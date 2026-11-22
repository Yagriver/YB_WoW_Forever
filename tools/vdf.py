import re,sys
tok=re.findall(r'"((?:[^"\\]|\\.)*)"|([{}])', open(sys.argv[1]).read())
pos=0
def parse():
    global pos; items=[]
    while pos<len(tok):
        s,b=tok[pos]
        if b=='}': pos+=1; return items
        pos+=1
        ns,nb=tok[pos]
        if nb=='{': pos+=1; items.append((s,parse()))
        else: pos+=1; items.append((s,ns))
    return items
root=parse()
cm=root[0][1]
groups={dict(g[1])['id']:g[1] for g in cm if g[0]=='group'}
def binds(gid):
    out=[]
    for k,v in groups[gid]:
        if k=='inputs':
            for name,inp in v:
                for a,acts in inp:
                    for act,body in acts:
                        bl=[x[1] for bb in body if bb[0]=='bindings' for x in bb[1]]
                        out.append((name,act,bl))
    return out
for gid,title in [('1','combat back buttons'),('17','city buttons'),('12','R5 emergencies'),('14','R5 menus')]:
    print('==',title)
    for n,a,bl in binds(gid):
        if 'back' in n or gid in('12','14') or n=='button_menu': print(f'  {n:24}{a:11}', ' | '.join(bl))
presets=[dict(p[1]) for p in cm if p[0]=='preset']
for p in cm:
    if p[0]=='preset':
        d=dict(p[1]); print('preset',d['id'],d['name'],[x for x in dict(p[1])['group_source_bindings']])
print('groups referenced exist:',all(gid in groups for p in cm if p[0]=='preset' for gid,_ in dict(p[1])['group_source_bindings']))
