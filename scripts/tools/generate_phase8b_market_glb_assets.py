import json
import math
import struct
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = PROJECT_ROOT / "assets" / "generated" / "map3d" / "models"

MATERIALS = {
    "stone": {"base": [0.24, 0.25, 0.23, 1.0], "roughness": 0.94},
    "wall": {"base": [0.31, 0.30, 0.27, 1.0], "roughness": 0.9},
    "wood": {"base": [0.16, 0.12, 0.09, 1.0], "roughness": 0.88},
    "ladder_highlight": {"base": [0.62, 0.38, 0.18, 1.0], "roughness": 0.86},
    "fabric": {"base": [0.28, 0.08, 0.065, 1.0], "roughness": 0.94},
    "fabric_teal": {"base": [0.055, 0.17, 0.18, 1.0], "roughness": 0.94},
    "roof": {"base": [0.18, 0.075, 0.055, 1.0], "roughness": 0.9},
    "dark": {"base": [0.07, 0.073, 0.07, 1.0], "roughness": 0.96},
    "window_emission": {"base": [0.8, 0.34, 0.11, 1.0], "roughness": 0.75, "emissive": [0.8, 0.34, 0.11]},
    "lantern_emission": {"base": [1.0, 0.42, 0.12, 1.0], "roughness": 0.7, "emissive": [1.0, 0.42, 0.12]},
}


def box_geometry():
    positions = []
    normals = []
    indices = []
    faces = [
        ((0, 0, 1), [(-0.5, -0.5, 0.5), (0.5, -0.5, 0.5), (0.5, 0.5, 0.5), (-0.5, 0.5, 0.5)]),
        ((0, 0, -1), [(0.5, -0.5, -0.5), (-0.5, -0.5, -0.5), (-0.5, 0.5, -0.5), (0.5, 0.5, -0.5)]),
        ((1, 0, 0), [(0.5, -0.5, 0.5), (0.5, -0.5, -0.5), (0.5, 0.5, -0.5), (0.5, 0.5, 0.5)]),
        ((-1, 0, 0), [(-0.5, -0.5, -0.5), (-0.5, -0.5, 0.5), (-0.5, 0.5, 0.5), (-0.5, 0.5, -0.5)]),
        ((0, 1, 0), [(-0.5, 0.5, 0.5), (0.5, 0.5, 0.5), (0.5, 0.5, -0.5), (-0.5, 0.5, -0.5)]),
        ((0, -1, 0), [(-0.5, -0.5, -0.5), (0.5, -0.5, -0.5), (0.5, -0.5, 0.5), (-0.5, -0.5, 0.5)]),
    ]
    for normal, verts in faces:
        base = len(positions)
        positions.extend(verts)
        normals.extend([normal] * 4)
        indices.extend([base, base + 1, base + 2, base, base + 2, base + 3])
    return positions, normals, indices


def cylinder_geometry(segments=16):
    positions = []
    normals = []
    indices = []

    for y, normal_y in ((0.5, 1), (-0.5, -1)):
        center_index = len(positions)
        positions.append((0, y, 0))
        normals.append((0, normal_y, 0))
        ring_start = len(positions)
        for i in range(segments):
            angle = math.tau * float(i) / float(segments)
            positions.append((math.cos(angle) * 0.5, y, math.sin(angle) * 0.5))
            normals.append((0, normal_y, 0))
        for i in range(segments):
            a = ring_start + i
            b = ring_start + ((i + 1) % segments)
            if normal_y > 0:
                indices.extend([center_index, a, b])
            else:
                indices.extend([center_index, b, a])

    side_start = len(positions)
    for i in range(segments):
        angle = math.tau * float(i) / float(segments)
        normal = (math.cos(angle), 0, math.sin(angle))
        positions.append((normal[0] * 0.5, -0.5, normal[2] * 0.5))
        positions.append((normal[0] * 0.5, 0.5, normal[2] * 0.5))
        normals.append(normal)
        normals.append(normal)
    for i in range(segments):
        a = side_start + i * 2
        b = side_start + ((i + 1) % segments) * 2
        indices.extend([a, b, a + 1, b, b + 1, a + 1])

    return positions, normals, indices


