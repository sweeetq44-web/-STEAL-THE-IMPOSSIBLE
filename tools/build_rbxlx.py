#!/usr/bin/env python3
"""
Builds a ready-to-open Roblox Studio XML Place File (.rbxlx) from default.project.json and src/.
Supports Rojo conventions:
  * *.server.luau -> Script
  * *.client.luau -> LocalScript
  * *.luau        -> ModuleScript
"""

import json
import os
import sys
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_JSON = os.path.join(REPO_ROOT, "default.project.json")
OUTPUT_RBXLX = os.path.join(REPO_ROOT, "StealTheImpossible.rbxlx")

_ref_counter = 0


def next_ref() -> str:
    global _ref_counter
    _ref_counter += 1
    return f"RBX{_ref_counter:08X}"


def cdata(text: str) -> str:
    # Safely handle any literal ']]>' inside Luau source
    safe = text.replace("]]>", "]]]]><![CDATA[>")
    return f"<![CDATA[{safe}]]>"


def prop_string(name: str, val: str) -> str:
    return f'<string name="{escape(name)}">{escape(val)}</string>'


def prop_protected(name: str, val: str) -> str:
    return f'<ProtectedString name="{escape(name)}">{cdata(val)}</ProtectedString>'


def prop_bool(name: str, val: bool) -> str:
    return f'<bool name="{escape(name)}">{"true" if val else "false"}</bool>'


def prop_float(name: str, val: float) -> str:
    return f'<float name="{escape(name)}">{val}</float>'


def prop_color3(name: str, rgb: list[float]) -> str:
    return (
        f'<Color3 name="{escape(name)}">'
        f"<R>{rgb[0]}</R><G>{rgb[1]}</G><B>{rgb[2]}</B>"
        f"</Color3>"
    )


def prop_token(name: str, token_val: int) -> str:
    return f'<token name="{escape(name)}">{token_val}</token>'


def serialize_script_file(filepath: str) -> str:
    filename = os.path.basename(filepath)
    if filename.endswith(".server.luau"):
        class_name = "Script"
        inst_name = filename[: -len(".server.luau")]
    elif filename.endswith(".client.luau"):
        class_name = "LocalScript"
        inst_name = filename[: -len(".client.luau")]
    elif filename.endswith(".luau"):
        class_name = "ModuleScript"
        inst_name = filename[: -len(".luau")]
    else:
        return ""

    with open(filepath, "r", encoding="utf-8") as f:
        source = f.read()

    lines = [
        f'<Item class="{class_name}" referent="{next_ref()}">',
        "  <Properties>",
        f'    {prop_string("Name", inst_name)}',
        f'    {prop_protected("Source", source)}',
        "  </Properties>",
        "</Item>",
    ]
    return "\n".join(lines)


def serialize_directory(dirpath: str, folder_name: str | None = None) -> str:
    entries = sorted(os.listdir(dirpath))
    children_xml: list[str] = []

    for entry in entries:
        full = os.path.join(dirpath, entry)
        if os.path.isdir(full):
            children_xml.append(serialize_directory(full, entry))
        elif os.path.isfile(full) and entry.endswith(".luau"):
            s = serialize_script_file(full)
            if s:
                children_xml.append(s)

    inner = "\n".join(children_xml)
    if folder_name is None:
        return inner

    return (
        f'<Item class="Folder" referent="{next_ref()}">\n'
        f"  <Properties>\n"
        f'    {prop_string("Name", folder_name)}\n'
        f"  </Properties>\n"
        f"{inner}\n"
        f"</Item>"
    )


def build_properties_xml(service_name: str, props: dict) -> str:
    items: list[str] = [prop_string("Name", service_name)]
    for k, v in props.items():
        if isinstance(v, bool):
            items.append(prop_bool(k, v))
        elif isinstance(v, (int, float)):
            items.append(prop_float(k, float(v)))
        elif isinstance(v, list) and len(v) == 3:
            items.append(prop_color3(k, v))
        elif k == "Technology" and v == "Future":
            items.append(prop_token("Technology", 4))
        elif isinstance(v, str):
            items.append(prop_string(k, v))
    return "\n    ".join(items)


def serialize_node(name: str, node: dict) -> str:
    class_name = node.get("$className", "Folder")
    props = node.get("$properties", {})
    path_rel = node.get("$path")

    children_xml: list[str] = []
    if path_rel:
        full_path = os.path.join(REPO_ROOT, path_rel)
        if os.path.isdir(full_path):
            children_xml.append(serialize_directory(full_path, None))

    for child_name, child_node in node.items():
        if child_name.startswith("$"):
            continue
        children_xml.append(serialize_node(child_name, child_node))

    props_xml = build_properties_xml(name, props)
    children_str = "\n".join(c for c in children_xml if c.strip())

    return (
        f'<Item class="{escape(class_name)}" referent="{next_ref()}">\n'
        f"  <Properties>\n"
        f"    {props_xml}\n"
        f"  </Properties>\n"
        f"{children_str}\n"
        f"</Item>"
    )


def main() -> int:
    with open(PROJECT_JSON, "r", encoding="utf-8") as f:
        project = json.load(f)

    tree = project["tree"]
    services_xml: list[str] = []
    for svc_name, svc_node in tree.items():
        if svc_name.startswith("$"):
            continue
        services_xml.append(serialize_node(svc_name, svc_node))

    xml_doc = (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
        "  <External>null</External>\n"
        "  <External>nil</External>\n"
        + "\n".join(services_xml)
        + "\n</roblox>\n"
    )

    # Validate XML structure strictly before writing!
    ET.fromstring(xml_doc)

    with open(OUTPUT_RBXLX, "w", encoding="utf-8") as f:
        f.write(xml_doc)

    size_kb = os.path.getsize(OUTPUT_RBXLX) / 1024.0
    print(f"Built {OUTPUT_RBXLX} cleanly ({size_kb:.1f} KB, valid Roblox XML)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
