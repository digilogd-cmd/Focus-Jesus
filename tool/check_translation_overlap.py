#!/usr/bin/env python3
"""Flags manuscript text that reproduces the 개역개정 translation.

For every chapter it fetches the 개역개정 text of each Bible chapter the
manuscript points to (references, scripture blocks, and passages cited in the
prose such as "갈라디아서 4:4", "(신 22:25)", "시편 23편", or a bare "26:8" /
"24장", read as the chapter's main book) from 대한성서공회 성경플랫폼, then
looks for runs of N or more consecutive Hangul syllables
(spaces and punctuation ignored) shared by the manuscript and the
translation. Paraphrase never produces long identical runs; copying does.

The translation text is cached outside the repository (it is copyrighted and
must not be committed): $FJ_NKRV_CACHE or ~/.cache/focus-jesus/nkrv.

Usage:
  python3 tool/check_translation_overlap.py                  # every season
  python3 tool/check_translation_overlap.py path/day08.json  # some files
  python3 tool/check_translation_overlap.py --n 10 ...       # stricter

Exit code 1 when an overlap is found that is not in
tool/translation_overlap_allowlist.txt (one Hangul-only string per line, for
fixed proper names such as tree or place names that have no other wording).
Needs network access on the first run.
"""
import argparse
import glob
import html
import json
import os
import re
import sys
import time
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
CONTENT = os.path.join(ROOT, 'assets', 'content')
BOOKS_DART = os.path.join(ROOT, 'lib', 'core', 'bible', 'bible_books.g.dart')
ALLOWLIST = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         'translation_overlap_allowlist.txt')
CACHE = os.environ.get('FJ_NKRV_CACHE',
                       os.path.expanduser('~/.cache/focus-jesus/nkrv'))
# The platform rejects requests that do not look like a browser.
UA = ('Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0 Mobile Safari/537.36')

REF = re.compile(r'^([1-3]?[A-Z]{2,3})\s+(\d+)(?::(\d+))?(?:-(\d+)(?::(\d+))?)?$')
VERSE = re.compile(
    r'<ibep-verse-text-renderer[^>]*>(.*?)</ibep-verse-text-renderer>', re.S)
TAG = re.compile(r'<[^>]+>')
NOT_HANGUL = re.compile(r'[^가-힣]')


def chapters_of(ref):
    """'GEN 11:27-12:9' -> [('GEN', 11), ('GEN', 12)]."""
    m = REF.match(ref.strip())
    if not m:
        raise ValueError(f'unrecognised reference {ref!r}')
    book, c1 = m.group(1), int(m.group(2))
    v1, a, b = m.group(3), m.group(4), m.group(5)
    if v1 is None:
        c2 = int(a) if a else c1          # 'GEN 6-9' or 'GEN 3'
    else:
        c2 = int(a) if (a and b) else c1  # 'GEN 11:27-12:9' or 'GEN 12:1-3'
    return [(book, c) for c in range(c1, c2 + 1)]


def load_books():
    """{korean name: (USFM code, chapter count)} from the app's book table."""
    with open(BOOKS_DART, encoding='utf-8') as f:
        src = f.read()
    books = {}
    for m in re.finditer(r"code: '(\w+)',\s*koreanName: '([^']+)'.*?verseCounts: <int>\[(.*?)\]",
                         src, re.S):
        books[m.group(2)] = (m.group(1), m.group(3).count(',') + (0 if m.group(3).strip().endswith(',') else 1))
    return books


# Standard Korean abbreviations, as in "(신 22:25-27)" or "롬 9:8".
ABBREVIATIONS = {
    '창': '창세기', '출': '출애굽기', '레': '레위기', '민': '민수기',
    '신': '신명기', '수': '여호수아', '삿': '사사기', '룻': '룻기',
    '삼상': '사무엘상', '삼하': '사무엘하', '왕상': '열왕기상',
    '왕하': '열왕기하', '대상': '역대상', '대하': '역대하', '스': '에스라',
    '느': '느헤미야', '에': '에스더', '욥': '욥기', '시': '시편',
    '잠': '잠언', '전': '전도서', '아': '아가', '사': '이사야',
    '렘': '예레미야', '애': '예레미야애가', '겔': '에스겔', '단': '다니엘',
    '호': '호세아', '욜': '요엘', '암': '아모스', '옵': '오바댜',
    '욘': '요나', '미': '미가', '나': '나훔', '합': '하박국', '습': '스바냐',
    '학': '학개', '슥': '스가랴', '말': '말라기', '마': '마태복음',
    '막': '마가복음', '눅': '누가복음', '요': '요한복음', '행': '사도행전',
    '롬': '로마서', '고전': '고린도전서', '고후': '고린도후서',
    '갈': '갈라디아서', '엡': '에베소서', '빌': '빌립보서', '골': '골로새서',
    '살전': '데살로니가전서', '살후': '데살로니가후서',
    '딤전': '디모데전서', '딤후': '디모데후서', '딛': '디도서',
    '몬': '빌레몬서', '히': '히브리서', '약': '야고보서',
    '벧전': '베드로전서', '벧후': '베드로후서', '요일': '요한일서',
    '요이': '요한이서', '요삼': '요한삼서', '유': '유다서',
    '계': '요한계시록',
}


