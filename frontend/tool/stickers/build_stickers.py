#!/usr/bin/env python3
"""Builds the nine live-battle stickers as Lottie JSON and Telegram .tgs files.

Source of truth: Paper file "SkillBattles MVP", artboard
"31 Battle stickers - Sticker set", and docs/specs/battle_stickers.md.
All geometry below is copied from the Paper SVG (96 x 96 canvas); only the
motion is added here.

Outputs:
  assets/stickers/<id>.json      96 x 96, 60 fps, for the Flutter app
  docs/stickers/tgs/<id>.tgs     512 x 512, 60 fps, gzipped, for Telegram

Loop stickers have an intro and a loop cycle. Markers in the JSON:
  intro  [0, loop start)      plays once
  loop   [loop start, end]    repeats; its first and last frames match
  settle frame used as the static picker / reduced-motion frame
One-shot stickers end on the settle frame (marker "settle" = last frame).

The .tgs version contains only the loop cycle for loop stickers (Telegram
always loops the whole file), and the whole one-shot plus a short hold on
the settle pose for one-shots.

Usage: python3 tool/stickers/build_stickers.py [--root <repo root>]
"""

import argparse
import gzip
import json
import math
import re
from pathlib import Path

FPS = 60

# AppColors used by the sticker set (spec, "Lottie asset notes").
INK = '#0E0F12'
WHITE = '#FFFFFF'
PRIMARY = '#2B4BF2'
ACCENT = '#F5A524'
DANGER = '#E5484D'
BLUSH = '#F5D9A3'
PRIMARY_LINE = '#DCE2FF'
BORDER = '#E6E7EB'
FAINT = '#A0A3AB'
MUTED = '#6B6F7A'

TUFT = 'M47 19C45 12 49 8 55 10'
BODY = ('M48 18C69 18 82 32 82 53C82 73 68 86 48 86C28 86 14 73 14 53'
        'C14 32 27 18 48 18Z')
BASE = (48, 86)  # the rig pivot: the bottom of the body

EASE = {
    'out': (0.23, 1, 0.32, 1),
    'in': (0.55, 0, 1, 0.45),
    'inout': (0.77, 0, 0.175, 1),
    'swing': (0.37, 0, 0.63, 1),
    'lin': (0.333, 0.333, 0.667, 0.667),
}


# --------------------------------------------------------------------------
# SVG path data -> Lottie bezier shapes
# --------------------------------------------------------------------------

_TOKEN = re.compile(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')


def _arc_to_cubics(x1, y1, rx, ry, phi, large, sweep, x2, y2):
    if rx == 0 or ry == 0:
        return [((x1, y1), (x2, y2), (x2, y2))]
    phi = math.radians(phi)
    cp, sp = math.cos(phi), math.sin(phi)
    dx, dy = (x1 - x2) / 2, (y1 - y2) / 2
    x1p, y1p = cp * dx + sp * dy, -sp * dx + cp * dy
    rx, ry = abs(rx), abs(ry)
    lam = x1p ** 2 / rx ** 2 + y1p ** 2 / ry ** 2
    if lam > 1:
        rx, ry = rx * math.sqrt(lam), ry * math.sqrt(lam)
    num = rx ** 2 * ry ** 2 - rx ** 2 * y1p ** 2 - ry ** 2 * x1p ** 2
    den = rx ** 2 * y1p ** 2 + ry ** 2 * x1p ** 2
    coef = math.sqrt(max(0.0, num / den))
    if large == sweep:
        coef = -coef
    cxp, cyp = coef * rx * y1p / ry, -coef * ry * x1p / rx
    cx = cp * cxp - sp * cyp + (x1 + x2) / 2
    cy = sp * cxp + cp * cyp + (y1 + y2) / 2

    def angle(ux, uy, vx, vy):
        return math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)

    th1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
    dth = angle((x1p - cxp) / rx, (y1p - cyp) / ry,
                (-x1p - cxp) / rx, (-y1p - cyp) / ry)
    if not sweep and dth > 0:
        dth -= 2 * math.pi
    elif sweep and dth < 0:
        dth += 2 * math.pi
    segs = max(1, math.ceil(abs(dth) / (math.pi / 2) - 1e-9))
    delta = dth / segs
    k = 4 / 3 * math.tan(delta / 4)

    def point(a):
        return (cx + rx * math.cos(a) * cp - ry * math.sin(a) * sp,
                cy + rx * math.cos(a) * sp + ry * math.sin(a) * cp)

    def deriv(a):
        return (-rx * math.sin(a) * cp - ry * math.cos(a) * sp,
                -rx * math.sin(a) * sp + ry * math.cos(a) * cp)

    out = []
    for i in range(segs):
        a1, a2 = th1 + i * delta, th1 + (i + 1) * delta
        p1, p2 = point(a1), point(a2)
        d1, d2 = deriv(a1), deriv(a2)
        out.append(((p1[0] + k * d1[0], p1[1] + k * d1[1]),
                    (p2[0] - k * d2[0], p2[1] - k * d2[1]),
                    p2))
    return out