def add_aligned(data, payload):
    while len(data) % 4 != 0:
        data.extend(b"\x00")
    offset = len(data)
    data.extend(payload)
    return offset, len(payload)


def pack_floats(values):
    flat = []
    for value in values:
        flat.extend(value)
    return struct.pack("<%sf" % len(flat), *flat)


def pack_indices(values):
    return struct.pack("<%sH" % len(values), *values)


def accessor_min_max(positions):
    return (
        [min(p[i] for p in positions) for i in range(3)],
        [max(p[i] for p in positions) for i in range(3)],
    )


def write_glb(path, node_specs, scene_name):
    data = bytearray()
    gltf = {
        "asset": {"version": "2.0", "generator": "phase8b_market_glb_generator"},
        "scene": 0,
        "scenes": [{"name": scene_name, "nodes": []}],
        "nodes": [],
        "meshes": [],
        "materials": [],
        "buffers": [{"byteLength": 0}],
        "bufferViews": [],
        "accessors": [],
    }

    material_indices = {}
    for name, spec in MATERIALS.items():
        material = {
            "name": name,
            "pbrMetallicRoughness": {
                "baseColorFactor": spec["base"],
                "metallicFactor": 0.0,
                "roughnessFactor": spec["roughness"],
            },
        }
        if "emissive" in spec:
            material["emissiveFactor"] = spec["emissive"]
        material_indices[name] = len(gltf["materials"])
        gltf["materials"].append(material)

    geometry_cache = {"box": box_geometry(), "cylinder": cylinder_geometry()}
    mesh_indices = {}

    def get_mesh(shape, material_name):
        key = (shape, material_name)
        if key in mesh_indices:
            return mesh_indices[key]

        positions, normals, indices = geometry_cache[shape]
        pos_offset, pos_len = add_aligned(data, pack_floats(positions))
        norm_offset, norm_len = add_aligned(data, pack_floats(normals))
        idx_offset, idx_len = add_aligned(data, pack_indices(indices))

        pos_view = len(gltf["bufferViews"])
        gltf["bufferViews"].append({"buffer": 0, "byteOffset": pos_offset, "byteLength": pos_len, "target": 34962})
        norm_view = len(gltf["bufferViews"])
        gltf["bufferViews"].append({"buffer": 0, "byteOffset": norm_offset, "byteLength": norm_len, "target": 34962})
        idx_view = len(gltf["bufferViews"])
        gltf["bufferViews"].append({"buffer": 0, "byteOffset": idx_offset, "byteLength": idx_len, "target": 34963})

        min_value, max_value = accessor_min_max(positions)
        pos_accessor = len(gltf["accessors"])
        gltf["accessors"].append({
            "bufferView": pos_view,
            "componentType": 5126,
            "count": len(positions),
            "type": "VEC3",
            "min": min_value,
            "max": max_value,
        })
        norm_accessor = len(gltf["accessors"])
        gltf["accessors"].append({
            "bufferView": norm_view,
            "componentType": 5126,
            "count": len(normals),
            "type": "VEC3",
        })
        idx_accessor = len(gltf["accessors"])
        gltf["accessors"].append({
            "bufferView": idx_view,
            "componentType": 5123,
            "count": len(indices),
            "type": "SCALAR",
        })

        mesh_index = len(gltf["meshes"])
        gltf["meshes"].append({
            "name": "%s_%s" % (shape, material_name),
            "primitives": [{
                "attributes": {"POSITION": pos_accessor, "NORMAL": norm_accessor},
                "indices": idx_accessor,
                "material": material_indices[material_name],
            }],
        })
        mesh_indices[key] = mesh_index
        return mesh_index

    for spec in node_specs:
        node_index = len(gltf["nodes"])
        gltf["nodes"].append({
            "name": spec["name"],
            "mesh": get_mesh(spec["shape"], spec["material"]),
            "translation": spec.get("translation", [0, 0, 0]),
            "scale": spec.get("scale", [1, 1, 1]),
        })
        gltf["scenes"][0]["nodes"].append(node_index)

    gltf["buffers"][0]["byteLength"] = len(data)
    json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    while len(json_bytes) % 4 != 0:
        json_bytes += b" "
    while len(data) % 4 != 0:
        data.extend(b"\x00")

    total_len = 12 + 8 + len(json_bytes) + 8 + len(data)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as file:
        file.write(struct.pack("<4sII", b"glTF", 2, total_len))
        file.write(struct.pack("<I4s", len(json_bytes), b"JSON"))
        file.write(json_bytes)
        file.write(struct.pack("<I4s", len(data), b"BIN\x00"))
        file.write(data)


