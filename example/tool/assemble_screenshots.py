"""Turns the frames record_screenshots.dart wrote into the pub.dev screenshots.

Run it from the example directory, after the recorder:

    flutter test tool/record_screenshots.dart
    python tool/assemble_screenshots.py

Lossy WebP, because most of each screenshot is a photograph. At this quality the
card text is indistinguishable from lossless under a 2x zoom, for a sixth of the
weight, and these files travel in the published archive.
"""

import os
import sys

from PIL import Image

SIZE = (1200, 750)
QUALITY = 88

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
frames = os.path.join(root, 'build', 'screenshots')
out_dir = os.path.abspath(os.path.join(root, '..', 'screenshots'))

if not os.path.isdir(frames):
    sys.exit('no frames in %s, run the recorder first' % frames)

if not os.path.isdir(out_dir):
    os.makedirs(out_dir)

for name in sorted(os.listdir(frames)):
    if not name.endswith('.png'):
        continue
    im = Image.open(os.path.join(frames, name)).convert('RGBA')
    flat = Image.new('RGB', im.size, (255, 255, 255))
    flat.paste(im, mask=im.split()[3])
    flat = flat.resize(SIZE, Image.LANCZOS)

    out = os.path.join(out_dir, name[:-4] + '.webp')
    flat.save(out, 'WEBP', quality=QUALITY, method=6)
    print('%-22s %d Ko' % (name[:-4], os.path.getsize(out) // 1024))
