'use strict';

/* =========================================================
   أثر — متتبع عادات بالعربية على طريقة GitHub و«العادات الذرية»
   كل البيانات محفوظة محليًا على الجهاز (localStorage).
   ========================================================= */

const STORE_KEY = 'athar-habits-v1';
const APP_VERSION = '1.0.0';
const SURFACE = '#141417';

const COLORS = [
  '#a3e635', '#5ed0ea', '#f5c142', '#a78bfa', '#5fd39a', '#f472b6', '#f07178',
  '#5aa9f5', '#f59e4a', '#5ed6c0', '#818cf8', '#e879f9', '#facc15', '#94a3b8',
];

const EMOJIS = (
  '🏃 🚶 🚴 🏋️ 🧘 🤸 🏊 ⚽ 💧 🥗 🍎 🥛 💊 😴 🛏️ 🦷 🧴 📖 📗 📚 ✍️ 📝 🧠 💻 🗣️ 🎸 🎨 📷 ' +
  '🎯 💰 🧹 🌱 🕌 📿 🤲 🌙 ☀️ ❤️ 🙏 👨‍👩‍👧 📞 ⏰ 📵 🚭 🍬 ☕ 🍔 🥤 🎮 📺 🛒 💸 🍕 🚫'
).split(' ');

const MONTHS = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const DAYS = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
const DAYS_MID = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
const DAYS_ONE = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
const ICS_DAYS = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];

const PRESETS = {
  build: [
    { name: 'شرب الماء', desc: 'اشرب ما يكفي طوال اليوم', emoji: '💧', color: '#5ed0ea', goal: 8, unit: 'كوب',
      atomic: { stack: 'بعد أن أصلي، سأشرب كوب ماء', twoMin: 'رشفة واحدة فقط', cue: 'زجاجة ماء دائمًا على مكتبي' } },
    { name: 'قراءة 20 صفحة', desc: 'خصص وقتًا لكتاب جيد', emoji: '📖', color: '#a78bfa', goal: 20, unit: 'صفحة',
      atomic: { identity: 'أنا قارئ', twoMin: 'اقرأ صفحة واحدة', stack: 'بعد العشاء، سأقرأ وأنا أشرب الشاي' } },
    { name: 'الجري صباحًا', desc: 'ابدأ يومك بالجري', emoji: '🏃', color: '#a3e635', goal: 1, unit: '',
      atomic: { identity: 'أنا رياضي', twoMin: 'البس حذاء الجري واخرج من الباب', cue: 'أضع ملابس الجري بجانب السرير' } },
    { name: 'التأمل', desc: 'لحظة هدوء لنفسك', emoji: '🧘', color: '#5fd39a', goal: 1, unit: '', atomic: { twoMin: 'تنفّس بعمق 3 مرات' } },
    { name: 'ورد القرآن', desc: 'ولو صفحة كل يوم', emoji: '📗', color: '#5ed6c0', goal: 1, unit: '',
      atomic: { stack: 'بعد صلاة الفجر، سأقرأ وردي', twoMin: 'آية واحدة' } },
    { name: 'أذكار الصباح والمساء', desc: 'حصّن يومك', emoji: '📿', color: '#818cf8', goal: 2, unit: 'مرة', atomic: {} },
    { name: 'تمارين الضغط', desc: 'ازدد قوة مع كل تكرار', emoji: '🏋️', color: '#f5c142', goal: 30, unit: 'تكرار',
      atomic: { twoMin: 'ضغطة واحدة', stack: 'بعد أن أغسل وجهي صباحًا، سأتمرن' } },
    { name: 'النوم 8 ساعات', desc: 'نم مبكرًا', emoji: '😴', color: '#818cf8', goal: 1, unit: '', atomic: {} },
    { name: 'اليوميات', desc: 'اكتب ما في بالك', emoji: '✍️', color: '#f472b6', goal: 1, unit: '', atomic: { twoMin: 'اكتب سطرًا واحدًا' } },
    { name: 'خيط الأسنان', desc: 'ابتسامة أصح', emoji: '🦷', color: '#5aa9f5', goal: 1, unit: '', atomic: { stack: 'بعد أن أفرّش أسناني، سأستخدم الخيط' } },
  ],
  quit: [
    { name: 'ترك التدخين', desc: 'أنفاس أنقى كل يوم', emoji: '🚭', color: '#f07178',
      atomic: { identity: 'أنا شخص لا يدخّن', why: 'صحتي، مالي، وعائلتي', replacement: 'أمضغ علكة أو أمشي 5 دقائق' } },
    { name: 'بلا سكر', desc: 'اختر حياة بسكر أقل', emoji: '🍬', color: '#f472b6',
      atomic: { friction: 'لا أشتري الحلويات ولا أحتفظ بها في البيت', replacement: 'فاكهة أو تمر' } },
    { name: 'تقليل الجوال', desc: 'لا تصفّح قبل النوم', emoji: '📵', color: '#5aa9f5',
      atomic: { trigger: 'أترك الجوال خارج غرفة النوم', friction: 'أحذف التطبيقات المشتتة من الشاشة الرئيسية' } },
    { name: 'بلا وجبات سريعة', desc: 'طعام بيتي أصح', emoji: '🍔', color: '#f59e4a', atomic: {} },
    { name: 'بلا مشروبات غازية', desc: 'الماء أفضل', emoji: '🥤', color: '#e879f9', atomic: { replacement: 'ماء فوار بالليمون' } },
    { name: 'تقليل الألعاب', desc: 'وقت أكثر لما يهم', emoji: '🎮', color: '#818cf8', atomic: {} },
    { name: 'بلا شراء عشوائي', desc: 'وفّر مالك', emoji: '💸', color: '#facc15', atomic: { friction: 'أنتظر 48 ساعة قبل أي شراء غير ضروري' } },
  ],
};

const IDENTITY_FIELD = ['identity', 'الهوية: من الشخص الذي تريد أن تصبحه؟', 'مثال: أنا شخص يهتم بصحته'];

const LAWS = {
  build: [
    { title: 'اجعلها واضحة', fields: [
      ['cue', 'النية التنفيذية (متى وأين؟)', 'سأقوم بـ ... في الساعة ... في ...'],
      ['stack', 'تكديس العادات', 'بعد أن [عادة حالية]، سأقوم بـ [العادة الجديدة]'],
    ] },
    { title: 'اجعلها جذابة', fields: [['bundle', 'ربط الإغراء', 'بعد أن أنجزها، سأفعل شيئًا أحبه: ...']] },
    { title: 'اجعلها سهلة', fields: [['twoMin', 'قاعدة الدقيقتين', 'أسهل نسخة منها تأخذ أقل من دقيقتين: ...']] },
    { title: 'اجعلها مُرضية', fields: [['reward', 'المكافأة الفورية', 'عندما أنجزها سأكافئ نفسي بـ ...']] },
  ],
  quit: [
    { title: 'اجعلها غير مرئية', fields: [['trigger', 'ما الذي يحفّزها؟ وكيف تبتعد عنه؟', 'مثال: أترك الجوال خارج غرفة النوم']] },
    { title: 'اجعلها غير جذابة', fields: [['why', 'لماذا تريد تركها؟', 'ما الضرر الذي تسببه، وما الذي ستكسبه بتركها؟']] },
    { title: 'اجعلها صعبة', fields: [['friction', 'أضف عوائق', 'مثال: لا أحتفظ بها في البيت']] },
    { title: 'اجعلها غير مُرضية', fields: [['accountability', 'شريك المحاسبة', 'سأخبر ... وإذا زللت سأقوم بـ ...']] },
    { title: 'العادة البديلة', fields: [['replacement', 'ماذا ستفعل بدلًا منها؟', 'عندما أشعر بالرغبة سأقوم بـ ...']] },
  ],
};

const QUOTES = [
  'تحسّن 1% كل يوم يعني أن تصبح أفضل بـ 37 ضعفًا خلال سنة.',
  'كل مرة تنجز فيها عادتك، تمنح صوتًا للشخص الذي تريد أن تصبحه.',
  'لا ترتفع إلى مستوى أهدافك، بل تهبط إلى مستوى أنظمتك.',
  'لا تفوّت مرتين أبدًا. المرة الواحدة خطأ، والمرتان بداية عادة جديدة.',
  'اجعلها سهلة لدرجة أنك لا تستطيع الرفض.',
  'البيئة أقوى من الإرادة. صمّم محيطك لينجح.',
  'العادة التي لا تُقاس لا تتحسن.',
  'أهم شيء أن تحضر. ابدأ صغيرًا، ثم كبّر.',
];

/* ---------- أيقونات (مستوحاة من Lucide) ---------- */
const ICONS = {
  plus: '<path d="M12 5v14M5 12h14"/>',
  minus: '<path d="M5 12h14"/>',
  x: '<path d="M18 6 6 18M6 6l12 12"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  left: '<path d="m15 18-6-6 6-6"/>',
  right: '<path d="m9 18 6-6-6-6"/>',
  down: '<path d="m6 9 6 6 6-6"/>',
  up: '<path d="m18 15-6-6-6 6"/>',
  settings: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
  chart: '<path d="M3 3v18h18"/><path d="M18 17V9"/><path d="M13 17V5"/><path d="M8 17v-3"/>',
  edit: '<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>',
  trash: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
  archive: '<rect width="20" height="5" x="2" y="3" rx="1"/><path d="M4 8v11a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8"/><path d="M10 12h4"/>',
  list: '<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>',
  cards: '<rect width="18" height="7" x="3" y="3" rx="2"/><rect width="18" height="7" x="3" y="14" rx="2"/>',
  grid: '<rect width="7" height="7" x="3" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="3" rx="1.5"/><rect width="7" height="7" x="14" y="14" rx="1.5"/><rect width="7" height="7" x="3" y="14" rx="1.5"/>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="m9 12 2 2 4-4"/>',
  shieldX: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/><path d="m14.5 9.5-5 5M9.5 9.5l5 5"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  download: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 10 5 5 5-5"/><path d="M12 15V3"/>',
  upload: '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m17 8-5-5-5 5"/><path d="M12 3v12"/>',
  cloud: '<path d="M12 13v8"/><path d="M4 14.9A7 7 0 1 1 15.7 8h1.8a4.5 4.5 0 0 1 2.5 8.2"/><path d="m8 17 4-4 4 4"/>',
  note: '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M16 13H8M16 17H8M10 9H8"/>',
  calendar: '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
  flame: '<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.07-2.14-.22-4.05 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.15.43-2.29 1-3a2.5 2.5 0 0 0 2.5 2.5z"/>',
  star: '<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01z"/>',
  percent: '<path d="M19 5 5 19"/><circle cx="6.5" cy="6.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/>',
  hash: '<path d="M4 9h16M4 15h16M10 3 8 21M16 3l-2 18"/>',
  trend: '<path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/>',
  sort: '<path d="m21 16-4 4-4-4M17 20V4M3 8l4-4 4 4M7 4v16"/>',
  sliders: '<path d="M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6"/>',
  atom: '<circle cx="12" cy="12" r="1"/><path d="M20.2 20.2c2.04-2.03.02-7.36-4.5-11.9-4.54-4.52-9.87-6.54-11.9-4.5-2.04 2.03-.02 7.36 4.5 11.9 4.54 4.52 9.87 6.54 11.9 4.5Z"/><path d="M15.7 15.7c4.52-4.54 6.54-9.87 4.5-11.9-2.03-2.04-7.36-.02-11.9 4.5-4.52 4.54-6.54 9.87-4.5 11.9 2.03 2.04 7.36.02 11.9-4.5Z"/>',
  book: '<path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>',
  info: '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>',
  target: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>',
  restore: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',
  share: '<path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><path d="m16 6-4-4-4 4"/><path d="M12 2v13"/>',
};