def parse_path(d):
    """Returns a list of Lottie shape values ({c, v, i, o}), one per subpath."""
    toks = _TOKEN.findall(d)
    pos = 0
    subs = []
    cur = None
    x = y = 0.0
    cmd = None
    last_c = None  # last cubic control point (for S)
    last_q = None  # last quadratic control point (for T)

    def num():
        nonlocal pos
        value = float(toks[pos])
        pos += 1
        return value

    def add_vertex(px, py, in_ctrl=None):
        cur['v'].append([px, py])
        cur['in'].append(list(in_ctrl) if in_ctrl else [px, py])
        cur['out'].append([px, py])

    def close():
        cur['c'] = True
        first, last = cur['v'][0], cur['v'][-1]
        if len(cur['v']) > 1 and abs(first[0] - last[0]) < 1e-6 and abs(first[1] - last[1]) < 1e-6:
            cur['in'][0] = cur['in'][-1]
            for key in ('v', 'in', 'out'):
                cur[key].pop()

    while pos < len(toks):
        tok = toks[pos]
        if tok.isalpha():
            cmd = tok
            pos += 1
            if cmd in 'Zz':
                close()
                x, y = cur['v'][0]
                last_c = last_q = None
                continue
        rel = cmd.islower()
        c = cmd.upper()
        ox, oy = (x, y) if rel else (0.0, 0.0)
        if c == 'M':
            x, y = ox + num(), oy + num()
            cur = {'c': False, 'v': [], 'in': [], 'out': []}
            subs.append(cur)
            add_vertex(x, y)
            cmd = 'l' if rel else 'L'
            last_c = last_q = None
            continue
        if c == 'L':
            x, y = ox + num(), oy + num()
            add_vertex(x, y)
            last_c = last_q = None
        elif c == 'H':
            x = ox + num()
            add_vertex(x, y)
            last_c = last_q = None
        elif c == 'V':
            y = oy + num()
            add_vertex(x, y)
            last_c = last_q = None
        elif c in 'CS':
            if c == 'C':
                c1 = (ox + num(), oy + num())
            else:
                c1 = (2 * x - last_c[0], 2 * y - last_c[1]) if last_c else (x, y)
            c2 = (ox + num(), oy + num())
            x, y = ox + num(), oy + num()
            cur['out'][-1] = list(c1)
            add_vertex(x, y, c2)
            last_c, last_q = c2, None
        elif c in 'QT':
            if c == 'Q':
                q = (ox + num(), oy + num())
            else:
                q = (2 * x - last_q[0], 2 * y - last_q[1]) if last_q else (x, y)
            nx, ny = ox + num(), oy + num()
            c1 = (x + 2 / 3 * (q[0] - x), y + 2 / 3 * (q[1] - y))
            c2 = (nx + 2 / 3 * (q[0] - nx), ny + 2 / 3 * (q[1] - ny))
            cur['out'][-1] = list(c1)
            x, y = nx, ny
            add_vertex(x, y, c2)
            last_c, last_q = None, q
        elif c == 'A':
            rx, ry, rot = num(), num(), num()
            large, sweep = int(num()), int(num())
            nx, ny = ox + num(), oy + num()
            for c1, c2, p in _arc_to_cubics(x, y, rx, ry, rot, large, sweep, nx, ny):
                cur['out'][-1] = list(c1)
                add_vertex(p[0], p[1], c2)
            x, y = nx, ny
            last_c = last_q = None
        else:
            raise ValueError(f'unsupported path command {cmd!r} in {d!r}')

    shapes = []
    for s in subs:
        shapes.append({
            'c': s['c'],
            'v': s['v'],
            'i': [[ci[0] - v[0], ci[1] - v[1]] for ci, v in zip(s['in'], s['v'])],
            'o': [[co[0] - v[0], co[1] - v[1]] for co, v in zip(s['out'], s['v'])],
        })
    return shapes


# --------------------------------------------------------------------------
# Properties and keyframes
# --------------------------------------------------------------------------

def rgba(hex_color):
    h = hex_color.lstrip('#')
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)] + [1]


def anim(*kfs):
    """Keyframes: (frame, value, ease) ... (frame, value).

    `ease` shapes the segment that leaves the keyframe; 'hold' keeps the
    value until the next keyframe. Every keyframe but the last carries
    handles, which lottie-web, rlottie and the Flutter player all need.
    """
    out = []
    for n, kf in enumerate(kfs):
        t, value = kf[0], kf[1]
        ease = kf[2] if len(kf) > 2 else None
        is_shape = isinstance(value, dict)
        s = [value] if (is_shape or isinstance(value, (int, float))) else list(value)
        frame = {'t': t, 's': s}
        if n < len(kfs) - 1:
            if ease is None:
                raise ValueError(f'keyframe at {t} needs an ease')
            if ease == 'hold':
                frame['h'] = 1
            else:
                x1, y1, x2, y2 = EASE[ease]
                if is_shape:
                    frame['o'] = {'x': x1, 'y': y1}
                    frame['i'] = {'x': x2, 'y': y2}
                else:
                    frame['o'] = {'x': [x1], 'y': [y1]}
                    frame['i'] = {'x': [x2], 'y': [y2]}
        out.append(frame)
    times = [f['t'] for f in out]
    if times != sorted(times) or len(set(times)) != len(times):
        raise ValueError(f'keyframe times must increase: {times}')
    return {'a': 1, 'k': out}


def xy(value):
    return [value, value] if isinstance(value, (int, float)) else value


def scale_prop(value):
    if isinstance(value, dict):
        return value
    return {'a': 0, 'k': xy(value)}


def num_prop(value):
    if isinstance(value, dict):
        return value
    return {'a': 0, 'k': value}


# --------------------------------------------------------------------------
# Shapes, groups, layers
# --------------------------------------------------------------------------

def P(d):
    return [{'ty': 'sh', 'nm': 'Path', 'ks': {'a': 0, 'k': s}} for s in parse_path(d)]


def morph(*kfs):
    """Path morph between SVG path strings with the same structure."""
    parsed = [(kf[0], parse_path(kf[1])) + tuple(kf[2:]) for kf in kfs]
    count = len(parsed[0][1])
    for kf in parsed:
        if len(kf[1]) != count:
            raise ValueError('morph: subpath counts differ')
        for a, b in zip(kf[1], parsed[0][1]):
            if len(a['v']) != len(b['v']) or a['c'] != b['c']:
                raise ValueError(f'morph: vertex counts differ at frame {kf[0]}')
    items = []
    for idx in range(count):
        items.append({'ty': 'sh', 'nm': 'Path', 'ks': anim(
            *[(kf[0], kf[1][idx]) + tuple(kf[2:]) for kf in parsed])})
    return items


def E(cx, cy, rx, ry=None, p=None, s=None):
    ry = rx if ry is None else ry
    return [{'ty': 'el', 'nm': 'Ellipse', 'd': 1,
             'p': p or {'a': 0, 'k': [cx, cy]},
             's': s or {'a': 0, 'k': [2 * rx, 2 * ry]}}]


def R(x, y, w, h, r):
    return [{'ty': 'rc', 'nm': 'Rect', 'd': 1,
             'p': {'a': 0, 'k': [x + w / 2, y + h / 2]},
             's': {'a': 0, 'k': [w, h]},
             'r': {'a': 0, 'k': r}}]


def tr(a=(0, 0), p=None, s=100, r=0, o=100):
    return {'ty': 'tr', 'nm': 'Transform',
            'a': {'a': 0, 'k': list(a)},
            'p': p if isinstance(p, dict) else {'a': 0, 'k': list(p if p else a)},
            's': scale_prop(s), 'r': num_prop(r), 'o': num_prop(o),
            'sk': {'a': 0, 'k': 0}, 'sa': {'a': 0, 'k': 0}}


def group(name, items, fill=None, stroke=None, width=3, trim=None, t=None):
    """A Lottie group. In `items`, the first entry paints on top."""
    it = []
    for item in items:
        it.extend(item if isinstance(item, list) else [item])
    if trim is not None:
        it.append({'ty': 'tm', 'nm': 'Trim', 's': num_prop(trim.get('s', 0)),
                   'e': num_prop(trim.get('e', 100)), 'o': {'a': 0, 'k': 0}, 'm': 1})
    if stroke is not None:
        it.append({'ty': 'st', 'nm': 'Stroke',
                   'c': stroke if isinstance(stroke, dict) else {'a': 0, 'k': rgba(stroke)},
                   'o': {'a': 0, 'k': 100}, 'w': {'a': 0, 'k': width},
                   'lc': 2, 'lj': 2, 'ml': 4})
    if fill is not None:
        it.append({'ty': 'fl', 'nm': 'Fill',
                   'c': fill if isinstance(fill, dict) else {'a': 0, 'k': rgba(fill)},
                   'o': {'a': 0, 'k': 100}, 'r': 1})
    it.append(t or tr())
    return {'ty': 'gr', 'nm': name, 'np': len(it), 'it': it}


