#!/usr/bin/env node
/**
 * 一次性脚本：补全 equipment.json 中的占位 / 空 attrs。
 *
 * 规则：
 *  - 占位 attrs（含"数值待考/存疑待考"等字样）按原属性名逐条替换为具体数值；
 *  - attrs 为空数组的装备按「部位 × 等级 × 品质」规则表生成 2-3 条属性；
 *  - 已有真实数值的 attrs（3 件）不动；
 *  - 其他字段（id/name/slot/level/quality/set/source/desc/icon）一律不动。
 *
 * 数值口径（参考端游/怀旧服常识，60 级蓝装为基准）：
 *  - 60 级蓝武器攻击约 400，紫 520，85 紫约 740，100 橙约 1130；
 *  - 60 级蓝防具防御约 190，血上限约 1100（古墓撑血套 ×1.3）；
 *  - 体力/身法/力量/灵气等主属性 60 级蓝约 32。
 * 有效等级：level>0 用原值；门派套装 level=0 按 40 级档计算。
 * 品质系数：green 0.8 / blue 1.0 / purple 1.3 / orange 1.7。
 * 每件装备按 id 加 ±5% 确定性抖动，避免同档装备数值完全一致。
 *
 * 用法：node tool/fill_equipment_attrs.js [--dry-run]
 */
const fs = require('fs');
const path = require('path');

const FILE = path.join(__dirname, '..', 'assets', 'data', 'equipment.json');
const DRY = process.argv.includes('--dry-run');

const PLACEHOLDER_RE = /待考|待定|占位|示例|TBD|存疑/;

// 品质系数
const QMUL = { green: 0.8, blue: 1.0, purple: 1.3, orange: 1.7 };

// 古墓/地宫"撑血"系套装：血上限 ×1.3，武器额外带血上限
const HP_SETS = ['燕王套装', '燕侯套装', '皓灵套装', '赤炼套装', '秦武套装', '秦魂套装', '秦皇套装'];

// 少室山四系套装 → 属性攻击系别
const ELEM_SETS = { 冰凝风寒套装: '冰', 毒影瘴华套装: '毒', 火炽焚焰套装: '火', 玄金刚杵套装: '玄' };
const ELEM_BY_NAME = [
  [/冰凝|风寒/, '冰'], [/毒影|瘴华/, '毒'], [/火炽|焚焰/, '火'], [/玄天|金刚/, '玄'],
];

// 套装隐藏属性（有资料依据的写具体值，其余写通用激活说明）
const HIDDEN_BY_SET = {
  玄昊套装: '隐藏属性：基础攻击 +30%（集齐套装生效）',
  渡泸西蜀套装: '隐藏属性：基础攻击 +30%（集齐套装生效）',
  明月素影套装: '隐藏属性：基础攻击 +30%（集齐套装生效）',
  碧天北斗套装: '隐藏属性：基础攻击 +30%（集齐套装生效）',
  碧玉套装: '隐藏属性：毒抗 +70（集齐套装生效）',
  门派套装: '隐藏属性：血上限 +20%（集齐套装生效）',
  战神套装: '隐藏属性：减抗 +45（集齐套装生效）',
  重楼套装: '隐藏属性：免疫控制类效果（集齐套装生效）',
};

// 有效等级：门派套 level=0 按 40 级档
function effLevel(e) {
  return e.level > 0 ? e.level : 40;
}

// 每件装备 ±5% 确定性抖动
function jitter(e) {
  return 1 + (((e.id * 13) % 11) - 5) / 100;
}

function base(e) {
  const L = effLevel(e);
  const q = QMUL[e.quality] || 1.0;
  const k = (L / 60) * q * jitter(e);
  return { L, q, k };
}

const R = (x) => Math.max(1, Math.round(x));