function ic(name, cls = '') {
  return `<svg class="${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name] || ''}</svg>`;
}

/* ---------- أدوات DOM ---------- */
const $ = (s, r = document) => r.querySelector(s);

function h(tag, props, ...kids) {
  const el = document.createElement(tag);
  if (props) {
    for (const [k, v] of Object.entries(props)) {
      if (v == null || v === false) continue;
      if (k === 'class') el.className = v;
      else if (k === 'html') el.innerHTML = v;
      else if (k === 'style' && typeof v === 'object') Object.assign(el.style, v);
      else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
      else if (k === 'value') el.value = v;
      else el.setAttribute(k, v === true ? '' : v);
    }
  }
  for (const c of kids.flat(Infinity)) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : String(c));
  }
  return el;
}

function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function mix(a, b, t) {
  const A = hexToRgb(a);
  const B = hexToRgb(b);
  const c = A.map((v, i) => Math.round(B[i] + (v - B[i]) * t));
  return `rgb(${c[0]},${c[1]},${c[2]})`;
}

function colorVars(c) {
  return `--c:${c};--tint:${mix(c, SURFACE, 0.09)};--tile:${mix(c, SURFACE, 0.18)};--tile-half:${mix(c, SURFACE, 0.1)};`;
}

/* ---------- التواريخ ---------- */
const pad = (n) => String(n).padStart(2, '0');
const keyOf = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const parseKey = (k) => {
  const [y, m, d] = k.split('-').map(Number);
  return new Date(y, m - 1, d);
};
const addDays = (d, n) => {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
};
const today = () => {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
};
const todayKey = () => keyOf(today());
const fmtDate = (d) => `${DAYS[d.getDay()]}، ${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
const daysBetween = (a, b) => Math.round((b - a) / 86400000);
const uid = () => Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4);

/* ---------- الحالة والتخزين ---------- */
function defaultState() {
  return {
    version: 1,
    settings: { view: 'cards', weekStart: 0, listDays: 5, introSeen: false, tipClosed: false },
    habits: [],
  };
}

function load() {
  try {
    const raw = localStorage.getItem(STORE_KEY);
    if (!raw) return defaultState();
    const s = JSON.parse(raw);
    const d = defaultState();
    return { ...d, ...s, settings: { ...d.settings, ...(s.settings || {}) }, habits: (s.habits || []).map(normalizeHabit) };
  } catch (e) {
    console.error(e);
    return defaultState();
  }
}

function normalizeHabit(hb) {
  return {
    id: hb.id || uid(),
    name: hb.name || 'عادة',
    desc: hb.desc || '',
    emoji: hb.emoji || '🎯',
    color: hb.color || COLORS[3],
    type: hb.type === 'quit' ? 'quit' : 'build',
    goal: Math.max(1, Number(hb.goal) || 1),
    unit: hb.unit || '',
    start: hb.start || todayKey(),
    archived: !!hb.archived,
    atomic: hb.atomic || {},
    log: hb.log || {},
    notes: hb.notes || {},
    reminders: hb.reminders || [],
    created: hb.created || Date.now(),
  };
}

let state = load();

function save() {
  try {
    localStorage.setItem(STORE_KEY, JSON.stringify(state));
  } catch (e) {
    toast('تعذّر الحفظ! صدّر نسخة احتياطية الآن.', '⚠️');
  }
}

const activeHabits = () => state.habits.filter((x) => !x.archived);
const findHabit = (id) => state.habits.find((x) => x.id === id);

/* ---------- منطق العادات ---------- */
function effectiveStart(hb) {
  let s = hb.start;
  if (hb.type === 'build') {
    for (const k of Object.keys(hb.log)) if (k < s) s = k;
  }
  return s;
}

// يعيد حالة اليوم: { fill: 0..1, slip, na }
function dayState(hb, k, tk = todayKey()) {
  if (k > tk) return { na: true, fill: 0 };
  if (hb.type === 'quit') {
    if (k < hb.start) return { na: true, fill: 0 };
    if (hb.log[k]) return { slip: true, fill: 0 };
    return { fill: 1 };
  }
  const v = hb.log[k] || 0;
  return { fill: Math.min(1, v / hb.goal), count: v };
}

const isDone = (hb, k, tk) => dayState(hb, k, tk).fill >= 1;

function computeStats(hb, year) {
  const t = today();
  const tk = keyOf(t);
  const startD = parseKey(effectiveStart(hb));
  let run = 0;
  let best = 0;
  let done = 0;
  let total = 0;
  let runBeforeToday = 0;
  let sum = 0;
  for (let d = new Date(startD); d <= t; d = addDays(d, 1)) {
    const k = keyOf(d);
    if (k === tk) runBeforeToday = run;
    if (year && d.getFullYear() !== year) {
      if (isDone(hb, k, tk)) run++;
      else run = 0;
      continue;
    }
    total++;
    if (isDone(hb, k, tk)) {
      run++;
      done++;
    } else run = 0;
    if (hb.type === 'build') sum += hb.log[k] || 0;
    best = Math.max(best, run);
  }
  const todayDone = isDone(hb, tk, tk);
  const cur = todayDone ? run : hb.type === 'quit' ? 0 : runBeforeToday;
  return {
    cur,
    best,
    done,
    total,
    rate: total ? Math.round((done / total) * 100) : 0,
    sum,
    todayDone,
  };
}

// عدد الأيام منذ آخر زلّة (للعادات التي تتركها)
function cleanDays(hb) {
  const t = today();
  let d = new Date(t);
  let n = 0;
  const startK = hb.start;
  while (keyOf(d) >= startK && !hb.log[keyOf(d)]) {
    n++;
    d = addDays(d, -1);
  }
  return n;
}

function goalLabel(hb) {
  if (hb.type === 'quit') return 'إقلاع';
  if (hb.goal > 1) return `${hb.goal} ${hb.unit || 'مرات'} يوميًا`;
  return 'يوميًا';
}

function tapDay(hb, k, { fromCard = false } = {}) {
  const tk = todayKey();
  if (k > tk) return;
  if (hb.type === 'quit') {
    if (k < hb.start) return;
    if (hb.log[k]) {
      delete hb.log[k];
      commit();
    } else {
      hb.log[k] = 1;
      commit();
      if (k === tk || fromCard) {
        toast('لا بأس، الزلّة لا تعني الفشل. المهم ألا تفوّت مرتين.', '🤍', {
          label: 'تراجع',
          fn: () => {
            delete hb.log[k];
            commit();
          },
        });
      }
    }
    return;
  }
  const v = hb.log[k] || 0;
  const nv = v >= hb.goal ? 0 : v + 1;
  if (nv) hb.log[k] = nv;
  else delete hb.log[k];
  commit();
  if (nv >= hb.goal && v < hb.goal && k === tk) celebrate(hb);
}

function celebrate(hb) {
  const yk = keyOf(addDays(today(), -1));
  const s = computeStats(hb);
  const ys = dayState(hb, yk);
  const started = yk >= effectiveStart(hb);
  let msg;
  if (started && ys.fill < 1 && s.done > 1) msg = 'عدت للمسار! لا تفوّت مرتين أبدًا.';
  else if ([7, 21, 30, 66, 100, 365].includes(s.cur)) msg = `${s.cur} يومًا متتاليًا! أنت تبني هوية جديدة.`;
  else if (hb.atomic.identity) msg = `صوت جديد لهويتك: «${hb.atomic.identity}»`;
  else msg = `أحسنت! ${s.cur > 1 ? `السلسلة: ${s.cur} أيام` : 'بداية رائعة'}`;
  toast(msg, hb.emoji);
}

/* ---------- الالتزام وإعادة الرسم ---------- */
const sheets = [];

function commit() {
  save();
  renderMain();
  for (const s of sheets) if (!s.isStatic) s.refresh();
}

/* ---------- إشعارات صغيرة ---------- */
function toast(msg, icon = '✨', action) {
  const box = $('#toasts');
  const el = h(
    'div',
    { class: 'toast' },
    h('span', { class: 't-ico' }, icon),
    h('span', { class: 't-msg' }, msg),
    action &&
      h('button', {
        onclick: () => {
          action.fn();
          dismiss();
        },
      }, action.label)
  );
  const dismiss = () => {
    el.classList.add('out');
    setTimeout(() => el.remove(), 300);
  };
  while (box.children.length > 1) box.firstChild.remove();
  box.append(el);
  setTimeout(dismiss, action ? 5000 : 3200);
}

function confirmBox(title, msg, okLabel = 'تأكيد', danger = false) {
  return new Promise((resolve) => {
    const close = (v) => {
      back.remove();
      resolve(v);
    };
    const back = h(
      'div',
      { class: 'modal-back', onclick: (e) => e.target === back && close(false) },
      h(
        'div',
        { class: 'modal' },
        h('h3', null, title),
        msg && h('p', null, msg),
        h(
          'div',
          { class: 'btn-row' },
          h('button', { class: 'btn ghost', onclick: () => close(false) }, 'إلغاء'),
          h('button', { class: `btn ${danger ? 'danger' : ''}`, onclick: () => close(true) }, okLabel)
        )
      )
    );
    document.body.append(back);
  });
}

function noteBox(hb, k) {
  const d = parseKey(k);
  const ta = h('textarea', { class: 'textarea', placeholder: 'ما الذي سار جيدًا؟ وما الذي اعترض طريقك؟', maxlength: 1000 });
  ta.value = hb.notes[k] || '';
  const close = () => back.remove();
  const back = h(
    'div',
    { class: 'modal-back', onclick: (e) => e.target === back && close() },
    h(
      'div',
      { class: 'modal' },
      h('h3', null, 'ملاحظة'),
      h('p', { style: 'margin-bottom:10px' }, `${hb.emoji} ${hb.name} · ${fmtDate(d)}`),
      ta,
      h(
        'div',
        { class: 'btn-row' },
        hb.notes[k] &&
          h('button', {
            class: 'btn danger',
            onclick: () => {
              delete hb.notes[k];
              commit();
              close();
            },
          }, 'حذف'),
        h('button', {
          class: 'btn',
          onclick: () => {
            const v = ta.value.trim();
            if (v) hb.notes[k] = v;
            else delete hb.notes[k];
            commit();
            close();
          },
        }, 'حفظ')
      )
    )
  );
  document.body.append(back);
  setTimeout(() => ta.focus(), 50);
}

/* ---------- لمسة طويلة ---------- */
function pressable(el, onTap, onLong) {
  let timer;
  let long = false;
  let sx = 0;
  let sy = 0;
  el.addEventListener('pointerdown', (e) => {
    long = false;
    sx = e.clientX;
    sy = e.clientY;
    if (onLong)
      timer = setTimeout(() => {
        long = true;
        onLong();
      }, 480);
  });
  el.addEventListener('pointermove', (e) => {
    if (Math.abs(e.clientX - sx) > 8 || Math.abs(e.clientY - sy) > 8) clearTimeout(timer);
  });
  for (const ev of ['pointerup', 'pointercancel', 'pointerleave']) el.addEventListener(ev, () => clearTimeout(timer));
  el.addEventListener('click', (e) => {
    e.stopPropagation();
    if (long) return;
    onTap && onTap(e);
  });
  el.addEventListener('contextmenu', (e) => e.preventDefault());
  return el;
}

/* ---------- الخريطة الحرارية (على طريقة GitHub) ---------- */
function heatmap(hb, { weeks, end = today(), months = true, gap = 3, aggregate = false, color }) {
  const ws = state.settings.weekStart;
  const tk = todayKey();
  const endWeekStart = addDays(end, -((end.getDay() - ws + 7) % 7));
  const first = addDays(endWeekStart, -(weeks - 1) * 7);
  const c = color || hb.color;
  const empty = mix(c, SURFACE, 0.13);
  const slip = mix('#f0616d', SURFACE, 0.32);
  const wrap = h('div', { class: 'hm-wrap' });

  if (months) {
    const row = h('div', { class: 'hm-months', style: `grid-template-columns:repeat(${weeks},1fr);column-gap:${gap}px` });
    // اترك مسافة كافية بين أسماء الأشهر حتى لا تتداخل في الخرائط الصغيرة
    const minGap = Math.max(4, Math.ceil(weeks / 8));
    let last = first.getMonth();
    let lastCol = -minGap;
    for (let w = 1; w < weeks - 1; w++) {
      const d = addDays(first, w * 7);
      if (d.getMonth() !== last) {
        last = d.getMonth();
        if (w < weeks - 2 && w - lastCol >= minGap) {
          row.append(h('span', { style: `grid-column:${w + 1} / span ${minGap}` }, MONTHS[last]));
          lastCol = w;
        }
      }
    }
    wrap.append(row);
  }

  const grid = h('div', { class: 'hm', style: `grid-template-columns:repeat(${weeks},1fr);--gap:${gap}px` });
  const frag = document.createDocumentFragment();
  for (let w = 0; w < weeks; w++) {
    for (let r = 0; r < 7; r++) {
      const d = addDays(first, w * 7 + r);
      const k = keyOf(d);
      let bg = empty;
      let cls = 'hm-c';
      if (k > tk) cls += ' future';
      else if (aggregate) {
        const f = aggregate(k);
        if (f > 0) bg = mix(c, empty, 0.3 + 0.7 * f);
      } else {
        const s = dayState(hb, k, tk);
        if (s.slip) bg = slip;
        else if (s.fill >= 1) bg = c;
        else if (s.fill > 0) bg = mix(c, empty, 0.3 + 0.5 * s.fill);
      }
      if (k === tk) cls += ' today';
      frag.append(h('div', { class: cls, style: `background:${bg}` }));
    }
  }
  grid.append(frag);
  wrap.append(grid);
  return wrap;
}

function fitWeeks(width, pitch) {
  return Math.max(8, Math.floor(width / pitch));
}

function contentWidth() {
  return Math.min(window.innerWidth, 640) - 32;
}

/* ---------- زر اليوم ---------- */
function ringSvg(frac, color) {
  const r = 15;
  const len = 2 * Math.PI * r;
  return `<svg class="ring" viewBox="0 0 36 36"><circle cx="18" cy="18" r="${r}" fill="none" stroke="${color}" stroke-opacity=".22" stroke-width="3.2"/><circle cx="18" cy="18" r="${r}" fill="none" stroke="${color}" stroke-width="3.2" stroke-linecap="round" stroke-dasharray="${len * frac} ${len}" transform="rotate(-90 18 18)"/></svg>`;
}

function todayButton(hb, small = false) {
  const tk = todayKey();
  const s = dayState(hb, tk, tk);
  let cls = `check${small ? ' sm' : ''}`;
  let html;
  let label;
  if (hb.type === 'quit') {
    if (s.na) {
      html = ic('shield');
      label = 'لم تبدأ بعد';
    } else if (s.slip) {
      cls += ' slip';
      html = ic('shieldX');
      label = 'زلّة اليوم';
    } else {
      cls += ' done';
      html = ic('shield');
      label = 'صامد اليوم، اضغط لتسجيل زلّة';
    }
  } else if (hb.goal > 1 && s.fill < 1) {
    html = ringSvg(s.fill, hb.color) + (s.count ? `<span class="ring-num">${s.count}</span>` : ic('plus'));
    label = `${s.count || 0} من ${hb.goal}`;
  } else {
    if (s.fill >= 1) cls += ' done';
    html = ic('check');
    label = s.fill >= 1 ? 'تم' : 'لم يتم';
  }
  const btn = h('button', { class: cls, html, 'aria-label': label, title: label });
  return pressable(btn, () => tapDay(hb, tk, { fromCard: true }), () => openHabit(hb.id));
}

/* ---------- الواجهة الرئيسية ---------- */
function renderMain() {
  const app = $('#app');
  const habits = activeHabits();
  const t = today();
  const view = state.settings.view;

  const top = h(
    'header',
    { class: 'topbar' },
    h('button', { class: 'icon-btn', 'aria-label': 'الإعدادات', html: ic('settings'), onclick: openSettings }),
    h(
      'div',
      { class: 'brand' },
      h('h1', null, 'أثر'),
      h('p', null, fmtDate(t))
    ),
    h('button', { class: 'icon-btn', 'aria-label': 'الإحصاءات', html: ic('chart'), onclick: () => openStats() }),
    h('button', { class: 'icon-btn primary', 'aria-label': 'عادة جديدة', html: ic('plus'), onclick: () => openEditor() })
  );

  const body = h('main');
  if (!habits.length) {
    body.append(emptyState());
  } else {
    body.append(tipBanner());
    if (view === 'list') body.append(listView(habits));
    else if (view === 'compact') body.append(compactView(habits));
    else body.append(...habits.map(cardView));
  }

  const sw = h(
    'nav',
    { class: 'switcher', 'aria-label': 'طريقة العرض' },
    [
      ['list', 'list', 'قائمة الأيام'],
      ['cards', 'cards', 'بطاقات'],
      ['compact', 'grid', 'مضغوط'],
    ].map(([v, icon, label]) =>
      h('button', {
        class: view === v ? 'on' : '',
        'aria-label': label,
        html: ic(icon),
        onclick: () => {
          state.settings.view = v;
          commit();
        },
      })
    )
  );

  app.replaceChildren(top, body, habits.length ? sw : '');
}

function tipBanner() {
  const standalone = window.navigator.standalone || matchMedia('(display-mode: standalone)').matches;
  const isIOS = /iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (!standalone && isIOS && !state.settings.installClosed) {
    return h(
      'div',
      { class: 'banner' },
      h('span', { style: 'font-size:22px' }, '📲'),
      h('div', { html: 'ثبّت التطبيق: اضغط زر <b>المشاركة</b> في Safari ثم <b>«إضافة إلى الشاشة الرئيسية»</b>.' }),
      h('button', {
        class: 'x',
        html: ic('x'),
        style: 'width:20px',
        onclick: () => {
          state.settings.installClosed = true;
          commit();
        },
      })
    );
  }
  if (state.settings.tipClosed) return '';
  const q = QUOTES[Math.floor(Date.now() / 86400000) % QUOTES.length];
  return h(
    'div',
    { class: 'banner' },
    h('span', { style: 'font-size:22px' }, '⚛️'),
    h('div', null, q),
    h('button', {
      class: 'x',
      html: ic('x'),
      style: 'width:20px',
      'aria-label': 'إخفاء',
      onclick: () => {
        state.settings.tipClosed = true;
        commit();
      },
    })
  );
}

function emptyState() {
  return h(
    'div',
    { class: 'empty' },
    h('div', { class: 'big' }, '🌱'),
    h('h2', null, 'ابدأ بعادة واحدة صغيرة'),
    h('p', null, 'العادات الصغيرة تتراكم مثل الفائدة المركبة. أضف عادة تريد بناءها، أو عادة ضارة تريد التخلص منها.'),
    h(
      'div',
      { class: 'btn-row', style: 'max-width:360px;margin:0 auto' },
      h('button', { class: 'btn', onclick: () => openEditor(null, 'build'), html: `${ic('plus')}<span>عادة أبنيها</span>` }),
      h('button', { class: 'btn ghost', onclick: () => openEditor(null, 'quit'), html: `${ic('shield')}<span>عادة أتركها</span>` })
    )
  );
}

function subtitle(hb) {
  if (hb.type === 'quit') {
    const n = cleanDays(hb);
    return `${n} ${n === 1 ? 'يوم' : 'يومًا'} بدون · ${hb.desc || 'اضغط الدرع عند الزلّة'}`;
  }
  return hb.desc || goalLabel(hb);
}

function cardView(hb) {
  const weeks = fitWeeks(contentWidth() - 28 + 3, 13.5);
  return h(
    'article',
    { class: 'card', style: colorVars(hb.color), onclick: () => openHabit(hb.id) },
    h(
      'div',
      { class: 'card-head' },
      h('div', { class: 'tile' }, hb.emoji),
      h(
        'div',
        { class: 'card-title' },
        h('h3', null, hb.name, hb.type === 'quit' && h('span', { class: 'tag quit' }, 'إقلاع')),
        h('p', null, subtitle(hb))
      ),
      todayButton(hb)
    ),
    heatmap(hb, { weeks, months: false })
  );
}

function compactView(habits) {
  const colW = (contentWidth() - 10) / 2 - 24;
  const weeks = fitWeeks(colW + 2, 10);
  return h(
    'div',
    { class: 'compact-grid' },
    habits.map((hb) =>
      h(
        'article',
        { class: 'card', style: colorVars(hb.color), onclick: () => openHabit(hb.id) },
        h(
          'div',
          { class: 'card-head' },
          h('div', { class: 'tile sm' }, hb.emoji),
          h('div', { class: 'card-title' }, h('h3', null, hb.name)),
          todayButton(hb, true)
        ),
        heatmap(hb, { weeks, months: false, gap: 2 })
      )
    )
  );
}

function listView(habits) {
  const n = state.settings.listDays;
  const t = today();
  const tk = keyOf(t);
  const days = [];
  for (let i = n - 1; i >= 0; i--) days.push(addDays(t, -i));
  days.reverse(); // اليوم أولًا من جهة الاسم

  const head = h(
    'div',
    { class: 'list-row head' },
    h('div', { class: 'list-name' }, h('span', { class: 'list-count' }, `${habits.length} عادة`)),
    h(
      'div',
      { class: 'days' },
      days
        .slice()
        .reverse()
        .map((d) =>
          h('div', { class: `day-h${keyOf(d) === tk ? ' today' : ''}` }, DAYS_ONE[d.getDay()], h('b', null, d.getDate()))
        )
    )
  );

  const rows = habits.map((hb) => {
    const cells = days
      .slice()
      .reverse()
      .map((d) => {
        const k = keyOf(d);
        const s = dayState(hb, k, tk);
        let cls = 'day-cell';
        let html = '';
        if (s.na) cls += ' na';
        else if (s.slip) {
          cls += ' slip';
          html = ic('x', 'x');
        } else if (s.fill >= 1) cls += ' done';
        else if (s.fill > 0) html = ringSvg(s.fill, hb.color);
        if (k === tk) cls += ' today';
        const btn = h('button', { class: cls, html, 'aria-label': `${hb.name} ${fmtDate(d)}` });
        return pressable(btn, () => tapDay(hb, k), () => noteBox(hb, k));
      });
    return h(
      'div',
      { class: 'list-row', style: colorVars(hb.color) },
      h('div', { class: 'list-name', onclick: () => openHabit(hb.id) }, h('div', { class: 'tile sm' }, hb.emoji), h('span', null, hb.name)),
      h('div', { class: 'days' }, cells)
    );
  });

  return h('div', null, h('div', { class: 'list' }, head, rows), h('p', { class: 'muted-note' }, 'اضغط مطولًا على أي يوم لإضافة ملاحظة'));
}

/* ---------- الصفحات المنبثقة ---------- */
function openSheet({ title, render, isStatic = false, onClose }) {
  const body = h('div', { class: 'sheet-body' });
  const titleEl = h('h2', { class: 'sheet-title' }, title || '');
  const extra = h('div', { class: 'sheet-spacer' });
  const s = { body, render, isStatic, titleEl, extra };
  const close = () => {
    el.classList.remove('open');
    setTimeout(() => el.remove(), 320);
    const i = sheets.indexOf(s);
    if (i >= 0) sheets.splice(i, 1);
    if (!sheets.length) document.body.classList.remove('locked');
    onClose && onClose();
  };
  const el = h(
    'section',
    { class: 'sheet', role: 'dialog', 'aria-modal': 'true' },
    h(
      'div',
      { class: 'sheet-head' },
      h('div', { class: 'grabber' }),
      h(
        'div',
        { class: 'sheet-title-row' },
        h('button', { class: 'icon-btn', 'aria-label': 'إغلاق', html: ic('x'), onclick: close }),
        titleEl,
        extra
      )
    ),
    body
  );
  s.el = el;
  s.close = close;
  s.refresh = () => {
    const st = body.scrollTop;
    const out = render(s);
    if (out === null) return close();
    body.replaceChildren(h('div', { class: 'sheet-inner' }, out));
    body.scrollTop = st;
  };
  sheets.push(s);
  document.body.append(el);
  document.body.classList.add('locked');
  s.refresh();
  requestAnimationFrame(() => requestAnimationFrame(() => el.classList.add('open')));

  // سحب للأسفل للإغلاق
  let y0 = null;
  el.querySelector('.sheet-head').addEventListener('touchstart', (e) => (y0 = e.touches[0].clientY), { passive: true });
  el.querySelector('.sheet-head').addEventListener('touchend', (e) => {
    if (y0 !== null && e.changedTouches[0].clientY - y0 > 70) close();
    y0 = null;
  });
  return s;
}

/* ---------- صفحة العادة ---------- */
function openHabit(id) {
  let month = new Date(today().getFullYear(), today().getMonth(), 1);
  const s = openSheet({
    title: '',
    render: (sh) => {
      const hb = findHabit(id);
      if (!hb) return null;
      sh.extra.replaceChildren(
        h('button', { class: 'icon-btn', 'aria-label': 'تعديل', html: ic('edit'), onclick: () => openEditor(hb.id) })
      );
      return habitDetail(hb, month, (m) => {
        month = m;
        sh.refresh();
      });
    },
  });
  return s;
}

function habitDetail(hb, month, setMonth) {
  const st = computeStats(hb);
  const tk = todayKey();
  const wrap = h('div', { style: colorVars(hb.color) });

  wrap.append(
    h(
      'div',
      { class: 'detail-head' },
      h('div', { class: 'tile lg' }, hb.emoji),
      h(
        'div',
        { style: 'flex:1;min-width:0' },
        h('h2', null, hb.name),
        h('p', null, hb.desc || goalLabel(hb))
      ),
      todayButton(hb)
    )
  );

  if (hb.atomic.identity) wrap.append(h('div', { class: 'identity' }, '🪪 ', h('b', null, hb.atomic.identity)));

  wrap.append(h('div', { class: 'panel' }, heatmap(hb, { weeks: fitWeeks(contentWidth() - 28 + 3, 12.5) })));

  const pills = h('div', { class: 'pills' });
  if (hb.type === 'quit') {
    const n = cleanDays(hb);
    pills.append(h('span', { class: 'pill', html: `${ic('shield')}${n} يوم بدون` }));
    pills.append(h('span', { class: 'pill', html: `${ic('star')}أفضل: ${st.best}` }));
  } else {
    pills.append(h('span', { class: 'pill', html: `${ic('flame')}${st.cur}` }));
    pills.append(h('span', { class: 'pill', html: `${ic('target')}${goalLabel(hb)}` }));
    pills.append(h('span', { class: 'pill', html: `${ic('star')}أفضل: ${st.best}` }));
  }
  pills.append(h('span', { class: 'pill', html: `${ic('percent')}${st.rate}%` }));
  wrap.append(pills);

  wrap.append(calendar(hb, month, setMonth));

  // الملاحظات
  const notes = Object.entries(hb.notes).sort((a, b) => (a[0] < b[0] ? 1 : -1));
  const notesPanel = h(
    'div',
    { class: 'panel' },
    h(
      'div',
      { class: 'panel-title' },
      h('span', { html: ic('note') }),
      h('span', { class: 'grow' }, 'ملاحظات'),
      h('button', { class: 'icon-btn sm', 'aria-label': 'ملاحظة اليوم', html: ic('plus'), onclick: () => noteBox(hb, tk) })
    ),
    notes.length
      ? notes.map(([k, v]) =>
          h(
            'div',
            { class: `note-item${k === tk ? ' today' : ''}`, onclick: () => noteBox(hb, k) },
            h('div', { class: 'when' }, k === tk ? 'اليوم' : fmtDate(parseKey(k))),
            h('div', { class: 'txt' }, v)
          )
        )
      : h('p', { class: 'hint', style: 'margin:0' }, 'لا توجد ملاحظات بعد. ما الذي سار جيدًا؟ وما الذي اعترض طريقك؟')
  );
  wrap.append(notesPanel);

  // خطة العادات الذرية
  const laws = LAWS[hb.type];
  const items = [];
  for (const law of laws) for (const [key, label] of law.fields) if (hb.atomic[key]) items.push([law.title, label, hb.atomic[key]]);
  wrap.append(
    h(
      'div',
      { class: 'panel' },
      h('div', { class: 'panel-title' }, h('span', { html: ic('atom') }), h('span', { class: 'grow' }, hb.type === 'quit' ? 'خطة الإقلاع' : 'خطة العادة الذرية')),
      items.length
        ? items.map(([law, label, v]) =>
            h('div', { class: 'plan-item' }, h('div', { class: 'k' }, `${law} · ${label}`), h('div', { class: 'v' }, v))
          )
        : h('p', { class: 'hint', style: 'margin:0 0 10px' }, 'لم تكتب خطتك بعد. العادات التي لها «متى وأين» واضحان تنجح أكثر بكثير.'),
      h('button', { class: 'btn ghost sm', style: 'margin-top:8px', onclick: () => openEditor(hb.id, null, true), html: `${ic('edit')}<span>${items.length ? 'تعديل الخطة' : 'اكتب خطتك'}</span>` })
    )
  );

  wrap.append(
    h(
      'div',
      { class: 'btn-row', style: 'margin-top:6px' },
      h('button', {
        class: 'btn ghost',
        html: `${ic('archive')}<span>أرشفة</span>`,
        onclick: async () => {
          if (await confirmBox('أرشفة العادة؟', 'ستختفي من الشاشة الرئيسية مع الاحتفاظ بكل سجلها. يمكنك استعادتها من الإعدادات.', 'أرشفة')) {
            hb.archived = true;
            commit();
            toast('تمت الأرشفة', '🗂️');
          }
        },
      }),
      h('button', {
        class: 'btn danger',
        html: `${ic('trash')}<span>حذف</span>`,
        onclick: async () => {
          if (await confirmBox('حذف العادة نهائيًا؟', 'سيُحذف كل سجلها وملاحظاتها ولا يمكن التراجع.', 'حذف', true)) {
            state.habits = state.habits.filter((x) => x.id !== hb.id);
            commit();
          }
        },
      })
    )
  );
  return wrap;
}

function calendar(hb, month, setMonth) {
  const ws = state.settings.weekStart;
  const tk = todayKey();
  const y = month.getFullYear();
  const m = month.getMonth();
  const first = new Date(y, m, 1);
  const offset = (first.getDay() - ws + 7) % 7;
  const gridStart = addDays(first, -offset);
  const lastDay = new Date(y, m + 1, 0);
  const cellsCount = Math.ceil((offset + lastDay.getDate()) / 7) * 7;

  const head = h('div', { class: 'cal-head' });
  for (let i = 0; i < 7; i++) head.append(h('span', null, DAYS_MID[(ws + i) % 7]));

  const grid = h('div', { class: 'cal-grid' });
  for (let i = 0; i < cellsCount; i++) {
    const d = addDays(gridStart, i);
    const k = keyOf(d);
    const s = dayState(hb, k, tk);
    let cls = 'cal-d';
    cls += d.getMonth() === m ? ' in' : ' out';
    if (k > tk) cls += ' future';
    else if (s.slip) cls += ' slip';
    else if (s.fill >= 1) cls += ' done';
    else if (s.fill > 0) cls += ' part';
    if (k === tk) cls += ' today';
    const showDot = !s.na && (s.slip || s.fill > 0);
    const cell = h(
      'button',
      { class: cls, 'aria-label': fmtDate(d) },
      hb.notes[k] && h('span', { class: 'note-dot' }),
      h('span', null, d.getDate()),
      showDot ? h('i') : h('i', { style: 'visibility:hidden' })
    );
    grid.append(pressable(cell, () => tapDay(hb, k), () => noteBox(hb, k)));
  }

  const nav = h(
    'div',
    { class: 'cal-nav' },
    h('div', { class: 'month', html: `${ic('calendar')}<span>${MONTHS[m]} ${y}</span>` }),
    h('button', { class: 'icon-btn sm', 'aria-label': 'الشهر السابق', html: ic('right'), onclick: () => setMonth(new Date(y, m - 1, 1)) }),
    h('button', {
      class: 'icon-btn sm',
      'aria-label': 'الشهر التالي',
      html: ic('left'),
      onclick: () => {
        const nx = new Date(y, m + 1, 1);
        if (nx <= today()) setMonth(nx);
      },
    })
  );

  return h(
    'div',
    { class: 'panel' },
    head,
    grid,
    nav,
    h('p', { class: 'muted-note' }, hb.type === 'quit' ? 'اضغط على يوم لتسجيل زلّة أو إلغائها · اضغط مطولًا لإضافة ملاحظة' : 'اضغط على يوم لتسجيله · اضغط مطولًا لإضافة ملاحظة')
  );
}

/* ---------- محرر العادة ---------- */
function openEditor(id, presetType, focusPlan = false) {
  const existing = id ? findHabit(id) : null;
  const draft = existing
    ? JSON.parse(JSON.stringify(existing))
    : normalizeHabit({ type: presetType || 'build', color: COLORS[activeHabits().length % COLORS.length] });

  const s = openSheet({ title: existing ? 'تعديل العادة' : 'عادة جديدة', isStatic: true, render: () => form() });

  function rerender() {
    const st = s.body.scrollTop;
    s.body.replaceChildren(h('div', { class: 'sheet-inner' }, form()));
    s.body.scrollTop = st;
  }

  function applyPreset(p) {
    Object.assign(draft, {
      name: p.name,
      desc: p.desc || '',
      emoji: p.emoji,
      color: p.color,
      goal: p.goal || 1,
      unit: p.unit || '',
      atomic: { ...p.atomic },
    });
    rerender();
  }

  function input(key, placeholder, obj = draft, extra = {}) {
    const el = h('input', { class: 'input', placeholder, value: obj[key] || '', ...extra });
    el.addEventListener('input', () => (obj[key] = el.value));
    return el;
  }

  function lawField([key, label, placeholder]) {
    const ta = h('textarea', { class: 'textarea', placeholder, style: 'min-height:64px' });
    ta.value = draft.atomic[key] || '';
    ta.addEventListener('input', () => (draft.atomic[key] = ta.value));
    return h('div', { class: 'field' }, h('label', null, label), ta);
  }

  function form() {
    const c = draft.color;
    const out = h('div', { style: colorVars(c) });

    out.append(
      h(
        'div',
        { class: 'field' },
        h(
          'div',
          { class: 'seg' },
          [
            ['build', '✨ عادة أبنيها'],
            ['quit', '🚫 عادة أتركها'],
          ].map(([t, label]) =>
            h('button', {
              class: draft.type === t ? 'on' : '',
              onclick: () => {
                if (draft.type === t) return;
                draft.type = t;
                rerender();
              },
            }, label)
          )
        ),
        h('p', { class: 'hint' }, draft.type === 'quit'
          ? 'كل يوم يُحسب نظيفًا تلقائيًا، وأنت تسجّل الزلّات فقط. هدفك سلسلة أطول بدون.'
          : 'سجّل إنجازك كل يوم، وشاهد المربعات تمتلئ مثل GitHub.')
      )
    );

    if (!existing) {
      out.append(
        h('div', { class: 'field' },
          h('label', null, 'اقتراحات سريعة'),
          h('div', { class: 'chips' }, PRESETS[draft.type].map((p) =>
            h('button', { class: `chip${draft.name === p.name ? ' on' : ''}`, onclick: () => applyPreset(p) }, `${p.emoji} ${p.name}`)
          ))
        )
      );
    }

    out.append(
      h('div', { class: 'field' }, h('label', null, 'الاسم'), input('name', draft.type === 'quit' ? 'مثال: ترك التدخين' : 'مثال: قراءة 20 صفحة', draft, { maxlength: 40 })),
      h('div', { class: 'field' }, h('label', null, 'وصف قصير'), input('desc', 'اختياري', draft, { maxlength: 60 }))
    );

    // الرمز
    const emojiGrid = h('div', { class: 'emoji-grid' });
    for (const e of EMOJIS) {
      const b = h('button', {
        class: draft.emoji === e ? 'on' : '',
        onclick: () => {
          draft.emoji = e;
          emojiGrid.querySelectorAll('.on').forEach((x) => x.classList.remove('on'));
          b.classList.add('on');
        },
      }, e);
      emojiGrid.append(b);
    }
    out.append(h('div', { class: 'field' }, h('label', null, 'الرمز'), emojiGrid));

    // اللون
    out.append(
      h('div', { class: 'field' },
        h('label', null, 'اللون'),
        h('div', { class: 'color-grid' }, COLORS.map((col) =>
          h('button', {
            class: draft.color === col ? 'on' : '',
            style: `background:${col}`,
            'aria-label': col,
            onclick: () => {
              draft.color = col;
              rerender();
            },
          })
        ))
      )
    );

    if (draft.type === 'build') {
      const num = h('span', { class: 'num' }, draft.goal);
      const setGoal = (v) => {
        draft.goal = Math.max(1, Math.min(999, v));
        num.textContent = draft.goal;
      };
      out.append(
        h('div', { class: 'field' },
          h('label', null, 'الهدف اليومي'),
          h('div', { class: 'two' },
            h('div', { class: 'stepper' },
              h('button', { class: 'icon-btn', html: ic('minus'), 'aria-label': 'إنقاص', onclick: () => setGoal(draft.goal - 1) }),
              num,
              h('button', { class: 'icon-btn', html: ic('plus'), 'aria-label': 'زيادة', onclick: () => setGoal(draft.goal + 1) })
            ),
            input('unit', 'الوحدة: كوب، صفحة…', draft, { maxlength: 14 })
          ),
          h('p', { class: 'hint' }, 'إذا كان الهدف أكثر من 1، كل ضغطة تضيف واحدًا حتى يكتمل اليوم.')
        )
      );
    } else {
      const di = h('input', { class: 'input', type: 'date', value: draft.start, max: todayKey() });
      di.addEventListener('change', () => di.value && (draft.start = di.value));
      out.append(h('div', { class: 'field' }, h('label', null, 'بدأت الإقلاع منذ'), di, h('p', { class: 'hint' }, 'تُحسب الأيام النظيفة من هذا التاريخ.')));
    }

    // العادات الذرية
    const laws = LAWS[draft.type];
    out.append(h('div', { class: 'section-label', style: 'margin-top:20px' }, draft.type === 'quit' ? '⚛️ القوانين المعكوسة للتخلص من العادة' : '⚛️ قوانين العادات الذرية الأربعة'));
    out.append(lawField(IDENTITY_FIELD));
    laws.forEach((law, i) => {
      const filled = law.fields.some(([k]) => draft.atomic[k]);
      out.append(
        h('details', { class: 'law', open: focusPlan || filled ? true : null },
          h('summary', null, h('span', { class: 'n' }, i + 1), law.title, h('span', { class: 'chev', html: ic('left') })),
          h('div', { class: 'law-body' }, law.fields.map(lawField))
        )
      );
    });

    // التذكيرات
    out.append(h('div', { class: 'section-label' }, '⏰ التذكيرات'));
    const remBox = h('div');
    const drawRem = () => {
      remBox.replaceChildren(
        ...draft.reminders.map((r, i) => {
          const time = h('input', { class: 'input', type: 'time', value: r.time });
          time.addEventListener('change', () => (r.time = time.value || r.time));
          return h('div', { class: 'reminder' },
            h('div', { class: 'reminder-top' },
              h('strong', { style: 'font-size:13px' }, `تذكير #${i + 1}`),
              time,
              h('button', { class: 'icon-btn sm', html: ic('trash'), 'aria-label': 'حذف التذكير', onclick: () => { draft.reminders.splice(i, 1); drawRem(); } })
            ),
            h('div', { class: 'weekday-pick' }, [0, 1, 2, 3, 4, 5, 6].map((i) => {
              const idx = (state.settings.weekStart + i) % 7;
              return h('button', {
                class: r.days.includes(idx) ? 'on' : '',
                onclick: (e) => {
                  r.days = r.days.includes(idx) ? r.days.filter((x) => x !== idx) : [...r.days, idx];
                  e.currentTarget.classList.toggle('on');
                },
              }, DAYS_MID[idx]);
            }))
          );
        }),
        draft.reminders.length < 5
          ? h('button', { class: 'btn ghost block sm', html: `${ic('plus')}<span>إضافة تذكير</span>`, onclick: () => { draft.reminders.push({ time: '08:00', days: [0, 1, 2, 3, 4, 5, 6] }); drawRem(); } })
          : '',
        h('p', { class: 'hint' }, 'بعد الحفظ، استخدم «أضف التذكيرات إلى التقويم» من الإعدادات لتصلك تنبيهات iPhone في وقتها.')
      );
    };
    drawRem();
    out.append(remBox);

    out.append(
      h('div', { class: 'sheet-footer' },
        h('button', { class: 'btn block', onclick: submit, html: `${ic('check')}<span>${existing ? 'حفظ التغييرات' : 'إضافة العادة'}</span>` })
      )
    );
    return out;
  }

  function submit() {
    draft.name = (draft.name || '').trim();
    if (!draft.name) {
      toast('اكتب اسمًا للعادة أولًا', '✏️');
      return;
    }
    for (const k of Object.keys(draft.atomic)) {
      draft.atomic[k] = (draft.atomic[k] || '').trim();
      if (!draft.atomic[k]) delete draft.atomic[k];
    }
    const clean = normalizeHabit(draft);
    if (existing) Object.assign(existing, clean);
    else state.habits.push(clean);
    s.close();
    commit();
    if (!existing) toast(draft.type === 'quit' ? 'بدأت رحلة الإقلاع. يومًا بيوم.' : 'أضيفت العادة. ابدأ صغيرًا!', clean.emoji);
  }

  return s;
}

