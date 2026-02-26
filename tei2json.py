#!/usr/bin/env python3
"""
tei2json.py

Usage:
  # single file -> prints JSON to stdout
  python tei2json.py input.xml

  # directory -> produce one JSON file per TEI named <basename>.json
  python tei2json.py --dir ./britishLibrary-data/data/tei --outdir json_output

  # directory -> produce OpenSearch bulk file
  python tei2json.py --dir ./britishLibrary-data/data/tei --bulk bulk_data.json --index britishlibrary-index-1 --idprefix ms
"""

from lxml import etree
import argparse
import json
import os
from pathlib import Path
from typing import List

NS = {"tei": "http://www.tei-c.org/ns/1.0"}

# ISO 639-3 language code mapping for scripts
SCRIPT_LANG_MAP = {
    "syr": "Syriac",
    "syr-Syre": "Syriac (Estrangela)",
    "syr-Syrj": "Syriac (Western)",
    "syr-Syrn": "Syriac (Eastern)",
    "ar": "Arabic",
    "grc": "Greek",
    "he": "Hebrew",
    "en": "English",
    "la": "Latin",
    "mul": "Multiple languages",
    "cop": "Coptic",
    "fr": "French",
    "hy": "Armenian",
    "zh-hant": "Chinese (Traditional)",
    "hyr": "Armenian",
    "qhy-x-cpas":"Classical Syriac (ܟܬܒܢܝܐ)",
    "xcl": "Lycian",
    "und": "Undetermined",
    "syr-x-syrm": "Syriac (Melkite script)",
    "ar-syr": "Arabic language written in Syriac script"
}


def map_script_to_language(script_codes):
    """Convert script codes to language names"""
    if not script_codes:
        return None
    codes = script_codes.split()
    langs = []
    for code in codes:
        lang = SCRIPT_LANG_MAP.get(code.strip(), code.strip())
        if lang not in langs:
            langs.append(lang)
    return ", ".join(langs) if langs else None

def text_list(root, xpath) -> List[str]:
    """Return trimmed text contents for nodes matched by xpath"""
    nodes = root.xpath(xpath, namespaces=NS)
    out = []
    for n in nodes:
        # If element node with mixed content, get all text recursively
        if isinstance(n, etree._Element):
            txt = ''.join(n.itertext()).strip()
        else:
            txt = (str(n) or "").strip()
        if txt:
            out.append(" ".join(txt.split()))
    return out

def html_fragment(node):
    """Serialize an element's inner content, preserving inline markup (like <span>)"""
    if node is None:
        return ""
    parts = []
    for child in node.iterchildren():
        parts.append(etree.tostring(child, encoding="unicode", method="html"))
    # include text node before first child if present
    if (node.text or "").strip():
        parts.insert(0, node.text.strip())
    return "".join(parts).strip()

def first_text(root, xpath):
    lst = text_list(root, xpath)
    return lst[0] if lst else None

def extract_json(tree):
    root = tree.getroot()

    # Title from titleStmt
    title_stmt = text_list(root, ".//tei:titleStmt/tei:title[@level='a']")
    
    # Author from titleStmt/author
    authors = text_list(root, ".//tei:titleStmt/tei:author")
    
    # Corpus URI from publicationStmt/idno[@type='URI']
    corpus_uri = first_text(root, ".//tei:publicationStmt/tei:idno[@type='URI']")
    
    # Work URI from title[@ref]
    work_uri = first_text(root, ".//tei:titleStmt/tei:title[@level='a']/@ref")
    
    # Catalog from title[@level='s'][@ref]
    catalog = first_text(root, ".//tei:titleStmt/tei:title[@level='s']/@ref")
    
    # Catalog name from title[@level='s'] text content
    catalog_name = first_text(root, ".//tei:titleStmt/tei:title[@level='s'][@ref]")
    
    # Section numbers from div[@type='section']/@n
    section_nos = text_list(root, ".//tei:div[@type='section']/@n")
    
    # Syriaca URIs - combine work and catalog URIs
    syriaca_uris = []
    if work_uri: syriaca_uris.append(work_uri)
    if catalog: syriaca_uris.append(catalog)
    syriaca_uri = " ".join(syriaca_uris) if syriaca_uris else None
    
    # idno from publicationStmt
    idno = first_text(root, ".//tei:publicationStmt/tei:idno[@type='URI']")
    
    # Date from origDate
    orig_date = first_text(root, ".//tei:origDate[@type='composition']")
    date_when = first_text(root, ".//tei:origDate[@type='composition']/@when")
    
    # Language usage from profileDesc/langUsage
    lang_usage = []
    for lang in root.xpath(".//tei:profileDesc/tei:langUsage/tei:language", namespaces=NS):
        lang_ident = lang.get('ident', '')
        lang_text = ''.join(lang.itertext()).strip()
        lang_name = SCRIPT_LANG_MAP.get(lang_ident, lang_ident)
        if lang_ident or lang_text:
            lang_usage.append({
                "ident": lang_ident,
                "language": lang_name,
                "description": lang_text
            })
    
    # Person names from name[@type='person'] in respStmt (not editors) and author
    person_names = []
    # Get authors
    person_names.extend(text_list(root, ".//tei:titleStmt/tei:author"))
    # Get names from respStmt only
    person_names.extend(text_list(root, ".//tei:titleStmt/tei:respStmt/tei:name[@type='person']"))
    
    # Sections: collect div[@type='section'] with their @n and Syriac text
    sections = []
    for div in root.xpath(".//tei:div[@type='section']", namespaces=NS):
        section_num = div.get('n', '')
        syr_text = ' '.join(div.xpath(".//tei:p[@xml:lang='syr']//text()", namespaces=NS))
        if section_num and syr_text:
            sections.append({
                "section": section_num,
                "text": " ".join(syr_text.split())
            })
    
    # Full Syriac text concatenated
    full_syriac_text = ' '.join(root.xpath(".//tei:div[@type='section']//tei:p[@xml:lang='syr']//text()", namespaces=NS))
    full_syriac_text = " ".join(full_syriac_text.split()) if full_syriac_text else None
    
    # Rubric from div[@type='rubric']
    rubric = first_text(root, ".//tei:div[@type='rubric']//tei:p[@xml:lang='syr']")

    out = {}
    if title_stmt: out["title"] = title_stmt
    if authors: out["author"] = authors
    if idno: out["idno"] = idno
    if corpus_uri: out["corpusUri"] = corpus_uri
    if work_uri: out["workUri"] = work_uri
    if catalog: out["catalog"] = catalog
    if catalog_name: out["catalogName"] = catalog_name
    if section_nos: out["sectionNo"] = section_nos
    if syriaca_uri: out["syriacaURI"] = syriaca_uri
    if orig_date: out["origDate"] = orig_date
    if date_when: out["dateWhen"] = date_when
    if lang_usage: out["langUsage"] = lang_usage
    if person_names: out["persName"] = person_names
    if sections: out["sections"] = sections
    if full_syriac_text: out["fullText"] = full_syriac_text
    if rubric: out["rubric"] = rubric

    return out