const gen = {
  atk(e, inner) {
    const { k } = base(e);
    return `${inner ? '内功' : '外功'}攻击 +${R(400 * k)}`;
  },
  atkSmall(e, inner) {
    const { k } = base(e);
    return `${inner ? '内功' : '外功'}攻击 +${R(140 * k)}`;
  },
  hp(e) {
    const { k } = base(e);
    const mul = HP_SETS.includes(e.set) ? 1.3 : 1.0;
    return `血上限 +${R(1100 * k * mul)}`;
  },
  hpHigh(e) {
    const { k } = base(e);
    return `血上限 +${R(1100 * k * 1.3)}`;
  },
  defOut(e) {
    const { k } = base(e);
    return `外功防御 +${R(190 * k)}`;
  },
  defIn(e) {
    const { k } = base(e);
    return `内功防御 +${R(190 * k)}`;
  },
  hit(e) {
    const { k } = base(e);
    return `命中 +${R(90 * k)}`;
  },
  dodge(e) {
    const { k } = base(e);
    return `闪避 +${R(70 * k)}`;
  },
  crit(e) {
    const { k } = base(e);
    return `会心 +${R(5 * k) + 2}`;
  },
  stat(e, name) {
    const { k } = base(e);
    return `${name} +${R(32 * k)}`;
  },
  elemAtk(e, elem) {
    const { k } = base(e);
    return `${elem || elemOf(e)}攻击 +${R(95 * k)}`;
  },
  resist(e, elem) {
    const { k } = base(e);
    return `${elem ? elem + '抗' : '全抗性'} +${R(35 * k)}`;
  },
  reduceRes(e) {
    const { k } = base(e);
    return `减抗 +${R(35 * k)}`;
  },
  hidden(e) {
    return HIDDEN_BY_SET[e.set] || '隐藏属性：集齐套装激活属性加成';
  },
};

function elemOf(e) {
  if (ELEM_SETS[e.set]) return ELEM_SETS[e.set];
  for (const [re, el] of ELEM_BY_NAME) if (re.test(e.name) || re.test(e.set || '')) return el;
  return '玄';
}

// "基础属性"：按部位给对应基础数值（武器→攻击、防具→防御、饰品→攻击/属性/体力）
function mapBasic(e, inner) {
  switch (e.slot) {
    case '武器': return gen.atk(e, inner);
    case '项链': return gen.atkSmall(e, inner);
    case '戒指': return gen.elemAtk(e);
    case '护符': return gen.stat(e, '体力');
    default: return inner ? gen.defIn(e) : gen.defOut(e);
  }
}

// 武器给全额攻击，其余部位攻击类属性给小额（避免饰品/防具攻击高过武器）
function mapAtk(e, inner) {
  return e.slot === '武器' || !e.slot ? gen.atk(e, inner) : gen.atkSmall(e, inner);
}

// 占位属性名 → 生成器（保留原属性构成，只填数值）
function mapPlaceholder(e, attr) {
  const key = attr.replace(/（.*?）/g, '').replace(/\(.*?\)/g, '').trim();
  const inner = e.id % 2 === 1;
  if (/^外功\/内功攻击/.test(key)) return mapAtk(e, inner);
  if (/^外功攻击/.test(key)) return mapAtk(e, false);
  if (/^内功攻击/.test(key)) return mapAtk(e, true);
  if (/^攻击/.test(key)) return mapAtk(e, inner);
  if (/^基础属性/.test(key)) return mapBasic(e, inner);
  if (/^血上限（96\/102/.test(attr)) return gen.hp(e);
  if (/^血上限（高于同级/.test(attr)) return gen.hpHigh(e);
  if (/^血上限/.test(key)) return HP_SETS.includes(e.set) ? gen.hpHigh(e) : gen.hp(e);
  if (/^外功防御/.test(key)) return gen.defOut(e);
  if (/^内功防御/.test(key)) return gen.defIn(e);
  if (/^(防御|基础防御)/.test(key)) return inner ? gen.defIn(e) : gen.defOut(e);
  if (/^力量/.test(key)) return gen.stat(e, '力量');
  if (/^灵气/.test(key)) return gen.stat(e, '灵气');
  if (/^体力/.test(key)) return gen.stat(e, '体力');
  if (/^身法/.test(key)) return gen.stat(e, '身法');
  if (/^定力/.test(key)) return gen.stat(e, '定力');
  if (/^门派主属性/.test(key)) return gen.stat(e, inner ? '灵气' : '力量');
  if (/^命中/.test(key)) return gen.hit(e);
  if (/^闪避/.test(key)) return gen.dodge(e);
  if (/^会心/.test(key)) return gen.crit(e);
  if (/^火攻击/.test(key)) return gen.elemAtk(e, '火');
  if (/^冰攻击/.test(key)) return gen.elemAtk(e, '冰');
  if (/^毒攻击/.test(key)) return gen.elemAtk(e, '毒');
  if (/^玄攻击/.test(key)) return gen.elemAtk(e, '玄');
  if (/^属性攻击/.test(key)) return gen.elemAtk(e);
  if (/^毒抗/.test(attr)) return '隐藏属性：毒抗 +70（集齐套装生效）';
  if (/^抗性/.test(key)) return gen.resist(e);
  if (/^减抗/.test(attr)) return gen.reduceRes(e);
  if (/^免疫控制/.test(key)) return gen.hidden(e);
  if (/^隐藏属性/.test(attr)) return gen.hidden(e);
  return null; // 未识别 → 走部位规则
}