def at(pivot, *kfs):
    """Position keyframes given as offsets from `pivot`."""
    return anim(*[(kf[0], [pivot[0] + kf[1][0], pivot[1] + kf[1][1]]) + tuple(kf[2:])
                  for kf in kfs])


def layer(name, groups, parent=None, a=(0, 0), p=None, s=100, r=0, o=100):
    return {
        'ddd': 0, 'ty': 4, 'nm': name, 'sr': 1, 'ao': 0, 'bm': 0,
        '_parent': parent,
        'ks': {'a': {'a': 0, 'k': list(a)},
               'p': p if isinstance(p, dict) else {'a': 0, 'k': list(p if p else a)},
               's': scale_prop(s), 'r': num_prop(r), 'o': num_prop(o)},
        'shapes': groups if isinstance(groups, list) else [groups],
    }


def comp(name, layers_bottom_to_top, op, markers=()):
    layers = list(reversed(layers_bottom_to_top))  # Lottie: first layer on top
    index = {}
    for n, lyr in enumerate(layers, start=1):
        lyr['ind'] = n
        lyr['ip'], lyr['op'], lyr['st'] = 0, op + 1, 0
        index[lyr['nm']] = n
    for lyr in layers:
        parent = lyr.pop('_parent')
        if parent:
            lyr['parent'] = index[parent]
    return {'v': '5.7.4', 'fr': FPS, 'ip': 0, 'op': op, 'w': 96, 'h': 96,
            'nm': name, 'ddd': 0, 'assets': [], 'layers': layers,
            'markers': [{'tm': tm, 'cm': cm, 'dr': dr} for tm, cm, dr in markers]}


# Shared character parts ----------------------------------------------------

def shadow(s=100, el=None, fill=BORDER):
    geo = el or E(48, 89, 22, 3.5)
    return layer('Shadow', group('Shadow', [geo], fill=fill), a=(48, 89), s=s)


def tuft():
    return layer('Tuft', group('Tuft', [P(TUFT)], stroke=INK), parent='Body')


def body(s=100, r=0, p=None):
    return layer('Body', group('Body', [P(BODY)], fill=WHITE, stroke=INK),
                 a=BASE, p=p or BASE, s=s, r=r)


def show_from(t):
    """Opacity: hidden until frame t, then visible."""
    return anim((0, 0, 'hold'), (t, 100))


def hide_at(t):
    return anim((0, 100, 'hold'), (t, 0))


# --------------------------------------------------------------------------
# The nine stickers
# --------------------------------------------------------------------------

def gg():
    """GG - one-shot 1.4 s. Stretch up, happy eyes, thumb pops with overshoot."""
    op = 84
    rig = anim((0, [106, 94], 'out'), (18, [94, 106], 'swing'), (34, [102, 98], 'out'), (48, [100, 100]))
    ground = anim((0, [109, 100], 'out'), (18, [91, 86], 'swing'), (34, [103, 100], 'out'), (48, [100, 100]))

    def twinkle(t0):
        return anim((t0, [0, 0], 'out'), (t0 + 10, [115, 115], 'swing'), (t0 + 20, [70, 70], 'swing'),
                    (t0 + 30, [112, 112], 'swing'), (t0 + 42, [100, 100]))

    layers = [
        shadow(s=ground),
        tuft(),
        body(s=rig),
        layer('Blush', group('Blush', [E(29, 61, 5, 3), E(65, 61, 5, 3)], fill=BLUSH,
                             t=tr(o=anim((12, 0, 'out'), (30, 100)))), parent='Body'),
        layer('Eyes', [
            group('Happy', [P('M31 51Q36 45 41 51M53 51Q58 45 63 51')], stroke=INK,
                  t=tr(a=(48, 49), s=anim((6, [100, 20], 'out'), (16, [100, 100])), o=show_from(6))),
            group('Open', [E(37, 53, 3.2, 4.2), E(59, 53, 3.2, 4.2)], fill=INK,
                  t=tr(a=(48, 53), s=anim((0, [100, 100], 'in'), (6, [100, 10])), o=hide_at(6))),
        ], parent='Body'),
        layer('Mouth', group('Mouth', [morph((0, 'M42 68H54', 'out'), (16, 'M39 61Q47 71 55 61', 'swing'),
                                             (40, 'M40 63Q47 70 54 63'))], stroke=INK), parent='Body'),
        layer('Prop/Thumb', group('Thumb', [
            group('Knuckles', [P('M61 69H69M61 76H69')], stroke=INK),
            group('Fist', [R(61, 62, 24, 21, 6)], fill=WHITE, stroke=INK),
            group('Finger', [P('M66 64V50C66 45.5 73 45.5 73 50V64')], fill=WHITE, stroke=INK),
        ], t=tr(a=(73, 70), s=anim((8, [0, 0], 'out'), (24, [118, 118], 'swing'), (40, [100, 100])),
                r=anim((8, -20, 'out'), (24, 6, 'swing'), (40, 0)))), parent='Body'),
        layer('FX/Sparkles', [
            group('Blue', [P('M18 12L20.2 18.8L27 21L20.2 23.2L18 30L15.8 23.2L9 21L15.8 18.8Z')], fill=PRIMARY,
                  t=tr(a=(18, 21), s=twinkle(16), r=anim((16, -30, 'out'), (58, 0)))),
            group('Amber', [P('M84 24L85.4 28.6L90 30L85.4 31.4L84 36L82.6 31.4L78 30L82.6 28.6Z')], fill=ACCENT,
                  t=tr(a=(84, 30), s=twinkle(22), r=anim((22, 30, 'out'), (64, 0)))),
        ]),
    ]
    return comp('GG', layers, op, [(op - 1, 'settle', 0)]), None


