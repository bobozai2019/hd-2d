from pathlib import Path

from generate_phase8b_market_glb_assets import MATERIALS, box, cylinder, write_glb


PROJECT_ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = PROJECT_ROOT / "assets" / "generated" / "map3d" / "models"


MATERIALS.update({
    "wall_trim": {"base": [0.18, 0.17, 0.155, 1.0], "roughness": 0.92},
    "ceramic": {"base": [0.42, 0.39, 0.33, 1.0], "roughness": 0.86},
    "fabric_red": {"base": [0.24, 0.065, 0.055, 1.0], "roughness": 0.96},
    "fabric_teal": {"base": [0.045, 0.13, 0.14, 1.0], "roughness": 0.96},
    "shadow_wood": {"base": [0.095, 0.072, 0.055, 1.0], "roughness": 0.94},
    "emission_lantern": {"base": [1.0, 0.42, 0.12, 1.0], "roughness": 0.7, "emissive": [1.0, 0.42, 0.12]},
    "emission_window": {"base": [0.82, 0.34, 0.12, 1.0], "roughness": 0.72, "emissive": [0.82, 0.34, 0.12]},
})


def right_tower_nodes():
    nodes = [
        box("RightTowerPlatformMain", "shadow_wood", [4.88, 2.24, 0.55], [2.25, 0.16, 0.8]),
        box("RightTowerPlatformShadowLip", "dark", [4.88, 2.08, 0.55], [2.35, 0.12, 0.86]),
        box("RightTowerUpperMass", "wall", [5.5, 3.05, -0.42], [1.55, 2.4, 2.6]),
        box("RightTowerSideButtress", "wall_trim", [4.58, 2.7, -0.24], [0.28, 2.2, 2.15]),
        box("RightTowerBalconyRailA", "shadow_wood", [4.18, 2.56, 0.95], [0.1, 0.62, 0.12]),
        box("RightTowerBalconyRailB", "shadow_wood", [4.78, 2.56, 0.95], [0.1, 0.62, 0.12]),
        box("RightTowerBalconyRailC", "shadow_wood", [5.38, 2.56, 0.95], [0.1, 0.62, 0.12]),
        box("RightTowerBalconyRailTop", "shadow_wood", [4.78, 2.86, 0.95], [1.36, 0.09, 0.12]),
        box("RightTowerDoorFrameA", "wall_trim", [5.22, 2.82, 0.02], [0.12, 1.08, 0.12]),
        box("RightTowerDoorFrameB", "wall_trim", [5.78, 2.82, 0.02], [0.12, 1.08, 0.12]),
        box("RightTowerDoorFrameTop", "wall_trim", [5.5, 3.33, 0.02], [0.72, 0.12, 0.12]),
        box("RightWindowFrameUpperA", "wall_trim", [4.78, 3.64, -1.15], [0.58, 0.08, 0.1]),
        box("RightWindowFrameUpperB", "wall_trim", [4.78, 3.28, -1.15], [0.58, 0.08, 0.1]),
        box("RightHangingClothRed", "fabric_red", [4.18, 2.16, 1.02], [0.34, 0.86, 0.045]),
        box("RightHangingClothTeal", "fabric_teal", [4.62, 2.10, 1.03], [0.3, 0.72, 0.045]),
        box("RightHangingClothShadowFold", "dark", [4.42, 1.66, 1.055], [0.58, 0.08, 0.05]),
        box("RightVisibleHighLadderLeftRailArtpass", "ladder_highlight", [4.02, 1.78, 1.28], [0.075, 3.05, 0.075]),
        box("RightVisibleHighLadderRightRailArtpass", "ladder_highlight", [4.46, 1.78, 1.28], [0.075, 3.05, 0.075]),
    ]
    for i, y in enumerate([0.54, 0.9, 1.26, 1.62, 1.98, 2.34, 2.7]):
        nodes.append(box("RightVisibleHighLadderRungArtpass%02d" % i, "ladder_highlight", [4.24, y, 1.31], [0.58, 0.065, 0.065]))
    return nodes