// 空 attrs 按部位生成 2-3 条
function genBySlot(e) {
  const inner = e.id % 2 === 1;
  const third = e.id % 3;
  switch (e.slot) {
    case '武器': {
      const attrs = [gen.atk(e, inner), third === 0 ? gen.hit(e) : third === 1 ? gen.crit(e) : gen.elemAtk(e)];
      if (HP_SETS.includes(e.set)) attrs.push(gen.hp(e));
      return attrs;
    }
    case '帽子': return [gen.defIn(e), gen.stat(e, '体力')];
    case '衣服': return [gen.hp(e), gen.defOut(e)];
    case '护腕': return [gen.defOut(e), gen.stat(e, inner ? '灵气' : '力量')];
    case '鞋子': return [gen.dodge(e), gen.stat(e, '身法')];
    case '腰带': return [gen.hp(e), gen.stat(e, '体力')];
    case '手套': return [gen.defOut(e), gen.hit(e)];
    case '护肩': return [gen.defIn(e), third === 0 ? gen.dodge(e) : gen.stat(e, '体力')];
    case '项链': return [gen.hp(e), gen.atkSmall(e, inner)];
    case '戒指': return [gen.elemAtk(e), gen.hit(e)];
    case '护符': return [gen.crit(e), gen.stat(e, '身法')];
    default: {
      // slot 为空（渡泸西蜀系列，武器命名）按武器处理
      const attrs = [gen.atk(e, inner), gen.hit(e)];
      if (HP_SETS.includes(e.set)) attrs.push(gen.hp(e));
      return attrs;
    }
  }
}

// ---- 主流程 ----
const data = JSON.parse(fs.readFileSync(FILE, 'utf8'));
let nPlaceholder = 0;
let nPlaceholderAttrs = 0;
let nEmpty = 0;
let nKept = 0;

for (const e of data) {
  const isPlaceholder = e.attrs.some((a) => PLACEHOLDER_RE.test(a));
  if (isPlaceholder) {
    nPlaceholder++;
    const mapped = e.attrs.map((a) => mapPlaceholder(e, a));
    // 未识别的占位条目用部位规则兜底补齐
    const fallback = genBySlot(e);
    const out = mapped.map((m, i) => m || fallback[i % fallback.length]);
    // 占位装备不足 2 条属性的，按部位规则补足（保持每件 2-4 条）
    for (const fa of fallback) {
      if (out.length >= 2) break;
      const type = fa.split(' +')[0];
      if (!out.some((a) => a.split(' +')[0] === type)) out.push(fa);
    }
    nPlaceholderAttrs += out.length;
    e.attrs = out;
  } else if (!e.attrs.length) {
    nEmpty++;
    e.attrs = genBySlot(e);
  } else {
    nKept++;
  }
}

console.log(`占位装备替换: ${nPlaceholder} 件 / ${nPlaceholderAttrs} 条属性`);
console.log(`空 attrs 生成: ${nEmpty} 件`);
console.log(`保留原值: ${nKept} 件`);

// 校验：不得再有占位字样、不得有空 attrs
const bad = data.filter(
  (e) => !e.attrs.length || e.attrs.some((a) => PLACEHOLDER_RE.test(a))
);
if (bad.length) {
  console.error('仍有残留问题装备:', bad.map((e) => e.id).join(','));
  process.exit(1);
}

if (!DRY) {
  const json = JSON.stringify(data, null, 2);
  JSON.parse(json); // 自检合法
  fs.writeFileSync(FILE, json, 'utf8');
  console.log('已写回', FILE);
} else {
  console.log('(dry-run，未写回)');
}