def fire():
    """On fire - intro 0.6 s + loop 1.2 s. Spark ignites, flame flickers, embers drift."""
    l0, cyc = 36, 72
    op = l0 + cyc
    flame_s = anim((0, [38, 45], 'out'), (20, [114, 117], 'swing'), (36, [100, 100], 'swing'),
                   (50, [97, 103], 'swing'), (64, [103, 92], 'swing'), (79, [98, 102], 'swing'),
                   (94, [102, 95], 'swing'), (108, [100, 100]))
    flame_r = anim((36, 0, 'swing'), (50, 4, 'swing'), (64, -3, 'swing'), (79, 3, 'swing'),
                   (94, -2, 'swing'), (108, 0))
    inner_s = anim((6, [0, 0], 'out'), (22, [110, 110], 'swing'), (36, [100, 100], 'swing'),
                   (50, [108, 92], 'swing'), (64, [94, 108], 'swing'), (79, [106, 94], 'swing'),
                   (94, [96, 106], 'swing'), (108, [100, 100]))

    def ember(name, center, r, color, start, top, born, gone):
        # Rises from `start` through `center` (its Paper position, reached at
        # the loop start) to `top`, fading; the same path repeats every cycle.
        rel = lambda q: [q[0] - center[0], q[1] - center[1]]
        b2 = born + cyc
        return group(name, [E(center[0], center[1], r)], fill=color, t=tr(
            a=center,
            p=at(center, (born, rel(start), 'lin'), (l0, [0, 0], 'lin'), (gone, rel(top), 'hold'),
                 (b2, rel(start), 'lin'), (op, [0, 0])),
            o=anim((born, 0, 'out'), (born + 10, 100, 'lin'), (gone - 14, 100, 'in'), (gone, 0, 'hold'),
                   (b2, 0, 'out'), (b2 + 10, 100, 'lin'), (op, 100))))

    layers = [
        shadow(s=anim((0, [100, 100], 'out'), (20, [108, 100], 'swing'), (36, [100, 100]))),
        body(s=anim((0, [100, 100], 'out'), (20, [103, 94], 'swing'), (36, [100, 100]))),
        layer('Prop/Flame', group('Flame', [
            group('Inner', [P('M48 13C51.5 17 54 20 53.5 23.5C53 26.5 51 27.5 48 27.5C45 27.5 43 26.5 42.5 23.5'
                              'C42.5 20 44.5 17 48 13Z')], fill=DANGER, t=tr(a=(48, 27.5), s=inner_s)),
            group('Outer', [P('M48 2C57 9 63 15 62 23C61 29 56 32 48 32C40 32 35 29 34 23C33 17 37 14 40 8.5'
                              'C42 11.5 43.5 13.5 45.5 14.5C45.5 9.5 46.5 6 48 2Z')], fill=ACCENT, stroke=INK),
        ], t=tr(a=(48, 32), s=flame_s, r=flame_r)), parent='Body'),
        layer('Brows', group('Brows', [P('M30 42L41 46M66 42L55 46')], stroke=INK,
                             t=tr(a=(48, 44), p=at((48, 44), (8, [0, -4], 'out'), (18, [0, 0])),
                                  o=anim((8, 0, 'out'), (18, 100)))), parent='Body'),
        layer('Eyes', group('Eyes', [E(37, 53, 3.2, 4.2), E(59, 53, 3.2, 4.2)], fill=INK), parent='Body'),
        layer('Mouth', [
            group('Grin', [
                group('Teeth', [P('M39 64.5H57V67.5H39Z')], fill=WHITE),
                group('Open', [P('M36 63H60C60 71 55 76 48 76C41 76 36 71 36 63Z')], fill=INK, stroke=INK),
            ], t=tr(a=(48, 63), s=anim((10, [60, 20], 'out'), (20, [108, 115], 'swing'), (32, [100, 100])),
                    o=show_from(10))),
            group('Line', [P('M42 68H54')], stroke=INK, t=tr(o=hide_at(10))),
        ], parent='Body'),
        layer('FX/Embers', [
            ember('Ember A', (20, 26), 2.5, ACCENT, (24, 40), (15, 12), 8, 58),
            ember('Ember B', (78, 20), 3, DANGER, (74, 33), (82, 7), 14, 54),
            ember('Ember C', (84, 36), 2, ACCENT, (80, 48), (88, 23), 10, 62),
        ]),
    ]
    return comp('On fire', layers, op, [(0, 'intro', l0), (l0, 'loop', cyc), (l0, 'settle', 0)]), (l0, cyc)


def facepalm():
    """Facepalm - one-shot 1.3 s. Hand slaps the face, squash, hit lines, head shake, sweat."""
    op = 78
    layers = [
        shadow(s=anim((12, [100, 100], 'in'), (16, [114, 100], 'out'), (30, [100, 100]))),
        tuft(),
        body(s=anim((0, [100, 100], 'out'), (12, [98, 102], 'in'), (16, [109, 94], 'out'), (30, [100, 100])),
             r=anim((30, 0, 'swing'), (42, 6, 'swing'), (54, -6, 'swing'), (66, 3, 'swing'), (78, 0))),
        layer('Eyes', [
            group('Peek', [
                group('Pupil', [E(65.5, 54.5, 2.6, 2.2)], fill=INK),
                group('Lid', [P('M61 51H70')], stroke=INK),
            ], t=tr(o=show_from(16))),
            group('Open', [E(37, 52, 3.2, 4.2), E(59, 52, 3.2, 4.2)], fill=INK, t=tr(o=hide_at(16))),
        ], parent='Body'),
        layer('Mouth', [
            group('Frown', [P('M40 73Q47 68 56 72')], stroke=INK, t=tr(o=show_from(16))),
            group('Oh', [E(48, 69, 3.5, 4)], fill=INK, t=tr(o=hide_at(16))),
        ], parent='Body'),
        layer('Prop/Hand', group('Hand', [P(
            'M21 59C19 49 21 40 28 37L30 27C30.5 23 35.5 23 35.5 27V35L37.5 23.5C38 19.5 43 19.5 43 23.5V35'
            'L45 25.5C45.5 21.5 50.5 21.5 50.5 25.5V37L52.5 31C53 27 58 27 58 31V47C58 55 52 61 42 61H29'
            'C25 61 22 61 21 59Z')], fill=WHITE, stroke=INK,
            t=tr(a=(40, 45), p=at((40, 45), (0, [-7, 22], 'in'), (16, [0, 3], 'out'), (28, [0, 0])),
                 r=anim((0, -20, 'in'), (16, 4, 'out'), (28, 0)))), parent='Body'),
        layer('FX/Hit', group('Hit', [P('M8 30L14 34M6 44H13M62 14L66 20')], stroke=INK, width=2.5,
                              t=tr(a=(30, 32), s=anim((16, [85, 85], 'out'), (28, [105, 105])),
                                   o=anim((0, 0, 'hold'), (16, 100, 'lin'), (22, 100, 'in'), (32, 0))))),
        layer('FX/Sweat', group('Sweat', [P('M75 26C78 30 80 33 80 35.2A5 5 0 0 1 70 35.2C70 33 72 30 75 26Z')],
                                fill=PRIMARY_LINE, stroke=PRIMARY, width=2.5,
                                t=tr(a=(75, 34), p=at((75, 34), (34, [-2, -10], 'out'), (62, [0, 0])),
                                     o=anim((34, 0, 'out'), (42, 100))))),
    ]
    return comp('Facepalm', layers, op, [(op - 1, 'settle', 0)]), None


