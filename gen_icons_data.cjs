// 一次性生成脚本：从 assets/icons 生成 equipment/beasts/gems/items JSON
const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const IC = path.join(ROOT, 'assets/icons');
const rel = (p) => {
  const i = p.replace(/\\/g, '/').indexOf('assets/icons/');
  return p.replace(/\\/g, '/').slice(i);
};

// ---------- slot 推断 ----------
function inferSlot(name) {
  if (name.includes('护腕')) return '护腕';
  if (/指环|戒指|(?<!权)戒/.test(name)) return '戒指';
  if (/环佩|链/.test(name)) return '项链';
  if (/护符|符/.test(name)) return '护符';
  if (/腰带|束带|束腰|腰环|腰丝|玉带|腰|带|缚/.test(name)) return '腰带';
  if (/衬肩|护肩|肩|膀/.test(name)) return '护肩';
  if (/护手|手套|裹手|手甲|手/.test(name)) return '手套';
  if (/靴|鞋|胫|脚|踱/.test(name)) return '鞋子';
  if (/冠|盔|帽|首|纶|顶/.test(name)) return '帽子';
  if (/铠|甲|衣|袍|胸|覆/.test(name)) return '衣服';
  return '';
}
const ls = (dir) => fs.readdirSync(path.join(IC, dir)).filter((f) => /\.(jpg|gif|bmp)$/.test(f));

const out = [];
const push = (e) => out.push(e);

// ---------- 古墓 ----------
{
  const levelOf = (n) => (n.startsWith('燕侯') ? 50 : n.startsWith('皓灵') ? 60 : 70);
  for (const f of ls('sets/gumu')) {
    const n = f.replace(/\.jpg$/, '');
    const slot = inferSlot(n) || '武器';
    push({
      name: n, slot, level: levelOf(n), quality: 'purple',
      set: n.slice(0, 2) + '套装',
      attrs: [],
      source: slot === '武器' ? '燕王古墓BOSS掉落（古3、古6层武器最值钱，9层赤霄掉赤炼系列）' : '燕弦玉在雁北（280,60）NPC处兑换',
      desc: '燕王古墓套装，以血上限为卖点的撑血套装。具体属性以游戏内为准。',
      icon: rel(path.join(IC, 'sets/gumu', f)),
    });
  }
}
// ---------- 地宫 ----------
{
  for (const f of ls('sets/digong')) {
    const n = f.replace(/\.jpg$/, '');
    const slot = inferSlot(n) || '武器';
    push({
      name: n, slot, level: n.startsWith('秦武') ? 75 : 85, quality: 'purple',
      set: n.slice(0, 2) + '套装',
      attrs: [],
      source: slot === '武器' ? '秦皇地宫BOSS掉落' : '秦皇珠兑换',
      desc: '秦皇地宫套装，部件含武器/衣服/护手/戒指/护符。具体属性以游戏内为准。',
      icon: rel(path.join(IC, 'sets/digong', f)),
    });
  }
}
// ---------- 少室山 ----------
{
  for (const f of ls('sets/shaoshi')) {
    const n = f.replace(/\.bmp$/, '');
    push({
      name: n, slot: inferSlot(n), level: 85, quality: 'orange',
      set: n.slice(0, 4) + '套装',
      attrs: [],
      source: '少室山副本掉落',
      desc: '少室山套装，按冰/毒/火/玄四系划分。具体属性以游戏内为准。',
      icon: rel(path.join(IC, 'sets/shaoshi', f)),
    });
  }
}
// ---------- 御赐 ----------
{
  const levelMap = {
    '熟铜': 18, '绫罗': 18, '精钢': 30, '蚕丝': 30, '黄金': 40, '蜀锦': 40,
    '混沌': 50, '玄冥': 50, '飞虎': 60, '王师': 60, '天威': 70, '天机': 70,
    '北斗': 80, '南箕': 80, '霸主': 90, '腾龙': 90,
  };
  for (const f of ls('sets/yuci')) {
    const n = f.replace(/\.jpg$/, '');
    const series = n.replace(/^御赐/, '').slice(0, 2);
    const level = levelMap[series] || 0;
    push({
      name: n, slot: inferSlot(n), level, quality: 'green',
      set: `御赐${series}套装`,
      attrs: [],
      source: '野外首领掉落万灵石，找苏州梁师成（169,138）兑换；80/90套需7、8级万灵石',
      desc: `御赐${series}套装，属性一般但隐藏属性不错。具体以游戏内为准。`,
      icon: rel(path.join(IC, 'sets/yuci', f)),
    });
  }
}
// ---------- 新手 ----------
{
  for (const f of ls('sets/xinshou')) {
    const n = f.replace(/\.jpg$/, '');
    push({
      name: n, slot: inferSlot(n), level: 15, quality: 'green',
      set: '新手套装',
      attrs: ['增加外防', '增加体质', '增加HP上限'],
      source: '新手任务 / 财富卡奖励',
      desc: '新手过渡套装，陪伴每个少侠走出大理的第一身行头。',
      icon: rel(path.join(IC, 'sets/xinshou', f)),
    });
  }
}
// ---------- 玄昊 ----------
{
  const levelMap = { '倚楼溪斜': 76, '明月素影': 86, '渡泸西蜀': 86, '碧天北斗': 96 };
  for (const f of ls('sets/xuanhao')) {
    const n = f.replace(/\.jpg$/, '');
    const series = Object.keys(levelMap).find((k) => n.startsWith(k));
    push({
      name: n, slot: inferSlot(n), level: series ? levelMap[series] : 0, quality: 'purple',
      set: series ? series + '套装' : '玄昊套装',
      attrs: [],
      source: '玄昊玉在洛阳NPC立繁处兑换',
      desc: '玄昊套装，96套隐藏属性有30%基础攻击加成。具体以游戏内为准。',
      icon: rel(path.join(IC, 'sets/xuanhao', f)),
    });
  }
}
// ---------- 缥缈峰 ----------
{
  for (const f of ls('sets/piaomiao')) {
    const n = f.replace(/\.jpg$/, '');
    push({
      name: n, slot: inferSlot(n), level: 95, quality: 'orange',
      set: '碧玉套装',
      attrs: ['隐藏属性：毒抗（+70/+60/+50）'],
      source: '大/小缥缈峰副本掉落',
      desc: '相传女娲采石补天，其一聚月之精华为玉，佩带者百毒不侵。刷大缥缈必备。',
      icon: rel(path.join(IC, 'sets/piaomiao', f)),
    });
  }
}
// ---------- 门派 ----------
{
  const known = { '心瀚': { level: 100, set: '少林心瀚套装' }, '菩提': { level: 100, set: '少林菩提套装' }, '天南': { level: 90, set: '天龙天南套装' } };
  for (const f of ls('sets/menpai')) {
    const n = f.replace(/\.jpg$/, '');
    const prefix = [...n].slice(0, 2).join('');
    const k = known[prefix];
    push({
      name: n, slot: inferSlot(n) || '武器', level: k ? k.level : 0, quality: 'blue',
      set: k ? k.set : prefix + '套装',
      attrs: [],
      source: '苏州老三环（跑跑）BOSS掉落为主，另有野外怪、任务奖励、竞技场箱子等',
      desc: '门派套装（10–100级每10级一套），集齐90套有+20%血上限隐藏属性。具体等级与属性以游戏内为准。',
      icon: rel(path.join(IC, 'sets/menpai', f)),
    });
  }
}

