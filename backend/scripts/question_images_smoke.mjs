import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';

export async function verifyQuestionImages(base) {
  const {entries} = JSON.parse(await readFile(new URL('../src/test/resources/question-images-manifest.json', import.meta.url), 'utf8'));
  assert.equal(entries.length, 23);
  for (const image of entries) {
    const response = await fetch(base + image.imageUrl);
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('content-type'), 'image/png');
    assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
    assert.deepEqual(response.headers.get('cache-control').split(/,\s*/).sort(), ['public', 'max-age=31536000', 'immutable'].sort());
    const bytes = Buffer.from(await response.arrayBuffer());
    assert.equal(bytes.length, image.sizeBytes);
    assert.equal(bytes.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
    assert.equal(createHash('sha256').update(bytes).digest('hex'), image.sha256);
    const head = await fetch(base + image.imageUrl, {method: 'HEAD'});
    assert.equal(head.status, 200);
    assert.equal(head.headers.get('content-length'), String(image.sizeBytes));
    assert.equal((await head.arrayBuffer()).byteLength, 0);
    const conditional = await fetch(base + image.imageUrl, {headers: {'If-Modified-Since': response.headers.get('last-modified')}});
    assert.equal(conditional.status, 304);
    assert.equal((await conditional.arrayBuffer()).byteLength, 0);
    if (base.startsWith('https:')) {
      assert.equal(response.headers.get('cross-origin-opener-policy'), 'same-origin');
      assert.equal(response.headers.get('cross-origin-embedder-policy'), 'require-corp');
    }
  }
  const missing = '/media/questions/SAT_MATH/00000000/' + '0'.repeat(64) + '.png';
  const response = await fetch(base + missing);
  assert.equal(response.status, 404);
  assert.equal((await response.json()).code, 'NOT_FOUND');
  assert(!response.headers.get('cache-control')?.includes('immutable'));
  const head = await fetch(base + missing, {method: 'HEAD'});
  assert.equal(head.status, 404);
  assert.equal((await head.arrayBuffer()).byteLength, 0);
  for (const path of ['/media/questions/', '/media/questions/application.yml', '/media/questions/%252e%252e/application.yml', '/media/questions/SAT_MATH/3f5a3602/']) {
    const r = await fetch(base + path, {redirect: 'manual'});
    // Nginx normalizes the doubly encoded traversal into a protected path;
    // the existing JWT rejection is also an allowed safe outcome for this input.
    const allowed = path.includes('%252e') ? [400, 404, 401, 403] : [400, 404];
    assert(allowed.includes(r.status), path + ': ' + r.status);
  }
  assert.equal((await fetch(base + '/api/v1/users/me')).status, 401);
  console.log('Question images: all 23 exact PNG hashes, GET/HEAD/304, immutable cache, missing/traversal, API security and same-origin proxy passed.');
}