def lol():
    """LOL - intro 0.4 s + loop 1.6 s. Rocks +-8 deg every 0.4 s, bounces 4 px, tears fly."""
    l0, cyc = 24, 96
    op = l0 + cyc
    rot = [(0, 0, 'out'), (24, -8, 'swing')]
    for k, t in enumerate(range(48, op + 1, 24)):
        rot.append((t, 8 if k % 2 == 0 else -8, 'swing'))
    rot[-1] = rot[-1][:2]
    bounce, ground, lines, laugh = [], [], [], []
    for k, t in enumerate(range(0, op + 1, 12)):
        up = k % 2 == 1
        bounce.append((t, [48, 82 if up else 86], 'in' if up else 'out'))
        ground.append((t, [90, 90] if up else [100, 100], 'in' if up else 'out'))
    for k, t in enumerate(range(l0, op + 1, 12)):
        lines.append((t, 100 if k % 2 == 0 else 0, 'out' if k % 2 == 0 else 'in'))
        laugh.append((t, [100, 100] if k % 2 == 0 else [104, 90], 'swing'))
    bounce[-1], ground[-1], lines[-1], laugh[-1] = bounce[-1][:2], ground[-1][:2], lines[-1][:2], laugh[-1][:2]

    drop = 'M{x} {y}C{a} {b} {c} {d} {c} {e}A{r} {r} 0 0 1 {f} {e}C{f} {g} {h} {b} {x} {y}Z'

    def tear(name, d, center, start, end):
        # Period 0.8 s: leaves the eye, passes its Paper position at the loop
        # start (frame 24, 72, 120), flies out and fades.
        p_kfs, o_kfs, s_kfs = [], [], []
        for b in (0, 48, 96):
            p_kfs += [(b, start, 'out'), (b + 24, [0, 0], 'lin'), (b + 40, end, 'hold')]
            o_kfs += [(b, 0, 'out'), (b + 8, 100, 'lin'), (b + 28, 100, 'in'), (b + 40, 0, 'hold')]
            s_kfs += [(b, [50, 50], 'out'), (b + 24, [100, 100], 'hold')]
        p_kfs[-1], o_kfs[-1], s_kfs[-1] = p_kfs[-1][:2], o_kfs[-1][:2], s_kfs[-1][:2]
        return group(name, [P(d)], fill=PRIMARY,
                     t=tr(a=center, p=at(center, *p_kfs), s=anim(*s_kfs), o=anim(*o_kfs)))

    layers = [
        shadow(s=anim(*ground)),
        tuft(),
        body(r=anim(*rot), p=anim(*bounce)),
        layer('Eyes', [
            group('Laugh', [P('M31 44L39 49L31 54M65 44L57 49L65 54')], stroke=INK,
                  t=tr(a=(48, 49), s=anim((8, [60, 60], 'out'), (16, [100, 100])), o=show_from(8))),
            group('Open', [E(37, 51, 3.2, 4.2), E(59, 51, 3.2, 4.2)], fill=INK, t=tr(o=hide_at(8))),
        ], parent='Body'),
        layer('Mouth', [
            group('Open', [
                group('Tongue', [P('M40 72C44 68 52 68 56 72C54 76 51 78 48 78C45 78 42 76 40 72Z')], fill=DANGER),
                group('Mouth', [P('M32 60H64C64 72 57 79 48 79C39 79 32 72 32 60Z')], fill=INK, stroke=INK),
            ], t=tr(a=(48, 60), s=anim((8, [50, 30], 'out'), *laugh), o=show_from(8))),
            group('Smile', [P('M41 64Q48 70 55 64')], stroke=INK, t=tr(o=hide_at(8))),
        ], parent='Body'),
        layer('FX/Tears', [
            tear('Left big', 'M13 36C15.5 39.5 17 42 17 43.8A4 4 0 0 1 9 43.8C9 42 10.5 39.5 13 36Z',
                 (13, 42), [15, 5], [-5, 6]),
            tear('Left small', 'M7 52C8.8 54.5 10 56.3 10 57.6A3 3 0 0 1 4 57.6C4 56.3 5.2 54.5 7 52Z',
                 (7, 56), [17, -3], [-3, 6]),
            tear('Right big', 'M84 30C86.5 33.5 88 36 88 37.8A4 4 0 0 1 80 37.8C80 36 81.5 33.5 84 30Z',
                 (84, 36), [-16, 9], [5, 6]),
            tear('Right small', 'M90 46C91.8 48.5 93 50.3 93 51.6A3 3 0 0 1 87 51.6C87 50.3 88.2 48.5 90 46Z',
                 (90, 50), [-18, 0], [2, 6]),
        ]),
        layer('FX/Lines', group('Lines', [P('M12 18L18 23M86 70L80 68')], stroke=INK, width=2.5,
                                t=tr(o=anim((0, 0, 'out'), *lines)))),
    ]
    return comp('LOL', layers, op, [(0, 'intro', l0), (l0, 'loop', cyc), (l0, 'settle', 0)]), (l0, cyc)