// 合并已有 62 件
const eqPath = path.join(ROOT, 'assets/data/equipment.json');
const existing = JSON.parse(fs.readFileSync(eqPath, 'utf8'));
let id = Math.max(...existing.map((e) => e.id)) + 1;
for (const e of out) e.id = id++;
const equipment = existing.concat(out);
fs.writeFileSync(eqPath, JSON.stringify(equipment, null, 2));
console.log('equipment:', equipment.length, '(existing', existing.length, '+ new', out.length, ')');

// ---------- 坐骑 ----------
{
  const schools = [
    ['gaibang', '丐帮', ['灰狼', '白狼', '银月狼'], '狼行天下，丐帮弟子最忠实的伙伴。'],
    ['tianshan', '天山', ['雕', '白雕', '骛影雕'], '天山灵雕，展翅之间已至千里之外。'],
    ['tianlong', '天龙', ['黄骠马', '青白骢马', '龙血马'], '天龙寺宝马，相传有龙血血脉。'],
    ['shaolin', '少林', ['虎', '白虎', '如意虎'], '少林伏虎，骑之正气凛然。'],
    ['emei', '峨眉', ['青凤', '红白凤', '琉璃凤'], '峨眉灵凤，霞光绕体，百鸟朝之。'],
    ['murong', '慕容', ['羚羊', '雪羚羊', '幽光羚'], '慕容世家灵羚，奔走如履平地。'],
    ['mingjiao', '明教', ['狮子', '白狮', '烈焰狮'], '明教圣狮，鬃毛如火，威风凛凛。'],
    ['xingxiu', '星宿', ['牦牛', '白牦牛', '青牦牛'], '星宿高原神牦，耐寒跋涉，稳如泰山。'],
    ['wudang', '武当', ['鹤', '金翼鹤', '瑞莲鹤'], '武当仙鹤，骑之飘飘然有出尘之姿。'],
    ['xiaoyao', '逍遥', ['鹿', '白鹿', '七彩鹿'], '逍遥灵鹿，踏云而行，自在逍遥。'],
  ];
  const tiers = ['40级坐骑', '60级坐骑', '80级坐骑'];
  const beasts = [];
  let bid = 1;
  for (const [dir, school, names, desc] of schools) {
    const files = ls('beasts/' + dir);
    names.forEach((n, i) => {
      const f = files.find((x) => x.replace(/\.gif$/, '') === n);
      if (!f) { console.error('MISSING beast icon', dir, n); return; }
      beasts.push({
        id: bid++, name: n, school,
        icon: rel(path.join(IC, 'beasts', dir, f)),
        source: `门派坐骑商人处购买（需学习对应骑术），${tiers[i]}。以游戏内为准。`,
        desc,
      });
    });
  }
  fs.writeFileSync(path.join(ROOT, 'assets/data/beasts.json'), JSON.stringify(beasts, null, 2));
  console.log('beasts:', beasts.length);
}

