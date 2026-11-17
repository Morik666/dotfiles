"""Run inside the HA container to register the inverter package, preserving YAML."""

import shutil
import sys
from pathlib import Path

import yaml
from yaml.nodes import MappingNode

root = Path(sys.argv[1] if len(sys.argv) > 1 else "/config").resolve()
config = root / "configuration.yaml"
text = config.read_text()
tree = yaml.compose(text)
if not isinstance(tree, MappingNode):
    raise SystemExit("Expected a mapping in configuration.yaml")


def child(node, name):
    if not isinstance(node, MappingNode):
        raise SystemExit(f"Expected a mapping containing {name}")
    return next((value for key, value in node.value if key.value == name), None)


home = child(tree, "homeassistant")
insertion = None
if home is None:
    insertion = (len(text), "\nhomeassistant:\n  packages:\n    crait_inverter: !include crait-inverter.yaml\n")
else:
    packages = child(home, "packages")
    if packages is None:
        insertion = (home.end_mark.index, "  packages:\n    crait_inverter: !include crait-inverter.yaml\n")
    elif packages.tag == "!include_dir_named":
        directory = (root / packages.value).resolve()
        if not directory.is_relative_to(root):
            raise SystemExit("Packages directory must be inside /config")
        directory.mkdir(parents=True, exist_ok=True)
        target = directory / "crait_inverter.yaml"
        source = root / "crait-inverter.yaml"
        if target.exists() and target.read_bytes() != source.read_bytes():
            raise SystemExit("An existing crait_inverter.yaml differs; merge it manually")
        if not target.exists():
            shutil.copy2(source, target)
    elif isinstance(packages, MappingNode):
        existing = child(packages, "crait_inverter")
        if existing is None:
            insertion = (packages.end_mark.index, "    crait_inverter: !include crait-inverter.yaml\n")
        elif existing.tag != "!include" or existing.value != "crait-inverter.yaml":
            raise SystemExit("An unrelated crait_inverter package already exists")
    else:
        raise SystemExit("Unsupported packages configuration; merge inverter.yaml manually")

if insertion:
    # Block mappings only: flow-style mappings need an explicit manual merge.
    if home is not None and home.flow_style:
        raise SystemExit("Flow-style homeassistant mapping requires a manual merge")
    if home is not None:
        packages = child(home, "packages")
        if isinstance(packages, MappingNode) and packages.flow_style:
            raise SystemExit("Flow-style packages mapping requires a manual merge")
    index, addition = insertion
    if index and text[index - 1] != "\n":
        addition = "\n" + addition
    config.write_text(text[:index] + addition + text[index:])
print("Inverter package registered")
