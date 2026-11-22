import re,sys
src=open(sys.argv[1]).read()
tok=re.findall(r'"((?:[^"\\]|\\.)*)"|([{}])', src); pos=0
def parse():
    global pos; items=[]
    while pos<len(tok):
        s,b=tok[pos]
        if b=='}': pos+=1; return items
        pos+=1; ns,nb=tok[pos]
        if nb=='{': pos+=1; items.append((s,parse()))
        else: pos+=1; items.append((s,ns))
    return items
cm=parse()[0][1]
assert src.count('{')==src.count('}') and src.count('"')%2==0
groups={dict(g[1])['id']:dict(g[1]) for g in cm if g[0]=='group'}
presets=[dict(p[1]) for p in cm if p[0]=='preset']
ok=True
for p in presets:
    for gid,srcb in p['group_source_bindings']:
        if gid not in groups: print("MISSING GROUP",gid); ok=False
allb=[]
def walk(x):
    for k,v in x:
        if k=='binding': allb.append(v)
        elif isinstance(v,list): walk(v)
walk(cm)
for b in allb:
    f=[q.strip() for q in b.split(",")]
    if len(f)!=4: print("BAD FIELD COUNT",b); ok=False
    c=f[0].split()
    if c[0]=="mode_shift" and c[2] not in groups: print("BAD MODESHIFT",b); ok=False
    if c[0]=="controller_action" and c[1]=="hold_layer" and not (1<=int(c[2])<=len(presets)): ok=False
    if c[0]=="controller_action" and c[1]=="change_preset" and int(c[2]) not in (1,2): ok=False
icons=sorted(set(q.split(",")[2].strip() for q in allb if ".png" in q))
keysent=sorted(set(tuple(x) for x in []))
print("groups",len(groups),"presets",[p['name'] for p in presets],"bindings",len(allb),"icons",len(icons),"OK" if ok else "PROBLEMS")
print(" ".join(icons))
# key combos sent by each multi-key binding block
for m in re.finditer(r'"bindings"\s*\{([^{}]*)\}', src):
    ks=re.findall(r'key_press (\w+), ([^,]*),', m.group(1))
    if ks: print("  ", "+".join(k for k,_ in ks).replace("LEFT_","").ljust(22), ks[0][1])
