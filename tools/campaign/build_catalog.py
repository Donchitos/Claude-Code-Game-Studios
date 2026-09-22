#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Offline, deterministic planning-to-playable compiler. Runtime never opens CSV.
Run normally to write; --check verifies the checked-in artifact without mutation.
Planning descriptions remain provenance, not claims of implemented mechanics.
"""
import argparse
import csv
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'assets/config/campaign_game.json'
MODES = 'sword fan orbit fireball flame meteor disc boomerang shield turret drone stomp chain lightning return_arc roots thorns spores ice_arrow frost winter ink seal void'.split()
STATS = 'damage cooldown_reduction area duration move_speed projectile_speed armor pickup_radius max_hp summon_damage summon_range summon_duration chain_count critical_chance return_damage slow_strength explosion_radius control_damage charge_speed reflect_count trail_width mark_capacity mark_heal mark_spread'.split()
AMOUNTS = [.12, .06, .12, .15, .06, .12, 2, 25, 15, .15, 50, .2, 1, .05, .18, .08, .15, .18, .15, 1, .15, 1, 1, 1]
BEHAVIORS = 'chase spitter flanker trail strafe charger crab jet burrow reflector fan_shooter bouncer slider buffer spike_line exploder rooter decoy diver anchor barrier shield channeler absorber'.split()
COLORS = ['#85d6ac','#f69b68','#72cbe8','#e8c779','#c9dbff','#b6d37a','#9ee5f5','#c2a5f0']
REGIONS = ['Gale Ravine','Ember Kilns','Sunken Tide','Bronze Hills','Snow Ridge','Ink Marsh','Hanging Terraces','Silent Court']
SKILL_NAMES = ['Patrol Sword','Star Fan','Stone Orbit','Ember Orb','Ash Fan','Coal Meteor','Tidal Disc','Echo Boomerang','Wave Guard','Clockwork Turret','Wandering Drones','Earth Stomper','Thunder Chain','Lightning Needle','Returning Arc','Binding Roots','Spore Thorns','Vine Spores','Frost Arrow','Ice Mirror','Snow Banner','Returning Ink','Erosion Seal','Void Needle']
# damage, cooldown, range, speed, radius, count, duration: materially different delivery profiles.
SKILL_NUMBERS = [(24,.65,650,620,9,1,1.3),(11,1.1,430,480,8,3,1.1),(10,.8,125,170,21,3,3),(27,1.7,560,390,65,1,2),(10,.6,215,0,95,1,1.8),(45,3.2,620,0,95,2,.8),(14,1.3,360,430,26,2,1.5),(19,1.8,540,400,17,2,2.4),(12,.9,135,0,110,1,1.8),(13,2.5,580,580,18,1,7),(9,1.9,650,340,14,3,6),(35,2.8,165,0,140,1,1),(14,1.25,420,0,38,4,.3),(38,2.6,620,0,78,2,.7),(18,1.6,480,490,16,2,2),(7,1.6,380,0,115,2,3.2),(22,1.3,260,460,30,3,1),(13,2.4,510,220,110,3,3),(32,1.5,760,740,11,1,1.4),(15,1.8,190,310,100,5,2),(9,.9,190,0,90,1,3.5),(16,1.1,510,480,14,3,1.5),(12,1.9,430,0,105,2,3),(34,2.1,720,690,12,2,1.8)]
MECHANICS = [
 ('直线飞剑穿过敌群。','Straight swords pierce aligned enemies.'),('向目标方向扇形散射多枚穿透短刃。','A fan of piercing blades covers the firing arc.'),('环绕自身的重印持续打击近敌。','Orbiting stones strike nearby enemies.'),('火珠命中后范围爆炸。','Fireballs explode on impact.'),('前方烈焰地带持续伤害敌人。','A flame strip ahead deals sustained damage.'),('预告落点后陨火范围重击。','Telegraphed meteors hit an area.'),('旋盘穿行攻击附近敌群。','Spinning discs cut through nearby groups.'),('声刃飞出后追随玩家折返，去回程均可命中。','Echo blades return toward the player and can hit on both paths.'),('护环跟随玩家打击近敌，并反射有限数量的敌弹。','A following guard ring strikes nearby enemies and reflects a limited number of hostile shots.'),('部署驻留弩台自动射击。','Deployed turrets fire at targets in range.'),('蜂群环绕玩家，自动瞄准范围内敌人射击。','Drones orbit the player and fire at enemies in range.'),('震地冲击击退近身敌群。','A ground shock knocks back nearby enemies.'),('雷电在多个敌人之间跳跃。','Lightning jumps between several enemies.'),('预告后对标记位置落雷。','Lightning strikes marked positions after a warning.'),('电轮去程与回程攻击。','Electric arcs strike on outgoing and returning paths.'),('延迟生成根区，持续伤害并束缚区域内敌人。','Delayed root fields deal sustained damage and bind enemies inside.'),('定向藤刺击中扇面敌人。','Directional thorns strike a forward fan.'),('延迟生成多片孢区，持续伤害并减速敌人。','Delayed spore fields deal sustained damage and slow enemies.'),('远距穿透冰箭攻击直线。','Long-range frost arrows pierce a line.'),('向四周放射寒冷碎片。','Frost shards radiate around the caster.'),('周期在脚下留下伤害与减速雪区，移动可铺开地带。','Periodically leaves damaging, slowing snow at your feet; move to spread the fields.'),('墨符飞射施加伤害印记。','Ink projectiles apply damaging marks.'),('固定蚀区周期攻击范围内目标。','Stationary seals pulse against enemies inside.'),('高速空相针贯穿远处敌人。','Fast void needles pierce distant enemies.')]
MISSION_EN = [
'First Steps in the Wind','Pull the Root Nails','Escort the Herbalist','Track the Broken-Bough Beast','Cleanse the Wind Well','Hold the Way Home','Break the Well Locks','Ancient Gale Beast',
'Cross the Ash Wings','Close Three Vents','Escort the Cooling Casket','Hunt the Furnace Carrier','Wash Away Furnace Ash','Evacuate the Workers','Cut the Fuel Pipes','Furnace Heart Golem',
'Hold the Rising Shore','Recover the Fleet Ledger','Escort the Ferry','Cleanse the Old Harbor','Break the Sluice Seals','Cross the Fin Swarm','Hunt the Deep Court Warden','Twin Fins of the Tide',
'Close the Mirror Nodes','Escort the Repair Automaton','Intercept the Inspector','Cleanse Mirror Dust','Hold the Core Platform','Break the Access Locks','Recover the Core Key','Master of a Thousand Mirrors',
'Light the Snow Beacons','Escort the Warming Cart','Hunt the Lost Watch Captain','Hold the Ice Entrance','Break the Frost Chains','Restore the Beacon Array','Escort the Messenger','Night Frost Vulture',
'Cleanse the Marsh Entrance','Hunt a Corrupted Sample','Escort the Sampling Lamp','Pull the Spore Roots','Hold the Broken Stele','Cleanse Three Steles','Hunt the Spore Crown','Mother of the Marsh',
'Hold the Wind Bridge','Escort the Anchor Breaker','Hunt the Rope Cutter','Cleanse the Bridge Anchors','Break the Outer Chains','Escort the Ley Vessel','Disable the Reinforcement Lifts','Hanging Anchor Titan',
'Cleanse the Court Seals','Break the Corridor Locks','Escort the Ley Casket','Hunt the Silent Core','Hold the Core Entrance','Close the Transfer Nodes','Faceless Court Keeper','The Ley Nexus']
PASSIVE_ZH = ['伤害比例','冷却缩减比例','攻击范围比例','效果持续时间比例','移动速度比例','投射物速度比例','护甲','拾取半径','生命上限','召唤伤害比例','召唤索敌范围','召唤持续时间比例','连锁数量','暴击概率','回程伤害比例','减速强度','爆炸半径比例','控制伤害比例','蓄力速度比例','反射数量','地带宽度比例','印记容量','印记恢复','印记扩散数量']

def build():
    rows = list(csv.DictReader((ROOT/'production/steam-1.0-content-matrix.csv').open(encoding='utf-8-sig')))
    assert len(rows) == 364
    by_id = {r['content_id']: r for r in rows}
    mission_rows = sorted((r for r in rows if r['content_type']=='mission'), key=lambda r:r['content_id'])
    ordinals = {r['content_id']:i+1 for i,r in enumerate(mission_rows)}
    type_map = {'chapter':'chapters','mission':'missions','character':'characters','active':'skills','passive':'passives','evolution':'evolutions','normal_enemy':'enemies','elite':'elites','boss':'bosses','prep_effect':'pills','risk_event':'events','challenge':'challenges','achievement':'achievements','region':'regions','scene':'scenes','objective':'objectives','progression_node':'progression_nodes','screen':'screens','difficulty':'difficulties'}
    data = {'schema':1,'profile':'CAMPAIGN_GAMEPLAY_V1','title':'灵枢行纪','title_en':'Spirit Nexus'}
    for collection in type_map.values(): data[collection]=[]
    for r in rows:
        unlock = 0 if r['first_available_after']=='START' else ordinals[r['first_available_after']]
        item = {'id':r['content_id'],'name':r['name'],'name_en':r['content_id'],'description':r['description'],'description_en':'','unlock_after':unlock,'planning_description':r['description']}
        data[type_map[r['content_type']]].append(item)
    for i,c in enumerate(data['chapters']):
        c.update(name_en=f'Chapter {i+1}: {REGIONS[i]}',chapter=i+1,theme=i,scene_ids=[f'S1-S{i+1:02}-01',f'S1-S{i+1:02}-02'],mission_ids=[m['content_id'] for m in mission_rows[i*8:i*8+8]],description_en=['Find the missing travelers and restore the first ley hub.','Stop the furnaces and trace their shipments.','Recover the fleet ledger and reopen the waterways.','Take back access to the life-draining machinery.','Light the beacons to unite the regions.','Find the remedy for corrupted ley energy.','Sever the outer anchors feeding the nexus.','Enter the nexus and end the extraction.'][i])
    for i,s in enumerate(data['skills']):
        damage,cd,reach,speed,radius,count,duration=SKILL_NUMBERS[i]
        s.update(name_en=SKILL_NAMES[i],mode=MODES[i],damage=damage,cooldown=cd,range=reach,speed=speed,radius=radius,count=count,duration=duration,color=COLORS[i//3],description=MECHANICS[i][0],description_en=MECHANICS[i][1],max_level=5)
    for i,p in enumerate(data['passives']):
        p.update(name_en=STATS[i].replace('_',' ').title()+' Manual',stat=STATS[i],amount=AMOUNTS[i],max_level=5,description=f'每级增加{PASSIVE_ZH[i]} {AMOUNTS[i]:g}。',description_en=f'Each rank adds {AMOUNTS[i]:g} to {STATS[i].replace("_"," ")}.')
    for i,e in enumerate(data['evolutions']):
        skill_id, passive_id = by_id[e['id']]['dependencies'].split(';')
        skill=next(s for s in data['skills'] if s['id']==skill_id)
        multiplier=round(1.65+(i%4)*.15,2)
        e.update(name_en=skill['name_en']+' Ascension',skill_id=skill_id,passive_id=passive_id,effect_multiplier=multiplier,mode=skill['mode'],required_skill_level=5,required_passive_level=5,description=f'{skill["name"]}与辅助均达5级：该技能伤害与射程提升至{multiplier:g}倍，并增加发射数量（最多16）。',description_en=f'With both ingredients at rank 5, multiply {skill["name_en"]} damage and range by {multiplier:g}, and increase its attack count (up to 16).')
    char_names=['Wandering Swordsman','Ember Weaver','Ring Guardian','Artificer','Thunder Caller','Root Binder','Frost Archer','Ink Scribe']
    for i,c in enumerate(data['characters']):
        stat=['projectile_speed','duration','armor','summon_damage','chain_count','slow_strength','charge_speed','mark_capacity'][i]
        amount=[.15,.2,3,.2,1,.12,.2,2][i]
        hp=[1,.85,1.3,.95,.9,1.1,.8,1][i]; speed=[1.05,1,.9,.95,1.08,.95,1.15,1][i]; damage=[1,1.2,.95,1,1.1,.95,1.15,1][i]
        c.update(name_en=char_names[i],start_skill=f'S1-A{i*3+1:02}',hp_multiplier=hp,speed_multiplier=speed,damage_multiplier=damage,passive_stat=stat,passive_amount=amount,color=COLORS[i],description=f'起手：{data["skills"][i*3]["name"]}；生命×{hp}，移速×{speed}，伤害×{damage}；{stat}+{amount}。',description_en=f'Starts with {SKILL_NAMES[i*3]}. HP x{hp}, speed x{speed}, damage x{damage}; {stat} +{amount}.')
    enemy_names=['Gale Fang','Bristle Bug','Branch Lizard','Furnace Snail','Ash Bat','Molten Pupa','Tide Crab','Water Spirit','Burrowing Fin','Mirror Puppet','Rivet Gunner','Axle Ball','Snow Lion','Frost Moth','Ice Worm','Spore Beast','Mud Hand','Mist Decoy','Wind Falcon','Anchor Puppet','Bridge Spirit','Hollow Guard','Silent Caster','Flow Eater']
    for i,e in enumerate(data['enemies']):
        e.update(name_en=enemy_names[i],behavior=BEHAVIORS[i],hp=round(26+(i//3)*5+(i%3)*8,1),speed=75+(i%3)*22,radius=13+(i%3)*3,damage=2+i//3,color=COLORS[i//3],projectile_speed=180+(i%4)*25,attack_cooldown=2.0+(i%3)*.4,description_en=f'{enemy_names[i]} uses {BEHAVIORS[i].replace("_"," ")} behavior. Watch its attack windup and move away from the danger.')
    for i,e in enumerate(data['elites']):
        source=data['enemies'][i*3+2]
        for key in ['behavior','speed','radius','damage','color','projectile_speed','attack_cooldown']:e[key]=source[key]
        e.update(name_en=REGIONS[i]+' Warden',hp=220+i*45,radius=25,damage=11+i,enemy_id=source['id'],description='强化追猎卫，使用本章第三类敌人的行为，体型更大且伤害更高。',description_en='A larger hunt warden with the third enemy behavior of this region, more health and higher damage.')
    patterns=['pounce','eruption','cross_tide','mirror','dive','spore_tide','anchors','seals','nexus']
    for i,b in enumerate(data['bosses']):
        b.update(name_en=MISSION_EN[(i+1)*8-1] if i<7 else ['Faceless Court Keeper','The Ley Nexus'][i-7],pattern=patterns[i],phase_patterns=[patterns[i],patterns[(i+3)%9],patterns[(i+6)%9]],hp=650+i*160,speed=65+i*3,radius=40+i,damage=6+i,color=COLORS[min(i,7)],attack_cooldown=3.4-i*.12,projectile_speed=190+i*8,description_en=f'Three combat phases: {patterns[i]}, {patterns[(i+3)%9]}, then {patterns[(i+6)%9]}. Read the warnings before each attack.')
    for i,m in enumerate(data['missions']):
        r=by_id[m['id']]; deps=r['dependencies'].split(';'); chapter=i//8+1; local=i%8
        kind=next(d.removeprefix('S1-O-') for d in deps if d.startswith('S1-O-'))
        count={'BREAK':3,'CLEANSE':2+(chapter>=5),'ESCORT':4+(local>3),'SURVIVE':1,'HUNT':1,'BOSS':1}[kind]
        # Alternating routes, mirror transforms and radius changes create distinct spatial problems.
        points=[]
        for j in range(count):
            angle=(j/count)*math.tau+(chapter-1)*.39+local*.19
            points.append([round(math.cos(angle)*(420+local*23)),round(math.sin(angle)*(260+chapter*12))])
        if kind=='ESCORT':
            points=[[-600+round(1200*j/(count-1)),round(math.sin(j*1.8+chapter)*240)] for j in range(count)]
        boss_id=next((d for d in deps if d.startswith('S1-B')),'')
        target_ids=[f'{m["id"]}:T{j+1}' for j in range(count)]
        if kind=='HUNT':target_ids=[m['id']+':HUNT']
        if kind=='BOSS':target_ids=[boss_id]
        seconds=float(65+chapter*7+local*4) if kind=='SURVIVE' else float(6+chapter*.6)
        enemy_ids=[f'S1-N{(chapter-1)*3+j+1:02}' for j in range(3)]
        if local>=4 and chapter>1:enemy_ids.append(f'S1-N{(chapter-2)*3+(local%3)+1:02}')
        if i==60:enemy_ids=['S1-N01','S1-N05','S1-N08','S1-N11','S1-N13','S1-N17','S1-N19','S1-N23']
        m.update(name_en=MISSION_EN[i],chapter=chapter,ordinal=i+1,kind=kind,scene_id=deps[0],prerequisite_id='START' if i==0 else mission_rows[i-1]['content_id'],briefing=m['planning_description'],briefing_en=f'{REGIONS[chapter-1]}: {MISSION_EN[i]}. '+{'SURVIVE':f'Survive {seconds:g}s, then enter the marked extraction circle.','BREAK':f'Destroy {count} marked anchors; inactive anchors cannot be damaged.','CLEANSE':f'Clear {count} circles, stay inside each for {seconds:g}s with no enemies nearby.','ESCORT':f'Stay near the escort through {count} waypoints; protect its health.','HUNT':'Defeat the marked hunt target, not its ordinary escorts.','BOSS':'Defeat this mission’s designated boss through all phases.'}[kind],success_text=f'{m["name"]}完成。'+('地脉恢复，八域重获生机。' if i==63 else '新的道路已经开放。'),success_text_en=f'{MISSION_EN[i]} complete. '+('The extraction has ended. Life returns to all eight realms.' if i==63 else 'The next route is open.'),timeout_seconds=float(360+chapter*20+local*5),target_seconds=seconds,target_count=count,order_mode='PLAYER_CHOICE' if m['id'] in ['S1-M02-07','S1-M07-07','S1-M08-02'] else 'FIXED',target_hp=float(85+chapter*14+local*5),target_positions=points,target_ids=target_ids,enemy_ids=enemy_ids,boss_id=boss_id,reward=35+chapter*10+local*3,first_grants=[],theme=chapter-1,target_radius=90.0,cleanse_enemy_radius=130.0,hold_seconds=seconds,escort_radius=180.0,escort_speed=85.0,escort_hp=450.0+chapter*40,order_pressure_max=.3,enemy_scaling=round(1+i*.008,3),spawn_interval=round(.95-local*.035,3),description_en=f'{kind.title()} objective in {REGIONS[chapter-1]}; {count} marked target(s).')
        if m['order_mode']=='PLAYER_CHOICE':m['briefing_en']=m['briefing_en'].replace('inactive anchors cannot be damaged.','choose the destruction order to change incoming pressure.')
        # Runtime-facing objective hint describes the actual simplified mechanic.
        m['briefing'] += {'SURVIVE':f' 存活{seconds:g}秒后进入撤离圈。','BREAK':f' 击破{count}个锚点；'+('可自选顺序。' if m['order_mode']=='PLAYER_CHOICE' else '依编号击破，未激活目标免伤。'),'CLEANSE':f' 在{count}个净化圈内分别保持{seconds:g}秒，附近有敌暂停累计。','ESCORT':f' 靠近护送物穿过{count}个路标并保护生命。','HUNT':' 击杀标记追猎目标。','BOSS':' 击杀本任务指定首领。'}[kind]
    for i,p in enumerate(data['pills']):
        stat=['max_hp','pickup_radius','armor','damage','move_speed','summon_damage','regeneration','armor','area','slow_strength','move_speed','rerolls'][i]
        amount=[25,70,5,.2,.08,.25,1.2,7,.15,.15,.15,1][i]
        p.update(name_en=['Breath Powder','Spirit Dew','Vein Guard','Ember Drink','Clear Tide Dew','Stable Machine Powder','Light Renewal','Bone Warmer','Spore Cleanser','Root Dew','Wind Powder','Seal Pill'][i],effect=stat,stat=stat,amount=amount,cost=20+i*4,duration=90.0,description=f'本局前90秒：{stat} +{amount}。' if stat!='rerolls' else '本局增加1次构筑刷新。',description_en=f'For the first 90 seconds: {stat} +{amount}.' if stat!='rerolls' else 'One additional draft reroll this run.')
    for i,e in enumerate(data['events']):
        safe={'reward':8+i%3*3,'damage':0,'pressure':0.0};risk={'reward':25+i*2,'damage':5+i%4*3,'pressure':round(.15+(i%3)*.1,2)}
        e.update(name_en=f'{REGIONS[i//3]} Encounter {i%3+1}',safe=safe,risk=risk,description=f'稳妥：胜利后获得{safe["reward"]}灵页。冒险：胜利后获得{risk["reward"]}灵页，立即损失{risk["damage"]}生命，压力增加{risk["pressure"]:.0%}。失败不兑现事件灵页。',description_en=f'Safe: earn {safe["reward"]} pages on victory. Risk: earn {risk["reward"]} pages on victory; immediately lose {risk["damage"]} HP and increase pressure by {risk["pressure"]:.0%}. Defeat forfeits event pages.')
    for i,c in enumerate(data['challenges']):
        chapter=i//3+1; mode=i%3
        c.update(name_en=f'{REGIONS[chapter-1]}: '+['Pressure Trial','Light Loadout','Dangerous Crossing'][mode],chapter=chapter,mission_id=f'S1-M{chapter:02}-08',stat='challenge_wins',stat_id=c['id'],threshold=1,enemy_multiplier=[1.4,1,1.2][mode],hazard_multiplier=[1,1,1.6][mode],max_skills=[4,2,4][mode],allow_pills=mode!=1,reward=80+chapter*20,description_en=['Defeat the chapter boss with stronger enemy pressure.','Defeat the chapter boss with two active slots and no pills.','Defeat the chapter boss with intensified arena hazards.'][mode])
    for i,a in enumerate(data['achievements']):
        dep=by_id[a['id']]['dependencies'];stat='completed_missions';threshold=1;sid=dep
        if i<8:stat='completed_count';threshold=(i+1)*8;sid=''
        elif i<16:stat='character_wins'
        elif i<32:stat='evolutions'
        elif i<56:stat='challenge_wins'
        else:stat=['pills_used','safe_wins','risk_wins','completed_count'][i-56];sid='';threshold=64 if i==59 else 1
        a.update(name_en=f'Milestone {i+1}: '+stat.replace('_',' ').title(),stat=stat,stat_id=sid,threshold=threshold,description_en=f'Record {threshold} {stat.replace("_"," ")}' +(f' for {sid}.' if sid else '.'))
    for c in data['challenges']:
        c['rule']={'stat':'challenge_win','id':c['id'],'target':1}
    for i,a in enumerate(data['achievements']):
        dep=by_id[a['id']]['dependencies']
        if i<8:rule={'stat':'completed','target':(i+1)*8}
        elif i<16:rule={'stat':'character_win','id':dep,'target':1}
        elif i<32:rule={'stat':'evolution_id','id':dep,'target':1}
        elif i<56:rule={'stat':'challenge_win','id':dep,'target':1}
        else:rule=[{'stat':'pills_used','target':1},{'stat':'safe_wins','target':1},{'stat':'risk_wins','target':1},{'stat':'completed','target':64}][i-56]
        a.update(rule=rule,description=by_id[a['id']]['description'])
        if i<8:a.update(name_en=REGIONS[i]+' Restored',description_en=f'Complete chapter {i+1}.')
        elif i<16:a.update(name_en=char_names[i-8]+' First Victory',description_en=f'Win a mission as the {char_names[i-8]}.')
        elif i<32:a.update(name_en=data['evolutions'][i-16]['name_en'],description_en='Create this evolution and save its discovery.')
        elif i<56:a.update(name_en=data['challenges'][i-32]['name_en']+' Complete',description_en='Win this optional challenge.')
        else:a.update(name_en=['First Preparation','Room to Spare','Evidence at a Risk','Leybound Finale'][i-56],description_en=['Use an unlocked preparation pill.','Choose a safe encounter option and win the run.','Choose a risky encounter option and win the run.','Complete and save the final ending.'][i-56])
    boss_moves_zh=['扑袭与延迟落点冲击','环状连续喷发','旋转十字潮线','短暂护盾与扇射','多道预警俯冲','环形持续孢区','锚环冲击与召援','多方向封印射线','环状脉冲与辐射弹幕']
    boss_moves_en=['pounces and delayed impact strikes','successive ring eruptions','rotating cross-shaped tide lanes','brief shields and fan volleys','multiple warned dive lanes','lingering rings of spores','anchor-ring strikes and reinforcements','seal rays from several directions','nexus pulses and radial projectiles']
    for b in data['bosses']:
        b.update(description='三阶段依次使用：'+'；'.join(boss_moves_zh[patterns.index(x)] for x in b['phase_patterns'])+'。先避开预警区再反击。',description_en='Three phases: '+'; '.join(boss_moves_en[patterns.index(x)] for x in b['phase_patterns'])+'. Dodge the warning zones, then counterattack.')
    stat_en=['damage','cooldown reduction','attack area','effect duration','movement speed','projectile speed','armor','pickup radius','maximum health','summon damage','summon range','summon duration','chain targets','critical chance','return damage','slow strength','explosion radius','damage against controlled enemies','charge speed','reflections','trail width','mark capacity','healing per mark','mark spread targets']
    stat_zh=dict(zip(STATS,PASSIVE_ZH))
    stat_zh.update(regeneration='每秒恢复生命',rerolls='构筑刷新次数')
    names_en=dict(zip(STATS,stat_en));names_en.update(regeneration='health restored per second',rerolls='draft rerolls')
    fractions=set(['damage','cooldown_reduction','area','duration','move_speed','projectile_speed','summon_damage','summon_duration','critical_chance','return_damage','slow_strength','explosion_radius','control_damage','charge_speed','trail_width'])
    def amount_text(stat,amount):
        return f'{amount:.0%}' if stat in fractions else f'{amount:g}'
    for p in data['passives']:
        val=amount_text(p['stat'],p['amount'])
        p.update(description=f'每级：{stat_zh[p["stat"]]}增加{val}。',description_en=f'Each rank: +{val} {names_en[p["stat"]]}.')
    data['passives'][18].update(description='每级使飞剑、震地偶、引霆针的施放速度提高15%（冷却除以1+累计增幅）。不影响其它主动。',description_en='Each rank adds 15% cast speed to Patrol Sword, Earth Stomper and Lightning Needle only (cooldown divided by 1 + total bonus).')
    for c in data['characters']:
        start=next(x for x in data['skills'] if x['id']==c['start_skill']);val=amount_text(c['passive_stat'],c['passive_amount'])
        c.update(description=f'起手{start["name"]}。生命×{c["hp_multiplier"]:g}，移速×{c["speed_multiplier"]:g}，伤害×{c["damage_multiplier"]:g}；{stat_zh[c["passive_stat"]]}增加{val}。',description_en=f'Starts with {start["name_en"]}. Health x{c["hp_multiplier"]:g}, movement x{c["speed_multiplier"]:g}, damage x{c["damage_multiplier"]:g}; +{val} {names_en[c["passive_stat"]]}.')
    for p in data['pills']:
        val=amount_text(p['stat'],p['amount'])
        p.update(description=f'本局前90秒：{stat_zh[p["stat"]]}增加{val}。' if p['stat']!='rerolls' else '本局增加1次构筑刷新。',description_en=f'First 90 seconds: +{val} {names_en[p["stat"]]}.' if p['stat']!='rerolls' else 'One additional draft reroll this run.')
    scene_en=['Broken Bridge Trail','Wind Well Ruins','Molten Mine Ridge','Deep Cooling Shaft','Old Shallow Harbor','Stone Tidal Court','Mirror Workshop','Core Transport Platform','Snow Beacon Pass','Cracked Ice Heights','Fungal Marsh Approach','Forgotten Stele Grove','Windward Bridge','Outer Anchor Terrace','Empty Court Corridor','Ley Nexus']
    environment_en=['Wind lanes alter movement routes.','Warned furnace vents threaten alternating areas.','Tides shift the safe paths.','Mirror hazards demand lateral movement.','Warned ice fractures divide the arena.','Spore fields threaten standing still.','Crosswinds and anchor zones restrict crossing.','Earlier hazards return in a warned sequence.']
    for i,r in enumerate(data['regions']):r.update(name_en=REGIONS[i],description_en=environment_en[i])
    for i,r in enumerate(data['scenes']):r.update(name_en=scene_en[i],description_en=environment_en[i//2])
    objective_en=['Survive and Extract','Break the Anchors','Cleanse the Zones','Hunt the Marked Target','Protect the Escort','Defeat the Boss']
    objective_desc=['Survive the announced time, then enter the extraction circle.','Destroy the marked anchors in the announced order.','Stand in each circle while nearby enemies are cleared. Progress pauses when interrupted.','Defeat every designated hunt target. Ordinary enemy deaths do not count.','Stay near the escort and protect its health through the ordered route.','Defeat the designated boss. Only this boss completes the mission.']
    for i,r in enumerate(data['objectives']):r.update(name_en=objective_en[i],description_en=objective_desc[i])
    for i,r in enumerate(data['progression_nodes']):
        branch=i//5;rank=i%5+1
        r.update(name=['锋意','体魄','采灵'][branch]+f'{rank}阶',name_en=['Edge','Vitality','Gathering'][branch]+f' Rank {rank}',unlock_after=[0,8,24,40,56][rank-1],description=['永久伤害每级增加8%。','永久生命上限每级增加10。','永久拾取半径每级增加15。'][branch],description_en=['Permanently adds 8% damage per rank.','Permanently adds 10 maximum health per rank.','Permanently adds 15 pickup radius per rank.'][branch])
    screens=['Main Menu','Character and Mission Selection','Pill Preparation','Permanent Growth','Codex and Achievements','Battle HUD','Pause and Save','Mission Results','Settings and Controls','Save Recovery','Chapter Story and Ending']
    screen_desc=['Start a new journey, continue, change settings or exit.','Review chapters, prerequisites and character strengths.','Cultivate and select a pill before starting.','Purchase permanent growth with earned pages.','Read discovered enemies, recipes and achievements.','Track objectives, health, build and resources.','Resume, save and exit, or abandon the current run.','Review rewards, retry or choose the next mission.','Adjust language, display, sound and controls.','Review save errors and explicitly choose recovery.','Read chapter discoveries and the final resolution.']
    for i,r in enumerate(data['screens']):r.update(name_en=screens[i],description_en=screen_desc[i])
    for i,r in enumerate(data['difficulties']):r.update(name_en=['Normal','Advanced','Extreme'][i],description_en=['Standard campaign difficulty.','Stronger enemies after the final ending.','The highest combat pressure after the final ending.'][i])
    for collection in data.values():
        if not isinstance(collection,list):continue
        for row in collection:
            assert row['description_en'] and row['name_en']!=row['id'], row['id']
    for m in data['missions']:
        m['first_grants']=[r['id'] for k in ['characters','skills','passives','evolutions','pills','events','chapters'] for r in data[k] if r['unlock_after']==m['ordinal']]
    data['tuning']={'arena_half_size':[960,640],'enemy_cap':180,'projectile_cap':400,'pickup_cap':300,'player_hp':160.0,'player_speed':280.0,'player_damage':12.0,'spawn_interval':.8,'xp_base':2,'xp_step':1,'save_interval':60.0,'mission_enemy_scaling':.008,'active_slots':4,'passive_slots':4,'max_skill_level':5,'enemy_spawn_radius':700.0,'pickup_radius':70.0,'invulnerability_seconds':.65,'critical_multiplier':1.75,'cooldown_floor':.2,'difficulty_multipliers':[1.0,1.3,1.65],'progression_cost_base':4,'progression_cost_step':4,'progression_max_level':5,'progression_damage_per_level':.08,'progression_hp_per_level':10.0,'progression_pickup_per_level':15.0,'event_interval':35.0,'hazard_interval':7.0,'hazard_warning':1.3,'hazard_radius':95.0,'hazard_damage':4.0,'environment_damage':4.0,'normal_enemy_xp':3.0,'elite_enemy_xp':12.0,'boss_xp':24.0,'target_xp':6.0}
    data['tuning'].update(progression_unlock_completed=[0,8,24,40,56], profile_pill_cap=99, profile_replay_reward=2, profile_kills_per_page=25, profile_battle_reward_cap=4, profile_first_herbs=3, profile_kills_per_herb=20, profile_battle_herb_cap=3)
    apply_chapter_one_b(data)
    apply_chapter_one_c(data)
    for m in data['missions'][:8]:
        m.update(xp_base=6,xp_step=4,upgrade_interval_ticks=180,spawn_view_size=[1280,720],spawn_visual_margin=80)
        if m['ordinal'] != 6:
            m.update(pickup_attract_radius=320,pickup_attract_speed=600)
    data['missions'][3]['clue_xp']=8
    data['missions'][3]['briefing']+=' 每条线索释放8点悟性；靠近绿色光点即可吸引拾取。'
    data['missions'][3]['briefing_en']+=' Each clue releases 8 XP; approach green motes to collect them.'
    data['missions'][7]['boss_phase_xp']=18
    data['missions'][7]['briefing']+=' 每次突破首领阶段释放18点悟性，可在战斗中完善构筑。'
    data['missions'][7]['briefing_en']+=' Each boss phase break releases 18 XP to develop your build during combat.'
    apply_chapter_one_g1(data)
    apply_chapter_one_g2(data)
    data['missions'][7]['boss_phase_entry_warning']=True
    apply_chapter_two(data)
    apply_chapter_three(data)
    from late_chapters import apply
    apply(data)
    validate(data)
    return data


def apply_chapter_one_b(data):
    trail = dict(start=[-720,0],route=[[-720,0],[-200,-320],[180,300],[720,0]],
        obstacles=[dict(x=-420,y=90,radius=52),dict(x=-170,y=40,radius=65),dict(x=330,y=-120,radius=60)],
        winds=[dict(id='W01',center=[-240,-180],size=[320,120],direction=1,forward=1.15,backward=.9),dict(id='W02',center=[260,180],size=[320,120],direction=-1,forward=1.15,backward=.9)],roots=[])
    well = dict(start=[-720,0],route=[[-720,0],[-440,220],[480,100],[0,-300],[-720,0]],
        obstacles=[dict(x=0,y=0,radius=80),dict(x=-230,y=-170,radius=48),dict(x=380,y=380,radius=48)],winds=[],
        roots=[dict(center=p,radius=65,warning_ticks=72,active_ticks=120,rest_ticks=240,offset_ticks=i*144,damage=4) for i,p in enumerate([[0,-160],[300,100],[-320,180]])])
    data['scenes'][0]['layout']=trail
    data['scenes'][1]['layout']=well
    data['scenes'][1].update(description='绕行井心与根区，在预警间隙选择安全路径。',description_en='Circle the well and cross root fields during safe intervals.')
    for m in data['missions'][:8]:
        m.update(scene_layout_id=m['scene_id'],wind_start_tick=2700 if m['ordinal']==1 else 0,tutorial=m['ordinal']==1,
                 elite_ids=[],spawn_safe_radius=620,spawn_attempts=16)
    def row(ids,sector,offset=0):
        return dict(enemy_ids=['S1-N%02d'%n for n in ids],sector=sector,count=8,interval=75,offset=offset)
    def stage(id,trigger,value,rows):return dict(id=id,trigger=trigger,value=value,rows=rows)
    data['missions'][0].update(enemy_ids=['S1-N01'],target_positions=[[720,0]],encounter_stages=[
        stage('LEARN_MOVE','ACTIVE_TICK',0,[row([1],2,120)]),
        stage('LEARN_SIDES','ACTIVE_TICK',1200,[row([1],0),row([1],1,150)]),
        stage('LEARN_WIND','ACTIVE_TICK',2700,[row([1],0),row([1],1,150),row([1],2,300)])],
        briefing='学习移动、自动攻击、拾取与升级；45秒后风带开放，72秒后进入东侧撤离圈。',
        briefing_en='Learn movement, automatic attacks, pickups and upgrades. Wind lanes open at 45s; enter the eastern exit after 72s.')
    data['missions'][1].update(enemy_ids=['S1-N01','S1-N02'],target_positions=[[-380,-280],[80,300],[600,-140]],encounter_stages=[
        stage('NORTH_FANGS','ANCHOR_PROGRESS',0,[row([1],0)]),
        stage('SOUTH_SPITTERS','ANCHOR_PROGRESS',1,[row([2],1)]),
        stage('TWO_SIDES','ANCHOR_PROGRESS',2,[row([1,2],2),row([1,2],3,90)])])
    data['missions'][2].update(target_positions=trail['route'],encounter_stages=[
        stage('SET_OUT','WAYPOINT',0,[row([1],2)]),
        stage('NORTH_RIDGE','WAYPOINT',1,[row([2],0)]),
        stage('SOUTH_BEND','WAYPOINT',2,[row([3],1)]),
        stage('HOME_STRETCH','WAYPOINT',3,[row([1,3],3)])],
        briefing='陪采药人经过四个路标；靠近才前进，可离队拦截远程与侧袭敌人。',
        briefing_en='Escort the herbalist through four waypoints. Stay nearby to move; intercept ranged and flanking enemies, then return.')


def apply_chapter_one_c(data):
    def row(ids,sector,count=6,offset=0):
        return dict(enemy_ids=ids,sector=sector,count=count,interval=75,offset=offset)
    def stage(id,trigger,value,rows):return dict(id=id,trigger=trigger,value=value,rows=rows)
    n=lambda *ids:['S1-N%02d'%i for i in ids]
    for m in data['missions'][3:8]:
        m.update(chapter_c=True,enemy_ids=n(1,2,3),elite_ids=[],encounter_stages=[])
    m=data['missions'][3]
    m.update(clues=[[-200,-320],[180,300],[720,0]],clue_radius=65,hunt_enemy_id='S1-E01',target_positions=[[680,-320]],
        hunt_retry_ticks=60,event_ids=[r['id'] for r in data['events'][:3]],
        hunt_charge=dict(warning_ticks=54,rush_ticks=42,rest_ticks=72,speed=620),
        encounter_stages=[stage('CLUE_AMBUSH','CLUE_PROGRESS',1,[row(n(1),0)]),stage('TRAIL_SIDES','CLUE_PROGRESS',2,[row(n(2,3),1)])],
        briefing='沿足迹依次寻找三处线索；首处可选择机缘，末处发现断枝兽。躲开直线预警，利用冲锋后的停顿反击。',
        briefing_en='Follow three ordered clues. Choose an encounter at the first; reveal the beast at the last. Dodge the warned charge and counter during its rest.')
    data['missions'][4].update(target_positions=[[-440,220],[480,100]],hold_seconds=6.6,
        encounter_stages=[stage('CLEANSE_%d'%i,'CLEANSE_HALF',i,[row(n(1 if i<2 else 3),2 if i%2==0 else 3),row(n(2 if i<2 else 1),0,4,90)]) for i in range(4)],
        briefing='清空两个净化圈并各累计停留6.6秒；开始净化和半程时会有有限增援。离圈或敌人靠近只暂停进度。',
        briefing_en='Clear each circle and hold for 6.6s. Limited reinforcements arrive at the start and halfway. Leaving or nearby enemies pauses progress.')
    data['missions'][5].update(elite_ids=['S1-E01'],target_positions=[[-720,0]],
        encounter_stages=[stage('HOLD_%d'%i,'ACTIVE_TICK',t,[row(n(1,2) if i==0 else n(1,3) if i==1 else n(1,2,3),sector,8,sector*120) for sector in [0,1,2]]) for i,t in enumerate([0,900,1800,2700,3600])]+[stage('ONE_ELITE','ACTIVE_TICK',3600,[row(['S1-E01'],3,1)])],
        briefing='应对远程与侧袭交替的敌潮；60秒后出现一只断枝兽精英，92秒后进入西侧撤离圈。',
        briefing_en='Face alternating ranged and flanking waves. One elite arrives after 60s; enter the western exit after 92s.')
    data['missions'][6].update(close_roots=True,target_positions=[[0,-300],[480,100],[-440,220]],
        encounter_stages=[stage('LOCK_%d'%i,'ANCHOR_PROGRESS',i,[row(n(1,2,3),i)]) for i in range(3)],
        briefing='依次拆除三锚：永久关闭北、东、西南根区，包括尚未生效的预警。安全空间随拆锚扩大。',
        briefing_en='Break three ordered anchors to permanently shut down north, east and southwest roots, including pending warnings.')
    data['missions'][7].update(boss_chapter=dict(warning_ticks=54,cooldown_ticks=150,impact_radius=90,second_delay_ticks=30,root_radius=65,root_duration_ticks=150,root_distance=160),
        encounter_stages=[stage('BEAST_GUARD','ACTIVE_TICK',0,[row(n(1,3),1,8)])],
        briefing='击败伏岚古兽：扑袭、双落点追击、扑袭与根区围堵。沿预警留出的空隙移动并反击。',
        briefing_en='Defeat the beast through pounce, double impact, then pounce with root containment. Use gaps in the warnings to counterattack.')
    data['bosses'][0].update(phase_patterns=['pounce','pounce','pounce'],description='扑袭、双落点追击、扑袭与根区围堵；无额外无敌阶段。',description_en='Pounce, double impact, then pounce with roots; no added invulnerability phase.')


def apply_chapter_one_g1(data):
    # Dispatch the next approach while the previous anchor is still actionable.
    for index in [1,6]:
        m=data['missions'][index]
        for i,stage in enumerate(m['encounter_stages']):
            stage['value']=max(0,i-1)
            for row in stage['rows']:
                row['interval']=45
                row['offset']+=90 if i==1 else 45 if i==2 else 0
        m['briefing']+=' 前往下一锚点的敌人会提前从侧面接近，留意来路。'
        m['briefing_en']+=' Enemies approach the next anchor early from the flanks; watch the route.'


def apply_chapter_one_g2(data):
    escort=data['missions'][2]
    old=escort['encounter_stages']
    escort['encounter_stages']=[old[0],old[1],old[3]]
    for stage,value in zip(escort['encounter_stages'],[0,2,3]):
        stage['value']=value
        for row in stage['rows']: row['interval']=45
    escort['encounter_stages'][1]['rows'].append(dict(enemy_ids=['S1-N02'],sector=1,count=4,interval=45,offset=45))
    escort['encounter_stages'][2]['rows'].append(dict(enemy_ids=['S1-N03'],sector=0,count=4,interval=45,offset=30))
    escort['briefing']='陪采药人经过四个路标；起步、北段转弯与南段归路分别出现敌人。靠近才前进，可离队拦截后返回。'
    escort['briefing_en']='Escort the herbalist through four waypoints. Enemies arrive at departure, the north turn and the southern return. Stay nearby to move; intercept enemies and return.'
    cleanse=data['missions'][4]
    for i,stage in enumerate(cleanse['encounter_stages']):
        stage['value']=(i//2)*2
        for row in stage['rows']:
            row['interval']=45
            row['offset']+=30 if i%2 else 0
    cleanse['briefing']='清空两个净化圈并各累计停留6.6秒；开始净化后两组有限增援会交错接近。离圈或敌人靠近只暂停进度。'
    cleanse['briefing_en']='Clear each circle and hold for 6.6s. Two limited reinforcement groups approach in sequence after cleansing begins. Leaving or nearby enemies pauses progress.'


def apply_chapter_two(data):
    ridge=dict(start=[-720,0],route=[[-720,0],[-360,-240],[200,-240],[700,0]],
        obstacles=[dict(x=-350,y=130,radius=70),dict(x=80,y=100,radius=80),dict(x=450,y=280,radius=60)],winds=[],
        roots=[dict(center=p,radius=75,warning_ticks=78,active_ticks=90,rest_ticks=252,offset_ticks=i*140,damage=4) for i,p in enumerate([[-360,-240],[180,-240],[580,0]])])
    shaft=dict(start=[-720,0],route=[[-720,0],[-400,240],[0,240],[380,240],[720,0]],
        obstacles=[dict(x=-320,y=-140,radius=65),dict(x=100,y=-160,radius=80),dict(x=440,y=-160,radius=60)],winds=[],
        roots=[dict(center=p,radius=75,warning_ticks=78,active_ticks=90,rest_ticks=252,offset_ticks=i*140,damage=4) for i,p in enumerate([[-400,240],[0,240],[380,240]])])
    data['scenes'][2]['layout']=ridge
    data['scenes'][3]['layout']=shaft
    for scene in data['scenes'][2:4]:
        scene.update(description='沿矿轨穿越错峰喷口；橙色圈先预警，再喷发。',description_en='Follow mine rails across staggered vents. Orange rings warn before eruption.')
    def wave(label,trigger,value,ids,sector,count=8,offset=0):
        return dict(id=label,trigger=trigger,value=value,rows=[dict(enemy_ids=['S1-N%02d'%n for n in ids],sector=sector,count=count,interval=45,offset=offset)])
    for m in data['missions'][8:16]:
        m.update(chapter_two=True,scene_layout_id=m['scene_id'],wind_start_tick=0,tutorial=False,elite_ids=[],
            spawn_safe_radius=620,spawn_attempts=16,xp_base=6,xp_step=4,upgrade_interval_ticks=180,
            spawn_view_size=[1280,720],spawn_visual_margin=80,pickup_attract_radius=320,pickup_attract_speed=600,
            enemy_ids=['S1-N04','S1-N05','S1-N06'])
    data['missions'][8].update(target_positions=[[720,0]],encounter_stages=[wave('ASH_%d'%i,'ACTIVE_TICK',t,[5] if i==0 else [4,5] if i==1 else [4,5,6],i%4) for i,t in enumerate([0,600,1200,1800,2400,3000,3600])],briefing='在灰翼与背炉群中坚持79秒，再进入东侧撤离圈。沿矿轨绕开橙色喷口预警。',briefing_en='Survive 79 seconds, then reach the east exit. Dodge orange vent warnings along the rails.')
    for index,layout in [(9,ridge),(14,shaft)]:
        data['missions'][index].update(thermal_anchors=True,target_positions=[r['center'] for r in layout['roots']],encounter_stages=[wave('PIPE_%d'%i,'ANCHOR_PROGRESS',max(0,i-1),[4,5,6],i,8,i*45) for i in range(3)])
    data['missions'][9].update(briefing='依次拆除三座喷口控制器；每座永久关闭对应喷口，包括正在预警的喷发。',briefing_en='Break the three controls in order. Each permanently shuts its vent, including pending warnings.')
    data['missions'][10].update(escort_label='冷却匣',escort_label_en='Cooling casket',target_positions=ridge['route'],encounter_stages=[wave('CASKET_%d'%i,'WAYPOINT',v,[4,5] if i<2 else [5,6],i,8) for i,v in enumerate([0,2,3])],briefing='护送冷却匣沿北侧矿轨通过四个路标。靠近才前进，喷口预警期间可离队清理侧袭。',briefing_en='Escort the cooling casket through four north-rail waypoints. Stay close to move; intercept flankers during vent warnings.')
    data['missions'][11].update(hunt_enemy_id='S1-E02',hunt_phase_xp=8,target_positions=[[520,-220]],encounter_stages=[wave('WARDEN_ESCORT','ACTIVE_TICK',0,[4,6],2),wave('WARDEN_FLANK','ACTIVE_TICK',360,[5],0,6)],briefing='击败标记的熔脊行者。它沿途留下预警热迹，绕开热迹并在转向时反击；每次突破生命阶段获得8点悟性。',briefing_en='Defeat the marked Furnace Warden. Circle its warned heat trail and counter while it turns. Each health phase break grants 8 XP.')
    data['elites'][1].update(behavior='trail',attack_cooldown=2.4,description='追击并留下预警热迹；不是第一章断枝兽。',description_en='Pursues and leaves warned thermal trails.')
    data['missions'][12].update(target_positions=[[-520,0],[520,0]],encounter_stages=[wave('ASH_CLEANSE_%d'%i,'CLEANSE_HALF',i*2,[4,5,6],i,8) for i in range(2)],briefing='清空两个炉灰圈并各累计停留7.2秒。每圈开始时有有限增援；离圈或敌人靠近暂停进度。',briefing_en='Clear two ash circles and hold each for 7.2 seconds. Limited reinforcements arrive when cleansing starts; leaving or nearby enemies pauses progress.')
    data['missions'][13].update(escort_label='炉工',escort_label_en='Furnace workers',rest_waypoint=3,target_positions=shaft['route'],encounter_stages=[wave('WORKERS_%d'%i,'WAYPOINT',v,[4,5] if i==0 else [5,6],i,8) for i,v in enumerate([0,2,3,4])],briefing='护送炉工通过五个路标。抵达中段后暂停整备，可选稳妥或冒险机缘，再继续撤离。',briefing_en='Escort workers through five waypoints. Pause at the midpoint for a safe or risky encounter, then continue evacuation.')
    data['missions'][14].update(briefing='任意顺序切断三根燃芯管；对应喷口立即关闭，尚未关闭的喷口保持原有预警节拍。按危险区域选择先后。',briefing_en='Cut three fuel pipes in any order. Each shuts its matching vent immediately; remaining vents retain their warning cycle. Choose which danger to remove first.')
    data['missions'][15].update(target_positions=[[480,0]],furnace_boss=dict(closed_ticks=180,open_ticks=150,closed_multiplier=.35,warning_ticks=78,cooldown_ticks=150,phase_xp=18),encounter_stages=[wave('FURNACE_GUARD','ACTIVE_TICK',0,[4,6],1)],briefing='炉心巨傀关门3秒减伤，开门2.5秒恢复全额伤害。三阶段依次使用单喷发、双喷发、三向封路；橙圈完整预警后才生效；每次突破阶段获得18点悟性。',briefing_en='The furnace closes for 3 seconds with reduced damage, then opens for 2.5 seconds at full damage. Three phases use one, two, then three warned eruptions. Each phase break grants 18 XP.')
    data['bosses'][1].update(phase_patterns=['eruption','eruption','eruption'],description='开闭炉门形成输出窗口，生命降低时增加错位喷发。',description_en='Cycling furnace doors create damage windows; lower health adds offset eruptions.')


def apply_chapter_three(data):
    harbor=dict(start=[-720,0],route=[[-720,0],[-380,220],[140,60],[720,0]],
        obstacles=[dict(x=-350,y=-140,radius=70),dict(x=-80,y=-80,radius=60),dict(x=340,y=240,radius=70)],winds=[],
        roots=[dict(center=p,radius=80,warning_ticks=90,active_ticks=150,rest_ticks=210,offset_ticks=i*150,damage=4) for i,p in enumerate([[-380,340],[140,-60],[480,-40]])])
    court=dict(start=[-720,0],route=[[-720,0],[-420,-220],[0,220],[420,-220],[720,0]],
        obstacles=[dict(x=-200,y=-350,radius=60),dict(x=200,y=350,radius=60),dict(x=0,y=-80,radius=55)],winds=[],
        roots=[dict(center=p,radius=80,warning_ticks=90,active_ticks=150,rest_ticks=210,offset_ticks=i*150,damage=4) for i,p in enumerate([[-420,-220],[0,220],[420,-220]])])
    data['scenes'][4]['layout']=harbor
    data['scenes'][5]['layout']=court
    for scene in data['scenes'][4:6]:
        scene.update(description='涨落潮显露不同安全通路；蓝色圈先预警，再涨水。',description_en='Tides shift the safe paths. Blue rings warn before the surge.')
    def wave(label,trigger,value,ids,sector,count=8,offset=0):
        return dict(id=label,trigger=trigger,value=value,rows=[dict(enemy_ids=['S1-N%02d'%n for n in ids],sector=sector,count=count,interval=45,offset=offset)])
    for m in data['missions'][16:24]:
        m.update(chapter_three=True,scene_layout_id=m['scene_id'],wind_start_tick=0,tutorial=False,elite_ids=[],
            spawn_safe_radius=620,spawn_attempts=16,xp_base=6,xp_step=4,upgrade_interval_ticks=180,
            spawn_view_size=[1280,720],spawn_visual_margin=80,pickup_attract_radius=320,pickup_attract_speed=600)
    data['missions'][16].update(target_positions=[[720,0]],encounter_stages=[wave('TIDE_%d'%i,'ACTIVE_TICK',t,[8] if i==0 else [7,8] if i==1 else [7,8,9],i%4) for i,t in enumerate([0,600,1200,1800,2400,3000,3600])],briefing='在潮蟹与汲水灵群中坚持86秒；三片潮池错峰翻涌，随蓝色预警更换安全滩，再进入东侧撤离圈。',briefing_en='Survive 86 seconds; three staggered tide pools force you to move between shoals on the blue warnings, then reach the east exit.')
    data['missions'][17].update(hunt_enemy_id='S1-E03',hunt_phase_xp=8,target_positions=[[520,-220]],encounter_stages=[wave('LEDGER_AHEAD','ACTIVE_TICK',0,[7,8],2),wave('LEDGER_FLANK','ACTIVE_TICK',360,[7],0,6)],briefing='击败携账册的覆潮祭卫；蟹甲护卫在前方与侧翼拦路。它潜地蓄水、出水爆发，出水窗口内输出；每次突破生命阶段获得8点悟性并打断其回潜。',briefing_en='Defeat the ledger-carrying Sunken Tide Warden while crab guards block the lanes ahead and to the flank. It dives to recharge and bursts on surfacing; strike while it is up. Each health phase break grants 8 XP and staggers its dive.')
    data['missions'][18].update(escort_label='渡船',escort_label_en='Ferry',rest_waypoint=2,escort_hp=660.0,target_positions=harbor['route'],encounter_stages=[wave('FERRY_%d'%i,'WAYPOINT',v,[7] if i==0 else [7,8] if i==1 else [8,9],i,8 if i<2 else 6) for i,v in enumerate([0,2,3])],briefing='护送渡船沿旧港航路通过四个路标。靠近才前进；潮池涨水时先离队等待，中段停靠可选稳妥或冒险机缘，再继续开船。',briefing_en='Escort the ferry through four harbor waypoints. Stay close to move; wait out surging flats, choose a safe or risky encounter at the midpoint stop, then sail on.')
    data['missions'][19].update(target_positions=[[-520,0],[440,60]],encounter_stages=[wave('HARBOR_CLEANSE_%d'%i,'CLEANSE_HALF',i*2,[7,8,9],i,8) for i in range(2)],briefing='清空两个净化圈并各累计停留7.8秒。南圈与潮池相叠：涨水时退到潮池远端的月牙区，月牙区可全程停留。',briefing_en='Clear two circles and hold each for 7.8 seconds. The south circle overlaps a tide pool: fall back to the far crescent during surges; the crescent is safe to hold throughout.')
    data['missions'][20].update(tide_flats=True,target_positions=[r['center'] for r in court['roots']],encounter_stages=[wave('SLUICE_%d'%i,'ANCHOR_PROGRESS',max(0,i-1),[7,8,9],i,8,i*45) for i in range(3)],briefing='依次拆除三座水闸印；每拆一座，对应潮池立即失去休潮、永久翻涌。趁预警期离开池区再拆下一座；与关闭热喷口相反，本章安全空间随拆印逐步递减。',briefing_en='Break the three sluice seals in order. Each removes its flat\'s rest phase for good — leave the flat during the warning after each break. Unlike closing thermal vents, safe ground here shrinks as you progress.')
    data['missions'][21].update(target_positions=[[-720,0]],encounter_stages=[wave('FIN_%d'%i,'ACTIVE_TICK',t,[8,9] if i==0 else [7,8,9],i%4) for i,t in enumerate([0,600,1200,1800,2400,3000,3600,4200,4800])],briefing='在潜鳍兽与汲水灵群中坚持106秒；地面跃出预警与直线喷流交替，再从西侧撤离。',briefing_en='Survive 106 seconds through burrowing fins and water jets, then reach the west exit.')
    # M03-07 calibration (2026-09-17): alternate-route arrival died 5/8 seeds pre-fix
    # (level-2 overwhelm before the first upgrade tick at 180). Rearguard fins drop
    # 8->5 and start 450 ticks in, spaced 60 ticks apart; the warden itself stays
    # stronger than M03-02's (enemy_scaling 1.176 vs 1.136).
    data['missions'][22].update(hunt_enemy_id='S1-E03',hunt_phase_xp=8,target_positions=[[540,-160]],encounter_stages=[wave('WARDEN_REAR','ACTIVE_TICK',0,[9],3,5,450),wave('WARDEN_DUEL','ACTIVE_TICK',600,[7,8],1,6)],briefing='与覆潮祭卫决斗；后路伏击不断。出水窗口内输出，每次阶段突破打断回潜蓄水并获得8点悟性。',briefing_en='Duel the Sunken Tide Warden while rearguard ambushes cut off your retreat. Strike while it surfaces; each phase break staggers its dive and grants 8 XP.')
    data['missions'][22]['encounter_stages'][0]['rows'][0]['interval']=60
    data['missions'][23].update(target_positions=[[500,-80]],tide_boss=dict(warning_ticks=78,cooldown_ticks=150,phase_xp=18,tooth_radius=34,tooth_spacing=215,arm_length=1250),encounter_stages=[wave('TIDE_GUARD','ACTIVE_TICK',0,[8,9],1)],briefing='沉潮双鳍在两侧交替竖起潮墙，齿列之间留有穿越窗口；生命降低时加密齿列，末期双侧齐发并加池环与辐射弹幕。每次突破阶段获得18点悟性。',briefing_en='The Twin Fins raise tide walls on alternating sides with crossing gaps between the teeth; lower health adds teeth, then both sides at once with pool rings and a radial barrage. Each phase break grants 18 XP.')
    data['elites'][2].update(description='潜地蓄水、出水爆发；出水期间可被伤害。阶段突破会打断回潜。',description_en='Dives to recharge and bursts on surfacing; vulnerable while up. Phase breaks stagger its dive.')
    data['bosses'][2].update(description='两侧交替潮墙，齿间保留穿越窗口；生命降低时加密齿列，末期双侧齐发并加池环与辐射弹幕。',description_en='Alternating side tide walls with crossing gaps between teeth; lower health adds teeth, then both sides at once with pool rings and a radial barrage.')


def validate(data):
    expected={'chapters':8,'missions':64,'characters':8,'skills':24,'passives':24,'evolutions':16,'enemies':24,'elites':8,'bosses':9,'pills':12,'events':24,'challenges':24,'achievements':60}
    gates=data['tuning']['progression_unlock_completed']
    assert len(gates)==5 and all(type(g) is int and 0<=g<=64 for g in gates) and gates==sorted(gates)
    all_ids=set()
    for kind,count in expected.items():
        assert len(data[kind])==count,(kind,len(data[kind]))
    for kind,rows in data.items():
        if not isinstance(rows,list):continue
        for r in rows:
            assert r['id'] not in all_ids,r['id'];all_ids.add(r['id'])
            assert all(isinstance(r[k],str) and r[k] for k in ['id','name','name_en','description','description_en']),r
            assert type(r['unlock_after']) is int and 0<=r['unlock_after']<=64
    assert len(all_ids)==364
    assert set(s['mode'] for s in data['skills'])==set(MODES)
    assert len(set(p['stat'] for p in data['passives']))==24
    assert set(e['behavior'] for e in data['enemies'])==set(BEHAVIORS)
    by_kind={k:{r['id']:r for r in v} for k,v in data.items() if isinstance(v,list)}
    for i,m in enumerate(data['missions']):
        assert m['ordinal']==i+1 and m['unlock_after']==i
        assert m['chapter']==i//8+1 and m['scene_id'] in by_kind['scenes']
        assert m['prerequisite_id']==('START' if i==0 else data['missions'][i-1]['id'])
        assert all(x in by_kind['enemies'] for x in m['enemy_ids'])
        assert not m['boss_id'] or m['boss_id'] in by_kind['bosses']
        assert len(m['target_positions'])==m['target_count']==len(m['target_ids'])
        assert m['timeout_seconds']>m['target_seconds']>0
        assert all(len(p)==2 and abs(p[0])<960 and abs(p[1])<640 for p in m['target_positions'])
        assert all(x in all_ids for x in m['first_grants'])
    for c in data['characters']:assert c['start_skill'] in by_kind['skills']
    for e in data['evolutions']:
        assert e['skill_id'] in by_kind['skills'] and e['passive_id'] in by_kind['passives']
        assert e['unlock_after']>=max(by_kind['skills'][e['skill_id']]['unlock_after'],by_kind['passives'][e['passive_id']]['unlock_after'])
    # Catch NaN and Infinity even if an editor changes tuning later.
    json.dumps(data,allow_nan=False)


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
    text=json.dumps(build(),ensure_ascii=False,indent=2,allow_nan=False)+'\n'
    if args.check:
        assert OUTPUT.read_text()==text,'catalog differs; run tools/campaign/build_catalog.py'
        print('CATALOG_REPRODUCIBLE 364 rows / 64 missions')
    else:
        OUTPUT.write_text(text,encoding='utf-8');print(f'CATALOG_BUILT {OUTPUT} (364 rows / 64 missions)')

if __name__=='__main__':main()