def hmm():
    """Hmm... - intro 0.8 s + loop 1.8 s. Hand to chin, tilt, brow, thought dots pop in turn."""
    l0, cyc = 48, 108
    op = l0 + cyc

    def dot(name, cx, cy, r, first_pop):
        pops = [(first_pop, [0, 0], 'out'), (first_pop + 10, [115, 115], 'swing'),
                (first_pop + 18, [100, 100], 'hold')]
        loop_pop = first_pop + 88  # the same pop inside the loop
        pops += [(loop_pop, [0, 0], 'out'), (loop_pop + 10, [115, 115], 'swing'), (loop_pop + 18, [100, 100])]
        return group(name, [E(cx, cy, r)], fill=WHITE, stroke=FAINT, width=2.5, t=tr(
            a=(cx, cy), p=at((cx, cy), (88, [0, 0], 'in'), (100, [2, -3], 'hold'), (loop_pop, [0, 0])),
            s=anim(*pops),
            o=anim((88, 100, 'in'), (100, 0, 'hold'), (loop_pop, 100))))

    layers = [
        shadow(),
        tuft(),
        body(r=anim((0, 0, 'swing'), (24, -5, 'swing'), (48, 0, 'swing'), (102, -3, 'swing'), (156, 0))),
        layer('Brows', [
            group('Flat', [P('M54 45L65 43')], stroke=INK,
                  t=tr(a=(60, 44), p=at((60, 44), (16, [0, -3], 'out'), (26, [0, 0])),
                       o=anim((16, 0, 'out'), (26, 100)))),
            group('Raised', [P('M30 41Q36 35 42 39')], stroke=INK,
                  t=tr(a=(36, 39), p=at((36, 39), (8, [0, 5], 'out'), (24, [0, 0])),
                       o=anim((8, 0, 'out'), (18, 100)))),
        ], parent='Body'),
        layer('Eyes', [
            group('Squint', [P('M55 52H65')], stroke=INK,
                  t=tr(a=(60, 52), s=anim((18, [60, 100], 'out'), (28, [100, 100])), o=show_from(18))),
            group('Right', [E(60, 49, 3.2, 4.2)], fill=INK,
                  t=tr(a=(60, 50), s=anim((10, [100, 100], 'in'), (18, [100, 20])), o=hide_at(18))),
            group('Left', [E(36, 50, 3.2, 4.2)], fill=INK,
                  t=tr(a=(36, 50), p=at((36, 50), (6, [2, -1], 'out'), (20, [0, 0])))),
        ], parent='Body'),
        layer('Mouth', group('Mouth', [morph((10, 'M43 67Q45.5 67 48 67T53 67', 'out'),
                                             (30, 'M47 67Q51 64 55 67T63 67'))], stroke=INK), parent='Body'),
        layer('Prop/Hand', group('Hand', [
            group('Fist', [R(27, 72, 19, 15, 6)], fill=WHITE, stroke=INK),
            group('Finger', [P('M38 75V64C38 60.5 43 60.5 43 64V73')], fill=WHITE, stroke=INK),
        ], t=tr(a=(36, 78), p=at((36, 78), (0, [0, 16], 'out'), (30, [0, 0])), o=anim((0, 0, 'out'), (10, 100)))),
            parent='Body'),
        layer('FX/Dots', [
            dot('Big', 86, 11, 5, 30),
            dot('Small', 77, 22, 3, 18),
        ]),
    ]
    return comp('Hmm', layers, op, [(0, 'intro', l0), (l0, 'loop', cyc), (l0, 'settle', 0)]), (l0, cyc)


def too_slow():
    """Too slow - intro 0.5 s + loop 2.0 s. Checks the watch, yawns, the hand ticks, Z's float."""
    l0, cyc = 30, 120
    op = l0 + cyc
    y0, y1, y2, y3 = 48, 68, 84, 102  # yawn: start, open, hold until, closed again

    ticks = [(4, -31, 'out'), (8, -15.5, 'hold'), (16, -15.5, 'out'), (20, 0, 'hold')]
    for k in range(12):
        t = l0 + 10 * k
        ticks += [(t, 30 * k, 'out'), (t + 4, 30 * k + 30, 'hold')]
    ticks.append((op, 360))

    def zed(name, d, center, start, end):
        p_kfs, o_kfs = [], []
        for b in (0, 60, 120):
            p_kfs += [(b, start, 'lin'), (b + 30, [0, 0], 'lin'), (b + 50, end, 'hold')]
            o_kfs += [(b, 0, 'out'), (b + 12, 100, 'lin'), (b + 38, 100, 'in'), (b + 50, 0, 'hold')]
        p_kfs[-1], o_kfs[-1] = p_kfs[-1][:2], o_kfs[-1][:2]
        return group(name, [P(d)], stroke=MUTED, width=2.5,
                     t=tr(a=center, p=at(center, *p_kfs), o=anim(*o_kfs)))

    yawn = lambda a, b: anim((y0, a, 'swing'), (y1, b, 'swing'), (y2, b, 'swing'), (y3, a))
    layers = [
        shadow(s=yawn([100, 100], [92, 90])),
        tuft(),
        body(s=yawn([100, 100], [97, 106])),
        layer('Eyes', [
            group('Closed', [P('M31 46H45M53 46H67')], stroke=INK,
                  t=tr(o=anim((0, 0, 'hold'), (y0 + 6, 100, 'hold'), (y3 - 6, 0)))),
            group('Sleepy', [
                group('Lids', [P('M31 49H45M53 49H67')], stroke=INK),
                group('Pupils', [P('M33 49A5 5 0 0 0 43 49Z M55 49A5 5 0 0 0 65 49Z')], fill=INK,
                      t=tr(a=(49, 49), s=anim((16, [100, 30], 'out'), (28, [100, 100], 'hold'),
                                              (y3 - 6, [100, 30], 'out'), (y3 + 6, [100, 100])))),
            ], t=tr(o=anim((0, 0, 'hold'), (16, 100, 'hold'), (y0 + 6, 0, 'hold'), (y3 - 6, 100)))),
            group('Look', [E(35, 54, 3.2, 4.2), E(57, 54, 3.2, 4.2)], fill=INK,
                  t=tr(a=(46, 54), s=anim((10, [100, 100], 'in'), (16, [100, 10])), o=hide_at(16))),
        ], parent='Body'),
        layer('Mouth', [
            group('Yawn', [E(0, 0, 0, p=yawn([52, 68], [51, 67]), s=yawn([11, 14], [15, 20]))], fill=INK,
                  t=tr(a=(52, 68), s=anim((16, [30, 30], 'out'), (28, [100, 100])), o=show_from(16))),
            group('Line', [P('M45 69H55')], stroke=INK, t=tr(o=hide_at(16))),
        ], parent='Body'),
        layer('Prop/Watch', group('Watch', [
            group('Hour', [P('M22 72L27 75')], stroke=ACCENT, t=tr(a=(22, 72), r=anim(*ticks))),
            group('Minute', [P('M22 72V64.5')], stroke=ACCENT),
            group('Face', [E(22, 72, 12.5)], fill=WHITE, stroke=INK),
            group('Crown', [P('M22 55V59M18.5 55H25.5')], stroke=INK),
        ], t=tr(a=(22, 72), r=yawn(0, -14))), parent='Body'),
        layer('FX/Zzz', [
            zed('Big Z', 'M80 4H86L80 10H86', (83, 7), [-4, 8], [2, -2]),
            zed('Small Z', 'M68 14H75L68 21H75', (71.5, 17.5), [-4, 8], [3, -6]),
        ]),
    ]
    return comp('Too slow', layers, op, [(0, 'intro', l0), (l0, 'loop', cyc), (l0, 'settle', 0)]), (l0, cyc)