def box(name, material, translation, scale):
    return {"name": name, "shape": "box", "material": material, "translation": translation, "scale": scale}


def cylinder(name, material, translation, scale):
    return {"name": name, "shape": "cylinder", "material": material, "translation": translation, "scale": scale}


def combined_market_nodes():
    nodes = [
        box("ForegroundLowWall", "dark", [0.1, 0.2, 4.72], [8.4, 0.3, 0.26]),
        box("ForegroundLeftStep", "dark", [-4.2, 0.12, 4.05], [3.2, 0.16, 0.72]),
        box("ForegroundRightStep", "dark", [4.45, 0.11, 4.0], [3.0, 0.14, 0.68]),
        box("LeftFacadeWallLip", "wall", [-6.05, 1.35, -0.6], [1.1, 2.7, 3.4]),
        box("LeftEaveDarkRoof", "roof", [-5.55, 2.82, -0.2], [2.9, 0.22, 1.9]),
        box("LeftShopSign", "wood", [-4.78, 1.72, 1.52], [0.9, 0.35, 0.08]),
        box("LeftWindowFrameA", "wood", [-5.48, 1.64, 0.85], [0.08, 0.9, 0.08]),
        box("LeftWindowFrameB", "wood", [-5.48, 1.64, 0.25], [0.08, 0.9, 0.08]),
        box("LeftDoorTopTrim", "wood", [-5.48, 2.06, 0.55], [0.08, 0.08, 0.82]),
        box("RightFacadeWallLip", "wall", [5.75, 1.38, -0.75], [1.2, 2.8, 3.2]),
        box("RightEaveDarkRoof", "roof", [5.22, 2.9, -0.38], [2.75, 0.22, 1.65]),
        box("RightBalconyShelf", "wood", [4.32, 2.1, 0.78], [1.15, 0.12, 0.52]),
        box("RightBalconyDarkUnderSide", "dark", [4.32, 1.96, 0.78], [1.15, 0.08, 0.52]),
        box("RightUpperClothA", "fabric_teal", [4.04, 1.74, 1.08], [0.26, 0.54, 0.04]),
        box("RightUpperClothB", "fabric", [4.34, 1.72, 1.08], [0.22, 0.48, 0.04]),
        box("RightVisibleHighLadderLeftRail", "ladder_highlight", [4.08, 1.78, 1.16], [0.09, 2.95, 0.09]),
        box("RightVisibleHighLadderRightRail", "ladder_highlight", [4.5, 1.78, 1.16], [0.09, 2.95, 0.09]),
        box("RightVisibleHighLadderRungA", "ladder_highlight", [4.29, 0.56, 1.18], [0.58, 0.08, 0.08]),
        box("RightVisibleHighLadderRungB", "ladder_highlight", [4.29, 0.96, 1.18], [0.58, 0.08, 0.08]),
        box("RightVisibleHighLadderRungC", "ladder_highlight", [4.29, 1.36, 1.18], [0.58, 0.08, 0.08]),
        box("RightVisibleHighLadderRungD", "ladder_highlight", [4.29, 1.76, 1.18], [0.58, 0.08, 0.08]),
        box("RightVisibleHighLadderRungE", "ladder_highlight", [4.29, 2.16, 1.18], [0.58, 0.08, 0.08]),
        box("RightVisibleHighLadderRungF", "ladder_highlight", [4.29, 2.56, 1.18], [0.58, 0.08, 0.08]),
        box("RightVisibleHighLadderTopHook", "ladder_highlight", [4.29, 2.9, 1.18], [0.64, 0.08, 0.08]),
        box("BackWallHorizontalTrimA", "wood", [0.0, 1.1, -3.18], [5.4, 0.08, 0.08]),
        box("BackWallHorizontalTrimB", "wood", [0.0, 2.1, -3.18], [5.4, 0.08, 0.08]),
        box("BackWallVerticalTrimA", "wood", [-2.2, 1.62, -3.18], [0.08, 1.22, 0.08]),
        box("BackWallVerticalTrimB", "wood", [-0.8, 1.62, -3.18], [0.08, 1.22, 0.08]),
        box("BackWallVerticalTrimC", "wood", [0.8, 1.62, -3.18], [0.08, 1.22, 0.08]),
        box("BackWallVerticalTrimD", "wood", [2.2, 1.62, -3.18], [0.08, 1.22, 0.08]),
        box("LeftCanopyStall", "fabric_teal", [-2.8, 1.48, 0.25], [2.05, 0.12, 1.3]),
        box("RightCanopyStall", "fabric", [2.7, 1.48, -0.15], [2.05, 0.12, 1.25]),
        box("LeftTable", "wood", [-2.8, 0.62, 0.55], [1.55, 0.18, 0.72]),
        box("RightTable", "wood", [2.7, 0.62, 0.25], [1.55, 0.18, 0.72]),
        box("CrateA", "wood", [-3.55, 0.28, 1.35], [0.42, 0.36, 0.42]),
        box("CrateB", "wood", [3.55, 0.26, 0.85], [0.46, 0.32, 0.36]),
        box("CrateC", "wood", [-1.72, 0.24, 1.05], [0.34, 0.28, 0.38]),
        box("CrateD", "wood", [1.78, 0.24, 0.74], [0.34, 0.28, 0.36]),
        cylinder("BarrelA", "wood", [-4.12, 0.45, 0.35], [0.32, 0.62, 0.32]),
        cylinder("BarrelB", "wood", [4.18, 0.4, 0.18], [0.28, 0.54, 0.28]),
        cylinder("BarrelC", "wood", [-3.75, 0.35, 1.0], [0.24, 0.46, 0.24]),
        cylinder("JarA", "dark", [-2.35, 0.82, 0.56], [0.18, 0.34, 0.18]),
        cylinder("JarB", "dark", [2.32, 0.82, 0.3], [0.16, 0.3, 0.16]),
        cylinder("JarC", "dark", [3.35, 0.82, -0.05], [0.14, 0.28, 0.14]),
        cylinder("PlateStackA", "wall", [-3.0, 0.78, 0.56], [0.26, 0.055, 0.26]),
        cylinder("PlateStackB", "wall", [3.02, 0.78, 0.28], [0.26, 0.055, 0.26]),
        cylinder("PlateStackC", "wall", [2.55, 0.79, 0.72], [0.22, 0.05, 0.22]),
        cylinder("PlateStackD", "wall", [3.45, 0.79, 0.55], [0.22, 0.05, 0.22]),
        box("FoldedClothA", "fabric", [-2.42, 0.82, 0.92], [0.66, 0.055, 0.3]),
        box("FoldedClothB", "fabric_teal", [2.1, 0.82, 0.64], [0.5, 0.055, 0.28]),
        box("ShelfA", "wood", [4.28, 1.18, -0.88], [0.9, 0.08, 0.28]),
        box("RearWindowGlowA", "window_emission", [-3.1, 1.92, -3.25], [0.42, 0.7, 0.04]),
        box("RearWindowGlowB", "window_emission", [-1.15, 1.92, -3.45], [0.42, 0.7, 0.04]),
        box("RearWindowGlowE", "window_emission", [0.75, 1.94, -3.35], [0.34, 0.6, 0.04]),
        box("RearWindowGlowF", "window_emission", [2.4, 1.92, -3.28], [0.3, 0.55, 0.04]),
        cylinder("RearLanternGlowC", "lantern_emission", [1.22, 1.72, -3.28], [0.22, 0.28, 0.22]),
        cylinder("RearLanternGlowD", "lantern_emission", [3.22, 1.72, -3.1], [0.22, 0.28, 0.22]),
    ]
    return nodes


