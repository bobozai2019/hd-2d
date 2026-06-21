import json
import struct
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
GLB_PATH = PROJECT_ROOT / "assets/generated/map3d/models/hd2d_market_plaza.glb"
TEXTURE_DIR = PROJECT_ROOT / "assets/generated/map3d/textures"

IMAGE_REPLACEMENTS = {
    "hd2d_market_plaza_limestone_wall_albedo": TEXTURE_DIR / "hd2d_market_plaza_limestone_wall_albedo.png",
    "hd2d_market_plaza_limestone_wall_normal": TEXTURE_DIR / "hd2d_market_plaza_limestone_wall_normal.png",
    "hd2d_market_plaza_stone_floor_albedo": TEXTURE_DIR / "hd2d_market_plaza_stone_floor_albedo.png",
    "hd2d_market_plaza_stone_floor_normal": TEXTURE_DIR / "hd2d_market_plaza_stone_floor_normal.png",
    "hd2d_market_plaza_aged_wood_albedo": TEXTURE_DIR / "hd2d_market_plaza_aged_wood_albedo.png",
    "hd2d_market_plaza_aged_wood_normal": TEXTURE_DIR / "hd2d_market_plaza_aged_wood_normal.png",
    "hd2d_market_plaza_terracotta_roof_albedo": TEXTURE_DIR / "hd2d_market_plaza_terracotta_roof_albedo.png",
    "hd2d_market_plaza_terracotta_roof_normal": TEXTURE_DIR / "hd2d_market_plaza_terracotta_roof_normal.png",
    "hd2d_market_plaza_market_fabric_albedo": TEXTURE_DIR / "hd2d_market_plaza_market_fabric_albedo.png",
    "hd2d_market_plaza_market_fabric_normal": TEXTURE_DIR / "hd2d_market_plaza_market_fabric_normal.png",
}


def main() -> None:
    data = GLB_PATH.read_bytes()
    magic, version, total_length = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67 or version != 2:
        raise RuntimeError(f"{GLB_PATH} is not a GLB v2 file")
    if total_length != len(data):
        raise RuntimeError(f"{GLB_PATH} length header does not match file size")

    chunks = _read_chunks(data)
    json_chunk = next(chunk for chunk_type, chunk in chunks if chunk_type == 0x4E4F534A)
    bin_chunk = next(chunk for chunk_type, chunk in chunks if chunk_type == 0x004E4942)
    gltf = json.loads(json_chunk.decode("utf-8"))

    replacement_by_buffer_view = {}
    for image in gltf.get("images", []):
        image_name = image.get("name", "")
        source_path = IMAGE_REPLACEMENTS.get(image_name)
        if source_path is None:
            continue
        if not source_path.exists():
            raise RuntimeError(f"Missing replacement texture: {source_path}")
        replacement_by_buffer_view[image["bufferView"]] = source_path.read_bytes()

    if not replacement_by_buffer_view:
        raise RuntimeError("No matching embedded GLB images were found to replace")

    new_bin = bytearray()
    for index, buffer_view in enumerate(gltf["bufferViews"]):
        source = replacement_by_buffer_view.get(index)
        if source is None:
            offset = int(buffer_view.get("byteOffset", 0))
            length = int(buffer_view["byteLength"])
            source = bin_chunk[offset:offset + length]

        _pad4(new_bin)
        buffer_view["byteOffset"] = len(new_bin)
        buffer_view["byteLength"] = len(source)
        new_bin.extend(source)

    _pad4(new_bin)
    gltf["buffers"][0]["byteLength"] = len(new_bin)

    json_bytes = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    json_padding = (4 - len(json_bytes) % 4) % 4
    json_bytes += b" " * json_padding

    output = bytearray()
    output.extend(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(json_bytes) + 8 + len(new_bin)))
    output.extend(struct.pack("<II", len(json_bytes), 0x4E4F534A))
    output.extend(json_bytes)
    output.extend(struct.pack("<II", len(new_bin), 0x004E4942))
    output.extend(new_bin)
    GLB_PATH.write_bytes(output)
    print(f"Patched {len(replacement_by_buffer_view)} embedded textures in {GLB_PATH}")


def _read_chunks(data: bytes) -> list[tuple[int, bytes]]:
    offset = 12
    chunks = []
    while offset < len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunks.append((chunk_type, data[offset:offset + chunk_length]))
        offset += chunk_length
    return chunks


def _pad4(buffer: bytearray) -> None:
    while len(buffer) % 4 != 0:
        buffer.append(0)


if __name__ == "__main__":
    main()
