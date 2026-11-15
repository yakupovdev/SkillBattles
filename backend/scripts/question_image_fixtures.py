"""Enrich only disposable smoke-test fixtures with matching packaged image identities."""
import json


def illustrated_fixture(backend, output):
    values = json.loads((backend / 'src/test/resources/fixtures/stage2-questions-test-only.json').read_text(encoding='utf-8'))
    entries = json.loads((backend / 'src/test/resources/question-images-manifest.json').read_text(encoding='utf-8'))['entries']
    for discipline in ('SAT_MATH', 'SAT_RW'):
        for difficulty in ('EASY', 'MEDIUM', 'HARD'):
            images = [e for e in entries if e['bindingStatus'] == 'READY'
                      and e['disciplineCode'] == discipline and e['difficulty'] == difficulty]
            questions = [q for q in values if q['disciplineCode'] == discipline and q['difficulty'] == difficulty]
            for image, question in zip(images, questions):
                question.update(externalKey=image['externalKey'], contentVersion=3, imageKey=image['imageKey'])
    output.write_text(json.dumps(values), encoding='utf-8')
    return output