/* ---------- الإحصاءات ---------- */
function openStats(initialId = 'all') {
  let sel = initialId;
  let year = today().getFullYear();
  openSheet({
    title: 'الإحصاءات',
    render: (sh) => {
      const habits = activeHabits();
      if (!habits.length) return h('div', { class: 'empty' }, h('div', { class: 'big' }, '📊'), h('p', null, 'أضف عادة لترى إحصاءاتك هنا.'));
      if (sel !== 'all' && !findHabit(sel)) sel = 'all';
      const out = h('div');
      out.append(
        h('div', { class: 'chips', style: 'margin-bottom:12px' },
          h('button', { class: `chip${sel === 'all' ? ' on' : ''}`, onclick: () => { sel = 'all'; sh.refresh(); } }, 'الكل'),
          habits.map((hb) =>
            h('button', { class: `chip${sel === hb.id ? ' on' : ''}`, style: colorVars(hb.color), onclick: () => { sel = hb.id; sh.refresh(); } }, hb.emoji, ' ', hb.name)
          )
        )
      );
      out.append(
        h('div', { class: 'year-nav' },
          h('button', { class: 'icon-btn sm', html: ic('right'), 'aria-label': 'السنة السابقة', onclick: () => { year--; sh.refresh(); } }),
          h('span', null, year),
          h('button', { class: 'icon-btn sm', html: ic('left'), 'aria-label': 'السنة التالية', onclick: () => { if (year < today().getFullYear()) { year++; sh.refresh(); } } })
        )
      );
      out.append(sel === 'all' ? statsAll(habits, year) : statsOne(findHabit(sel), year));
      return out;
    },
  });
}