def citation_patterns(books):
    """(book citation, bare chapter citation) patterns for prose."""
    names = list(books) + list(ABBREVIATIONS)
    # Longest names first so '요한계시록' wins over '요한', '요일' over '요'.
    names.sort(key=len, reverse=True)
    cite = re.compile(r'(?<![가-힣])(' + '|'.join(map(re.escape, names)) +
                      r')\s*(\d+)\s*(?:[:장편])')
    bare = re.compile(r'(?<![가-힣\d:.])(\d+)\s*(?::\s*\d|장)')
    return cite, bare


def cited_chapters(text, books, patterns, home):
    """Chapters cited in prose: '갈라디아서 4:4', '(신 22:25)', '시편 23편',
    and bare '26:8' or '24장', which point into [home], the chapter's main
    book. Reading too much only compares more text, never less."""
    cite, bare = patterns

    def chapter(code, count, c):
        if 1 <= c <= count:
            yield (code, c)

    for m in cite.finditer(text):
        code, count = books[ABBREVIATIONS.get(m.group(1), m.group(1))]
        yield from chapter(code, count, int(m.group(2)))
    if home is not None:
        for m in bare.finditer(cite.sub(' ', text)):
            yield from chapter(*home, int(m.group(1)))


def fetch_chapter(book, chapter):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f'{book}.{chapter}.txt')
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return f.read()
    url = f'https://bible.bskorea.or.kr/bible/NKRV/{book}.{chapter}'
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                page = r.read().decode('utf-8')
            break
        except OSError:
            if attempt == 3:
                raise
            time.sleep(2 ** (attempt + 1))  # 2, 4, 8 s
    verses = [html.unescape(TAG.sub('', v)) for v in VERSE.findall(page)]
    text = '\n'.join(v.strip() for v in verses if v.strip())
    if not text:
        raise RuntimeError(f'no verse text found at {url}')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)
    time.sleep(0.3)
    return text


def strings(node, where=''):
    """Every reader-facing string in a chapter JSON, with its location."""
    if isinstance(node, dict):
        for k, v in node.items():
            if k in ('id', 'seasonId', 'kind', 'type', 'ref', 'role',
                     'reviewStatus', 'contentVersion'):
                continue
            yield from strings(v, f'{where}.{k}' if where else k)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from strings(v, f'{where}[{i}]')
    elif isinstance(node, str):
        yield where, node


def refs_in(node):
    if isinstance(node, dict):
        if isinstance(node.get('ref'), str):
            yield node['ref']
        for v in node.values():
            yield from refs_in(v)
    elif isinstance(node, list):
        for v in node:
            yield from refs_in(v)


def overlaps(text, grams, n):
    """Maximal runs of >= n syllables of [text] found in [grams]."""
    h = NOT_HANGUL.sub('', text)
    hits, i = [], 0
    while i + n <= len(h):
        if h[i:i + n] in grams:
            j = i + n
            while j < len(h) and h[j - n + 1:j + 1] in grams:
                j += 1
            hits.append(h[i:j])
            i = j
        else:
            i += 1
    return hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('files', nargs='*')
    ap.add_argument('--n', type=int, default=12,
                    help='minimum shared run in Hangul syllables (default 12)')
    args = ap.parse_args()
    files = args.files or sorted(glob.glob(os.path.join(CONTENT, 'season*', 'day[0-9][0-9].json')))
    allow = set()
    if os.path.exists(ALLOWLIST):
        with open(ALLOWLIST, encoding='utf-8') as f:
            allow = {NOT_HANGUL.sub('', l) for l in f if not l.startswith('#')}
            allow.discard('')

    books = load_books()
    patterns = citation_patterns(books)
    by_code = {code: (code, count) for code, count in books.values()}

    failures = 0
    for path in files:
        with open(path, encoding='utf-8') as f:
            chapter = json.load(f)
        refs = list(refs_in(chapter))
        bible_chapters = {c for r in refs for c in chapters_of(r)}
        home = by_code.get(chapters_of(refs[0])[0][0]) if refs else None
        for _, text in strings(chapter):
            bible_chapters.update(cited_chapters(text, books, patterns, home))
        bible_chapters = sorted(bible_chapters)
        source = ''.join(NOT_HANGUL.sub('', fetch_chapter(b, c))
                         for b, c in bible_chapters)
        grams = {source[i:i + args.n] for i in range(len(source) - args.n + 1)}
        found = []
        for where, text in strings(chapter):
            for run in overlaps(text, grams, args.n):
                if any(run in a or a in run for a in allow if len(a) >= args.n):
                    continue
                found.append((where, run))
        name = os.path.basename(path)
        print(f'{name}: {len(bible_chapters)} Bible chapters compared, '
              f'{len(found)} overlap(s) of >= {args.n} syllables')
        for where, run in found:
            print(f'    {where}: {run}')
        failures += len(found)
    if failures:
        print(f'\n{failures} overlap(s). Paraphrase these, or add a fixed proper '
              f'name to {os.path.relpath(ALLOWLIST, ROOT)}.')
        sys.exit(1)
    print('\nOK: no reproduced translation text.')


if __name__ == '__main__':
    main()
