"""ADR-0012: authored chapter 4-8 layouts and bounded objective-driven waves."""

def apply(data):
    colors=['#e8c779','#c9dbff','#b6d37a','#9ee5f5','#c2a5f0']
    hazards=['镜阵','霜隙','孢池','锚风','封印']
    hints=['拆除节点会关闭对应镜阵。','沿雪道顺风推进，避开霜隙。','孢池错峰喷发，净化安全岛可稳定停留。','横风影响移速，拆链关闭对应锚风区。','拆锁关闭封印，核心战保留环形弹幕逃生缺口。']
    en_hints=['Breaking nodes disables their mirror fields.','Follow the tailwind and avoid frost rifts.','Staggered spore pools leave safe cleansing islands.','Crosswinds affect movement; breaking chains closes anchor fields.','Break locks to disable seals; the nexus barrage leaves an escape gap.']
    escort_names={4:('修补偶','Repair Automaton'),5:('暖炉车','Warming Cart'),6:('采样灯','Sampling Lamp'),7:('断锚舟','Ley Vessel'),8:('地脉匣','Ley Casket')}
    for chapter in range(4,9):
        theme=chapter-4
        for local_scene in range(2):
            flip=1 if local_scene==0 else -1
            # Three navigable lanes; roots avoid the central escort/cleanse islands.
            layout=dict(start=[-720,0],route=[[-720,0],[-380,flip*160],[80,-flip*160],[420,flip*160],[720,0]],
                obstacles=[dict(x=-220,y=flip*340,radius=60),dict(x=270,y=-flip*340,radius=65),dict(x=40,y=flip*70,radius=45)],
                winds=[],roots=[dict(center=[x,flip*y],radius=70,warning_ticks=90,active_ticks=120+theme*15,rest_ticks=240,offset_ticks=i*150,damage=4) for i,(x,y) in enumerate([(-420,-290),(0,300),(460,-270)])])
            if chapter in (5,7):
                layout['winds']=[dict(id='WIND',center=[0,0],size=[900,180],direction=flip,forward=1.2,backward=.8)]
            scene=data['scenes'][(chapter-1)*2+local_scene]
            scene.update(layout=layout,description=hazards[theme]+'区域先预警再生效。'+hints[theme],description_en=en_hints[theme]+' Fields warn before activating.')
        ids=[f'S1-N{(chapter-1)*3+i:02}' for i in (1,2,3)]
        def wave(label,trigger,value,sector,count=6,offset=0,enemy_ids=None):
            return dict(id=label,trigger=trigger,value=value,rows=[dict(enemy_ids=enemy_ids or ids,sector=sector,count=count,interval=75,offset=offset)])
        for local,m in enumerate(data['missions'][(chapter-1)*8:chapter*8]):
            scene=next(s for s in data['scenes'] if s['id']==m['scene_id'])
            layout=scene['layout']; kind=m['kind']
            m.update(late_chapter=True,scene_layout_id=m['scene_id'],wind_start_tick=0,tutorial=False,elite_ids=[],enemy_ids=ids.copy(),
                spawn_safe_radius=620,spawn_attempts=16,xp_base=6,xp_step=4,upgrade_interval_ticks=180,spawn_view_size=[1280,720],spawn_visual_margin=80,pickup_attract_radius=320,pickup_attract_speed=600,
                late_hazard_color=colors[theme],late_hint=hints[theme],late_hint_en=en_hints[theme])
            if kind=='SURVIVE':
                m['encounter_stages']=[wave(f'HOLD_{i}','ACTIVE_TICK',t,i%4,6) for i,t in enumerate(range(0,int(m['target_seconds']*60)-600,720))]
                m['target_positions']=[[720 if local%2==0 else -720,0]]
                objective=f'守住{m["target_seconds"]:g}秒，再进入撤离圈。'
                en=f'Survive {m["target_seconds"]:g}s, then reach the exit.'
            elif kind=='BREAK':
                m.update(late_close_fields=True,target_positions=[r['center'] for r in layout['roots']],encounter_stages=[wave(f'LOCK_{i}','ANCHOR_PROGRESS',i,i%4,5) for i in range(3)])
                objective='击破三个节点，逐一关闭对应危险区；'+('可自由选择拆除顺序。' if m['order_mode']=='PLAYER_CHOICE' else '依编号拆除。')
                en='Break three nodes to disable their fields; '+('choose the order.' if m['order_mode']=='PLAYER_CHOICE' else 'follow the numbered order.')
            elif kind=='CLEANSE':
                positions=[[-520,40],[370,40],[620,-150]][:m['target_count']]
                m.update(target_positions=positions,encounter_stages=[wave(f'CLEANSE_{i}','CLEANSE_HALF',i*2,i%4,6,enemy_ids=ids[:2]) for i in range(m['target_count'])])
                objective=f'清空并驻守{m["target_count"]}个安全岛，每处{m["hold_seconds"]:g}秒；入圈触发一次守卫增援。'
                en=f'Clear {m["target_count"]} safe islands and hold each for {m["hold_seconds"]:g}s; entering calls one guard wave.'
            elif kind=='ESCORT':
                count=m['target_count']; route=layout['route'] if count==5 else [layout['route'][i] for i in (0,1,3,4)]
                m.update(late_waypoint_xp=12,target_positions=route,escort_label=escort_names[chapter][0],escort_label_en=escort_names[chapter][1],rest_waypoint=2,
                    encounter_stages=[wave(f'ESCORT_{i}','WAYPOINT',i,i%4,5,enemy_ids=[ids[0],ids[2]]) for i in range(count)])
                objective=f'靠近{m["escort_label"]}沿路标前进，每到非终点路标释放12悟性；中途机缘选择后继续。'
                en=f'Stay near the {m["escort_label_en"]}; each non-final waypoint releases 12 XP. Choose an encounter at the midpoint.'
            elif kind=='HUNT':
                m.update(hunt_enemy_id=f'S1-E{chapter:02}',late_hunt_xp=10,target_positions=[[500,-160]],encounter_stages=[wave('HUNT_AHEAD','ACTIVE_TICK',0,2,5,enemy_ids=ids[:2]),wave('HUNT_REAR','ACTIVE_TICK',600,3,4)])
                objective='击败本章指定精英，避开其专属攻击；生命阶段突破释放10悟性。'
                en='Defeat the regional elite and avoid its special attack; each health phase break releases 10 XP.'
            else:
                pattern=data['bosses'][int(m['boss_id'][-2:])-1]['pattern']
                m.update(target_positions=[[470,0]],late_boss=dict(pattern=pattern,warning_ticks=90,cooldown_ticks=180,phase_xp=18,radius=55,spacing=150,length=700,projectile_speed=150),encounter_stages=[wave('BOSS_GUARDS','ACTIVE_TICK',0,1,5,enemy_ids=ids[:2])])
                objective='击败三阶段首领；完整预警后攻击生效，每次阶段突破释放18悟性。'
                en='Defeat the three-phase boss; attacks follow full warnings and each phase break releases 18 XP.'
            if kind=='BREAK':
                m['late_hint']='拆除对应节点停止后续喷发；已经出现的预警仍会生效。'
                m['late_hint_en']='Breaking a node stops future eruptions; existing warnings still resolve.'
            else:
                m['late_hint']=['镜阵先预警再爆发，从亮圈之间绕行。','沿雪道顺风推进，避开霜隙。','孢池错峰喷发，净化安全岛可稳定停留。','横风影响移速，避开锚风危险区。','避开封印预警，沿空隙移动。'][theme]
                m['late_hint_en']=['Mirror fields warn before erupting; move between the marked circles.','Follow the tailwind and avoid frost rifts.','Staggered spore pools leave safe cleansing islands.','Crosswinds affect movement; avoid anchor fields.','Avoid seal warnings and move through the gaps.'][theme]
            if kind=='BOSS':
                labels={'mirror':('镜阵横向排开，向上下避让。','Mirror blasts form rows; dodge vertically.'),'dive':('平行俯冲线先预警，横移穿过线间空隙。','Parallel dive lines warn first; sidestep between them.'),'spore_tide':('孢池环绕首领展开，离开圈列再输出。','Spore pools encircle the boss; step outside them to attack.'),'anchors':('锚环的边缘有伤害，圈心与圈外可避险。','Anchor ring edges hurt; the center and exterior are safe.'),'seals':('封印线向内交叉，在预警结束前离开交点。','Seal lines cross inward; leave their intersections before impact.'),'nexus':('核心震环与放射弹幕先预警；弹幕朝向留有缺口。','Nexus rings and radial shots warn first; the barrage leaves an aimed gap.')}
                m['late_hint'],m['late_hint_en']=labels[pattern]
            if kind=='BOSS':
                if pattern=='dive': m['late_boss'].update(radius=28,cooldown_ticks=210)
                if pattern in ('anchors','seals'): m['late_boss'].update(cooldown_ticks=240,warning_ticks=120)
            if chapter==6 and kind in ('CLEANSE','ESCORT','BREAK','SURVIVE'):
                for stage in m['encounter_stages']:
                    stage['rows'][0].update(enemy_ids=[ids[0],ids[2]],count=4,interval=105)
                m['encounter_stages'][0]['rows'].append(dict(enemy_ids=[ids[1]],sector=2,count=1,interval=120,offset=900))
            m['briefing']=objective+' '+m['late_hint']
            m['briefing_en']=en+' '+m['late_hint_en']
            m['description']=m['briefing']; m['description_en']=m['briefing_en']