def ez():
    """Ez - one-shot 1.2 s. Shades drop and bounce, smirk, glint, sparkle."""
    op = 72
    layers = [
        shadow(s=anim((28, [100, 100], 'out'), (32, [108, 100], 'swing'), (44, [100, 100]))),
        tuft(),
        body(s=anim((28, [100, 100], 'out'), (32, [104, 96], 'swing'), (44, [100, 100]))),
        layer('Eyes', group('Eyes', [E(37, 53, 3.2, 4.2), E(59, 53, 3.2, 4.2)], fill=INK,
                            t=tr(a=(48, 53), s=anim((8, [100, 100], 'out'), (20, [100, 70])), o=hide_at(28))),
              parent='Body'),
        layer('Mouth', group('Mouth', [morph((28, 'M42 68H54', 'out'), (44, 'M41 68Q49 73 57 65'))], stroke=INK),
              parent='Body'),
        layer('Prop/Shades', group('Shades', [
            group('Glint', [P('M31 53L35 49M55 53L59 49')], stroke=WHITE, width=2,
                  trim={'e': anim((40, 0, 'out'), (52, 100))}),
            group('Right lens', [P('M51 46H69V50C69 55 66 58 61 58H59C54 58 51 55 51 50Z')], fill=INK, stroke=INK),
            group('Left lens', [P('M27 46H45V50C45 55 42 58 37 58H35C30 58 27 55 27 50Z')], fill=INK, stroke=INK),
            group('Bar', [P('M22 46H74')], stroke=INK),
        ], t=tr(a=(48, 52), p=at((48, 52), (6, [0, -30], 'in'), (28, [0, 0], 'out'), (34, [0, -3], 'in'),
                                 (40, [0, 0])))), parent='Body'),
        layer('FX/Sparkle', group('Sparkle', [P('M84 22L85.8 28.2L92 30L85.8 31.8L84 38L82.2 31.8L76 30L82.2 28.2Z')],
                                  fill=PRIMARY,
                                  t=tr(a=(84, 30), s=anim((46, [0, 0], 'out'), (56, [120, 120], 'swing'),
                                                          (66, [100, 100])),
                                       r=anim((46, -45, 'out'), (66, 0))))),
    ]
    return comp('Ez', layers, op, [(op - 1, 'settle', 0)]), None


def wait_what():
    """Wait, what? - one-shot 1.2 s. Jump and stretch, eyes pop, jaw drops, lines flash, land."""
    op = 72
    layers = [
        shadow(s=anim((4, [104, 100], 'out'), (15, [82, 78], 'swing'), (22, [82, 78], 'in'),
                      (34, [106, 100], 'out'), (50, [100, 100]))),
        tuft(),
        body(p=anim((0, [48, 86], 'out'), (4, [48, 88], 'out'), (15, [48, 81], 'swing'), (22, [48, 81], 'in'),
                    (34, [48, 86])),
             s=anim((0, [100, 100], 'out'), (4, [104, 95], 'out'), (15, [95, 104], 'swing'), (28, [97, 102], 'in'),
                    (34, [106, 94], 'out'), (44, [98, 102], 'swing'), (54, [100, 100]))),
        layer('Eyes', [
            group('Shocked', [
                group('Pupils', [E(36, 50, 2.8), E(60, 50, 2.8)], fill=INK),
                group('Whites', [E(36, 49, 8), E(60, 49, 8)], fill=WHITE, stroke=INK),
            ], t=tr(a=(48, 49), s=anim((5, [50, 50], 'out'), (15, [125, 125], 'swing'), (44, [100, 100])),
                    o=show_from(5))),
            group('Open', [E(37, 51, 3.2, 4.2), E(59, 51, 3.2, 4.2)], fill=INK, t=tr(o=hide_at(5))),
        ], parent='Body'),
        layer('Mouth', [
            group('Jaw', [E(48, 71, 5, 6.5)], fill=INK,
                  t=tr(a=(48, 66), s=anim((5, [40, 30], 'out'), (15, [120, 123], 'swing'), (44, [100, 100])),
                       o=show_from(5))),
            group('Smile', [P('M41 65Q48 70 55 65')], stroke=INK, t=tr(o=hide_at(5))),
        ], parent='Body'),
        layer('FX/Shock', group('Shock', [P('M22 14L27 21M74 14L69 21M10 32L17 35M86 32L79 35')], stroke=DANGER,
                                t=tr(a=(48, 30), s=anim((8, [112, 112], 'out'), (40, [100, 100])),
                                     o=anim((0, 0, 'hold'), (8, 100, 'hold'), (16, 0, 'hold'), (20, 100))))),
    ]
    return comp('Wait, what?', layers, op, [(op - 1, 'settle', 0)]), None


def crying():
    """Crying - intro 0.8 s + loop 1.8 s. A tear wells, streams run (trim), sobs, puddle."""
    l0, cyc = 48, 108
    op = l0 + cyc
    sob = [(20, [100, 100], 'out'), (30, [105, 95], 'swing'), (48, [100, 100], 'swing')]
    for t in range(l0, op, 36):
        sob += [(t + 18, [101, 96], 'swing'), (t + 36, [100, 100], 'swing')]
    sob[-1] = sob[-1][:2]

    puddle = [(24, [44, 7], 'out'), (48, [56, 8], 'hold')]
    for land in (66, 84, 102, 120, 138):
        puddle += [(land, [56, 8], 'out'), (land + 4, [59, 8.6], 'swing'), (land + 14, [56, 8], 'hold')]
    puddle[-1] = puddle[-1][:2]

    def drip(name, x, births):
        p_kfs, o_kfs, s_kfs = [], [], []
        for b in births:
            p_kfs += [(b + 4, [x, 80], 'in'), (b + 16, [x, 88], 'hold')]
            o_kfs += [(b - 1, 0, 'out'), (b, 100, 'lin'), (b + 10, 100, 'in'), (b + 16, 0, 'hold')]
            s_kfs += [(b, [0, 0], 'out'), (b + 6, [100, 100], 'hold')]
        p_kfs[-1], o_kfs[-1], s_kfs[-1] = p_kfs[-1][:2], o_kfs[-1][:2], s_kfs[-1][:2]
        return group(name, [E(0, 0, 2)], fill=PRIMARY,
                     t=tr(a=(0, 0), p=anim(*p_kfs), s=anim(*s_kfs), o=anim(*o_kfs)))

    stream_trim = {'e': anim((24, 0, 'out'), (48, 100))}
    layers = [
        layer('Shadow', group('Shadow', [E(0, 0, 0, p={'a': 0, 'k': [48, 89]}, s=anim(*puddle))],
                              fill=anim((24, rgba(BORDER), 'out'), (48, rgba(PRIMARY_LINE))))),
        tuft(),
        body(s=anim(*sob)),
        layer('Brows', group('Brows', [morph((16, 'M30 43L40 39M66 43L56 39', 'out'),
                                             (28, 'M30 42L40 38M66 42L56 38'))], stroke=INK), parent='Body'),
        layer('Eyes', [
            group('Shut', [P('M31 48Q36 53 41 48M55 48Q60 53 65 48')], stroke=INK,
                  t=tr(a=(48, 49), s=anim((24, [100, 40], 'out'), (34, [100, 100])), o=show_from(24))),
            group('Open', [E(37, 51, 3.2, 4.2), E(59, 51, 3.2, 4.2)], fill=INK,
                  t=tr(a=(48, 51), s=anim((18, [100, 100], 'in'), (24, [100, 10])), o=hide_at(24))),
        ], parent='Body'),
        layer('FX/Tears', [
            group('Right stream', [P('M59.25 55.5C58.8 62 58.8 71 59.3 77.5')], stroke=PRIMARY, width=6,
                  trim=stream_trim),
            group('Left stream', [P('M36.75 55.5C36.3 62 36.3 71 36.8 77.5')], stroke=PRIMARY, width=6,
                  trim=stream_trim),
            group('First tear', [P('M33 58C34.5 60 35.5 61.5 35.5 62.5A2.5 2.5 0 0 1 30.5 62.5'
                                   'C30.5 61.5 31.5 60 33 58Z')], fill=PRIMARY,
                  t=tr(a=(33, 58), p=at((33, 58), (12, [0, 0], 'in'), (30, [0, 14])),
                       s=anim((0, [0, 0], 'out'), (12, [100, 100])), o=anim((22, 100, 'in'), (30, 0)))),
        ], parent='Body'),
        layer('Mouth', group('Mouth', [morph((20, 'M43 70Q48 67 53 70', 'out'), (36, 'M43 73Q48 66 53 73'))],
                             stroke=INK), parent='Body'),
        layer('FX/Drips', [
            drip('Right drip', 59.3, (68, 104, 140)),
            drip('Left drip', 36.8, (50, 86, 122)),
        ]),
    ]
    return comp('Crying', layers, op, [(0, 'intro', l0), (l0, 'loop', cyc), (l0, 'settle', 0)]), (l0, cyc)