function yearEnd(year) {
  const t = today();
  return year >= t.getFullYear() ? t : new Date(year, 11, 31);
}

function yearWeeks(year) {
  const end = yearEnd(year);
  const start = new Date(year, 0, 1);
  return Math.ceil((daysBetween(start, end) + 7) / 7) + 1;
}

function statTile(icon, val, unit, label, style = '') {
  return h('div', { class: 'stat', style },
    h('div', { class: 'ico', html: ic(icon) }),
    h('div', { class: 'val' }, val, unit && h('small', null, ' ', unit)),
    h('div', { class: 'lbl' }, label)
  );
}

function monthChart(values, color, year) {
  const W = 320;
  const H = 120;
  const max = Math.max(1, ...values);
  const lastMonth = year === today().getFullYear() ? today().getMonth() : 11;
  const pts = values.slice(0, lastMonth + 1).map((v, i) => [W - (i / 11) * W, H - (v / max) * (H - 10) - 4]);
  const line = pts.map((p, i) => `${i ? 'L' : 'M'}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(' ');
  const area = pts.length ? `${line} L${pts[pts.length - 1][0].toFixed(1)},${H} L${W},${H} Z` : '';
  const gid = `g${Math.random().toString(36).slice(2, 7)}`;
  let grid = '';
  for (let i = 0; i < 12; i++) grid += `<line x1="${W - (i / 11) * W}" y1="0" x2="${W - (i / 11) * W}" y2="${H}" stroke="#ffffff" stroke-opacity=".05" stroke-dasharray="2 4"/>`;
  const labels = [0, 2, 4, 6, 8, 10]
    .map((i) => `<text x="${W - (i / 11) * W}" y="${H + 16}" fill="#8d8d96" font-size="10" text-anchor="middle">${MONTHS[i]}</text>`)
    .join('');
  const dots = pts.map((p) => `<circle cx="${p[0]}" cy="${p[1]}" r="2.6" fill="${color}"/>`).join('');
  return h('div', {
    class: 'chart',
    html: `<svg viewBox="-6 -6 ${W + 12} ${H + 28}"><defs><linearGradient id="${gid}" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="${color}" stop-opacity=".45"/><stop offset="1" stop-color="${color}" stop-opacity="0"/></linearGradient></defs>${grid}<line x1="0" y1="${H}" x2="${W}" y2="${H}" stroke="#ffffff" stroke-opacity=".15"/>${area ? `<path d="${area}" fill="url(#${gid})"/><path d="${line}" fill="none" stroke="${color}" stroke-width="2.2" stroke-linejoin="round"/>` : ''}${dots}${labels}</svg>`,
  });
}

function statsOne(hb, year) {
  const st = computeStats(hb, year);
  const out = h('div', { style: colorVars(hb.color) });
  out.append(
    h('div', { class: 'panel' },
      h('div', { class: 'detail-head', style: 'margin:0 0 12px' },
        h('div', { class: 'tile' }, hb.emoji),
        h('div', null, h('h2', { style: 'font-size:16px' }, hb.name), h('p', null, hb.desc || goalLabel(hb)))
      ),
      heatmap(hb, { weeks: yearWeeks(year), end: yearEnd(year), gap: 2 })
    )
  );
  const totalVal = hb.type === 'build' && hb.goal > 1 ? st.sum : st.done;
  const totalUnit = hb.type === 'build' && hb.goal > 1 ? hb.unit || 'مرة' : 'يوم';
  out.append(
    h('div', { class: 'stats-grid' },
      statTile('hash', totalVal, totalUnit, hb.type === 'quit' ? 'أيام نظيفة' : 'إتمامات'),
      statTile('percent', st.rate, '%', 'معدل الإنجاز')
    )
  );
  const months = new Array(12).fill(0);
  const tk = todayKey();
  for (let d = new Date(year, 0, 1); d.getFullYear() === year && keyOf(d) <= tk; d = addDays(d, 1)) {
    if (isDone(hb, keyOf(d), tk)) months[d.getMonth()]++;
  }
  out.append(
    h('div', { class: 'panel' },
      h('div', { class: 'panel-title' }, h('span', { html: ic('trend') }), h('span', { class: 'grow' }, hb.type === 'quit' ? 'أيام نظيفة / شهر' : 'الإنجازات / شهر')),
      monthChart(months, hb.color, year)
    )
  );
  out.append(
    h('div', { class: 'stats-grid' },
      statTile(hb.type === 'quit' ? 'shield' : 'flame', hb.type === 'quit' ? cleanDays(hb) : st.cur, 'يوم', 'السلسلة الحالية'),
      statTile('star', st.best, 'يوم', 'أفضل سلسلة')
    )
  );
  return out;
}

function statsAll(habits, year) {
  const tk = todayKey();
  const accent = '#8b7cf6';
  const frac = (k) => {
    let act = 0;
    let done = 0;
    for (const hb of habits) {
      if (k < effectiveStart(hb)) continue;
      act++;
      if (isDone(hb, k, tk)) done++;
    }
    return act ? done / act : 0;
  };
  const out = h('div', { style: colorVars(accent) });
  out.append(h('div', { class: 'panel' }, heatmap(null, { weeks: yearWeeks(year), end: yearEnd(year), gap: 2, aggregate: frac, color: accent })));

  let totalDone = 0;
  let totalPossible = 0;
  const months = new Array(12).fill(0);
  for (let d = new Date(year, 0, 1); d.getFullYear() === year && keyOf(d) <= tk; d = addDays(d, 1)) {
    const k = keyOf(d);
    for (const hb of habits) {
      if (k < effectiveStart(hb)) continue;
      totalPossible++;
      if (isDone(hb, k, tk)) {
        totalDone++;
        months[d.getMonth()]++;
      }
    }
  }
  const todayDone = habits.filter((hb) => isDone(hb, tk, tk)).length;
  const bestStreak = habits.reduce((m, hb) => Math.max(m, computeStats(hb).best), 0);
  out.append(
    h('div', { class: 'stats-grid' },
      statTile('check', `${todayDone}/${habits.length}`, '', 'إنجاز اليوم'),
      statTile('percent', totalPossible ? Math.round((totalDone / totalPossible) * 100) : 0, '%', 'معدل الإنجاز')
    ),
    h('div', { class: 'panel' },
      h('div', { class: 'panel-title' }, h('span', { html: ic('trend') }), h('span', { class: 'grow' }, 'الإنجازات / شهر')),
      monthChart(months, accent, year)
    ),
    h('div', { class: 'stats-grid' },
      statTile('hash', totalDone, '', 'إجمالي الإتمامات'),
      statTile('star', bestStreak, 'يوم', 'أطول سلسلة')
    )
  );

  // ترتيب العادات حسب الالتزام
  const ranked = habits.map((hb) => [hb, computeStats(hb, year)]).sort((a, b) => b[1].rate - a[1].rate);
  out.append(
    h('div', { class: 'group' },
      ranked.map(([hb, st]) =>
        h('button', { class: 'row', style: colorVars(hb.color), onclick: () => openStats(hb.id) },
          h('div', { class: 'tile sm' }, hb.emoji),
          h('div', { class: 'row-label' }, hb.name, h('small', null, hb.type === 'quit' ? `${cleanDays(hb)} يوم بدون` : `السلسلة ${st.cur} · الأفضل ${st.best}`)),
          h('div', { class: 'row-value' }, `${st.rate}%`)
        )
      )
    )
  );
  return out;
}

/* ---------- الإعدادات ---------- */
function settingsRow(icon, color, label, onclick, value) {
  return h('button', { class: 'row', onclick },
    h('div', { class: 'row-icon', style: `background:${mix(color, SURFACE, 0.2)};color:${color}`, html: ic(icon) }),
    h('div', { class: 'row-label' }, label),
    h('div', { class: 'row-value' }, value || '', h('span', { html: ic('left') }))
  );
}

function openSettings() {
  openSheet({
    title: 'الإعدادات',
    render: () => {
      const archived = state.habits.filter((x) => x.archived).length;
      const remCount = state.habits.reduce((n, x) => n + (x.archived ? 0 : x.reminders.length), 0);
      return h('div', null,
        h('div', { class: 'section-label' }, 'التطبيق'),
        h('div', { class: 'group' },
          settingsRow('sliders', '#f472b6', 'عام', openGeneral),
          settingsRow('bell', '#5ed0ea', 'التذكيرات', openReminders, remCount ? `${remCount}` : ''),
          settingsRow('archive', '#34d399', 'العادات المؤرشفة', openArchived, archived ? `${archived}` : ''),
          settingsRow('cloud', '#5aa9f5', 'النسخ والاستعادة', openBackup, state.settings.lastBackup ? h('span', { style: 'display:flex;align-items:center;gap:6px' }, h('span', { class: 'dot-ok' }), 'تم') : ''),
          settingsRow('sort', '#f07178', 'أعد ترتيب العادات', openReorder)
        ),
        h('div', { class: 'section-label' }, 'مساعدة'),
        h('div', { class: 'group' },
          settingsRow('atom', '#a78bfa', 'دليل العادات الذرية', openGuide),
          settingsRow('book', '#f59e4a', 'إظهار المقدمة', () => showIntro(true))
        ),
        h('div', { class: 'section-label' }, 'حول التطبيق'),
        h('div', { class: 'group' },
          h('div', { class: 'row' },
            h('div', { class: 'row-icon', style: `background:${mix('#94a3b8', SURFACE, 0.2)};color:#94a3b8`, html: ic('info') }),
            h('div', { class: 'row-label' }, 'أثر', h('small', null, 'بياناتك محفوظة على جهازك فقط، بلا حساب ولا إعلانات.')),
            h('div', { class: 'row-value' }, `v${APP_VERSION}`)
          )
        )
      );
    },
  });
}