def stall_nodes():
    nodes = [
        box("StallClusterA_Canopy", "fabric_teal", [-3.08, 1.52, 0.18], [2.25, 0.12, 1.38]),
        box("StallClusterA_TableTop", "shadow_wood", [-3.05, 0.68, 0.58], [1.72, 0.16, 0.82]),
        box("StallClusterA_ShelfLower", "shadow_wood", [-3.05, 0.48, 0.58], [1.52, 0.1, 0.7]),
        box("StallClusterB_Canopy", "fabric_red", [2.42, 1.48, -0.05], [2.28, 0.12, 1.32]),
        box("StallClusterB_TableTop", "shadow_wood", [2.46, 0.66, 0.28], [1.78, 0.16, 0.78]),
        box("StallClusterB_ShelfLower", "shadow_wood", [2.46, 0.46, 0.28], [1.56, 0.1, 0.66]),
        box("StallClusterC_BackRack", "shadow_wood", [0.12, 1.12, -1.92], [2.0, 1.15, 0.14]),
        box("StallClusterC_TopShelf", "shadow_wood", [0.12, 1.58, -1.78], [1.9, 0.1, 0.38]),
        box("StallClusterC_LowerShelf", "shadow_wood", [0.12, 0.98, -1.78], [1.9, 0.1, 0.38]),
    ]
    prop_positions = [
        ("A", -3.62, 0.83, 0.58), ("A", -3.22, 0.83, 0.3), ("A", -2.78, 0.82, 0.72), ("A", -2.42, 0.8, 0.42),
        ("B", 1.78, 0.82, 0.22), ("B", 2.24, 0.82, 0.58), ("B", 2.72, 0.82, 0.18), ("B", 3.08, 0.8, 0.62),
        ("C", -0.58, 1.18, -1.55), ("C", -0.12, 1.2, -1.52), ("C", 0.34, 1.18, -1.55), ("C", 0.72, 1.16, -1.52),
    ]
    for index, (cluster, x, y, z) in enumerate(prop_positions):
        material = "ceramic" if index % 3 != 0 else "dark"
        nodes.append(cylinder("StallCluster%s_CeramicJar%02d" % (cluster, index), material, [x, y, z], [0.14, 0.28, 0.14]))
        if index % 2 == 0:
            nodes.append(cylinder("StallCluster%s_PlateStack%02d" % (cluster, index), "ceramic", [x + 0.18, y - 0.08, z + 0.08], [0.22, 0.045, 0.22]))
    nodes.extend([
        box("StallClusterA_FabricDrop", "fabric_red", [-3.05, 0.47, 1.0], [1.3, 0.45, 0.04]),
        box("StallClusterB_FabricDrop", "fabric_teal", [2.46, 0.46, 0.68], [1.3, 0.42, 0.04]),
        box("StallClusterC_HangingGoods", "fabric_red", [0.86, 1.18, -1.45], [0.22, 0.58, 0.04]),
    ])
    return nodes


def wall_detail_nodes():
    nodes = [
        box("WallTrimBackHorizontalLower", "wall_trim", [0.0, 1.02, -3.08], [5.8, 0.08, 0.09]),
        box("WallTrimBackHorizontalUpper", "wall_trim", [0.0, 2.18, -3.08], [5.8, 0.08, 0.09]),
        box("WallTrimBackEaveShadow", "dark", [0.0, 2.76, -3.0], [6.2, 0.18, 0.42]),
    ]
    for i, x in enumerate([-2.6, -1.42, -0.22, 1.12, 2.48]):
        nodes.append(box("WallTrimBackVertical%02d" % i, "wall_trim", [x, 1.62, -3.08], [0.08, 1.18, 0.09]))
    for i, x in enumerate([-3.2, -2.0, -0.8, 0.56, 1.78, 2.88]):
        nodes.append(box("WindowFrameBack%02d" % i, "wall_trim", [x, 2.02, -3.0], [0.44, 0.58, 0.08]))
        nodes.append(box("BackLanternShell%02d" % i, "emission_lantern", [x + 0.34, 1.72, -2.86], [0.16, 0.23, 0.16]))
    nodes.extend([
        box("DoorFrameLeftShopA", "wall_trim", [-5.42, 1.42, 0.54], [0.1, 1.28, 0.08]),
        box("DoorFrameLeftShopB", "wall_trim", [-5.42, 1.42, 1.18], [0.1, 1.28, 0.08]),
        box("WindowFrameLeftUpper", "wall_trim", [-5.34, 2.18, -0.28], [0.1, 0.76, 0.68]),
        box("DoorFrameRightShopA", "wall_trim", [5.48, 1.4, 0.18], [0.1, 1.18, 0.08]),
        box("DoorFrameRightShopB", "wall_trim", [5.48, 1.4, 0.82], [0.1, 1.18, 0.08]),
    ])
    return nodes


def foreground_nodes():
    return [
        box("ForegroundLowWallArtpassCenter", "dark", [0.0, 0.26, 4.42], [8.6, 0.34, 0.34]),
        box("ForegroundStepArtpassLeftA", "dark", [-4.16, 0.16, 3.72], [3.4, 0.18, 0.78]),
        box("ForegroundStepArtpassLeftB", "stone", [-3.18, 0.28, 3.36], [1.3, 0.16, 0.36]),
        box("ForegroundStepArtpassRightA", "dark", [4.22, 0.15, 3.62], [3.3, 0.18, 0.76]),
        box("ForegroundStepArtpassRightB", "stone", [3.24, 0.27, 3.26], [1.25, 0.15, 0.34]),
        box("ForegroundLowWallCornerStoneA", "stone", [-5.7, 0.42, 4.18], [0.72, 0.36, 0.44]),
        box("ForegroundLowWallCornerStoneB", "stone", [5.48, 0.4, 4.08], [0.66, 0.34, 0.42]),
    ]


def combined_artpass_nodes():
    return right_tower_nodes() + stall_nodes() + wall_detail_nodes() + foreground_nodes()


def main():
    write_glb(MODEL_DIR / "hd2d_market_reference_match_artpass.glb", combined_artpass_nodes(), "hd2d_market_reference_match_artpass")
    write_glb(MODEL_DIR / "hd2d_market_prop_wall_detail_set.glb", wall_detail_nodes(), "hd2d_market_prop_wall_detail_set")
    write_glb(MODEL_DIR / "hd2d_market_prop_stall_detail_set.glb", stall_nodes(), "hd2d_market_prop_stall_detail_set")
    write_glb(MODEL_DIR / "hd2d_market_prop_right_tower_set.glb", right_tower_nodes(), "hd2d_market_prop_right_tower_set")


if __name__ == "__main__":
    main()