STICKERS = {
    'gg': gg,
    'fire': fire,
    'facepalm': facepalm,
    'lol': lol,
    'hmm': hmm,
    'too_slow': too_slow,
    'ez': ez,
    'wait_what': wait_what,
    'crying': crying,
}


# --------------------------------------------------------------------------
# Telegram version: 512 x 512, loop-only, gzipped
# --------------------------------------------------------------------------

TGS_SIZE = 512
TGS_FILL = 0.88  # share of the 512 canvas the 96 canvas occupies; keeps jumps inside


def _scale_value(v, k):
    if isinstance(v, list):
        return [_scale_value(x, k) for x in v]
    if isinstance(v, dict):  # bezier shape
        return {'c': v['c'], 'v': _scale_value(v['v'], k), 'i': _scale_value(v['i'], k),
                'o': _scale_value(v['o'], k)}
    return v * k


def _scale_prop(p, k, off=(0, 0)):
    if p['a']:
        for kf in p['k']:
            kf['s'] = _scale_value(kf['s'], k)
            if off != (0, 0) and len(kf['s']) == 2:
                kf['s'] = [kf['s'][0] + off[0], kf['s'][1] + off[1]]
    else:
        p['k'] = _scale_value(p['k'], k)
        if off != (0, 0):
            p['k'] = [p['k'][0] + off[0], p['k'][1] + off[1]]


def _scale_shapes(items, k):
    for it in items:
        ty = it['ty']
        if ty == 'gr':
            _scale_shapes(it['it'], k)
        elif ty == 'sh':
            _scale_prop(it['ks'], k)
        elif ty == 'el':
            _scale_prop(it['p'], k)
            _scale_prop(it['s'], k)
        elif ty == 'rc':
            _scale_prop(it['p'], k)
            _scale_prop(it['s'], k)
            _scale_prop(it['r'], k)
        elif ty == 'st':
            _scale_prop(it['w'], k)
        elif ty == 'tr':
            _scale_prop(it['a'], k)
            _scale_prop(it['p'], k)


def _shift_times(node, dt):
    if isinstance(node, dict):
        if node.get('a') == 1 and isinstance(node.get('k'), list):
            for kf in node['k']:
                kf['t'] -= dt
        for value in node.values():
            _shift_times(value, dt)
    elif isinstance(node, list):
        for value in node:
            _shift_times(value, dt)


def to_tgs(doc, loop):
    t = json.loads(json.dumps(doc))
    k = TGS_SIZE / 96 * TGS_FILL
    off = (TGS_SIZE - 96 * k) / 2
    for lyr in t['layers']:
        _scale_prop(lyr['ks']['a'], k)
        _scale_prop(lyr['ks']['p'], k, (0, 0) if 'parent' in lyr else (off, off))
        _scale_shapes(lyr['shapes'], k)
    if loop:
        start, cyc = loop
        _shift_times(t['layers'], start)
        op = cyc
    else:
        op = doc['op'] + 36  # rest on the settle pose before Telegram restarts it
    for lyr in t['layers']:
        lyr['ip'], lyr['op'] = 0, op + 1
    t.update({'tgs': 1, 'w': TGS_SIZE, 'h': TGS_SIZE, 'op': op, 'markers': []})
    return t


def _round(node):
    if isinstance(node, float):
        r = round(node, 3)
        return int(r) if r == int(r) else r
    if isinstance(node, list):
        return [_round(x) for x in node]
    if isinstance(node, dict):
        return {key: _round(value) for key, value in node.items()}
    return node


def dump(doc):
    return json.dumps(_round(doc), separators=(',', ':'), ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('--root', default=str(Path(__file__).resolve().parents[2]))
    args = parser.parse_args()
    root = Path(args.root)
    json_dir = root / 'assets' / 'stickers'
    tgs_dir = root / 'docs' / 'stickers' / 'tgs'
    json_dir.mkdir(parents=True, exist_ok=True)
    tgs_dir.mkdir(parents=True, exist_ok=True)
    for sticker_id, build in STICKERS.items():
        doc, loop = build()
        doc['nm'] = sticker_id
        text = dump(doc)
        (json_dir / f'{sticker_id}.json').write_text(text)
        tgs_bytes = gzip.compress(dump(to_tgs(doc, loop)).encode(), compresslevel=9, mtime=0)
        (tgs_dir / f'{sticker_id}.tgs').write_bytes(tgs_bytes)
        kind = f'intro {loop[0] / FPS:.1f}s + loop {loop[1] / FPS:.1f}s' if loop else f'one-shot {doc["op"] / FPS:.1f}s'
        print(f'{sticker_id:10s} {kind:28s} json {len(text) / 1024:5.1f} KB   tgs {len(tgs_bytes) / 1024:4.1f} KB')


if __name__ == '__main__':
    main()