function openGeneral() {
  openSheet({
    title: 'عام',
    render: (sh) => {
      const seg = (opts, cur, set) =>
        h('div', { class: 'seg' }, opts.map(([v, label]) => h('button', { class: cur === v ? 'on' : '', onclick: () => { set(v); commit(); } }, label)));
      return h('div', null,
        h('div', { class: 'field' }, h('label', null, 'بداية الأسبوع'),
          seg([[6, 'السبت'], [0, 'الأحد'], [1, 'الاثنين']], state.settings.weekStart, (v) => (state.settings.weekStart = v))),
        h('div', { class: 'field' }, h('label', null, 'عدد الأيام في عرض القائمة'),
          seg([[4, '4'], [5, '5'], [7, '7']], state.settings.listDays, (v) => (state.settings.listDays = v))),
        h('div', { class: 'field' }, h('label', null, 'بطاقة الاقتباس اليومي'),
          seg([[false, 'إظهار'], [true, 'إخفاء']], !!state.settings.tipClosed, (v) => (state.settings.tipClosed = v)))
      );
    },
  });
}

function openArchived() {
  openSheet({
    title: 'العادات المؤرشفة',
    render: () => {
      const list = state.habits.filter((x) => x.archived);
      if (!list.length) return h('div', { class: 'empty' }, h('div', { class: 'big' }, '🗂️'), h('p', null, 'لا توجد عادات مؤرشفة.'));
      return h('div', { class: 'group' },
        list.map((hb) =>
          h('div', { class: 'row', style: colorVars(hb.color) },
            h('div', { class: 'tile sm' }, hb.emoji),
            h('div', { class: 'row-label' }, hb.name),
            h('button', { class: 'icon-btn sm', html: ic('restore'), 'aria-label': 'استعادة', onclick: () => { hb.archived = false; commit(); toast('استُعيدت العادة', hb.emoji); } }),
            h('button', {
              class: 'icon-btn sm',
              html: ic('trash'),
              'aria-label': 'حذف',
              onclick: async () => {
                if (await confirmBox('حذف نهائي؟', `سيُحذف «${hb.name}» مع كل سجله.`, 'حذف', true)) {
                  state.habits = state.habits.filter((x) => x.id !== hb.id);
                  commit();
                }
              },
            })
          )
        )
      );
    },
  });
}