// ---------- 宝石 ----------
{
  const attrs = {
    '变石': '外功攻击', '尖晶石': '内功攻击',
    '红宝石': '火攻击', '蓝宝石': '冰攻击', '绿宝石': '毒攻击', '黄宝石': '玄攻击',
    '红晶石': '火抗性', '蓝晶石': '冰抗性', '绿晶石': '毒抗性', '黄晶石': '玄抗性',
    '红冥石': '减火抗', '蓝冥石': '减冰抗', '绿冥石': '减毒抗', '黄冥石': '减玄抗',
    '紫玉': '力量', '祖母绿': '灵气', '黄玉': '体力', '碧玺': '身法', '月光石': '定力',
    '血精石': '血上限',
    '虎眼石': '会心攻击（以游戏内为准）', '猫眼石': '会心防御（以游戏内为准）',
    '石榴石': '命中（以游戏内为准）', '皓石': '闪避（以游戏内为准）',
    '黑宝石': '属性加成以游戏内为准',
  };
  const gems = [];
  let gid = 1;
  for (const f of ls('gems')) {
    const raw = f.replace(/\.jpg$/, '');
    const n = raw.replace(/（.*?）.*/, '');
    gems.push({
      id: gid++, name: n,
      icon: rel(path.join(IC, 'gems', f)),
      attr: attrs[n] || '属性加成以游戏内为准',
      desc: `${n}（1～9级），镶嵌于装备之上提升属性，级数越高加成越多。`,
    });
  }
  fs.writeFileSync(path.join(ROOT, 'assets/data/gems.json'), JSON.stringify(gems, null, 2));
  console.log('gems:', gems.length);
}

// ---------- 道具 ----------
{
  const descs = {
    '大理回城符': '一念回大理，段氏故地的风花雪月尽在眼前。',
    '洛阳回城符': '一念回洛阳，摆摊一条街的热闹又回来了。',
    '苏州回城符': '一念回苏州，老三环的队伍还差一个人。',
    '定位符': '记录当前坐标，随时随地传送回来，蹲BOSS抢怪必备。',
    '易容丹': '改头换面重新做人，江湖恩怨一笔勾销。',
    '染发剂': '换个发色换种心情，当年多少人攒金就为这一瓶。',
    '新人令牌': '新人报到凭证，萌新江湖路的起点。',
    '门派召集令': '师门有难，一纸召集，同门速归。',
    '土灵珠': '土灵护身，遁地而行，跑路保命的神器。',
    '列阵飞箭': '列阵齐射，箭如雨下，宋辽战场上的大杀器。',
    '彩虹之箭': '七彩流光破空而出，好看就是硬道理。',
    '点金之箭（用于极限打孔装备打孔）': '点石成金，极限打孔装备的最后一孔就靠它。',
    '湘妃箭': '湘妃竹泪化神箭，雅致与杀伤并存。',
    '竹箭': '最朴实的箭矢，新手村外的第一袋口粮。',
    '紫竹箭': '紫竹为杆，比竹箭多一分坚韧。',
    '落星之箭': '箭落如流星，夜战之中最亮的那道光。',
    '牛角': '普通的牛角，生活技能材料，积少成多。',
    '牦牛角': '高原牦牛之角，质地坚韧的上好材料。',
    '玉犀角': '玉质犀角，珍稀材料，打造装备的抢手货。',
    '浚云之角': '云端神兽之角，传说中可遇不可求。',
    '若水之角': '上善若水，灵角温润，打造良材。',
    '飞瀑之角': '飞瀑流泉淬炼之角，自带三分灵气。',
    '白玉瓶': '白玉无瑕，盛药储丹的雅致容器。',
    '翡翠瓶': '翡翠晶莹，炼药师们的最爱。',
    '陶瓷瓶': '粗陶土瓶，朴素耐用，行走江湖常备。',
    '沙蚕': '钓鱼饵料之一，海边一挖一大把。',
    '虹虫': '泛着虹光的虫子，鱼儿见了走不动道。',
    '蚯蚓': '最经典的鱼饵，钓鱼佬的青春回来了。',
  };
  const items = [];
  let iid = 1;
  for (const f of ls('items')) {
    const n = f.replace(/\.jpg$/, '');
    items.push({
      id: iid++, name: n,
      icon: rel(path.join(IC, 'items', f)),
      desc: descs[n] || '经典道具，具体用途以游戏内为准。',
    });
  }
  fs.writeFileSync(path.join(ROOT, 'assets/data/items.json'), JSON.stringify(items, null, 2));
  console.log('items:', items.length);
}
