#!/usr/bin/env python3
"""Читает снимки партии Civilization V, которые пишет Advisor.lua.
  python3 advisor.py            краткая сводка последнего снимка
  python3 advisor.py --json     полный JSON последнего снимка
  python3 advisor.py --list     какие снимки есть
  python3 advisor.py --turn 57  снимок конкретного хода (начало хода)
"""
import json, os, sqlite3, sys

DB = os.path.expanduser("~/Library/Application Support/Sid Meier's Civilization 5/ModUserData/Civ5Advisor-1.db")

def load(key="latest"):
    con = sqlite3.connect(DB)
    row = con.execute("select Value from SimpleValues where Name=?", (key,)).fetchone()
    return json.loads(row[0]) if row else None

def keys():
    con = sqlite3.connect(DB)
    return [r[0] for r in con.execute("select Name from SimpleValues where Name like 't%' order by Name")]

def summary(s):
    e = s["empire"]; h = e["happiness"]
    out = [f"Ход {s['turn']} ({s['phase']}), {s['civ']} — {s['leader']}, {s['era']}, счёт {s['score']}, {s['handicap']}, {s['speed']}"
           + (", сетевая" if s.get("multiplayer") else "") + ("" if s.get("honest") else ", РЕЖИМ БЕЗ ФИЛЬТРА")]
    r = e.get("research") or {}
    out.append(f"Золото {e['gold']} ({e['goldRate']:+}/ход) · наука {e['science']} · {r.get('name','—')} через {r.get('turns','—')} · "
               f"культура {e['culturePerTurn']}/ход, до института {e['nextPolicyCost']-e['culture']} · вера {e['faith']} (+{e['faithPerTurn']})")
    out.append(f"Счастье {h['excess']:+} (есть {h['happy']}, несчастья {h['unhappy']}: города {h['fromCities']}, население {h['fromPopulation']}, "
               f"оккупация {h['fromOccupied']}) · ЗВ {e['goldenAge']['meter']}/{e['goldenAge']['threshold']}"
               + (f", идёт ещё {e['goldenAge']['turnsLeft']}" if e['goldenAge']['turnsLeft'] else ""))
    out.append(f"Технологий {e['techsKnown']}, институтов {e['numPolicies']}" + (f", идеология {e['ideology']}" if e.get("ideology") else "")
               + (f", религия {e['religion']}" if e.get("religion") else (", пантеон" if e.get("pantheon") else "")))
    tr = e["tradeRoutes"]
    out.append(f"Торговых путей {tr['used']}/{tr['available']}: " + "; ".join(f"{x['from']}→{x['to']} ({x['goldForMe']}з, {x['turnsLeft']}х)" for x in tr["routes"]) )
    out.append(f"\nГорода ({len(s['cities'])}):")
    for c in s["cities"]:
        flags = "".join(k for k, v in (("★", c["capital"]), ("марионетка ", c["puppet"]), ("оккупирован ", c["occupied"])) if v)
        out.append(f"  {c['name']} {flags}нас.{c['pop']} рост {c['growthTurns']}х (+{c['foodSurplus']}) · пр-во {c['production']} · зол {c['gold']} · "
                   f"наука {c['science']} · культ {c['culture']} · вера {c['faith']} · строит {c.get('building','—')} ({c.get('buildingTurns','—')}х)"
                   + (f" · урон {c['damage']}" if c["damage"] else "") + f" · содержание {sum(b['maintenance'] for b in c['paidBuildings'])}з")
    units = s["units"]
    idle = [u for u in units if u["combat"] and not u["automated"] and u["moves"] >= u["maxMoves"] and u["activity"] not in ("SLEEP", "SENTRY", "HEAL") and u["fortifyTurns"] == 0]
    mil = [u for u in units if u["combat"]]
    out.append(f"\nЮнитов {len(units)}, военных {len(mil)}, не задействованы в этот ход: {len(idle)}")
    for u in idle[:12]: out.append(f"  {u['type']} ({u['x']},{u['y']}) hp{u['hp']} xp{u['xp']}")
    out.append("\nДержавы:")
    for m in s["majors"]:
        st = []
        if m["atWarWithMe"]: st.append("ВОЙНА")
        if m["friendshipWithMe"]: st.append("дружба")
        if m["theyDenouncedMe"]: st.append("осудил нас")
        if m["iDenouncedThem"]: st.append("мы осудили")
        out.append(f"  {m['leader']} ({m['civ']}){' чел.' if m['human'] else ''} счёт {m['score']}, {m['era']}, городов {m['cities']}"
                   + (f", настрой {m.get('approach')}" if m.get("approach") else "") + (" · " + ", ".join(st) if st else ""))
        if m.get("disputes"):
            d = m["disputes"]; out.append(f"      споры: земля {d['land']}, победа {d['victory']}, чудеса {d['wonders']}, ГГ {d['cityStates']}")
        for o in (m.get("opinion") or [])[:8]: out.append(f"      · {o}")
        for r in m.get("relations", []): out.append(f"      {'воюет с' if r['war'] else 'дружит с'} #{r['with']}")
    out.append("\nГорода-государства:")
    for cs in sorted(s["cityStates"], key=lambda x: -x["influence"]):
        out.append(f"  {cs['name']} [{cs['trait']}, {cs['personality']}] влияние {cs['influence']} {cs.get('status','')}"
                   + (f", союзник: {cs['allyName']}" if cs.get("allyName") else "") + (f" · квест: {cs['quest']}" if cs.get("quest") else ""))
    f = s.get("foreign") or {}
    out.append(f"\nВидимые чужие города: {len(f.get('cities', []))}, юниты в поле зрения: {len(f.get('units', []))}")
    if s.get("notifications"):
        out.append("\nУведомления хода:")
        for n in s["notifications"][-15:]: out.append(f"  [{n['type']}] {n['summary']}")
    if s.get("errors"):
        out.append("\nОШИБКИ ВЫГРУЗКИ:"); out += [f"  {x}" for x in s["errors"]]
    return "\n".join(out)

if __name__ == "__main__":
    if not os.path.exists(DB): sys.exit(f"нет базы {DB}: игра ещё не делала снимков")
    a = sys.argv[1:]
    if a[:1] == ["--list"]: print("\n".join(keys())); sys.exit()
    key = "latest"
    if a[:1] == ["--turn"] and len(a) > 1: key = f"t{int(a[1]):04d}_start"
    s = load(key)
    if s is None: sys.exit(f"снимка {key} нет; есть: {', '.join(keys()[-5:])}")
    print(json.dumps(s, ensure_ascii=False, indent=1) if "--json" in a else summary(s))