function openReorder() {
  openSheet({
    title: 'ترتيب العادات',
    render: () => {
      const list = activeHabits();
      if (!list.length) return h('p', { class: 'hint' }, 'لا توجد عادات بعد.');
      const move = (hb, dir) => {
        const arr = state.habits;
        const act = arr.filter((x) => !x.archived);
        const i = act.indexOf(hb);
        const j = i + dir;
        if (j < 0 || j >= act.length) return;
        const a = arr.indexOf(act[i]);
        const b = arr.indexOf(act[j]);
        [arr[a], arr[b]] = [arr[b], arr[a]];
        commit();
      };
      return h('div', { class: 'group' },
        list.map((hb, i) =>
          h('div', { class: 'reorder-row', style: colorVars(hb.color) },
            h('div', { class: 'tile sm' }, hb.emoji),
            h('div', { class: 'name' }, hb.name),
            h('button', { class: 'icon-btn sm', html: ic('up'), 'aria-label': 'لأعلى', disabled: i === 0 ? true : null, style: i === 0 ? 'opacity:.3' : '', onclick: () => move(hb, -1) }),
            h('button', { class: 'icon-btn sm', html: ic('down'), 'aria-label': 'لأسفل', disabled: i === list.length - 1 ? true : null, style: i === list.length - 1 ? 'opacity:.3' : '', onclick: () => move(hb, 1) })
          )
        )
      );
    },
  });
}