def main():
    write_glb(MODEL_DIR / "hd2d_market_reference_match.glb", combined_market_nodes(), "hd2d_market_reference_match")
    write_glb(MODEL_DIR / "hd2d_market_prop_foreground_steps.glb", [
        box("ForegroundLowWall", "dark", [0, 0.25, 0], [2.2, 0.5, 0.35]),
        box("ForegroundStepA", "dark", [-0.55, 0.1, -0.45], [1.0, 0.2, 0.5]),
        box("ForegroundStepB", "dark", [0.65, 0.08, -0.55], [1.2, 0.16, 0.42]),
    ], "hd2d_market_prop_foreground_steps")
    write_glb(MODEL_DIR / "hd2d_market_prop_crates.glb", [
        box("CrateA", "wood", [-0.24, 0.2, 0], [0.44, 0.4, 0.44]),
        box("CrateB", "wood", [0.28, 0.16, 0.1], [0.4, 0.32, 0.36]),
    ], "hd2d_market_prop_crates")
    write_glb(MODEL_DIR / "hd2d_market_prop_barrels.glb", [
        cylinder("BarrelA", "wood", [-0.24, 0.33, 0], [0.32, 0.66, 0.32]),
        cylinder("BarrelB", "wood", [0.28, 0.28, 0.06], [0.26, 0.56, 0.26]),
    ], "hd2d_market_prop_barrels")
    write_glb(MODEL_DIR / "hd2d_market_prop_tableware.glb", [
        cylinder("JarA", "dark", [-0.34, 0.22, 0], [0.18, 0.34, 0.18]),
        cylinder("PlateStackA", "wall", [0.0, 0.08, 0.02], [0.26, 0.055, 0.26]),
        cylinder("PlateStackB", "wall", [0.34, 0.08, -0.04], [0.24, 0.05, 0.24]),
    ], "hd2d_market_prop_tableware")
    write_glb(MODEL_DIR / "hd2d_market_prop_ladder.glb", [
        box("LadderLeftRail", "wood", [-0.28, 0.0, 0], [0.08, 2.5, 0.08]),
        box("LadderRightRail", "wood", [0.28, 0.0, 0], [0.08, 2.5, 0.08]),
        box("LadderRungA", "wood", [0, -0.75, 0], [0.68, 0.07, 0.07]),
        box("LadderRungB", "wood", [0, -0.25, 0], [0.68, 0.07, 0.07]),
        box("LadderRungC", "wood", [0, 0.25, 0], [0.68, 0.07, 0.07]),
        box("LadderRungD", "wood", [0, 0.75, 0], [0.68, 0.07, 0.07]),
    ], "hd2d_market_prop_ladder")
    write_glb(MODEL_DIR / "hd2d_market_prop_hanging_cloth.glb", [
        box("HangingClothRed", "fabric", [-0.28, 0, 0], [0.32, 0.7, 0.035]),
        box("HangingClothDark", "fabric", [0.18, -0.05, 0], [0.26, 0.6, 0.035]),
    ], "hd2d_market_prop_hanging_cloth")
    write_glb(MODEL_DIR / "hd2d_market_prop_signboard.glb", [
        box("ShopSignBoard", "wood", [0, 0, 0], [0.9, 0.35, 0.08]),
        box("ShopSignTrimTop", "dark", [0, 0.2, 0.02], [1.0, 0.05, 0.1]),
    ], "hd2d_market_prop_signboard")


if __name__ == "__main__":
    main()