def process_file(path: Path):
    parser = etree.XMLParser(recover=True, remove_blank_text=True)
    tree = etree.parse(str(path), parser=parser)
    data = extract_json(tree)
    return data

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path", help="TEI XML file or directory")
    ap.add_argument("--outdir", "-o", help="directory to write per-file JSON outputs")
    ap.add_argument("--bulk", help="write an OpenSearch bulk file (newline-delimited index JSON + doc JSON)")
    ap.add_argument("--manuscripts", help="write a manuscripts.json array file for web UI")
    ap.add_argument("--index", default="britishlibrary-index-1", help="index name for bulk")
    ap.add_argument("--idprefix", default="ms", help="prefix for _id in bulk (e.g., ms)")
    args = ap.parse_args()

    p = Path(args.path)
    targets = []
    if p.is_dir():
        targets = sorted(p.glob("*.xml"))
    elif p.is_file():
        targets = [p]
    else:
        raise SystemExit("Path not found")

    os.makedirs(args.outdir or ".", exist_ok=True)

    bulk_writer = None
    if args.bulk:
        bulk_writer = open(args.bulk, "w", encoding="utf8")
    
    manuscripts_list = []

    for f in targets:
        try:
            j = process_file(f)
        except Exception as e:
            print(f"ERROR parsing {f}: {e}")
            continue

        fname = f.stem
        # if outdir requested, write each JSON
        if args.outdir:
            outp = Path(args.outdir) / (fname + ".json")
            with open(outp, "w", encoding="utf8") as fh:
                json.dump(j, fh, ensure_ascii=False, indent=2)
            print(f"Wrote {outp}")

        # if bulk requested, write two-line bulk entry
        if bulk_writer:
            meta = {"index": {"_index": args.index, "_id": f"{args.idprefix}-{fname}"}}
            bulk_writer.write(json.dumps(meta, ensure_ascii=False) + "\n")
            bulk_writer.write(json.dumps(j, ensure_ascii=False) + "\n")
        
        # collect for manuscripts array
        if args.manuscripts:
            j["id"] = f"{fname}"
            # Deduplicate and clean fields
            for key, value in j.items():
                if isinstance(value, list):
                    seen = set()
                    deduped = []
                    for item in value:
                        if item and item not in seen:
                            seen.add(item)
                            deduped.append(item)
                    j[key] = deduped
            
            manuscripts_list.append(j)

    if bulk_writer:
        bulk_writer.close()
        print(f"Wrote bulk file {args.bulk}")
    
    if args.manuscripts:
        with open(args.manuscripts, "w", encoding="utf8") as fh:
            json.dump(manuscripts_list, fh, ensure_ascii=False, indent=2)
        print(f"Wrote manuscripts file {args.manuscripts}")
    
    # If single file with no output flags, print to stdout
    if p.is_file() and not args.outdir and not args.bulk and not args.manuscripts and len(targets) == 1:
        j = process_file(p)
        print(json.dumps(j, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