/* ---------- الملفات: مشاركة/تنزيل ---------- */
async function deliverFile(name, mime, text) {
  const blob = new Blob([text], { type: mime });
  const file = new File([blob], name, { type: mime });
  if (navigator.canShare && navigator.canShare({ files: [file] })) {
    try {
      await navigator.share({ files: [file], title: name });
      return true;
    } catch (e) {
      if (e.name === 'AbortError') return false;
    }
  }
  const url = URL.createObjectURL(blob);
  const a = h('a', { href: url, download: name });
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 4000);
  return true;
}

function openBackup() {
  openSheet({
    title: 'النسخ والاستعادة',
    render: () => {
      const fileIn = h('input', { type: 'file', accept: '.json,application/json', style: 'display:none' });
      fileIn.addEventListener('change', async () => {
        const f = fileIn.files[0];
        if (!f) return;
        try {
          const data = JSON.parse(await f.text());
          if (!Array.isArray(data.habits)) throw new Error('bad');
          if (!(await confirmBox('استعادة النسخة؟', `ستُستبدل بياناتك الحالية بـ ${data.habits.length} عادة من الملف.`, 'استعادة', true))) return;
          const d = defaultState();
          state = { ...d, ...data, settings: { ...d.settings, ...(data.settings || {}), introSeen: true }, habits: data.habits.map(normalizeHabit) };
          commit();
          toast('تمت الاستعادة بنجاح', '✅');
        } catch (e) {
          toast('الملف غير صالح', '⚠️');
        }
      });
      const last = state.settings.lastBackup;
      return h('div', null,
        h('p', { class: 'hint', style: 'margin:0 4px 14px;font-size:13px' },
          'بياناتك محفوظة على هذا الجهاز فقط. صدّر نسخة احتياطية بين حين وآخر واحفظها في «الملفات» أو iCloud Drive، لتنقلها لجهاز آخر أو تستعيدها عند الحاجة.'),
        h('div', { class: 'group' },
          settingsRow('download', '#5aa9f5', 'تصدير نسخة احتياطية', async () => {
            const name = `athar-backup-${todayKey()}.json`;
            const ok = await deliverFile(name, 'application/json', JSON.stringify(state, null, 1));
            if (ok) {
              state.settings.lastBackup = Date.now();
              commit();
            }
          }, last ? new Date(last).toLocaleDateString('ar-u-nu-latn') : ''),
          settingsRow('upload', '#34d399', 'استعادة من ملف', () => fileIn.click())
        ),
        fileIn,
        h('div', { class: 'section-label' }, 'منطقة الخطر'),
        h('div', { class: 'group' },
          settingsRow('trash', '#f0616d', 'حذف كل البيانات', async () => {
            if (await confirmBox('حذف كل شيء؟', 'سيُحذف كل العادات والسجلات والملاحظات من هذا الجهاز.', 'حذف الكل', true)) {
              state = { ...defaultState(), settings: { ...defaultState().settings, introSeen: true } };
              commit();
            }
          })
        )
      );
    },
  });
}

/* ---------- التذكيرات عبر تقويم iPhone ---------- */
function icsEscape(s) {
  return String(s).replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\n/g, '\\n');
}

function buildICS(habits) {
  const lines = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//Athar//Habits//AR', 'CALSCALE:GREGORIAN', 'X-WR-CALNAME:أثر · العادات'];
  const now = new Date();
  const stamp = `${now.getUTCFullYear()}${pad(now.getUTCMonth() + 1)}${pad(now.getUTCDate())}T${pad(now.getUTCHours())}${pad(now.getUTCMinutes())}00Z`;
  const t = today();
  const dstr = `${t.getFullYear()}${pad(t.getMonth() + 1)}${pad(t.getDate())}`;
  for (const hb of habits) {
    hb.reminders.forEach((r, i) => {
      if (!r.days.length) return;
      const [hh, mm] = r.time.split(':');
      const body = hb.atomic.cue || hb.atomic.stack || hb.atomic.twoMin || hb.atomic.replacement || hb.desc || '';
      lines.push(
        'BEGIN:VEVENT',
        `UID:${hb.id}-${i}@athar.app`,
        `DTSTAMP:${stamp}`,
        `DTSTART:${dstr}T${hh}${mm}00`,
        'DURATION:PT10M',
        `RRULE:FREQ=WEEKLY;BYDAY=${r.days.slice().sort().map((d) => ICS_DAYS[d]).join(',')}`,
        `SUMMARY:${icsEscape(`${hb.emoji} ${hb.name}`)}`,
        `DESCRIPTION:${icsEscape(body || 'افتح «أثر» وسجّل عادتك')}`,
        'TRANSP:TRANSPARENT',
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        `DESCRIPTION:${icsEscape(hb.name)}`,
        'TRIGGER:PT0M',
        'END:VALARM',
        'END:VEVENT'
      );
    });
  }
  lines.push('END:VCALENDAR');
  return lines.join('\r\n');
}

function openReminders() {
  openSheet({
    title: 'التذكيرات',
    render: () => {
      const withRem = activeHabits().filter((x) => x.reminders.length);
      return h('div', null,
        h('div', { class: 'panel' },
          h('div', { class: 'panel-title' }, h('span', { html: ic('bell') }), 'كيف تعمل التذكيرات؟'),
          h('p', { class: 'hint', style: 'margin:0;font-size:13px' },
            'تطبيقات الويب على iPhone لا تستطيع جدولة تنبيهات محلية بنفسها، لذلك يصدّر «أثر» تذكيراتك كأحداث متكررة في تقويم iPhone مع تنبيه في الوقت المحدد. أضفها مرة واحدة، وأعد التصدير إذا غيّرت الأوقات.')
        ),
        withRem.length
          ? h('div', { class: 'group', style: 'margin-bottom:14px' },
              withRem.map((hb) =>
                h('button', { class: 'row', style: colorVars(hb.color), onclick: () => openEditor(hb.id) },
                  h('div', { class: 'tile sm' }, hb.emoji),
                  h('div', { class: 'row-label' }, hb.name, h('small', null, hb.reminders.map((r) => `${r.time} (${r.days.length === 7 ? 'يوميًا' : r.days.map((d) => DAYS_MID[d]).join('، ')})`).join(' · '))),
                  h('div', { class: 'row-value', html: ic('left') })
                )
              )
            )
          : h('p', { class: 'hint', style: 'margin:0 4px 14px' }, 'لا توجد تذكيرات بعد. افتح أي عادة ← تعديل ← «إضافة تذكير».'),
        withRem.length &&
          h('button', {
            class: 'btn block',
            html: `${ic('calendar')}<span>أضف التذكيرات إلى التقويم</span>`,
            onclick: () => {
              const ics = buildICS(withRem);
              const blob = new Blob([ics], { type: 'text/calendar' });
              const url = URL.createObjectURL(blob);
              // على iPhone يفتح Safari ملف التقويم ويعرض زر «إضافة الكل»
              const a = h('a', { href: url, target: '_blank', rel: 'noopener' });
              document.body.append(a);
              a.click();
              a.remove();
              setTimeout(() => URL.revokeObjectURL(url), 60000);
            },
          }),
        withRem.length &&
          h('button', {
            class: 'btn ghost block',
            style: 'margin-top:10px',
            html: `${ic('share')}<span>مشاركة ملف التقويم</span>`,
            onclick: () => deliverFile('athar-reminders.ics', 'text/calendar', buildICS(withRem)),
          })
      );
    },
  });
}

/* ---------- دليل العادات الذرية ---------- */
function openGuide() {
  openSheet({
    title: 'العادات الذرية',
    render: () =>
      h('div', { class: 'guide' },
        h('p', null, 'من كتاب «العادات الذرية» لجيمس كلير: التغييرات الصغيرة جدًا، عندما تتكرر يوميًا، تصنع نتائج مذهلة. السر ليس في الأهداف بل في الأنظمة.'),
        h('div', { class: 'panel' },
          h('h3', { style: 'margin-top:0' }, '✨ لبناء عادة جيدة'),
          h('ol', null,
            h('li', null, h('b', null, 'اجعلها واضحة: '), 'حدّد متى وأين: «سأقرأ 10 صفحات الساعة 9 مساءً في غرفتي». واستخدم تكديس العادات: «بعد أن أصلي العشاء، سأقرأ».'),
            h('li', null, h('b', null, 'اجعلها جذابة: '), 'اربطها بشيء تحبه، وانضم لأناس يرونها أمرًا طبيعيًا.'),
            h('li', null, h('b', null, 'اجعلها سهلة: '), 'قاعدة الدقيقتين: ابدأ بنسخة لا تتجاوز دقيقتين. أتقن الحضور قبل أن تحسّن الأداء.'),
            h('li', null, h('b', null, 'اجعلها مُرضية: '), 'كافئ نفسك فورًا، وتتبّع عادتك. رؤية المربعات تمتلئ مكافأة بحد ذاتها.')
          )
        ),
        h('div', { class: 'panel' },
          h('h3', { style: 'margin-top:0' }, '🚫 للتخلص من عادة سيئة (القوانين المعكوسة)'),
          h('ol', null,
            h('li', null, h('b', null, 'اجعلها غير مرئية: '), 'أزل المحفزات من بيئتك.'),
            h('li', null, h('b', null, 'اجعلها غير جذابة: '), 'ذكّر نفسك بفوائد تركها وأضرار الاستمرار فيها.'),
            h('li', null, h('b', null, 'اجعلها صعبة: '), 'زِد الخطوات بينك وبينها.'),
            h('li', null, h('b', null, 'اجعلها غير مُرضية: '), 'شريك محاسبة أو عقد مع نفسك يجعل لها ثمنًا فوريًا.')
          ),
          h('p', null, 'ولا تكتفِ بالترك: ضع عادة بديلة تلبي الحاجة نفسها.')
        ),
        h('div', { class: 'panel' },
          h('h3', { style: 'margin-top:0' }, '🪪 العادات المبنية على الهوية'),
          h('p', null, 'بدل «أريد أن أترك التدخين» قل «أنا لست مدخّنًا». كل مرة تنجز عادتك هي صوت للشخص الذي تريد أن تصبحه. اكتب هويتك في كل عادة وسيذكّرك «أثر» بها.')
        ),
        h('div', { class: 'panel' },
          h('h3', { style: 'margin-top:0' }, '🔁 لا تفوّت مرتين'),
          h('p', null, 'الكمال ليس شرطًا. إذا فوّتّ يومًا، عد في اليوم التالي مباشرة. المرة الواحدة حادث، والمرتان بداية نمط جديد.')
        )
      ),
  });
}

/* ---------- المقدمة ---------- */
function demoHabit(color, density) {
  const log = {};
  const t = today();
  let seed = 7;
  for (let i = 0; i < 200; i++) {
    seed = (seed * 9301 + 49297) % 233280;
    if (seed / 233280 < density) log[keyOf(addDays(t, -i))] = 1;
  }
  return { type: 'build', goal: 1, color, log, start: keyOf(addDays(t, -200)), notes: {}, atomic: {} };
}

function showIntro(force = false) {
  if (!force && state.settings.introSeen) return;
  let i = 0;
  const slides = [
    () => h('div', null,
      h('div', { class: 'demo-hm' }, heatmap(demoHabit('#a78bfa', 0.78), { weeks: fitWeeks(Math.min(window.innerWidth, 480) - 76, 12), months: false })),
      h('h2', null, 'شاهد عاداتك', h('br'), h('em', null, 'تؤتي ثمارها.')),
      h('p', null, 'كل مربع يوم. كل يوم تنجز فيه عادتك يمتلئ مربعه، تمامًا مثل لوحة المساهمات في GitHub. مع الوقت ترى تقدمك بعينيك.')
    ),
    () => h('div', null,
      h('div', { class: 'art' }, '⚛️'),
      h('h2', null, 'العادات ', h('em', null, 'الذرية')),
      h('p', null, 'تحسّن 1% كل يوم = 37 ضعفًا في سنة. لكل عادة تضيفها، يساعدك «أثر» على تطبيق القوانين الأربعة:'),
      h('ol', null,
        h('li', null, h('b', null, 'واضحة: '), 'متى وأين ستفعلها؟'),
        h('li', null, h('b', null, 'جذابة: '), 'اربطها بشيء تحبه'),
        h('li', null, h('b', null, 'سهلة: '), 'قاعدة الدقيقتين'),
        h('li', null, h('b', null, 'مُرضية: '), 'كافئ نفسك فورًا')
      )
    ),
    () => h('div', null,
      h('div', { class: 'demo-hm' }, heatmap({ ...demoHabit('#f07178', 0.93), type: 'quit', log: { [keyOf(addDays(today(), -40))]: 1, [keyOf(addDays(today(), -95))]: 1 }, start: keyOf(addDays(today(), -150)) }, { weeks: fitWeeks(Math.min(window.innerWidth, 480) - 76, 12), months: false })),
      h('h2', null, 'عادات نافعة', h('br'), h('em', null, 'بدلًا من الضارة.')),
      h('p', null, 'للعادات التي تريد تركها: كل يوم يُحسب نظيفًا تلقائيًا، وأنت تسجّل الزلّات فقط. حدد محفزاتها، اجعلها صعبة، وضع عادة بديلة.')
    ),
    () => h('div', null,
      h('div', { class: 'art' }, '📲'),
      h('h2', null, 'على شاشتك', h('br'), h('em', null, 'الرئيسية.')),
      h('p', null, 'في Safari اضغط زر المشاركة ⬆️ ثم «إضافة إلى الشاشة الرئيسية». سيعمل «أثر» كتطبيق كامل، وبدون إنترنت.'),
      h('p', null, 'بياناتك تبقى على جهازك. لا حساب ولا إعلانات.')
    ),
  ];
  const root = h('div', { class: 'intro' });
  const draw = () => {
    const last = i === slides.length - 1;
    root.replaceChildren(
      h('div', { style: 'display:flex;justify-content:flex-start' },
        !last ? h('button', { style: 'color:var(--muted);font-size:14px;padding:8px', onclick: finish }, 'تخطّي') : h('span', { style: 'height:36px' })),
      h('div', { class: 'intro-slide' }, slides[i]()),
      h('div', { class: 'intro-dots' }, slides.map((_, j) => h('span', { class: j === i ? 'on' : '' }))),
      h('div', { class: 'intro-actions' },
        h('button', { class: 'btn block', onclick: () => (last ? finish() : (i++, draw())) }, last ? 'ابدأ الآن' : 'التالي')
      )
    );
  };
  const finish = () => {
    state.settings.introSeen = true;
    save();
    root.remove();
  };
  let x0 = null;
  root.addEventListener('touchstart', (e) => (x0 = e.touches[0].clientX), { passive: true });
  root.addEventListener('touchend', (e) => {
    if (x0 === null) return;
    const dx = e.changedTouches[0].clientX - x0;
    // في الواجهة العربية السحب لليمين = التالي
    if (dx > 50 && i < slides.length - 1) (i++, draw());
    else if (dx < -50 && i > 0) (i--, draw());
    x0 = null;
  });
  draw();
  document.body.append(root);
}

/* ---------- التشغيل ---------- */
renderMain();
showIntro();

let lastDay = todayKey();
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible' && todayKey() !== lastDay) {
    lastDay = todayKey();
    commit();
  }
});
setInterval(() => {
  if (todayKey() !== lastDay) {
    lastDay = todayKey();
    commit();
  }
}, 60000);

let resizeT;
window.addEventListener('resize', () => {
  clearTimeout(resizeT);
  resizeT = setTimeout(commit, 150);
});

if ('serviceWorker' in navigator && location.protocol !== 'file:') {
  navigator.serviceWorker.register('sw.js').catch(() => {});
}
